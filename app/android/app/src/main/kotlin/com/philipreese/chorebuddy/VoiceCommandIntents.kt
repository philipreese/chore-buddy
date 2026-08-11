package com.philipreese.chorebuddy

import android.content.Context
import android.content.Intent

/**
 * The ADD_CHORE/COMPLETE_CHORE intent contract MainActivity exposes for
 * Tasker/adb/AppFunctions callers, and the MethodChannel name the Dart side
 * listens on (see voice_command_channel.dart). No custom permission -- this
 * is a personal sideloaded device and Tasker must be able to fire these --
 * so every extra is parsed defensively: a malformed or missing required
 * extra makes [parse] return null rather than forwarding anything to Dart.
 *
 * [dispatchAddChore]/[dispatchCompleteChore] let the AppFunctions
 * declarations (VoiceCommandFunctions.kt) fire the exact same intents
 * instead of duplicating this parsing/validation, so there is exactly one
 * command path regardless of caller.
 */
object VoiceCommandIntents {
    const val CHANNEL = "com.philipreese.chorebuddy/voice_commands"

    const val ACTION_ADD_CHORE = "com.philipreese.chorebuddy.action.ADD_CHORE"
    const val ACTION_COMPLETE_CHORE = "com.philipreese.chorebuddy.action.COMPLETE_CHORE"

    private const val EXTRA_NAME = "name"
    private const val EXTRA_RECURRENCE = "recurrence"
    private const val EXTRA_DUE = "due"

    private val VALID_RECURRENCES =
        setOf("none", "daily", "everyOtherDay", "weekly", "monthly")

    /**
     * Parses [intent] into the map handed to Dart over [CHANNEL], or null if
     * [intent] isn't one of our actions or is missing its required `name`
     * extra. Never throws: `Bundle`/`Intent` extra getters return null on a
     * type mismatch rather than crash, so a malformed extra just degrades to
     * "field absent".
     */
    fun parse(intent: Intent?): Map<String, Any?>? {
        val name = intent?.getStringExtra(EXTRA_NAME)?.trim()
        if (name.isNullOrEmpty()) return null

        return when (intent.action) {
            ACTION_ADD_CHORE -> {
                val recurrence = intent.getStringExtra(EXTRA_RECURRENCE)
                    ?.takeIf { it in VALID_RECURRENCES }
                mapOf(
                    "command" to "add",
                    "name" to name,
                    "recurrence" to recurrence,
                    "due" to intent.getStringExtra(EXTRA_DUE),
                )
            }
            ACTION_COMPLETE_CHORE -> mapOf(
                "command" to "complete",
                "name" to name,
            )
            else -> null
        }
    }

    fun dispatchAddChore(context: Context, name: String, recurrence: String?, dueDate: String?) {
        val intent = Intent(ACTION_ADD_CHORE, null, context, MainActivity::class.java)
            .putExtra(EXTRA_NAME, name)
            .apply {
                if (recurrence != null) putExtra(EXTRA_RECURRENCE, recurrence)
                if (dueDate != null) putExtra(EXTRA_DUE, dueDate)
            }
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun dispatchCompleteChore(context: Context, name: String) {
        val intent = Intent(ACTION_COMPLETE_CHORE, null, context, MainActivity::class.java)
            .putExtra(EXTRA_NAME, name)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}
