package com.makhanchor.broadcastautomator

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.WindowManager
import androidx.core.content.FileProvider
import java.io.File
import java.net.URLEncoder
import java.util.ArrayDeque

/**
 * Accessibility service that drives WhatsApp to send a queued broadcast.
 * Opens each contact's chat, taps send, and advances until done, while a
 * system overlay (ProgressOverlayView) shows live progress on top of
 * WhatsApp.
 */
class WhatsAppAutomationService : AccessibilityService() {

    companion object {
        const val ACTION_START = "com.makhanchor.broadcastautomator.action.START"
        const val ACTION_STOP = "com.makhanchor.broadcastautomator.action.STOP"
        const val ACTION_PAUSE = "com.makhanchor.broadcastautomator.action.PAUSE"
        const val ACTION_RESUME = "com.makhanchor.broadcastautomator.action.RESUME"
        const val ACTION_PAUSE_RESUME = "com.makhanchor.broadcastautomator.action.PAUSE_RESUME"

        private const val POLL_MS = 400L
        private const val SETTLE_MS = 1200L
        private const val CONFIRM_MS = 1600L
        private const val SEND_TIMEOUT_MS = 12000L
        private const val DELAY_BETWEEN_CONTACTS_MS = 800L

        private val SEND_LABELS = listOf(
            "send",
            "senden",
            "enviar",
            "envoyer",
            "invia",
            "kirim",
            "发送",
            "bhejein",
            "bhejo",
        )

        private var serviceInstance: WhatsAppAutomationService? = null
        fun instance() = serviceInstance

        fun isAccessibilityEnabled(context: Context): Boolean {
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            return enabled.split(':').any { entry ->
                entry.contains(context.packageName) &&
                    entry.contains(WhatsAppAutomationService::class.java.simpleName)
            }
        }

        private var manualSendContactId: String? = null
        private var manualSendPhone: String? = null
        private var manualSendActive: Boolean = false

        fun prepareManualSend(contactId: String?, phone: String?) {
            manualSendContactId = contactId
            manualSendPhone = phone
            manualSendActive = !contactId.isNullOrEmpty() || !phone.isNullOrEmpty()
        }

        fun whatsAppPackage(context: Context): String? {
            val candidates = listOf("com.whatsapp", "com.whatsapp.w4b")
            return candidates.firstOrNull { pkg ->
                try {
                    context.packageManager.getPackageInfo(pkg, 0)
                    true
                } catch (_: Exception) {
                    false
                }
            }
        }

        fun normalizePhoneUtil(raw: String): String {
            val trimmed = raw.trim()
            if (trimmed.isEmpty()) return ""

            var digits = trimmed.filter { it.isDigit() }
            if (digits.isEmpty()) return ""

            while (digits.startsWith("00")) {
                digits = digits.drop(2)
            }

            val hasPlus = trimmed.startsWith("+")
            if (hasPlus) {
                if (digits.startsWith("910") && digits.length == 13) {
                    digits = "91" + digits.substring(3)
                }
            } else {
                if (digits.startsWith("0") && digits.length == 11) {
                    digits = digits.drop(1)
                }
                if (digits.length == 10) {
                    digits = "91$digits"
                } else if (digits.startsWith("910") && digits.length == 13) {
                    digits = "91" + digits.substring(3)
                }
            }

            if (digits.length < 10) {
                return ""
            }

            return digits
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var job: WaJob? = null
    private var running = false
    private var paused = false
    private var stopped = false
    private var currentIndex = 0
    private var sent = 0
    private var failed = 0
    private var skipped = 0
    private var elapsedRunTimeMs = 0L
    private var lastResumeTimeMs = 0L
    private var customStatusText: String? = null

    private var overlayView: ProgressOverlayView? = null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_START -> startJob()
                ACTION_STOP -> stopJob(false)
                ACTION_PAUSE -> pauseJob()
                ACTION_RESUME -> resumeJob()
                ACTION_PAUSE_RESUME -> if (paused) resumeJob() else pauseJob()
            }
        }
    }

    // ---- Lifecycle ----

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInstance = this
        val filter = IntentFilter().apply {
            addAction(ACTION_START)
            addAction(ACTION_STOP)
            addAction(ACTION_PAUSE)
            addAction(ACTION_RESUME)
            addAction(ACTION_PAUSE_RESUME)
        }
        registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (manualSendActive && event != null) {
            if (event.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
                val source = event.source
                val vid = source?.viewIdResourceName?.lowercase() ?: ""
                val desc = (event.contentDescription ?: source?.contentDescription)?.toString()?.lowercase() ?: ""
                val text = (event.text?.joinToString(" ") ?: source?.text?.toString())?.lowercase() ?: ""

                val isVoice = desc.contains("voice") || desc.contains("mic") ||
                    desc.contains("audio") || desc.contains("record")

                val isSend = !isVoice && (
                    vid.contains("send") ||
                    (desc.isNotEmpty() && SEND_LABELS.any { desc == it || desc.contains(it) }) ||
                    (text.isNotEmpty() && SEND_LABELS.any { text == it || text.contains(it) })
                )

                if (isSend) {
                    val cid = manualSendContactId
                    val cPhone = manualSendPhone
                    manualSendActive = false
                    manualSendContactId = null
                    manualSendPhone = null

                    if (!cid.isNullOrEmpty()) {
                        LocalDbSync.update(this, "contacts", cid, mapOf("status" to "Sent"))
                        BroadcastStore.recordContactResult(this, cid, "", cPhone ?: "", "Sent")
                    } else if (!cPhone.isNullOrEmpty()) {
                        BroadcastStore.recordContactResult(this, "", "", cPhone, "Sent")
                    }

                    mainHandler.postDelayed({
                        performGlobalAction(GLOBAL_ACTION_BACK)
                        mainHandler.postDelayed({
                            relaunchApp()
                        }, 400L)
                    }, 500L)
                }
            }
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(receiver)
        } catch (_: Exception) {
        }
        hideOverlay()
        serviceInstance = null
        super.onDestroy()
    }

    override fun onUnbind(intent: Intent?): Boolean {
        stopJob(true)
        return super.onUnbind(intent)
    }

    // ---- Job control ----

    private fun startJob() {
        val loaded = BroadcastStore.loadJob(this) ?: return
        if (running) return
        if (loaded.contacts.isEmpty()) return

        job = loaded
        running = true
        paused = false
        stopped = false
        currentIndex = 0
        sent = 0
        failed = 0
        skipped = 0
        elapsedRunTimeMs = 0L
        lastResumeTimeMs = System.currentTimeMillis()

        BroadcastStore.setStartTime(this, System.currentTimeMillis())
        loaded.contacts.forEach { c ->
            BroadcastStore.recordContactResult(this, c.id, c.name, c.phone, "Pending")
        }

        updateCampaign(mapOf("status" to "Sending", "current_index" to 0))
        pushStatus()
        showOverlay()
        processNext()
    }

    private fun pauseJob() {
        if (!running || paused) return
        paused = true
        elapsedRunTimeMs += System.currentTimeMillis() - lastResumeTimeMs
        pushStatus()
    }

    private fun resumeJob() {
        if (!running || !paused) return
        paused = false
        elapsedRunTimeMs = 0L
        lastResumeTimeMs = System.currentTimeMillis()
        pushStatus()
        mainHandler.post { processNext() }
    }

    private fun stopJob(quiet: Boolean) {
        if (!running) return
        running = false
        stopped = true
        BroadcastStore.setEndTime(this, System.currentTimeMillis())
        job?.let {
            updateCampaign(mapOf("status" to "Stopped"))
            BroadcastStore.clearJob(this)
        }
        pushStatus()
        if (!quiet) {
            mainHandler.postDelayed({
                hideOverlay()
                relaunchApp()
            }, 800)
        } else {
            hideOverlay()
        }
    }

    private fun finishJob() {
        running = false
        BroadcastStore.setEndTime(this, System.currentTimeMillis())
        val j = job
        if (j != null) {
            updateCampaign(mapOf("status" to "Completed", "current_index" to j.contacts.size))
            BroadcastStore.clearJob(this)
        }
        pushStatus()
        mainHandler.postDelayed({
            hideOverlay()
            relaunchApp()
        }, 2500)
    }

    // ---- Send loop ----

    private fun processNext() {
        val j = job ?: return
        if (!running || stopped) return
        if (paused) {
            updateOverlay()
            return
        }

        // Auto pause check
        if (j.autoPauseMinutes > 0) {
            val activeTimeMs = elapsedRunTimeMs + (System.currentTimeMillis() - lastResumeTimeMs)
            if (activeTimeMs >= j.autoPauseMinutes * 60 * 1000) {
                pauseJob()
                updateOverlay()
                return
            }
        }

        if (currentIndex >= j.contacts.size) {
            finishJob()
            return
        }
        updateOverlay()
        val contact = j.contacts[currentIndex]
        launchChat(j, contact, attempt = 1)
    }

    private fun launchChat(j: WaJob, contact: WaContact, attempt: Int) {
        val pkg = whatsAppPackage()
        if (pkg == null) {
            handleFailure(contact)
            return
        }
        val phone = normalizePhone(contact.phone)
        if (phone.isEmpty()) {
            handleInvalid(contact)
            return
        }

        val message = resolveMessage(j.message, contact)
        val validAttachments = j.attachments.filter { it.path.isNotEmpty() && File(it.path).exists() }

        val intent: Intent = when {
            validAttachments.size > 1 -> {
                val uriList = ArrayList<Uri>()
                validAttachments.forEach { att ->
                    val file = File(att.path)
                    val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                    uriList.add(uri)
                    grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                var commonMime = "*/*"
                val mimeTypes = validAttachments.map { it.mimeType.lowercase() }.toSet()
                if (mimeTypes.all { it.startsWith("image/") }) {
                    commonMime = "image/*"
                } else if (mimeTypes.all { it.startsWith("video/") }) {
                    commonMime = "video/*"
                } else if (mimeTypes.all { it.startsWith("audio/") }) {
                    commonMime = "audio/*"
                }
                Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    type = commonMime
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uriList)
                    val clipData = ClipData.newUri(contentResolver, "attachment_0", uriList.first())
                    for (i in 1 until uriList.size) {
                        clipData.addItem(ClipData.Item(uriList[i]))
                    }
                    this.clipData = clipData
                    putExtra("jid", "$phone@s.whatsapp.net")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            validAttachments.size == 1 -> {
                val att = validAttachments.first()
                val file = File(att.path)
                val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                Intent(Intent.ACTION_SEND).apply {
                    type = att.mimeType.ifEmpty { "*/*" }
                    putExtra(Intent.EXTRA_TEXT, message)
                    putExtra(Intent.EXTRA_STREAM, uri)
                    clipData = ClipData.newUri(contentResolver, "attachment", uri)
                    putExtra("jid", "$phone@s.whatsapp.net")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            !j.attachmentPath.isNullOrEmpty() && !j.attachmentMime.isNullOrEmpty() && File(j.attachmentPath).exists() -> {
                val file = File(j.attachmentPath)
                val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                Intent(Intent.ACTION_SEND).apply {
                    type = j.attachmentMime
                    putExtra(Intent.EXTRA_TEXT, message)
                    putExtra(Intent.EXTRA_STREAM, uri)
                    clipData = ClipData.newUri(contentResolver, "attachment", uri)
                    putExtra("jid", "$phone@s.whatsapp.net")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            else -> {
                val encoded = Uri.encode(message)
                val link = "https://api.whatsapp.com/send?phone=$phone&text=$encoded"
                Intent(Intent.ACTION_VIEW, Uri.parse(link))
            }
        }
        intent.setPackage(pkg)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(intent)
        } catch (_: Exception) {
            handleFailure(contact)
            return
        }
        mainHandler.postDelayed(
            { waitForSendButton(j, contact, attempt, 0L) },
            SETTLE_MS,
        )
    }

    private fun waitForSendButton(
        j: WaJob,
        contact: WaContact,
        attempt: Int,
        elapsed: Long,
    ) {
        if (!running || stopped) return
        if (paused) {
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, elapsed) },
                POLL_MS,
            )
            return
        }
        val root = rootInActiveWindow ?: run {
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, elapsed + POLL_MS) },
                POLL_MS,
            )
            return
        }
        if (!isWhatsAppWindow(root.packageName?.toString())) {
            // Still on our app (or another window) while WhatsApp loads.
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, elapsed + POLL_MS) },
                POLL_MS,
            )
            return
        }

        // 1. Check for modal error dialogs (e.g. "isn't on WhatsApp", "invalid number")
        if (detectAndDismissWhatsAppDialog(root)) {
            handleInvalid(contact)
            return
        }

        // 2. Populate input / caption if inside chat
        val message = resolveMessage(j.message, contact)
        val validAttachments = j.attachments.filter { it.path.isNotEmpty() && File(it.path).exists() }
        if (validAttachments.size > 1 && message.isNotEmpty()) {
            populateCaptionIfPresent(root, message)
        } else if (validAttachments.isEmpty() && message.isNotEmpty()) {
            populateChatInputIfEmpty(root, message)
        }

        // 3. Look for send button
        val send = findSendButton(root)
        if (send != null) {
            val preSendDelay = j.preSendDelaySeconds
            if (preSendDelay > 0) {
                startPreSendCountdown(j, contact, attempt, preSendDelay)
            } else {
                executeSendClick(j, contact, attempt)
            }
            return
        }

        // 4. Recovery: If after 2.4s or 4.8s we are still not inside a chat (e.g. stuck on HomeActivity)
        if ((elapsed == 2400L || elapsed == 4800L) && !isInsideChat(root)) {
            dismissSearchModeIfActive(root)
            relaunchChatIntent(j, contact)
        }

        if (elapsed >= SEND_TIMEOUT_MS) {
            retryOrFail(j, contact, attempt)
        } else {
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, elapsed + POLL_MS) },
                POLL_MS,
            )
        }
    }

    private fun startPreSendCountdown(
        j: WaJob,
        contact: WaContact,
        attempt: Int,
        secondsRemaining: Int,
    ) {
        if (!running || stopped) return
        if (paused) {
            mainHandler.postDelayed(
                { startPreSendCountdown(j, contact, attempt, secondsRemaining) },
                POLL_MS,
            )
            return
        }
        if (secondsRemaining <= 0) {
            customStatusText = null
            updateOverlay()
            executeSendClick(j, contact, attempt)
            return
        }

        customStatusText = "Sending in ${secondsRemaining}s..."
        updateOverlay()

        mainHandler.postDelayed(
            { startPreSendCountdown(j, contact, attempt, secondsRemaining - 1) },
            1000L,
        )
    }

    private fun executeSendClick(
        j: WaJob,
        contact: WaContact,
        attempt: Int,
    ) {
        if (!running || stopped) return
        if (paused) {
            mainHandler.postDelayed(
                { executeSendClick(j, contact, attempt) },
                POLL_MS,
            )
            return
        }
        customStatusText = null
        val root = rootInActiveWindow
        val send = if (root != null && isWhatsAppWindow(root.packageName?.toString())) {
            findSendButton(root)
        } else {
            null
        }

        if (send != null) {
            val clicked = performClickOnNearestClickable(send)
            if (!clicked) {
                retryOrFail(j, contact, attempt)
                return
            }
            mainHandler.postDelayed(
                {
                    if (!running || stopped) return@postDelayed
                    markSent(contact)
                },
                CONFIRM_MS,
            )
        } else {
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, 0L) },
                POLL_MS,
            )
        }
    }

    private fun retryOrFail(j: WaJob, contact: WaContact, attempt: Int) {
        if (j.autoRetry && attempt <= 1) {
            launchChat(j, contact, attempt + 1)
        } else {
            handleFailure(contact)
        }
    }

    private fun handleInvalid(contact: WaContact) {
        val j = job ?: return
        customStatusText = null
        if (j.skipInvalid) {
            skipped++
            markContact(contact, "Skipped")
        } else {
            failed++
            markContact(contact, "Failed")
        }
        currentIndex++
        pushStatus()
        mainHandler.postDelayed({ processNext() }, DELAY_BETWEEN_CONTACTS_MS)
    }

    private fun handleFailure(contact: WaContact) {
        if (!running || stopped) return
        customStatusText = null
        failed++
        markContact(contact, "Failed")
        currentIndex++
        pushStatus()
        mainHandler.postDelayed({ processNext() }, DELAY_BETWEEN_CONTACTS_MS)
    }

    private fun markSent(contact: WaContact) {
        if (!running || stopped) return
        customStatusText = null
        sent++
        markContact(contact, "Sent")
        currentIndex++
        pushStatus()
        val j = job
        val base = j?.delaySeconds?.times(1000) ?: 6000
        val extra = if (j?.randomizeDelay == true) {
            (0..6000).random() - 3000
        } else {
            0
        }
        mainHandler.postDelayed(
            { processNext() },
            (base + extra).coerceAtLeast(1500).toLong(),
        )
    }

    private fun markContact(contact: WaContact, status: String) {
        BroadcastStore.recordContactResult(this, contact.id, contact.name, contact.phone, status)
        if (contact.id.isNotEmpty()) {
            LocalDbSync.update(this, "contacts", contact.id, mapOf("status" to status))
        }
    }

    private fun updateCampaign(fields: Map<String, Any>) {
        val campaignId = job?.campaignId ?: return
        LocalDbSync.update(this, "campaigns", campaignId, fields)
    }

    // ---- Overlay + state ----

    private fun currentState(): BroadcastState {
        val j = job
        val currentContact = j?.contacts?.getOrNull(currentIndex)
        return BroadcastState(
            campaignId = j?.campaignId ?: "",
            campaignName = j?.campaignName ?: "",
            running = running,
            paused = paused,
            currentIndex = currentIndex,
            total = j?.contacts?.size ?: 0,
            sent = sent,
            failed = failed,
            currentContactName = currentContact?.name ?: "",
            currentContactPhone = currentContact?.phone ?: "",
            delaySeconds = j?.delaySeconds ?: 6,
            statusText = customStatusText,
        )
    }

    private fun pushStatus() {
        val j = job
        BroadcastStore.setStatus(
            this,
            j?.campaignId,
            j?.campaignName,
            running,
            paused,
            currentIndex,
            j?.contacts?.size ?: 0,
            sent,
            failed,
            skipped,
        )
        updateOverlay()
    }

    private fun showOverlay() {
        if (overlayView != null) return
        try {
            overlayView = ProgressOverlayView.show(this, currentState())
        } catch (_: Exception) {
        }
    }

    private fun updateOverlay() {
        overlayView?.update(currentState())
    }

    private fun hideOverlay() {
        overlayView?.let { view ->
            try {
                (getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(view)
            } catch (_: Exception) {
            }
        }
        overlayView = null
    }

    private fun relaunchApp() {
        try {
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP,
            )
            startActivity(intent)
        } catch (_: Exception) {
        }
    }

    // ---- Helpers ----

    private fun whatsAppPackage(): String? = whatsAppPackage(this)

    private fun normalizePhone(raw: String): String = normalizePhoneUtil(raw)

    private fun isWhatsAppWindow(packageName: String?): Boolean =
        packageName?.startsWith("com.whatsapp") == true

    private fun resolveMessage(template: String, contact: WaContact): String {
        var result = template
        val nameRegex = Regex("""\{\{\s*name\s*\}\}|\{\s*name\s*\}""", RegexOption.IGNORE_CASE)
        result = nameRegex.replace(result) { contact.name.trim() }

        val phoneRegex = Regex("""\{\{\s*(?:number|phone)\s*\}\}|\{\s*(?:number|phone)\s*\}""", RegexOption.IGNORE_CASE)
        result = phoneRegex.replace(result) { contact.phone.trim() }

        contact.extraFields.forEach { (key, value) ->
            if (key.isNotBlank()) {
                val escapedKey = Regex.escape(key.trim())
                val dynamicRegex = Regex("""\{\{\s*$escapedKey\s*\}\}|\{\s*$escapedKey\s*\}""", RegexOption.IGNORE_CASE)
                result = dynamicRegex.replace(result) { value.trim() }
            }
        }
        return result
    }

    private fun isInsideChat(root: AccessibilityNodeInfo): Boolean {
        return findChatInput(root) != null || findSendButton(root) != null || findCaptionInput(root) != null
    }

    private fun dismissSearchModeIfActive(root: AccessibilityNodeInfo) {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName?.lowercase() ?: ""
            if (vid.contains("search_back") || vid.contains("search_close") || vid.contains("clear_search")) {
                performClickOnNearestClickable(node)
                return
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
    }

    private fun relaunchChatIntent(j: WaJob, contact: WaContact) {
        try {
            val pkg = whatsAppPackage() ?: return
            val phone = normalizePhone(contact.phone)
            if (phone.isEmpty()) return
            val message = resolveMessage(j.message, contact)
            val encoded = Uri.encode(message)
            val link = "https://api.whatsapp.com/send?phone=$phone&text=$encoded"
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link)).apply {
                setPackage(pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun detectAndDismissWhatsAppDialog(root: AccessibilityNodeInfo): Boolean {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var dialogDetected = false
        var okButton: AccessibilityNodeInfo? = null

        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName?.lowercase() ?: ""
            val text = node.text?.toString()?.lowercase() ?: ""
            val desc = node.contentDescription?.toString()?.lowercase() ?: ""

            if (text.contains("isn't on whatsapp") ||
                text.contains("is not on whatsapp") ||
                text.contains("not on whatsapp") ||
                text.contains("shared via url is invalid") ||
                text.contains("url is invalid") ||
                text.contains("couldn't find contact") ||
                text.contains("não está no whatsapp") ||
                text.contains("não é cadastrado") ||
                text.contains("no está en whatsapp") ||
                text.contains("pas sur whatsapp") ||
                text.contains("nicht auf whatsapp")
            ) {
                dialogDetected = true
            }

            if (vid.endsWith("/button1") || vid.endsWith("/button2") || vid.contains("id/ok") || vid.endsWith("/close")) {
                okButton = node
            } else if (text == "ok" || text == "dismiss" || text == "cancel" || desc == "ok") {
                okButton = node
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }

        if (dialogDetected) {
            if (okButton != null) {
                performClickOnNearestClickable(okButton)
            } else {
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
            return true
        }
        return false
    }

    private fun populateCaptionIfPresent(root: AccessibilityNodeInfo, message: String): Boolean {
        if (message.isEmpty()) return false
        val captionNode = findCaptionInput(root) ?: return false
        val currentText = captionNode.text?.toString() ?: ""
        if (currentText == message) {
            return true
        }
        val arguments = Bundle().apply {
            putCharSequence(
                AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                message,
            )
        }
        return captionNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    private fun findCaptionInput(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName?.lowercase() ?: ""
            val cls = node.className?.toString() ?: ""
            val hint = node.hintText?.toString()?.lowercase() ?: ""
            val desc = node.contentDescription?.toString()?.lowercase() ?: ""

            if (!vid.contains("search") && !hint.contains("search") && !desc.contains("search")) {
                if (cls.contains("EditText") || node.isEditable) {
                    if (vid.contains("caption") || hint.contains("caption") || desc.contains("caption")) {
                        return node
                    }
                }
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    private fun populateChatInputIfEmpty(root: AccessibilityNodeInfo, message: String): Boolean {
        if (message.isEmpty()) return false
        val inputNode = findChatInput(root) ?: return false
        val currentText = inputNode.text?.toString() ?: ""
        if (currentText.isNotEmpty()) {
            return true
        }
        val arguments = Bundle().apply {
            putCharSequence(
                AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                message,
            )
        }
        return inputNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    private fun findChatInput(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName?.lowercase() ?: ""
            val cls = node.className?.toString() ?: ""
            val hint = node.hintText?.toString()?.lowercase() ?: ""
            val desc = node.contentDescription?.toString()?.lowercase() ?: ""

            // Do NOT match search bars or filters!
            if (!vid.contains("search") && !vid.contains("filter") &&
                !hint.contains("search") && !desc.contains("search")) {
                if (cls.contains("EditText") || node.isEditable) {
                    if (vid.endsWith("/entry") || vid.contains("id/entry") || vid.contains("conversation_text_entry")) {
                        return node
                    }
                }
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    private fun findSendButton(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var fallback: AccessibilityNodeInfo? = null
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName?.lowercase() ?: ""
            val desc = node.contentDescription?.toString()?.lowercase() ?: ""

            // Exclude voice message / microphone button
            val isVoice = desc.contains("voice") || desc.contains("mic") ||
                desc.contains("audio") || desc.contains("record")
            if (isVoice) {
                for (i in 0 until node.childCount) {
                    node.getChild(i)?.let { queue.add(it) }
                }
                continue
            }

            if (vid.endsWith("/send") || vid.endsWith("/send_button") || vid.contains("id/send")) {
                return node
            }
            if (desc.isNotEmpty() && SEND_LABELS.any { desc == it || desc.contains(it) }) {
                return node
            }
            if (vid.contains("send") && fallback == null) {
                fallback = node
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return fallback
    }

    private fun performClickOnNearestClickable(
        node: AccessibilityNodeInfo,
    ): Boolean {
        var current: AccessibilityNodeInfo? = node
        while (current != null) {
            if (current.isClickable) {
                return current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
            current = current.parent
        }
        return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }
}
