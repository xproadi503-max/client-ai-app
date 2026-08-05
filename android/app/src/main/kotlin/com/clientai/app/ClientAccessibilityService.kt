package com.clientai.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class ClientAccessibilityService : AccessibilityService() {

    companion object {
        var lastMessage: String = ""
        var activeApp: String = ""
        var messageSender: String = ""
        var onMessageReceived: ((String, String, String) -> Unit)? = null

        val supportedApps = setOf(
            "com.whatsapp",
            "org.telegram.messenger",
            "com.instagram.android",
            "com.facebook.orca",
            "com.linkedin.android"
        )
    }

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            packageNames = supportedApps.toTypedArray()
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        val packageName = event.packageName?.toString() ?: return
        if (packageName !in supportedApps) return

        activeApp = packageName

        when (event.eventType) {
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                // New notification = new message
                val text = event.text?.joinToString(" ") ?: return
                if (text.isNotBlank() && text != lastMessage) {
                    lastMessage = text
                    messageSender = extractSender(text)
                    onMessageReceived?.invoke(lastMessage, activeApp, messageSender)
                    sendToFlutter(lastMessage, activeApp, messageSender)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Try to extract latest chat message from screen
                val root = rootInActiveWindow ?: return
                extractLatestMessage(root, packageName)
            }
        }
    }

    private fun extractLatestMessage(root: AccessibilityNodeInfo, pkg: String) {
        // Try common message text node IDs for WhatsApp, Telegram, Instagram
        val messageNodeIds = when (pkg) {
            "com.whatsapp" -> listOf("com.whatsapp:id/message_text")
            "org.telegram.messenger" -> listOf("org.telegram.messenger:id/message_text")
            "com.instagram.android" -> listOf("com.instagram.android:id/message_content")
            else -> emptyList()
        }

        for (id in messageNodeIds) {
            val nodes = root.findAccessibilityNodeInfosByViewId(id)
            if (nodes.isNotEmpty()) {
                val lastNode = nodes.last()
                val text = lastNode.text?.toString() ?: continue
                if (text.isNotBlank() && text != lastMessage) {
                    lastMessage = text
                    onMessageReceived?.invoke(text, pkg, "")
                    sendToFlutter(text, pkg, "")
                }
                break
            }
        }
    }

    private fun extractSender(notificationText: String): String {
        // "John: Hello there" -> "John"
        val colonIndex = notificationText.indexOf(":")
        return if (colonIndex > 0) notificationText.substring(0, colonIndex).trim()
        else ""
    }

    private fun sendToFlutter(message: String, app: String, sender: String) {
        val intent = Intent("com.clientai.app.NEW_MESSAGE").apply {
            putExtra("message", message)
            putExtra("app", app)
            putExtra("sender", sender)
        }
        sendBroadcast(intent)
    }

    override fun onInterrupt() {}
}
