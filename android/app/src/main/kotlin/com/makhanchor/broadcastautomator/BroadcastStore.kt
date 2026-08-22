package com.makhanchor.broadcastautomator

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** A single contact to be messaged. */
data class WaContact(
    val id: String,
    val name: String,
    val phone: String,
)

/** The full automation job, persisted between Flutter and the accessibility service. */
data class WaJob(
    val campaignId: String,
    val campaignName: String,
    val message: String,
    val delaySeconds: Int,
    val randomizeDelay: Boolean,
    val autoRetry: Boolean,
    val skipInvalid: Boolean,
    val contacts: List<WaContact>,
    val attachmentPath: String?,
    val attachmentMime: String?,
    val autoPauseMinutes: Int,
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
    private const val KEY_RANDOMIZE = "job_randomize_delay"
    private const val KEY_RETRY = "job_auto_retry"
    private const val KEY_SKIP_INVALID = "job_skip_invalid"
    private const val KEY_CONTACTS = "job_contacts_json"
    private const val KEY_ATTACHMENT_PATH = "job_attachment_path"
    private const val KEY_ATTACHMENT_MIME = "job_attachment_mime"
    private const val KEY_AUTO_PAUSE_MINUTES = "job_auto_pause_minutes"

    fun saveJob(
        context: Context,
        campaignId: String,
        campaignName: String,
        message: String,
        delaySeconds: Int,
        randomizeDelay: Boolean,
        autoRetry: Boolean,
        skipInvalid: Boolean,
        contacts: List<WaContact>,
        attachmentPath: String?,
        attachmentMime: String?,
        autoPauseMinutes: Int,
    ) {
        val arr = JSONArray()
        contacts.forEach { c ->
            arr.put(
                JSONObject()
                    .put("id", c.id)
                    .put("name", c.name)
                    .put("phone", c.phone),
            )
        }
        prefs(context).edit()
            .putString(KEY_CAMPAIGN_ID, campaignId)
            .putString(KEY_CAMPAIGN_NAME, campaignName)
            .putString(KEY_MESSAGE, message)
            .putInt(KEY_DELAY, delaySeconds)
            .putBoolean(KEY_RANDOMIZE, randomizeDelay)
            .putBoolean(KEY_RETRY, autoRetry)
            .putBoolean(KEY_SKIP_INVALID, skipInvalid)
            .putString(KEY_CONTACTS, arr.toString())
            .putString(KEY_ATTACHMENT_PATH, attachmentPath)
            .putString(KEY_ATTACHMENT_MIME, attachmentMime)
            .putInt(KEY_AUTO_PAUSE_MINUTES, autoPauseMinutes)
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
            contacts.add(
                WaContact(
                    id = o.optString("id"),
                    name = o.optString("name"),
                    phone = o.optString("phone"),
                ),
            )
        }
        return WaJob(
            campaignId = campaignId,
            campaignName = p.getString(KEY_CAMPAIGN_NAME, "") ?: "",
            message = p.getString(KEY_MESSAGE, "") ?: "",
            delaySeconds = p.getInt(KEY_DELAY, 0),
            randomizeDelay = p.getBoolean(KEY_RANDOMIZE, false),
            autoRetry = p.getBoolean(KEY_RETRY, false),
            skipInvalid = p.getBoolean(KEY_SKIP_INVALID, false),
            contacts = contacts,
            attachmentPath = p.getString(KEY_ATTACHMENT_PATH, null),
            attachmentMime = p.getString(KEY_ATTACHMENT_MIME, null),
            autoPauseMinutes = p.getInt(KEY_AUTO_PAUSE_MINUTES, 0),
        )
    }

    fun clearJob(context: Context) {
        prefs(context).edit().remove(KEY_CAMPAIGN_ID).apply()
    }

    // ---- Status ----
    private const val KEY_ST_CAMPAIGN_ID = "status_campaign_id"
    private const val KEY_ST_CAMPAIGN_NAME = "status_campaign_name"
    private const val KEY_ST_RUNNING = "status_running"
    private const val KEY_ST_PAUSED = "status_paused"
    private const val KEY_ST_CURRENT = "status_current_index"
    private const val KEY_ST_TOTAL = "status_total"
    private const val KEY_ST_SENT = "status_sent"
    private const val KEY_ST_FAILED = "status_failed"

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
    ) {
        prefs(context).edit()
            .putString(KEY_ST_CAMPAIGN_ID, campaignId)
            .putString(KEY_ST_CAMPAIGN_NAME, campaignName)
            .putBoolean(KEY_ST_RUNNING, running)
            .putBoolean(KEY_ST_PAUSED, paused)
            .putInt(KEY_ST_CURRENT, currentIndex)
            .putInt(KEY_ST_TOTAL, total)
            .putInt(KEY_ST_SENT, sent)
            .putInt(KEY_ST_FAILED, failed)
            .apply()
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
            .apply()
    }
}
