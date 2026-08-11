import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MethodChannel name shared with the Kotlin side -- see
/// `VoiceCommandIntents.CHANNEL` in `MainActivity.kt`.
const kVoiceCommandChannelName = 'com.philipreese.chorebuddy/voice_commands';

/// Low-level wrapper over the hand-written voice-command MethodChannel:
/// platform-channel calls only, no command parsing/domain logic. Kept
/// separate from the call site so unit tests can substitute a fake and
/// never touch a platform channel (mirrors [AppShortcuts]/
/// [NotificationScheduler]).
abstract class VoiceCommandChannel {
  /// Registers [onCommand] for an ADD_CHORE/COMPLETE_CHORE intent that
  /// arrives while the app is already running (MainActivity.onNewIntent).
  Future<void> initialize({
    required void Function(Map<String, dynamic> command) onCommand,
  });

  /// The command carried by the intent that cold-launched the app, if any --
  /// consumed exactly once, mirroring
  /// `NotificationScheduler.getLaunchPayload`.
  Future<Map<String, dynamic>?> getLaunchCommand();
}

/// Real implementation backed by the app's own MethodChannel (no plugin
/// involved -- see `MainActivity.kt`).
///
/// Every channel call is wrapped so a platform failure (missing platform
/// channel under `flutter test`, a plugin quirk) degrades to "no command"
/// instead of crashing app startup, the same pattern [PluginAppShortcuts]
/// and [PluginNotificationScheduler] use.
class PlatformVoiceCommandChannel implements VoiceCommandChannel {
  static const MethodChannel _channel = MethodChannel(kVoiceCommandChannelName);

  @override
  Future<void> initialize({
    required void Function(Map<String, dynamic> command) onCommand,
  }) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'voiceCommand') return;
      final args = call.arguments;
      if (args is Map) {
        onCommand(Map<String, dynamic>.from(args));
      }
    });
  }

  @override
  Future<Map<String, dynamic>?> getLaunchCommand() async {
    try {
      final result = await _channel.invokeMethod<Map>('getLaunchCommand');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e, st) {
      debugPrint('VoiceCommandChannel.getLaunchCommand failed: $e\n$st');
      return null;
    }
  }
}

final voiceCommandChannelProvider = Provider<VoiceCommandChannel>((ref) {
  return PlatformVoiceCommandChannel();
});
