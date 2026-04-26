package com.troubleshootbangla.pocketpilotai

import android.Manifest
import android.content.pm.PackageManager
import android.provider.Telephony
import android.view.WindowManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val securityChannel = "pocketpilot_ai/security"
    private val smsReaderChannel = "pocketpilot_ai/sms_reader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            securityChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecureEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            smsReaderChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInboxMessages" -> handleGetInboxMessages(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleGetInboxMessages(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("permission_denied", "READ_SMS permission not granted", null)
            return
        }

        val requestedLimit = call.argument<Int>("limit") ?: 200
        val safeLimit = requestedLimit.coerceIn(1, 500)
        val sinceMillis = call.argument<Number>("sinceMillis")?.toLong()
        val beforeMillis = call.argument<Number>("beforeMillis")?.toLong()
        val beforeMessageId = call.argument<Number>("beforeMessageId")?.toLong()

        Thread {
            try {
                val projection = arrayOf("_id", "address", "body", "date", "thread_id")
                val selectionParts = mutableListOf<String>()
                val selectionArgsList = mutableListOf<String>()

                if (sinceMillis != null) {
                    selectionParts += "date >= ?"
                    selectionArgsList += sinceMillis.toString()
                }

                if (beforeMillis != null && beforeMessageId != null) {
                    selectionParts += "(date < ? OR (date = ? AND _id < ?))"
                    selectionArgsList += beforeMillis.toString()
                    selectionArgsList += beforeMillis.toString()
                    selectionArgsList += beforeMessageId.toString()
                } else if (beforeMillis != null) {
                    selectionParts += "date < ?"
                    selectionArgsList += beforeMillis.toString()
                }

                val selection = if (selectionParts.isEmpty()) null else selectionParts.joinToString(" AND ")
                val selectionArgs = if (selectionArgsList.isEmpty()) null else selectionArgsList.toTypedArray()
                val sortOrder = "date DESC, _id DESC LIMIT $safeLimit"
                val messages = mutableListOf<Map<String, Any?>>()

                contentResolver.query(
                    Telephony.Sms.Inbox.CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    sortOrder,
                )?.use { cursor ->
                    val idIndex = cursor.getColumnIndex("_id")
                    val addressIndex = cursor.getColumnIndex("address")
                    val bodyIndex = cursor.getColumnIndex("body")
                    val dateIndex = cursor.getColumnIndex("date")
                    val threadIdIndex = cursor.getColumnIndex("thread_id")

                    while (cursor.moveToNext()) {
                        messages.add(
                            mapOf(
                                "id" to if (idIndex >= 0) cursor.getLong(idIndex) else 0L,
                                "address" to if (addressIndex >= 0) cursor.getString(addressIndex) else "",
                                "body" to if (bodyIndex >= 0) cursor.getString(bodyIndex) else "",
                                "date" to if (dateIndex >= 0) cursor.getLong(dateIndex) else 0L,
                                "threadId" to if (threadIdIndex >= 0) cursor.getLong(threadIdIndex) else null,
                            ),
                        )
                    }
                }

                runOnUiThread { result.success(messages) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "sms_read_failed",
                        error.message ?: "Unable to read SMS inbox",
                        null,
                    )
                }
            }
        }.start()
    }
}
