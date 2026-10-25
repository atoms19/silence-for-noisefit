package dev.silence.silence_app

import com.google.mlkit.nl.smartreply.SmartReply
import com.google.mlkit.nl.smartreply.SmartReplySuggestionResult
import com.google.mlkit.nl.smartreply.TextMessage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * On-device reply suggestions through ML Kit Smart Reply. Nothing leaves the phone; an
 * unsupported language or any failure yields an empty list so the caller can fall back.
 */
class SmartReplyEngine {
    private val client = SmartReply.getClient()

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "suggest") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val texts = call.argument<List<String>>("messages").orEmpty()
            val sender = call.argument<String>("sender").orEmpty().ifBlank { "contact" }
            suggest(texts, sender) { result.success(it) }
        }
    }

    /** Suggests replies to the last of [texts], all sent by [sender], oldest first. */
    private fun suggest(texts: List<String>, sender: String, done: (List<String>) -> Unit) {
        if (texts.isEmpty()) {
            done(emptyList())
            return
        }
        val now = System.currentTimeMillis()
        val conversation = texts.mapIndexed { i, text ->
            TextMessage.createForRemoteUser(text, now - (texts.size - i) * 1000L, sender)
        }
        client.suggestReplies(conversation)
            .addOnSuccessListener { r ->
                done(
                    if (r.status == SmartReplySuggestionResult.STATUS_SUCCESS) {
                        r.suggestions.map { it.text }
                    } else {
                        emptyList()
                    }
                )
            }
            .addOnFailureListener { done(emptyList()) }
    }

    companion object {
        const val CHANNEL = "dev.silence/smart_reply"
    }
}
