import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/notifications/notification_scheduler.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/notifications/notifications_enabled_provider.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ScheduledCall {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });
}

/// Records every call instead of touching a platform channel, so the
/// gating logic in [NotificationServiceImpl] can be unit tested without a
/// device.
class FakeNotificationScheduler implements NotificationScheduler {
  final List<ScheduledCall> scheduled = [];
  final List<int> canceled = [];
  int cancelAllCallCount = 0;

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    scheduled.add(
      ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
  }
}

void main() {
  late AppDatabase db;
  late FakeNotificationScheduler scheduler;
  late ProviderContainer container;

  final future = DateTime.now().add(const Duration(days: 1));
  final past = DateTime.now().subtract(const Duration(days: 1));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduler = FakeNotificationScheduler();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ChoreEntity chore({
    int id = 1,
    String name = 'Water Plants',
    DateTime? nextDueDate,
    bool isNotificationEnabled = true,
  }) {
    return ChoreEntity(
      id: id,
      name: name,
      isActive: true,
      nextDueDate: nextDueDate,
      recurrence: RecurrenceType.none,
      isNotificationEnabled: isNotificationEnabled,
      createdAt: DateTime.now(),
    );
  }

  group('NotificationService gating', () {
    test('schedules when every gate passes, id == chore id', () async {
      final service = container.read(notificationServiceProvider);

      await service.scheduleForChore(chore(id: 42, nextDueDate: future));

      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.id, equals(42));
      expect(scheduler.scheduled.single.payload, equals('42'));
      expect(scheduler.scheduled.single.scheduledDate, equals(future));
      // Cancel/replace semantics: always cancels any existing instance
      // first, even on the happy path.
      expect(scheduler.canceled, equals([42]));
    });

    test('global toggle off: cancels only, never schedules', () async {
      container.read(notificationsEnabledProvider.notifier).setEnabled(false);
      final service = container.read(notificationServiceProvider);

      await service.scheduleForChore(chore(nextDueDate: future));

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.canceled, contains(1));
    });

    test('per-chore flag off: cancels only, never schedules', () async {
      final service = container.read(notificationServiceProvider);

      await service.scheduleForChore(
        chore(nextDueDate: future, isNotificationEnabled: false),
      );

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.canceled, contains(1));
    });

    test('no due date: cancels only, never schedules', () async {
      final service = container.read(notificationServiceProvider);

      await service.scheduleForChore(chore(nextDueDate: null));

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.canceled, contains(1));
    });

    test('due date in the past: cancels only, never schedules', () async {
      final service = container.read(notificationServiceProvider);

      await service.scheduleForChore(chore(nextDueDate: past));

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.canceled, contains(1));
    });

    test('cancelForChore delegates straight to the scheduler', () async {
      final service = container.read(notificationServiceProvider);

      await service.cancelForChore(7);

      expect(scheduler.canceled, equals([7]));
    });

    test('rescheduleAll re-evaluates every active chore against the gates',
        () async {
      final scheduledId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Scheduled'),
          nextDueDate: Value(future),
        ),
      );
      final pastId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Past Due'),
          nextDueDate: Value(past),
        ),
      );
      final disabledId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Reminder Off'),
          nextDueDate: Value(future),
          isNotificationEnabled: const Value(false),
        ),
      );
      final archivedId = await db.insertChore(
        const ChoresCompanion(name: Value('Archived')),
      );
      await db.archiveChore(archivedId);

      final service = container.read(notificationServiceProvider);
      await service.rescheduleAll();

      final scheduledIds = scheduler.scheduled.map((c) => c.id).toSet();
      expect(scheduledIds, equals({scheduledId}));
      expect(scheduler.canceled, containsAll([scheduledId, pastId, disabledId]));
      expect(scheduler.canceled, isNot(contains(archivedId)));
    });

    test('toggling notifications off cancels all, back on reschedules all',
        () async {
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Scheduled'),
          nextDueDate: Value(future),
        ),
      );

      container.read(notificationsEnabledProvider.notifier).setEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.cancelAllCallCount, equals(1));

      container.read(notificationsEnabledProvider.notifier).setEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.scheduled, hasLength(1));
    });
  });
}
