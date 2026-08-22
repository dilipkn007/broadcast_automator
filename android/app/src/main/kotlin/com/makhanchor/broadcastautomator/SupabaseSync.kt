package com.makhanchor.broadcastautomator

import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Fire-and-forget writes to Supabase PostgREST from the native side.
 * Relies on open RLS policies for the anon role.
 */
object SupabaseSync {
    const val SUPABASE_URL = "https://irisxsklwelqakeloerg.supabase.co"
    const val SUPABASE_ANON_KEY =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyaXN4c2tsd2VscWFrZWxvZXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyMDcxODcsImV4cCI6MjEwMTc4MzE4N30.IfqSNlGjKfud-lW9qigoAE1U3A2VjhKhDExrbIJmSzs"

    private val executor = Executors.newSingleThreadExecutor()

    fun patch(table: String, id: String, fields: Map<String, Any?>) {
        if (id.isEmpty()) return
        executor.execute {
            try {
                val url = URL("$SUPABASE_URL/rest/v1/$table?id=eq.$id")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "PATCH"
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                conn.setRequestProperty("apikey", SUPABASE_ANON_KEY)
                conn.setRequestProperty("Authorization", "Bearer $SUPABASE_ANON_KEY")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("Prefer", "return=minimal")
                conn.doOutput = true
                val body = buildString {
                    append('{')
                    var first = true
                    for ((key, value) in fields) {
                        if (!first) append(',')
                        first = false
                        append('"').append(key).append('"').append(':')
                        append(jsonValue(value))
                    }
                    append('}')
                }
                conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                val code = conn.responseCode
                if (code !in 200..299) {
                    val error = conn.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                    android.util.Log.w("SupabaseSync", "PATCH $table/$id failed: $code $error")
                }
                conn.disconnect()
            } catch (e: Exception) {
                android.util.Log.w("SupabaseSync", "PATCH $table/$id error: ${e.message}")
            }
        }
    }

    private fun jsonValue(value: Any?): String = when (value) {
        null -> "null"
        is Number -> value.toString()
        is Boolean -> value.toString()
        else -> {
            val escaped = value.toString()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t")
            "\"$escaped\""
        }
    }
}
