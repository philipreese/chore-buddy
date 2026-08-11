package com.philipreese.chorebuddy

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles the ADD_CHORE/COMPLETE_CHORE voice-command intents (see
 * VoiceCommandIntents.kt) in addition to Flutter's normal activity duties.
 *
 * Cold start: the launch intent is captured in [onCreate], before the
 * Flutter engine's Dart isolate is guaranteed ready to receive a channel
 * call, and handed to Dart lazily via the `getLaunchCommand` pull -- the
 * same "pull once at startup" shape `NotificationScheduler.getLaunchPayload`
 * already uses for a notification that launched the app.
 *
 * Already running (singleTop, so a re-fired intent lands here via
 * [onNewIntent] instead of a new instance): the Dart engine is already up,
 * so the command is pushed immediately over the channel.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingCommand: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingCommand = VoiceCommandIntents.parse(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VoiceCommandIntents.CHANNEL,
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchCommand" -> {
                    result.success(pendingCommand)
                    pendingCommand = null
                }
                else -> result.notImplemented()
            }
        }
        channel = methodChannel
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val command = VoiceCommandIntents.parse(intent)
        if (command != null) {
            channel?.invokeMethod("voiceCommand", command)
        }
    }
}
