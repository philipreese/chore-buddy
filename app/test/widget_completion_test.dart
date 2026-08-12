import 'dart:convert';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/background_completion.dart';
import 'package:chorebuddy/core/strings/standard_strings.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_scheduler.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers [completeChoreFromWidget] -- the core behind a checkbox tap on
/// the home-screen widget. Deliberately never touches
/// [widgetInteractivityHandler] itself (the `@pragma('vm:entry-point')`
/// top-level function): that reads real SharedPreferences and opens a real
/// plugin-backed scheduler, neither available under `flutter test`.
/// [completeChoreFromWidget] is exactly the seam that keeps the
/// platform-channel bits out of this suite, the same way
/// [completeChoreFromNotification] is for the notification action.
void main() {
  late AppDatabase db;
  late FakeNotificationScheduler scheduler;
  late FakeWidgetDataWriter writer;
  const strings = StandardStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduler = FakeNotificationScheduler();
    writer = FakeWidgetDataWriter();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertChore({
    required String name,
    DateTime? nextDueDate,
    RecurrenceType recurrence = RecurrenceType.daily,
  }) {
    return db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
        isNotificationEnabled: const Value(true),
      ),
    );
  }

  test(
      'inserts a completion record, advances the due date, reschedules, and re-syncs the widget',
      () async {
    final choreId = await insertChore(
      name: 'Take Out Trash',
      nextDueDate: DateTime(2099, 8, 9, 8, 0),
      recurrence: RecurrenceType.daily,
    );

    await completeChoreFromWidget(
      db: db,
      scheduler: scheduler,
      widgetSyncService: WidgetSyncService(db, strings: strings, writer: writer),
      choreId: choreId,
      notificationsEnabled: true,
      strings: strings,
      completedAt: DateTime(2099, 8, 9, 9, 0),
    );

    final history = await db.watchHistoryForChore(choreId).first;
    expect(history, hasLength(1));
    expect(history.single.completedAt, equals(DateTime(2099, 8, 9, 9, 0)));

    final updated =
        await (db.select(db.chores)..where((c) => c.id.equals(choreId)))
            .getSingle();
    expect(updated.nextDueDate, equals(DateTime(2099, 8, 10, 8, 0)));

    // Cancel/replace: the completed reminder is cancelled and a fresh one
    // scheduled for the advanced due date, mirroring
    // completeChoreFromNotification.
    expect(scheduler.canceled, equals([choreId, choreId]));
    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.scheduledDate,
        equals(DateTime(2099, 8, 10, 8, 0)));

    // The widget's data was re-synced exactly once, after the completion
    // landed.
    expect(writer.updateWidgetCallCount, equals(1));
    expect(writer.savedJson, hasLength(1));
    // The advanced chore still has a (future) due date, so it stays on the
    // widget — dated chores are shown regardless of due window.
    final decoded = jsonDecode(writer.savedJson.single) as List<dynamic>;
    expect(decoded, hasLength(1));
    expect(
      (decoded.single as Map<String, dynamic>)['overdue'],
      isFalse,
    );
  });

  test('a chore deleted before the tap is handled just cancels, without throwing',
      () async {
    await completeChoreFromWidget(
      db: db,
      scheduler: scheduler,
      widgetSyncService: WidgetSyncService(db, strings: strings, writer: writer),
      choreId: 999,
      notificationsEnabled: true,
      strings: strings,
    );

    expect(scheduler.canceled, equals([999]));
    expect(scheduler.scheduled, isEmpty);
    // The completion core no-ops for a missing chore, but the widget is
    // still re-synced so a since-deleted row never lingers in its list.
    expect(writer.updateWidgetCallCount, equals(1));
  });
}
