package com.makhanchor.broadcastautomator

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
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
        private const val SEND_TIMEOUT_MS = 20000L
        private const val DELAY_BETWEEN_CONTACTS_MS = 800L

        private val SEND_LABELS = listOf(
            "send",
            "senden",
            "enviar",
            "envoyer",
            "invia",
            "kirim",
            "发送",
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
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var job: WaJob? = null
    private var running = false
    private var paused = false
    private var stopped = false
    private var currentIndex = 0
    private var sent = 0
    private var failed = 0
    private var elapsedRunTimeMs = 0L
    private var lastResumeTimeMs = 0L

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
        // UI automation is driven by polling, not events.
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
        elapsedRunTimeMs = 0L
        lastResumeTimeMs = System.currentTimeMillis()

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

        val message = resolveMessage(j.message, contact.name)
        val intent: Intent = if (!j.attachmentPath.isNullOrEmpty() && !j.attachmentMime.isNullOrEmpty()) {
            val file = File(j.attachmentPath)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            Intent(Intent.ACTION_SEND).apply {
                type = j.attachmentMime
                putExtra(Intent.EXTRA_TEXT, message)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra("jid", "$phone@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        } else {
            val link = "https://wa.me/$phone?text=" + URLEncoder.encode(message, "UTF-8")
            Intent(Intent.ACTION_VIEW, Uri.parse(link))
        }
        intent.setPackage(pkg)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
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
        val send = findSendButton(root)
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
        } else if (elapsed >= SEND_TIMEOUT_MS) {
            retryOrFail(j, contact, attempt)
        } else {
            mainHandler.postDelayed(
                { waitForSendButton(j, contact, attempt, elapsed + POLL_MS) },
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
        if (j.skipInvalid) {
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
        failed++
        markContact(contact, "Failed")
        currentIndex++
        pushStatus()
        mainHandler.postDelayed({ processNext() }, DELAY_BETWEEN_CONTACTS_MS)
    }

    private fun markSent(contact: WaContact) {
        if (!running || stopped) return
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
        if (contact.id.isEmpty()) return
        SupabaseSync.patch("contacts", contact.id, mapOf("status" to status))
    }

    private fun updateCampaign(fields: Map<String, Any>) {
        val campaignId = job?.campaignId ?: return
        SupabaseSync.patch("campaigns", campaignId, fields)
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

    private fun whatsAppPackage(): String? {
        val candidates = listOf("com.whatsapp", "com.whatsapp.w4b")
        return candidates.firstOrNull { pkg ->
            try {
                packageManager.getPackageInfo(pkg, 0)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun isWhatsAppWindow(packageName: String?): Boolean =
        packageName?.startsWith("com.whatsapp") == true

    private fun resolveMessage(template: String, name: String): String =
        template.replace("{Name}", name.ifEmpty { "there" })

    private fun normalizePhone(raw: String): String {
        var digits = raw.filter { it.isDigit() }
        if (digits.isEmpty()) return ""
        if (digits.startsWith("0")) digits = digits.drop(1)
        if (digits.length == 10) digits = "91$digits"
        return digits
    }

    private fun findSendButton(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var fallback: AccessibilityNodeInfo? = null
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val vid = node.viewIdResourceName
            val desc = node.contentDescription?.toString()?.lowercase() ?: ""
            if (vid != null && (vid.endsWith("/send") || vid.endsWith("/send_button") || vid.contains("id/send"))) {
                return node
            }
            if (desc.isNotEmpty() && SEND_LABELS.any { desc.contains(it) }) {
                return node
            }
            if (vid != null && vid.contains("send") && fallback == null) {
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
