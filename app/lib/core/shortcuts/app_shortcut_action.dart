/// Identifies which app shortcut or quick-settings tile was tapped, and the
/// route it opens.
///
/// [id] doubles as the `type` registered for the matching [ShortcutItem]
/// (see `app_shortcuts.dart`) and, for the quick-settings tile, the intent
/// extra `NewMissionTileService` attaches to its launch intent -- the
/// `quick_actions` Android plugin reads that same extra off the launch/new
/// intent, so both entry points feed the exact same Dart handler.
enum AppShortcutAction {
  newMission('new_mission', '/chores/new'),
  overdue('overdue', '/chores');

  const AppShortcutAction(this.id, this.route);

  final String id;
  final String route;

  static AppShortcutAction? fromId(String id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }
}
