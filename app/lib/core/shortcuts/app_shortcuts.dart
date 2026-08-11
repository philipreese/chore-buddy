import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

/// Low-level wrapper over the `quick_actions` plugin: platform-channel calls
/// only, no action-id-to-route translation. Kept separate from the call site
/// so unit tests can substitute a fake and never touch a platform channel.
abstract class AppShortcuts {
  /// Registers [onAction] for both a tap on a shortcut while the app is
  /// running and the shortcut that launched the app cold.
  Future<void> initialize({required void Function(String actionId) onAction});

  /// Replaces the app's launcher long-press shortcuts with [items].
  Future<void> setShortcutItems(List<ShortcutItem> items);
}

/// Real implementation backed by `quick_actions`.
///
/// Every plugin call is wrapped so a platform failure (missing platform
/// channel under `flutter test`, an OS below the supported version) degrades
/// to "no shortcuts" instead of crashing app startup -- the same pattern
/// `PluginNotificationScheduler` uses.
class PluginAppShortcuts implements AppShortcuts {
  final QuickActions _plugin = const QuickActions();

  @override
  Future<void> initialize({
    required void Function(String actionId) onAction,
  }) async {
    try {
      await _plugin.initialize(onAction);
    } catch (e, st) {
      debugPrint('AppShortcuts.initialize failed: $e\n$st');
    }
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    try {
      await _plugin.setShortcutItems(items);
    } catch (e, st) {
      debugPrint('AppShortcuts.setShortcutItems failed: $e\n$st');
    }
  }
}

final appShortcutsProvider = Provider<AppShortcuts>((ref) {
  return PluginAppShortcuts();
});
