import 'package:chorebuddy/core/shortcuts/app_shortcuts.dart';
import 'package:quick_actions/quick_actions.dart';

/// Records registered items and, optionally, replays a launch action back
/// through [onAction] as soon as [initialize] is called -- mirrors how the
/// real plugin invokes its handler once at startup when a shortcut launched
/// the app cold. Never touches a platform channel.
class FakeAppShortcuts implements AppShortcuts {
  FakeAppShortcuts({this.launchAction});

  final String? launchAction;
  List<ShortcutItem> registeredItems = [];
  void Function(String actionId)? handler;

  @override
  Future<void> initialize({
    required void Function(String actionId) onAction,
  }) async {
    handler = onAction;
    if (launchAction != null) {
      onAction(launchAction!);
    }
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    registeredItems = items;
  }
}
