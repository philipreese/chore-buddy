import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../strings/app_strings.dart';
import '../strings/flavor_provider.dart';
import 'notification_scheduler.dart';
import 'notifications_enabled_provider.dart';

/// Cancels any existing reminder for [chore], then reschedules it if (and
/// only if) every gate passes: [notificationsEnabled], the chore's own
/// reminder flag, a due date is set, and that due date is still in the
/// future. Notification id == chore id, so this is cancel/replace.
///
/// Pulled out of [NotificationServiceImpl] so the background
/// complete-from-notification handler -- which has no `Ref` to read the
/// global toggle from -- can reschedule through the exact same gates
/// instead of re-implementing them.
Future<void> scheduleChoreNotification({
  required NotificationScheduler scheduler,
  required ChoreEntity chore,
  required bool notificationsEnabled,
  required AppStrings strings,
}) async {
  await scheduler.cancel(chore.id);

  if (!notificationsEnabled) return;
  if (!chore.isNotificationEnabled) return;

  final dueDate = chore.nextDueDate;
  if (dueDate == null) return;
  if (dueDate.isBefore(DateTime.now())) return;

  await scheduler.zonedSchedule(
    id: chore.id,
    title: strings.notificationTitle(chore.name),
    body: strings.notificationBody,
    scheduledDate: dueDate,
    payload: chore.id.toString(),
    completeActionLabel: strings.notificationCompleteAction,
    snoozeActionLabel: strings.notificationSnoozeAction,
  );
}

/// Schedules/cancels the one-shot due-date reminder for a chore. Interface
/// + provider so call sites never depend on the plugin directly and widget
/// tests can substitute a fake via `notificationServiceProvider.overrideWithValue`.
abstract class NotificationService {
  /// Cancels any existing reminder for [chore], then reschedules it if (and
  /// only if) every gate passes: global notifications on, the chore's own
  /// reminder flag on, a due date is set, and that due date is still in the
  /// future. Notification id == chore id, so this is cancel/replace.
  Future<void> scheduleForChore(ChoreEntity chore);

  Future<void> cancelForChore(int choreId);

  Future<void> cancelAll();

  /// Re-evaluates every active chore against the gates in [scheduleForChore].
  /// Used when the global notifications toggle turns back on.
  Future<void> rescheduleAll();
}

class NotificationServiceImpl implements NotificationService {
  final NotificationScheduler scheduler;
  final AppDatabase db;
  final Ref ref;

  NotificationServiceImpl({
    required this.scheduler,
    required this.db,
    required this.ref,
  });

  @override
  Future<void> scheduleForChore(ChoreEntity chore) {
    return scheduleChoreNotification(
      scheduler: scheduler,
      chore: chore,
      notificationsEnabled: ref.read(notificationsEnabledProvider),
      strings: ref.read(appStringsProvider),
    );
  }

  @override
  Future<void> cancelForChore(int choreId) => scheduler.cancel(choreId);

  @override
  Future<void> cancelAll() => scheduler.cancelAll();

  @override
  Future<void> rescheduleAll() async {
    final chores = await db.getActiveChores();
    for (final chore in chores) {
      await scheduleForChore(chore);
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return PluginNotificationScheduler();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final scheduler = ref.watch(notificationSchedulerProvider);
  return NotificationServiceImpl(scheduler: scheduler, db: db, ref: ref);
});
