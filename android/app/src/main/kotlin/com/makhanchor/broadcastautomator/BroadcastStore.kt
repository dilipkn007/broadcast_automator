package com.makhanchor.broadcastautomator

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** A single contact to be messaged. */
data class WaContact(
    val id: String,
    val name: String,
    val phone: String,
    val extraFields: Map<String, String> = emptyMap(),
)

/** A single media/document attachment to be sent. */
data class WaAttachment(
    val path: String,
    val mimeType: String,
)

/** The full automation job, persisted between Flutter and the accessibility service. */
data class WaJob(
    val campaignId: String,
    val campaignName: String,
    val message: String,
    val delaySeconds: Int,
    val preSendDelaySeconds: Int = 2,
    val randomizeDelay: Boolean,
    val autoRetry: Boolean,
    val skipInvalid: Boolean,
    val contacts: List<WaContact>,
    val attachmentPath: String?,
    val attachmentMime: String?,
    val attachments: List<WaAttachment> = emptyList(),
    val autoPauseMinutes: Int,
    val pauseAfterMessages: Int = 0,
    val autoResumeMinutes: Int = 0,
)

/** Persists the current job + live progress in SharedPreferences. */
object BroadcastStore {
    private const val PREFS = "broadcast_automator_prefs"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ---- Job ----
    private const val KEY_CAMPAIGN_ID = "job_campaign_id"
    private const val KEY_CAMPAIGN_NAME = "job_campaign_name"
    private const val KEY_MESSAGE = "job_message"
    private const val KEY_DELAY = "job_delay_seconds"
    private const val KEY_PRE_SEND_DELAY = "job_pre_send_delay_seconds"
    private const val KEY_RANDOMIZE = "job_randomize_delay"
    private const val KEY_RETRY = "job_auto_retry"
    private const val KEY_SKIP_INVALID = "job_skip_invalid"
    private const val KEY_CONTACTS = "job_contacts_json"
    private const val KEY_ATTACHMENT_PATH = "job_attachment_path"
    private const val KEY_ATTACHMENT_MIME = "job_attachment_mime"
    private const val KEY_ATTACHMENTS = "job_attachments_json"
    private const val KEY_AUTO_PAUSE_MINUTES = "job_auto_pause_minutes"
    private const val KEY_PAUSE_AFTER_MESSAGES = "job_pause_after_messages"
    private const val KEY_AUTO_RESUME_MINUTES = "job_auto_resume_minutes"

    fun saveJob(
        context: Context,
        campaignId: String,
        campaignName: String,
        message: String,
        delaySeconds: Int,
        preSendDelaySeconds: Int = 2,
        randomizeDelay: Boolean,
        autoRetry: Boolean,
        skipInvalid: Boolean,
        contacts: List<WaContact>,
        attachmentPath: String?,
        attachmentMime: String?,
        attachments: List<WaAttachment> = emptyList(),
        autoPauseMinutes: Int,
        pauseAfterMessages: Int = 0,
        autoResumeMinutes: Int = 0,
    ) {
        val arr = JSONArray()
        contacts.forEach { c ->
            val obj = JSONObject()
                .put("id", c.id)
                .put("name", c.name)
                .put("phone", c.phone)
            if (c.extraFields.isNotEmpty()) {
                val extraObj = JSONObject()
                c.extraFields.forEach { (k, v) ->
                    extraObj.put(k, v)
                }
                obj.put("extraFields", extraObj)
            }
            arr.put(obj)
        }
        val attArr = JSONArray()
        attachments.forEach { a ->
            attArr.put(
                JSONObject()
                    .put("path", a.path)
                    .put("mimeType", a.mimeType),
            )
        }
        prefs(context).edit()
            .putString(KEY_CAMPAIGN_ID, campaignId)
            .putString(KEY_CAMPAIGN_NAME, campaignName)
            .putString(KEY_MESSAGE, message)
            .putInt(KEY_DELAY, delaySeconds)
            .putInt(KEY_PRE_SEND_DELAY, preSendDelaySeconds)
            .putBoolean(KEY_RANDOMIZE, randomizeDelay)
            .putBoolean(KEY_RETRY, autoRetry)
            .putBoolean(KEY_SKIP_INVALID, skipInvalid)
            .putString(KEY_CONTACTS, arr.toString())
            .putString(KEY_ATTACHMENT_PATH, attachmentPath)
            .putString(KEY_ATTACHMENT_MIME, attachmentMime)
            .putString(KEY_ATTACHMENTS, attArr.toString())
            .putInt(KEY_AUTO_PAUSE_MINUTES, autoPauseMinutes)
            .putInt(KEY_PAUSE_AFTER_MESSAGES, pauseAfterMessages)
            .putInt(KEY_AUTO_RESUME_MINUTES, autoResumeMinutes)
            .apply()
    }

