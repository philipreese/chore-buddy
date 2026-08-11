import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/notifications/background_completion.dart';
import 'package:chorebuddy/core/notifications/notification_scheduler.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_scheduler.dart';

/// Covers the factored logic behind the "Complete" notification action --
/// see `background_completion.dart`. Deliberately never touches
/// `notificationBackgroundResponseHandler` itself (the `@pragma('vm:entry-
/// point')` top-level function): that opens a real plugin-backed scheduler
/// and reads real SharedPreferences, neither of which are available under
/// `flutter test`. [completeChoreFromNotification] is exactly the seam that
/// keeps the platform-channel bits out of this suite for every group here
/// except the last, which mocks just enough of the plugin's own channel to
/// cover the real `PluginNotificationScheduler`'s background-isolate guard
/// (item 8, spec 28 device feedback) -- a bug that lives inside that class,
/// so [FakeNotificationScheduler] can't reproduce it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeNotificationScheduler scheduler;
  const strings = SuperheroStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduler = FakeNotificationScheduler();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertChore({
    required String name,
    DateTime? nextDueDate,
    RecurrenceType recurrence = RecurrenceType.daily,
    bool isNotificationEnabled = true,
  }) {
    return db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
        isNotificationEnabled: Value(isNotificationEnabled),
      ),
    );
  }

  Future<ChoreEntity> fetchChore(int id) {
    return (db.select(db.chores)..where((c) => c.id.equals(id))).getSingle();
  }

  group('completeChoreFromNotification', () {
    test(
        'inserts a completion record, advances the due date, and reschedules from the fresh row',
        () async {
      final choreId = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2099, 8, 9, 14, 0),
        recurrence: RecurrenceType.daily,
      );

      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
        completedAt: DateTime(2099, 8, 9, 15, 0),
      );

      final history = await db.watchHistoryForChore(choreId).first;
      expect(history, hasLength(1));
      expect(history.single.completedAt, equals(DateTime(2099, 8, 9, 15, 0)));
      expect(history.single.note, equals(''));

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2099, 8, 10, 14, 0)));

      // Cancel/replace semantics: the fired notification is cancelled, and
      // exactly one fresh schedule is issued for the advanced due date.
      expect(scheduler.canceled, equals([choreId, choreId]));
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.id, equals(choreId));
      expect(scheduler.scheduled.single.scheduledDate,
          equals(DateTime(2099, 8, 10, 14, 0)));
      expect(scheduler.scheduled.single.payload, equals(choreId.toString()));
    });

    test('does not reschedule when the global toggle is off', () async {
      final choreId = await insertChore(
        name: 'Feed Cat',
        nextDueDate: DateTime(2099, 8, 9, 8, 0),
      );

      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: false,
        strings: strings,
        completedAt: DateTime(2099, 8, 9, 9, 0),
      );

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2099, 8, 10, 8, 0)));
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.canceled, equals([choreId, choreId]));
    });

    test('does not reschedule when the chore\'s own reminder flag is off',
        () async {
      final choreId = await insertChore(
        name: 'Mop Floors',
        nextDueDate: DateTime(2099, 8, 9, 8, 0),
        isNotificationEnabled: false,
      );

      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
        completedAt: DateTime(2099, 8, 9, 9, 0),
      );

      expect(scheduler.scheduled, isEmpty);
    });

    test('none recurrence clears the due date and schedules nothing',
        () async {
      final choreId = await insertChore(
        name: 'One-off task',
        nextDueDate: DateTime(2099, 8, 9, 8, 0),
        recurrence: RecurrenceType.none,
      );

      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
        completedAt: DateTime(2099, 8, 9, 9, 0),
      );

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, isNull);
      expect(scheduler.scheduled, isEmpty);
    });

    test('a chore deleted before the action is handled just cancels, without throwing',
        () async {
      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: 999,
        notificationsEnabled: true,
        strings: strings,
      );

      expect(scheduler.canceled, equals([999]));
      expect(scheduler.scheduled, isEmpty);
      final history = await (db.select(db.completionRecords)).get();
      expect(history, isEmpty);
    });

    test('defaults completedAt to now when not supplied', () async {
      final choreId = await insertChore(
        name: 'Take Out Trash',
        nextDueDate: DateTime.now().add(const Duration(days: 1)),
      );

      final before = DateTime.now();
      await completeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
      );

      // The dateTime() column stores whole-second precision, so compare
      // with a tolerance rather than exact before/after bounds.
      final history = await db.watchHistoryForChore(choreId).first;
      final drift = history.single.completedAt.difference(before).abs();
      expect(drift < const Duration(seconds: 5), isTrue);
    });
  });

  group('snoozeChoreFromNotification', () {
    test('advances the due date to tomorrow and reschedules from the fresh row',
        () async {
      final choreId = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2099, 8, 9, 14, 0),
        recurrence: RecurrenceType.daily,
      );

      await snoozeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
        now: DateTime(2099, 8, 9, 15, 0),
      );

      final history = await db.watchHistoryForChore(choreId).first;
      expect(history, isEmpty);

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2099, 8, 10, 14, 0)));
      // Recurrence is untouched by a snooze.
      expect(updated.recurrence, equals(RecurrenceType.daily));

      // Cancel/replace semantics, same as completeChoreFromNotification: the
      // fired notification is cancelled explicitly, and scheduleChoreNotification
      // cancels again itself before issuing the fresh schedule.
      expect(scheduler.canceled, equals([choreId, choreId]));
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.id, equals(choreId));
      expect(scheduler.scheduled.single.scheduledDate,
          equals(DateTime(2099, 8, 10, 14, 0)));
    });

    test('a chore with no due date is just cancelled, without throwing',
        () async {
      final choreId = await insertChore(name: 'One-off task', nextDueDate: null);

      await snoozeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: true,
        strings: strings,
      );

      expect(scheduler.canceled, equals([choreId]));
      expect(scheduler.scheduled, isEmpty);
    });

    test('a chore deleted before the action is handled just cancels, without throwing',
        () async {
      await snoozeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: 999,
        notificationsEnabled: true,
        strings: strings,
      );

      expect(scheduler.canceled, equals([999]));
      expect(scheduler.scheduled, isEmpty);
    });

    test('does not reschedule when the global toggle is off', () async {
      final choreId = await insertChore(
        name: 'Feed Cat',
        nextDueDate: DateTime(2099, 8, 9, 8, 0),
      );

      await snoozeChoreFromNotification(
        db: db,
        scheduler: scheduler,
        choreId: choreId,
        notificationsEnabled: false,
        strings: strings,
        now: DateTime(2099, 8, 9, 9, 0),
      );

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2099, 8, 10, 8, 0)));
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group(
    'completeChoreFromNotification with the real, uninitialized plugin '
    'scheduler',
    () {
      // The one deliberate exception to this file's plugin-free rule (see
      // the top-of-file doc comment): item 8's bug lives inside
      // PluginNotificationScheduler itself, so a FakeNotificationScheduler
      // can't reproduce it. This mocks flutter_local_notifications' own
      // MethodChannel just enough to prove the *real* scheduler -- freshly
      // constructed and never `initialize()`d, exactly like the background
      // isolate's reschedule path -- completes the reschedule without
      // throwing and without ever attempting a permission request (which
      // would throw with no foreground Activity to prompt on).
      const channel = MethodChannel('dexterous.com/flutter/local_notifications');
      final permissionRequestCalls = <String>[];
      final zonedScheduleCalls = <Map<Object?, Object?>>[];

      setUp(() {
        // On a device, the background isolate's plugin registrant assigns
        // FlutterLocalNotificationsPlatform.instance before any Dart code
        // runs; under `flutter test` no registrant runs, so mirror that
        // one assignment here or the plugin's zonedSchedule dies with a
        // LateInitializationError before ever reaching the mocked channel.
        AndroidFlutterLocalNotificationsPlugin.registerWith();
        permissionRequestCalls.clear();
        zonedScheduleCalls.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestNotificationsPermission') {
            permissionRequestCalls.add(call.method);
            return true;
          }
          if (call.method == 'zonedSchedule') {
            zonedScheduleCalls.add(call.arguments as Map<Object?, Object?>);
            return null;
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test(
        'schedules the next reminder without throwing and without '
        'requesting notification permission',
        () async {
          final choreId = await insertChore(
            name: 'Water Plants',
            nextDueDate: DateTime(2099, 8, 9, 14, 0),
            recurrence: RecurrenceType.daily,
          );

          await completeChoreFromNotification(
            db: db,
            scheduler: PluginNotificationScheduler(),
            choreId: choreId,
            notificationsEnabled: true,
            strings: strings,
            completedAt: DateTime(2099, 8, 9, 15, 0),
          );

          expect(zonedScheduleCalls, hasLength(1));
          expect(zonedScheduleCalls.single['id'], equals(choreId));
          expect(permissionRequestCalls, isEmpty);
        },
      );
    },
  );
}
