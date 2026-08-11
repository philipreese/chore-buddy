import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers the "Not Today" snooze affordance on ChoreCard -- see
/// snooze_flow.dart and snooze_service.dart.
void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;
  late FakeWidgetDataWriter widgetDataWriter;
  const strings = SuperheroStrings();
  final now = DateTime(2026, 8, 10, 12, 0, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
    widgetDataWriter = FakeWidgetDataWriter();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tickerProvider.overrideWith((ref) => Stream.value(now)),
        nowProvider.overrideWith((ref) => now),
        notificationServiceProvider.overrideWithValue(notificationService),
        widgetDataWriterProvider.overrideWithValue(widgetDataWriter),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<ChoreEntity> fetchChore(int choreId) {
    return (db.select(db.chores)..where((c) => c.id.equals(choreId)))
        .getSingle();
  }

  group('Snooze from ChoreCard', () {
    testWidgets(
        'tapping Not Today moves the due date to tomorrow, inserts no record, and reschedules + syncs',
        (tester) async {
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Water Plants'),
          nextDueDate: Value(DateTime(2026, 8, 9, 14, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.snooze));
      await tester.pumpAndSettle();

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));

      final history =
          await (db.select(db.completionRecords)).get();
      expect(history, isEmpty);

      expect(notificationService.scheduled, hasLength(1));
      expect(notificationService.scheduled.single.id, equals(choreId));
      expect(
        notificationService.scheduled.single.nextDueDate,
        equals(DateTime(2026, 8, 11, 14, 0)),
      );

      expect(widgetDataWriter.updateWidgetCallCount, greaterThanOrEqualTo(1));

      expect(find.text(strings.choreSnoozed), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('the Not Today affordance is hidden for a chore with no due date',
        (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('One-off task'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.snooze), findsNothing);

      await unmount(tester);
    });
  });
}
