import 'package:chorebuddy/core/voice/voice_command_channel.dart';

/// Records the registered callback and replays [launchCommand] (if any)
/// through [getLaunchCommand] exactly once, mirroring how
/// [FakeAppShortcuts] simulates a cold-start launch action. Never touches a
/// platform channel.
class FakeVoiceCommandChannel implements VoiceCommandChannel {
  FakeVoiceCommandChannel({this.launchCommand});

  final Map<String, dynamic>? launchCommand;
  void Function(Map<String, dynamic> command)? handler;
  bool _launchCommandConsumed = false;

  @override
  Future<void> initialize({
    required void Function(Map<String, dynamic> command) onCommand,
  }) async {
    handler = onCommand;
  }

  @override
  Future<Map<String, dynamic>?> getLaunchCommand() async {
    if (_launchCommandConsumed) return null;
    _launchCommandConsumed = true;
    return launchCommand;
  }

  /// Simulates a voice/Tasker-fired intent arriving while the app is
  /// already running (MainActivity.onNewIntent).
  void fireLiveCommand(Map<String, dynamic> command) {
    handler?.call(command);
  }
}
