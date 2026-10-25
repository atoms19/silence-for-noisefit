package dev.silence.silence_app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/** Receives phone notifications and forwards them to the app while it is running. */
class SilenceNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val sink = NotificationBridge.sink ?: return
        if (sbn.packageName == packageName) return
        val notification = sbn.notification ?: return
        val flags = notification.flags
        if (flags and Notification.FLAG_ONGOING_EVENT != 0) return
        if (flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (title.isBlank() && text.isBlank()) return
        ReplyStore.remember(sbn.key, notification)
        sink(
            mapOf(
                "type" to "phoneNotification",
                "canReply" to ReplyStore.has(sbn.key),
                "package" to sbn.packageName,
                "key" to sbn.key,
                "title" to title,
                "text" to text,
                "category" to (notification.category ?: ""),
                "postTime" to sbn.postTime,
            )
        )
    }
}

/** Hands listener events to whichever activity currently owns the Flutter engine. */
object NotificationBridge {
    @Volatile
    var sink: ((Map<String, Any?>) -> Unit)? = null
}
