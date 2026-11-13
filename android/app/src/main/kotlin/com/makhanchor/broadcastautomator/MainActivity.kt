package com.makhanchor.broadcastautomator

import android.Manifest
import android.content.ContentResolver
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.ContactsContract
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.net.URLDecoder

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.makhanchor.broadcastautomator/native"
        private const val TAG = "BroadcastAutomator"
        private const val REQ_PICK_FILE = 4201
        private const val REQ_PICK_CONTACT = 4202
        private const val REQ_CONTACTS_PERMISSION = 4203
    }

    private var pendingPicker: ((Uri?) -> Unit)? = null
    private var pendingContactPicker: ((Uri?) -> Unit)? = null
    private var pendingContactsChannelResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveJob" -> handleSaveJob(call, result)
                    "startBroadcast" -> handleStartBroadcast(call, result)
                    "stopBroadcast" -> sendControlAction(
                        WhatsAppAutomationService.ACTION_STOP, result,
                    )
                    "pauseBroadcast" -> sendControlAction(
                        WhatsAppAutomationService.ACTION_PAUSE, result,
                    )
                    "resumeBroadcast" -> sendControlAction(
                        WhatsAppAutomationService.ACTION_RESUME, result,
                    )
                    "getBroadcastStatus" -> result.success(BroadcastStore.getStatusMap(this))
                    "getBroadcastReport" -> result.success(BroadcastStore.getReportMap(this))
                    "isAccessibilityEnabled" ->
                        result.success(WhatsAppAutomationService.isAccessibilityEnabled(this))
                    "openAccessibilitySettings" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                            )
                        } catch (_: Exception) {
                        }
                        result.success(true)
                    }
                    "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))
                    "openOverlaySettings" -> {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName"),
                                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                            )
                        } catch (_: Exception) {
                        }
                        result.success(true)
                    }
                    "pickCsv" -> pickFile(
                        arrayOf(
                            "text/csv",
                            "text/comma-separated-values",
                            "application/csv",
                            "text/plain",
                        ),
                    ) { uri ->
                        if (uri == null) {
                            result.error("cancelled", "File selection cancelled", null)
                        } else {
                            try {
                                val name = queryDisplayName(uri)
                                if (!name.endsWith(".csv", ignoreCase = true)) {
                                    result.error("invalid_file_type", "Only .csv files are allowed", null)
                                    return@pickFile
                                }
                                val content = contentResolver.openInputStream(uri)
                                    ?.bufferedReader()?.use { it.readText() }
                                if (content == null) {
                                    result.error("read_failed", "Could not read file", null)
                                } else {
                                    result.success(
                                        mapOf(
                                            "content" to content,
                                            "name" to name,
                                        ),
                                    )
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "pickCsv failed", e)
                                result.error("read_failed", e.message, null)
                            }
                        }
                    }
                    "pickAttachment" -> pickFile(
                        arrayOf(
                            "image/*",
                            "video/*",
                            "audio/*",
                            "application/pdf",
                            "application/msword",
                            "application/vnd.openxmlformats-officedocument.*",
                            "*/*",
                        ),
                    ) { uri ->
                        if (uri == null) {
                            result.error("cancelled", "File selection cancelled", null)
                        } else {
                            try {
                                val picked = copyToInternal(uri)
                                if (picked == null) {
                                    result.error("read_failed", "Could not copy file", null)
                                } else {
                                    result.success(picked)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "pickAttachment failed", e)
                                result.error("read_failed", e.message, null)
                            }
                        }
                    }
                    "hasContactsPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this, Manifest.permission.READ_CONTACTS
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    "getDeviceContacts" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this, Manifest.permission.READ_CONTACTS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(fetchAllContacts())
                        } else {
                            pendingContactsChannelResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.READ_CONTACTS),
                                REQ_CONTACTS_PERMISSION
                            )
                        }
                    }
                    "pickSingleContact" -> {
                        pickContact { uri ->
                            if (uri == null) {
                                result.error("cancelled", "Contact selection cancelled", null)
                            } else {
                                try {
                                    var name = ""
                                    var phone = ""
                                    contentResolver.query(
                                        uri,
                                        arrayOf(
                                            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                                            ContactsContract.CommonDataKinds.Phone.NUMBER
                                        ),
                                        null,
                                        null,
                                        null
                                    )?.use { cursor ->
                                        if (cursor.moveToFirst()) {
                                            val nIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                                            val pIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                                            if (nIdx >= 0) name = cursor.getString(nIdx) ?: ""
                                            if (pIdx >= 0) phone = cursor.getString(pIdx) ?: ""
                                        }
                                    }
                                    val cleanPhone = phone.replace(Regex("[^0-9+]"), "")
                                    if (cleanPhone.isEmpty()) {
                                        result.error("no_phone", "Selected contact has no phone number", null)
                                    } else {
                                        result.success(mapOf("name" to name.trim(), "phone" to cleanPhone))
                                    }
                                } catch (e: Exception) {
                                    Log.e(TAG, "pickSingleContact failed", e)
                                    result.error("read_failed", e.message, null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sendControlAction(action: String, result: MethodChannel.Result) {
        try {
            sendBroadcast(Intent(action).setPackage(packageName))
        } catch (e: Exception) {
            Log.e(TAG, "sendControlAction failed", e)
        }
        result.success(true)
    }

    private fun handleSaveJob(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("bad_args", "Invalid arguments", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val rawContacts = (args["contacts"] as? List<*>) ?: emptyList<Any>()
        val contacts = rawContacts.mapNotNull { it as? Map<*, *> }.map { m ->
            WaContact(
                id = m["id"]?.toString() ?: "",
                name = m["name"]?.toString() ?: "",
                phone = m["phone"]?.toString() ?: "",
            )
        }
        @Suppress("UNCHECKED_CAST")
        val rawAttachments = (args["attachments"] as? List<*>) ?: emptyList<Any>()
        val attachments = rawAttachments.mapNotNull { it as? Map<*, *> }.mapNotNull { m ->
            val path = m["path"]?.toString() ?: return@mapNotNull null
            val mimeType = m["mimeType"]?.toString() ?: "*/*"
            if (path.isNotEmpty()) WaAttachment(path, mimeType) else null
        }.toMutableList()

        val singlePath = args["attachmentPath"]?.toString()
        val singleMime = args["attachmentMime"]?.toString() ?: "*/*"
        if (attachments.isEmpty() && !singlePath.isNullOrEmpty()) {
            attachments.add(WaAttachment(singlePath, singleMime))
        }

        BroadcastStore.saveJob(
            context = this,
            campaignId = args["campaignId"]?.toString() ?: "",
            campaignName = args["campaignName"]?.toString() ?: "",
            message = args["message"]?.toString() ?: "",
            delaySeconds = (args["delaySeconds"] as? Number)?.toInt() ?: 6,
            preSendDelaySeconds = (args["preSendDelaySeconds"] as? Number)?.toInt() ?: 2,
            randomizeDelay = args["randomizeDelay"] == true,
            autoRetry = args["autoRetry"] == true,
            skipInvalid = args["skipInvalid"] == true,
            contacts = contacts,
            attachmentPath = singlePath,
            attachmentMime = singleMime,
            attachments = attachments,
            autoPauseMinutes = (args["autoPauseMinutes"] as? Number)?.toInt() ?: 0,
        )
        result.success(true)
    }

    private fun handleStartBroadcast(call: MethodCall, result: MethodChannel.Result) {
        val campaignId = call.argument<String>("campaignId")
        if (campaignId.isNullOrEmpty()) {
            result.error("invalid_campaign", "campaignId is required", null)
            return
        }
        if (!WhatsAppAutomationService.isAccessibilityEnabled(this)) {
            result.success(
                mapOf(
                    "started" to false,
                    "accessibilityEnabled" to false,
                    "overlayPermission" to Settings.canDrawOverlays(this),
                    "error" to "ACCESSIBILITY_NOT_ENABLED",
                ),
            )
            return
        }
        if (!Settings.canDrawOverlays(this)) {
            result.success(
                mapOf(
                    "started" to false,
                    "accessibilityEnabled" to true,
                    "overlayPermission" to false,
                    "error" to "OVERLAY_NOT_GRANTED",
                ),
            )
            return
        }
        try {
            sendBroadcast(
                Intent(WhatsAppAutomationService.ACTION_START).setPackage(packageName),
            )
        } catch (e: Exception) {
            Log.e(TAG, "startBroadcast failed", e)
            result.success(
                mapOf(
                    "started" to false,
                    "accessibilityEnabled" to true,
                    "overlayPermission" to true,
                    "error" to "SERVICE_START_FAILED: ${e.message}",
                ),
            )
            return
        }
        result.success(
            mapOf(
                "started" to true,
                "accessibilityEnabled" to true,
                "overlayPermission" to true,
            ),
        )
    }

    // ---- File picking ----

    private fun pickFile(mimeTypes: Array<String>, onResult: (Uri?) -> Unit) {
        pendingPicker = onResult
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = if (mimeTypes.size == 1) mimeTypes[0] else "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        try {
            startActivityForResult(Intent.createChooser(intent, "Select file"), REQ_PICK_FILE)
        } catch (e: Exception) {
            pendingPicker = null
            onResult(null)
            Log.e(TAG, "pickFile launch failed", e)
        }
    }

    private fun pickContact(onResult: (Uri?) -> Unit) {
        pendingContactPicker = onResult
        val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
        try {
            startActivityForResult(intent, REQ_PICK_CONTACT)
        } catch (e: Exception) {
            pendingContactPicker = null
            onResult(null)
            Log.e(TAG, "pickContact launch failed", e)
        }
    }

    private fun fetchAllContacts(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
        )
        try {
            contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                null,
                null,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " COLLATE NOCASE ASC",
            )?.use { cursor ->
                val nameIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numberIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                val seen = HashSet<String>()
                while (cursor.moveToNext()) {
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) ?: "" else ""
                    val number = if (numberIdx >= 0) cursor.getString(numberIdx) ?: "" else ""
                    val cleanPhone = number.replace(Regex("[^0-9+]"), "")
                    if (cleanPhone.isNotEmpty()) {
                        val key = "$name|$cleanPhone"
                        if (seen.add(key)) {
                            list.add(mapOf("name" to name.trim(), "phone" to cleanPhone))
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "fetchAllContacts error", e)
        }
        return list
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PICK_FILE) {
            val callback = pendingPicker
            pendingPicker = null
            callback?.invoke(if (resultCode == RESULT_OK) data?.data else null)
        } else if (requestCode == REQ_PICK_CONTACT) {
            val callback = pendingContactPicker
            pendingContactPicker = null
            callback?.invoke(if (resultCode == RESULT_OK) data?.data else null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_CONTACTS_PERMISSION) {
            val res = pendingContactsChannelResult
            pendingContactsChannelResult = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                res?.success(fetchAllContacts())
            } else {
                res?.error("permission_denied", "Contacts permission denied by user", null)
            }
        }
    }

    private fun queryDisplayName(uri: Uri): String {
        return try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(0) ?: "file"
                } else {
                    "file"
                }
            } ?: "file"
        } catch (_: Exception) {
            "file"
        }
    }

    private fun copyToInternal(uri: Uri): Map<String, Any>? {
        return try {
            val name = queryDisplayName(uri)
                .replace(Regex("[^a-zA-Z0-9._\\-]"), "_")
                .ifEmpty { "attachment" }
            val dir = File(filesDir, "attachments").apply { mkdirs() }
            val target = File(dir, name)
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            val mime = contentResolver.getType(uri) ?: guessMime(name)
            mapOf(
                "path" to target.absolutePath,
                "mimeType" to mime,
                "name" to name,
            )
        } catch (e: Exception) {
            Log.e(TAG, "copyToInternal failed", e)
            null
        }
    }

    private fun guessMime(fileName: String): String {
        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".jpg") || lower.endsWith(".jpeg") -> "image/jpeg"
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".gif") -> "image/gif"
            lower.endsWith(".webp") -> "image/webp"
            lower.endsWith(".mp4") -> "video/mp4"
            lower.endsWith(".3gp") -> "video/3gp"
            lower.endsWith(".mp3") -> "audio/mpeg"
            lower.endsWith(".pdf") -> "application/pdf"
            lower.endsWith(".doc") -> "application/msword"
            lower.endsWith(".docx") -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            else -> "application/octet-stream"
        }
    }
}
