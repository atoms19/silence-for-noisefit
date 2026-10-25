package dev.silence.silence_app

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Bundle

/** Remembers the inline-reply action of recent notifications so a watch quick reply can answer one. */
object ReplyStore {
    private class Target(val intent: PendingIntent, val inputs: Array<RemoteInput>)

    private val targets = object : LinkedHashMap<String, Target>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Target>?) = size > 40
    }

    @Synchronized
    fun remember(key: String, notification: Notification) {
        val action = notification.actions?.firstOrNull { !it.remoteInputs.isNullOrEmpty() } ?: return
        val intent = action.actionIntent ?: return
        targets[key] = Target(intent, action.remoteInputs)
    }

    @Synchronized
    fun has(key: String) = targets.containsKey(key)

    /** Fills the reply field and fires the notification's own reply action. */
    @Synchronized
    fun reply(context: Context, key: String, text: String): Boolean {
        val target = targets[key] ?: return false
        val fill = Intent()
        val results = Bundle()
        for (input in target.inputs) results.putCharSequence(input.resultKey, text)
        RemoteInput.addResultsToIntent(target.inputs, fill, results)
        return try {
            target.intent.send(context, 0, fill)
            true
        } catch (_: PendingIntent.CanceledException) {
            false
        }
    }
}
