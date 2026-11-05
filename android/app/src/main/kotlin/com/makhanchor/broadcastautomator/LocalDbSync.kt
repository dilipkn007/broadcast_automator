package com.makhanchor.broadcastautomator

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.util.concurrent.Executors

/**
 * Thread-safe, direct offline writes to the local SQLite database from native Android.
 */
object LocalDbSync {
    private const val TAG = "LocalDbSync"
    private const val DB_NAME = "broadcast_automator.db"
    private val executor = Executors.newSingleThreadExecutor()

    private fun openDb(context: Context): SQLiteDatabase? {
        return try {
            val dbFile = context.getDatabasePath(DB_NAME)
            if (dbFile.exists()) {
                SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open SQLite database", e)
            null
        }
    }

    fun update(context: Context, table: String, id: String, fields: Map<String, Any?>) {
        if (id.isEmpty()) return
        val appContext = context.applicationContext
        executor.execute {
            var db: SQLiteDatabase? = null
            try {
                db = openDb(appContext) ?: return@execute
                val values = ContentValues()
                for ((key, value) in fields) {
                    when (value) {
                        null -> values.putNull(key)
                        is String -> values.put(key, value)
                        is Int -> values.put(key, value)
                        is Long -> values.put(key, value)
                        is Boolean -> values.put(key, if (value) 1 else 0)
                        is Double -> values.put(key, value)
                        is Float -> values.put(key, value)
                        is Number -> values.put(key, value.toLong())
                        else -> values.put(key, value.toString())
                    }
                }
                db.update(table, values, "id = ?", arrayOf(id))
            } catch (e: Exception) {
                Log.e(TAG, "Error updating $table with id $id", e)
            } finally {
                try {
                    db?.close()
                } catch (_: Exception) {}
            }
        }
    }
}
