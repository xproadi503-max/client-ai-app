package com.clientai.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.clientai.app/accessibility"
    private val EVENT_CHANNEL = "com.clientai.app/message_stream"

    private var eventSink: EventChannel.EventSink? = null

    private val messageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val message = intent.getStringExtra("message") ?: ""
            val app = intent.getStringExtra("app") ?: ""
            val sender = intent.getStringExtra("sender") ?: ""
            eventSink?.success(mapOf(
                "message" to message,
                "app" to app,
                "sender" to sender
            ))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "getLastMessage" -> {
                        result.success(ClientAccessibilityService.lastMessage)
                    }
                    "getActiveApp" -> {
                        result.success(ClientAccessibilityService.activeApp)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(
                        messageReceiver,
                        IntentFilter("com.clientai.app.NEW_MESSAGE")
                    )
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    try { unregisterReceiver(messageReceiver) } catch (e: Exception) {}
                }
            })
    }

    private fun isAccessibilityEnabled(): Boolean {
        val service = "$packageName/${ClientAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: ""
        return enabledServices.contains(service)
    }
}
