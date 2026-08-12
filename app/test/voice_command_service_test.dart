import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/strings/standard_strings.dart';
import 'package:chorebuddy/core/voice/voice_command_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_scheduler.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers [executeVoiceCommand] -- the single path both the ADD_CHORE/
/// COMPLETE_CHORE intents and the AppFunctions declarations (which fire the
/// same intents) ultimately run through. Free of platform channels: the
/// MethodChannel bridge itself (voice_command_channel.dart) is a thin
/// fakeable wrapper covered separately in voice_launch_test.dart.
void main() {
  late AppDatabase db;
  late FakeNotificationScheduler scheduler;
  late WidgetSyncService widgetSyncService;
  const strings = StandardStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduler = FakeNotificationScheduler();
    widgetSyncService = WidgetSyncService(
      db,
      strings: strings,
      writer: FakeWidgetDataWriter(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertChore({
    required String name,
    DateTime? nextDueDate,
    RecurrenceType recurrence = RecurrenceType.none,
    bool isActive = true,
  }) {
    return db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
        isActive: Value(isActive),
      ),
    );
  }

  Future<ChoreEntity> fetchChore(int id) {
    return (db.select(db.chores)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<VoiceCommandResult> run(
    Map<String, dynamic> command, {
    DateTime? now,
  }) {
    return executeVoiceCommand(
      db: db,
      scheduler: scheduler,
      widgetSyncService: widgetSyncService,
      notificationsEnabled: true,
      strings: strings,
      command: command,
      now: now,
    );
  }

  group('add', () {
    test('inserts a chore with no recurrence/due date', () async {
      final result = await run({'command': 'add', 'name': 'Water Plants'});

      expect(result, isA<VoiceCommandAdded>());
      expect((result as VoiceCommandAdded).name, 'Water Plants');

      final chores = await db.getActiveChores();
      expect(chores, hasLength(1));
      expect(chores.single.name, 'Water Plants');
      expect(chores.single.recurrence, RecurrenceType.none);
      expect(chores.single.nextDueDate, isNull);
    });

    test('inserts a chore with recurrence and a due date', () async {
      final result = await run({
        'command': 'add',
        'name': 'Feed Cat',
        'recurrence': 'daily',
        'due': '2099-08-09T14:00:00',
      });

      expect(result, isA<VoiceCommandAdded>());
      final chores = await db.getActiveChores();
      expect(chores.single.recurrence, RecurrenceType.daily);
      expect(chores.single.nextDueDate, DateTime(2099, 8, 9, 14, 0));
      // A future due date is scheduled -- reuses the same gates every other
      // add path goes through.
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.title, contains('Feed Cat'));
    });

    test('an unrecognized recurrence value falls back to none rather than crashing', () async {
      final result = await run({
        'command': 'add',
        'name': 'Mystery Task',
        'recurrence': 'fortnightly',
      });

      expect(result, isA<VoiceCommandAdded>());
      final chores = await db.getActiveChores();
      expect(chores.single.recurrence, RecurrenceType.none);
    });

    test('a malformed due date is dropped rather than crashing or writing garbage', () async {
      final result = await run({
        'command': 'add',
        'name': 'Odd Date',
        'due': 'not-a-date',
      });

      expect(result, isA<VoiceCommandAdded>());
      final chores = await db.getActiveChores();
      expect(chores.single.nextDueDate, isNull);
    });

    test('a duplicate name is rejected gracefully, without throwing', () async {
      await insertChore(name: 'Water Plants');

      final result = await run({'command': 'add', 'name': 'water plants'});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.duplicateName,
      );
      final chores = await db.getActiveChores();
      expect(chores, hasLength(1));
    });

    test('a missing name fails as an invalid command', () async {
      final result = await run({'command': 'add', 'name': '  '});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.invalidCommand,
      );
      expect(await db.getActiveChores(), isEmpty);
    });

    test('syncs the widget after a successful add', () async {
      await run({'command': 'add', 'name': 'Water Plants'});

      final writer = widgetSyncService.writer as FakeWidgetDataWriter;
      expect(writer.updateWidgetCallCount, 1);
    });
  });

  group('complete', () {
    test('completes an exact case-insensitive match', () async {
      final id = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2099, 8, 9, 14, 0),
        recurrence: RecurrenceType.daily,
      );

      final result = await run(
        {'command': 'complete', 'name': 'water plants'},
        now: DateTime(2099, 8, 9, 15, 0),
      );

      expect(result, isA<VoiceCommandCompleted>());
      expect((result as VoiceCommandCompleted).name, 'Water Plants');

      final chore = await fetchChore(id);
      expect(chore.nextDueDate, DateTime(2099, 8, 10, 14, 0));
      final history = await db.watchHistoryForChore(id).first;
      expect(history, hasLength(1));
    });

    test('completes via a unique prefix match', () async {
      final id = await insertChore(name: 'Water the Plants');

      final result = await run({'command': 'complete', 'name': 'water'});

      expect(result, isA<VoiceCommandCompleted>());
      final history = await db.watchHistoryForChore(id).first;
      expect(history, hasLength(1));
    });

    test('an ambiguous prefix is a no-op, not a guess', () async {
      await insertChore(name: 'Water Plants');
      await insertChore(name: 'Water Lawn');

      final result = await run({'command': 'complete', 'name': 'water'});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.ambiguous,
      );
      expect(await (db.select(db.completionRecords)).get(), isEmpty);
    });

    test('no match is a no-op', () async {
      await insertChore(name: 'Water Plants');

      final result = await run({'command': 'complete', 'name': 'mow lawn'});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.notFound,
      );
    });

    test('an archived chore is never matched', () async {
      await insertChore(name: 'Water Plants', isActive: false);

      final result = await run({'command': 'complete', 'name': 'Water Plants'});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.notFound,
      );
    });

    test('a missing name fails as an invalid command', () async {
      final result = await run({'command': 'complete', 'name': ''});

      expect(result, isA<VoiceCommandFailed>());
      expect(
        (result as VoiceCommandFailed).reason,
        VoiceCommandFailureReason.invalidCommand,
      );
    });
  });

  test('an unrecognized command type fails as invalid rather than throwing', () async {
    final result = await run({'command': 'snooze', 'name': 'Water Plants'});

    expect(result, isA<VoiceCommandFailed>());
    expect(
      (result as VoiceCommandFailed).reason,
      VoiceCommandFailureReason.invalidCommand,
    );
  });
}