    fun loadJob(context: Context): WaJob? {
        val p = prefs(context)
        val campaignId = p.getString(KEY_CAMPAIGN_ID, null) ?: return null
        val contactsJson = p.getString(KEY_CONTACTS, "[]") ?: "[]"
        val contacts = ArrayList<WaContact>()
        val arr = JSONArray(contactsJson)
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            val extrasMap = mutableMapOf<String, String>()
            val extraObj = o.optJSONObject("extraFields")
            if (extraObj != null) {
                val keys = extraObj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    extrasMap[k] = extraObj.optString(k, "")
                }
            }
            contacts.add(
                WaContact(
                    id = o.optString("id"),
                    name = o.optString("name"),
                    phone = o.optString("phone"),
                    extraFields = extrasMap,
                ),
            )
        }

        val attJson = p.getString(KEY_ATTACHMENTS, "[]") ?: "[]"
        val attachments = ArrayList<WaAttachment>()
        val attArr = JSONArray(attJson)
        for (i in 0 until attArr.length()) {
            val o = attArr.getJSONObject(i)
            val path = o.optString("path")
            val mime = o.optString("mimeType")
            if (path.isNotEmpty()) {
                attachments.add(WaAttachment(path = path, mimeType = mime))
            }
        }
        val singlePath = p.getString(KEY_ATTACHMENT_PATH, null)
        val singleMime = p.getString(KEY_ATTACHMENT_MIME, null)
        if (attachments.isEmpty() && !singlePath.isNullOrEmpty()) {
            attachments.add(WaAttachment(path = singlePath, mimeType = singleMime ?: "*/*"))
        }

        return WaJob(
            campaignId = campaignId,
            campaignName = p.getString(KEY_CAMPAIGN_NAME, "") ?: "",
            message = p.getString(KEY_MESSAGE, "") ?: "",
            delaySeconds = p.getInt(KEY_DELAY, 0),
            preSendDelaySeconds = p.getInt(KEY_PRE_SEND_DELAY, 2),
            randomizeDelay = p.getBoolean(KEY_RANDOMIZE, false),
            autoRetry = p.getBoolean(KEY_RETRY, false),
            skipInvalid = p.getBoolean(KEY_SKIP_INVALID, false),
            contacts = contacts,
            attachmentPath = singlePath,
            attachmentMime = singleMime,
            attachments = attachments,
            autoPauseMinutes = p.getInt(KEY_AUTO_PAUSE_MINUTES, 0),
            pauseAfterMessages = p.getInt(KEY_PAUSE_AFTER_MESSAGES, 0),
            autoResumeMinutes = p.getInt(KEY_AUTO_RESUME_MINUTES, 0),
        )
    }

    fun clearJob(context: Context) {
        prefs(context).edit().remove(KEY_CAMPAIGN_ID).apply()
    }

    // ---- Status & Report ----
    private const val KEY_ST_CAMPAIGN_ID = "status_campaign_id"
    private const val KEY_ST_CAMPAIGN_NAME = "status_campaign_name"
    private const val KEY_ST_RUNNING = "status_running"
    private const val KEY_ST_PAUSED = "status_paused"
    private const val KEY_ST_CURRENT = "status_current_index"
    private const val KEY_ST_TOTAL = "status_total"
    private const val KEY_ST_SENT = "status_sent"
    private const val KEY_ST_FAILED = "status_failed"
    private const val KEY_ST_SKIPPED = "status_skipped"
    private const val KEY_ST_START_TIME = "status_start_time"
    private const val KEY_ST_END_TIME = "status_end_time"
    private const val KEY_ST_RESULTS = "status_contact_results_json"

    fun setStatus(
        context: Context,
        campaignId: String?,
        campaignName: String?,
        running: Boolean,
        paused: Boolean,
        currentIndex: Int,
        total: Int,
        sent: Int,
        failed: Int,
        skipped: Int = 0,
    ) {
        val editor = prefs(context).edit()
            .putBoolean(KEY_ST_RUNNING, running)
            .putBoolean(KEY_ST_PAUSED, paused)
            .putInt(KEY_ST_CURRENT, currentIndex)
            .putInt(KEY_ST_TOTAL, total)
            .putInt(KEY_ST_SENT, sent)
            .putInt(KEY_ST_FAILED, failed)
            .putInt(KEY_ST_SKIPPED, skipped)
        if (campaignId != null) editor.putString(KEY_ST_CAMPAIGN_ID, campaignId)
        if (campaignName != null) editor.putString(KEY_ST_CAMPAIGN_NAME, campaignName)
        editor.apply()
    }

    fun setStartTime(context: Context, startTimeMs: Long) {
        prefs(context).edit()
            .putLong(KEY_ST_START_TIME, startTimeMs)
            .putLong(KEY_ST_END_TIME, 0L)
            .putString(KEY_ST_RESULTS, "[]")
            .apply()
    }

    fun setEndTime(context: Context, endTimeMs: Long) {
        prefs(context).edit()
            .putLong(KEY_ST_END_TIME, endTimeMs)
            .apply()
    }

    fun recordContactResult(
        context: Context,
        id: String,
        name: String,
        phone: String,
        status: String,
    ) {
        val p = prefs(context)
        val raw = p.getString(KEY_ST_RESULTS, "[]") ?: "[]"
        val arr = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        var replaced = false
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            if ((id.isNotEmpty() && obj.optString("id") == id) ||
                (phone.isNotEmpty() && obj.optString("phone") == phone)) {
                obj.put("status", status)
                replaced = true
                break
            }
        }
        if (!replaced) {
            arr.put(
                JSONObject()
                    .put("id", id)
                    .put("name", name)
                    .put("phone", phone)
                    .put("status", status),
            )
        }
        p.edit().putString(KEY_ST_RESULTS, arr.toString()).apply()
    }

    fun getStatus(context: Context): JSONObject {
        val p = prefs(context)
        return JSONObject()
            .put("campaignId", p.getString(KEY_ST_CAMPAIGN_ID, null))
            .put("campaignName", p.getString(KEY_ST_CAMPAIGN_NAME, null))
            .put("running", p.getBoolean(KEY_ST_RUNNING, false))
            .put("paused", p.getBoolean(KEY_ST_PAUSED, false))
            .put("currentIndex", p.getInt(KEY_ST_CURRENT, 0))
            .put("total", p.getInt(KEY_ST_TOTAL, 0))
            .put("sent", p.getInt(KEY_ST_SENT, 0))
            .put("failed", p.getInt(KEY_ST_FAILED, 0))
            .put("skipped", p.getInt(KEY_ST_SKIPPED, 0))
    }

    /** Status as a plain map, safe to pass through a MethodChannel. */
    fun getStatusMap(context: Context): Map<String, Any?> {
        val p = prefs(context)
        return mapOf(
            "campaignId" to p.getString(KEY_ST_CAMPAIGN_ID, null),
            "campaignName" to p.getString(KEY_ST_CAMPAIGN_NAME, null),
            "running" to p.getBoolean(KEY_ST_RUNNING, false),
            "paused" to p.getBoolean(KEY_ST_PAUSED, false),
            "currentIndex" to p.getInt(KEY_ST_CURRENT, 0),
            "total" to p.getInt(KEY_ST_TOTAL, 0),
            "sent" to p.getInt(KEY_ST_SENT, 0),
            "failed" to p.getInt(KEY_ST_FAILED, 0),
            "skipped" to p.getInt(KEY_ST_SKIPPED, 0),
        )
    }

    /** Full report map including contact-by-contact status and calculated duration. */
    fun getReportMap(context: Context): Map<String, Any?> {
        val p = prefs(context)
        val startTime = p.getLong(KEY_ST_START_TIME, 0L)
        val endTime = p.getLong(KEY_ST_END_TIME, 0L)
        val durationSeconds = if (startTime > 0L) {
            val end = if (endTime > startTime) endTime else System.currentTimeMillis()
            ((end - startTime) / 1000).toInt()
        } else {
            0
        }

        val resultsJson = p.getString(KEY_ST_RESULTS, "[]") ?: "[]"
        val contactsList = ArrayList<Map<String, String>>()
        try {
            val arr = JSONArray(resultsJson)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                contactsList.add(
                    mapOf(
                        "id" to o.optString("id", ""),
                        "name" to o.optString("name", ""),
                        "phone" to o.optString("phone", ""),
                        "status" to o.optString("status", ""),
                    ),
                )
            }
        } catch (_: Exception) {
        }

        return mapOf(
            "campaignId" to p.getString(KEY_ST_CAMPAIGN_ID, null),
            "campaignName" to p.getString(KEY_ST_CAMPAIGN_NAME, null),
            "running" to p.getBoolean(KEY_ST_RUNNING, false),
            "paused" to p.getBoolean(KEY_ST_PAUSED, false),
            "currentIndex" to p.getInt(KEY_ST_CURRENT, 0),
            "total" to p.getInt(KEY_ST_TOTAL, 0),
            "sent" to p.getInt(KEY_ST_SENT, 0),
            "failed" to p.getInt(KEY_ST_FAILED, 0),
            "skipped" to p.getInt(KEY_ST_SKIPPED, 0),
            "durationSeconds" to durationSeconds,
            "contacts" to contactsList,
        )
    }

    fun clearStatus(context: Context) {
        prefs(context).edit()
            .remove(KEY_ST_CAMPAIGN_ID)
            .putBoolean(KEY_ST_RUNNING, false)
            .putBoolean(KEY_ST_PAUSED, false)
            .putInt(KEY_ST_CURRENT, 0)
            .putInt(KEY_ST_TOTAL, 0)
            .putInt(KEY_ST_SENT, 0)
            .putInt(KEY_ST_FAILED, 0)
            .putInt(KEY_ST_SKIPPED, 0)
            .apply()
    }
}
