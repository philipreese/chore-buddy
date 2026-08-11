import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/chores/domain/completion_service.dart';
import '../database/app_database.dart';
import '../home_widget/widget_sync_service.dart';
import '../settings/settings_prefs_service.dart';
import '../strings/app_strings.dart';
import '../strings/superhero_strings.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';

/// Completes [choreId] and reschedules its next reminder from a fresh read
/// of the row, reusing [CompletionService] (and, through it,
/// `calculateNextDueDate`) for the due-date math and
/// [scheduleChoreNotification] for the same gates the in-app flows use.
///
/// Free of platform channels -- [db] and [scheduler] are injected -- so this
/// is unit-testable with an in-memory database and a fake scheduler; nothing
/// here depends on the plugin being initialized or a `Ref` being available,
/// which matters because it also runs from the background isolate where
/// neither exists.
Future<void> completeChoreFromNotification({
  required AppDatabase db,
  required NotificationScheduler scheduler,
  required int choreId,
  required bool notificationsEnabled,
  required AppStrings strings,
  DateTime? completedAt,
}) async {
  final chore = await db.getChoreById(choreId);
  if (chore == null) {
    // The chore was deleted after the notification was scheduled; nothing
    // to complete, just make sure no stray alarm/tray entry is left.
    await scheduler.cancel(choreId);
    return;
  }

  await CompletionService(db).completeChore(
    chore: chore,
    completedAt: completedAt ?? DateTime.now(),
  );

  // Dismiss the notification that was just acted on before evaluating
  // whether a new one should replace it.
  await scheduler.cancel(choreId);

  // Re-read rather than patch the chore captured above: completeChore()
  // only advances nextDueDate, and every other reschedule call site in the
  // app schedules from a fresh row for the same reason (see
  // completion_flow.dart).
  final updated = await db.getChoreById(choreId);
  if (updated == null) return;

  await scheduleChoreNotification(
    scheduler: scheduler,
    chore: updated,
    notificationsEnabled: notificationsEnabled,
    strings: strings,
  );
}

/// Entry point the plugin invokes -- on a background isolate, with no
/// running app guaranteed -- when the user taps the "Complete" action on a
/// chore notification. `@pragma('vm:entry-point')` is required so the Dart
/// compiler doesn't tree-shake a function that is only ever reached via a
/// native callback lookup, never a direct Dart call.
///
/// Only one AppFlavor exists today (see `flavor_provider.dart`), so
/// `SuperheroStrings` is used directly rather than re-deriving the flavor
/// choice, which is never persisted; if a second flavor is ever added this
/// will need to read the same preference `FlavorNotifier` would.
@pragma('vm:entry-point')
Future<void> notificationBackgroundResponseHandler(
  NotificationResponse response,
) async {
  if (response.actionId != kCompleteChoreActionId) return;

  final choreId = int.tryParse(response.payload ?? '');
  if (choreId == null) return;

  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  try {
    final settings = await SharedPreferencesSettingsService().load();
    await completeChoreFromNotification(
      db: db,
      scheduler: PluginNotificationScheduler(),
      choreId: choreId,
      notificationsEnabled: settings.notificationsEnabled,
      strings: const SuperheroStrings(),
    );
    // The widget's overdue/today list is stale the moment this completion
    // lands, and nothing else will refresh it until the app is next opened.
    await WidgetSyncService(db, strings: const SuperheroStrings()).sync();
  } catch (e, st) {
    debugPrint('notificationBackgroundResponseHandler failed: $e\n$st');
  } finally {
    await db.close();
  }
}

/// Completes [choreId] via [completeChoreFromNotification] and then
/// re-syncs the widget's data -- the core of [widgetInteractivityHandler],
/// pulled out so tests can inject fakes for [scheduler] and
/// [widgetSyncService] instead of touching a platform channel. Reuses
/// [completeChoreFromNotification] rather than re-implementing the
/// completion/reschedule math for a second entry point.
Future<void> completeChoreFromWidget({
  required AppDatabase db,
  required NotificationScheduler scheduler,
  required WidgetSyncService widgetSyncService,
  required int choreId,
  required bool notificationsEnabled,
  required AppStrings strings,
  DateTime? completedAt,
}) async {
  await completeChoreFromNotification(
    db: db,
    scheduler: scheduler,
    choreId: choreId,
    notificationsEnabled: notificationsEnabled,
    strings: strings,
    completedAt: completedAt,
  );
  await widgetSyncService.sync();
}

/// Entry point `home_widget` invokes -- on a background isolate, via
/// WorkManager, with no running app guaranteed -- when the checkbox on a
/// widget chore row is tapped. [uri] is the fill-in intent's data set by
/// `ChoreWidgetRemoteViewsFactory` on the Android side, of the form
/// `chorebuddy://complete/<choreId>`; any other host is ignored, since the
/// same callback channel could in principle carry other widget actions
/// later. `@pragma('vm:entry-point')` is required for the same reason it is
/// on [notificationBackgroundResponseHandler]: this is only ever reached via
/// a native callback lookup, never a direct Dart call.
@pragma('vm:entry-point')
Future<void> widgetInteractivityHandler(Uri? uri) async {
  if (uri == null || uri.host != 'complete' || uri.pathSegments.isEmpty) {
    return;
  }
  final choreId = int.tryParse(uri.pathSegments.first);
  if (choreId == null) return;

  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  try {
    final settings = await SharedPreferencesSettingsService().load();
    const strings = SuperheroStrings();
    await completeChoreFromWidget(
      db: db,
      scheduler: PluginNotificationScheduler(),
      widgetSyncService: WidgetSyncService(db, strings: strings),
      choreId: choreId,
      notificationsEnabled: settings.notificationsEnabled,
      strings: strings,
    );
  } catch (e, st) {
    debugPrint('widgetInteractivityHandler failed: $e\n$st');
  } finally {
    await db.close();
  }
}
