import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/services/haptics_service.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

class FakeHapticsService implements HapticsService {
  int callCount = 0;

  @override
  Future<void> completionFeedback() async {
    callCount++;
  }
}

class DisabledHapticsNotifier extends HapticsEnabledNotifier {
  @override
  bool build() => false;
}

void main() {
  late AppDatabase db;
  late FakeHapticsService haptics;
  late FakeNotificationService notificationService;
  const strings = SuperheroStrings();
  final now = DateTime(2026, 8, 10, 12, 0, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    haptics = FakeHapticsService();
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({bool hapticsEnabled = true}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tickerProvider.overrideWith((ref) => Stream.value(now)),
        nowProvider.overrideWith((ref) => now),
        hapticsServiceProvider.overrideWithValue(haptics),
        notificationServiceProvider.overrideWithValue(notificationService),
        widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
        if (!hapticsEnabled)
          hapticsEnabledProvider.overrideWith(DisabledHapticsNotifier.new),
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
    // Drain the 5s undo-snackbar timer before unmounting so no pending
    // timers survive the test body.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<List<CompletionRecordEntity>> fetchHistory(int choreId) {
    return (db.select(db.completionRecords)
          ..where((r) => r.choreId.equals(choreId)))
        .get();
  }

  // `watchActiveChoresWithDetails()` is the same query the on-screen chore
  // list already watches; a fresh `.first` on it can wait forever for a
  // write that never comes, since the shared broadcast stream doesn't
  // replay its latest value to a late subscriber. A plain one-shot select
  // sidesteps that.
  Future<ChoreEntity> fetchChore(int choreId) {
    return (db.select(db.chores)..where((c) => c.id.equals(choreId))).getSingle();
  }

  group('Chore completion flow', () {
    testWidgets(
        'complete -> dialog -> confirm inserts a record, advances due date, shows snackbar, fires haptics once',
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

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text(strings.completionReportTitle), findsOneWidget);

      await tester.tap(find.text(strings.logButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(strings.choreCompleted), findsOneWidget);
      expect(find.text(strings.undoAction), findsOneWidget);
      expect(haptics.callCount, equals(1));

      final history = await fetchHistory(choreId);
      expect(history.length, equals(1));

      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));

      // Completion advances the due date, which must reschedule the
      // notification for the chore at its new due instant.
      expect(notificationService.scheduled, hasLength(1));
      expect(notificationService.scheduled.single.id, equals(choreId));
      expect(
        notificationService.scheduled.single.nextDueDate,
        equals(DateTime(2026, 8, 11, 14, 0)),
      );

      await unmount(tester);
    });

    testWidgets('cancel does nothing', (tester) async {
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Feed Cat'),
          nextDueDate: Value(DateTime(2026, 8, 9, 8, 0)),
          recurrence: const Value(RecurrenceType.weekly),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text(strings.completionReportTitle), findsOneWidget);

      await tester.tap(find.text(strings.abortButton));
      await tester.pumpAndSettle();

      expect(find.text(strings.completionReportTitle), findsNothing);
      expect(find.text(strings.choreCompleted), findsNothing);
      expect(haptics.callCount, equals(0));

      final history = await fetchHistory(choreId);
      expect(history, isEmpty);

      final chore = await fetchChore(choreId);
      expect(chore.nextDueDate, equals(DateTime(2026, 8, 9, 8, 0)));

      await unmount(tester);
    });

    testWidgets('UNDO within the window deletes the record and restores the prior due date',
        (tester) async {
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Feed Cat'),
          nextDueDate: Value(DateTime(2026, 8, 9, 8, 0)),
          recurrence: const Value(RecurrenceType.weekly),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.logButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(strings.undoAction), findsOneWidget);

      final historyAfterComplete = await fetchHistory(choreId);
      expect(historyAfterComplete.length, equals(1));

      await tester.tap(find.text(strings.undoAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final historyAfterUndo = await fetchHistory(choreId);
      expect(historyAfterUndo, isEmpty);

      final chore = await fetchChore(choreId);
      expect(chore.nextDueDate, equals(DateTime(2026, 8, 9, 8, 0)));

      // Haptics fired for the completion only — never for the undo.
      expect(haptics.callCount, equals(1));

      // One reschedule for the completion, one more restoring the prior
      // due date on undo.
      expect(notificationService.scheduled, hasLength(2));
      expect(
        notificationService.scheduled.last.nextDueDate,
        equals(DateTime(2026, 8, 9, 8, 0)),
      );

      await unmount(tester);
    });

    testWidgets('haptics disabled: completion commits but never vibrates',
        (tester) async {
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Dust Shelves'),
          nextDueDate: Value(DateTime(2026, 8, 9, 8, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );

      await tester.pumpWidget(buildTestWidget(hapticsEnabled: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.logButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(strings.choreCompleted), findsOneWidget);
      expect(haptics.callCount, equals(0));

      await unmount(tester);
    });

    testWidgets('a new completion while one is pending commits the prior one instead of stacking',
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

      // First completion.
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.logButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final historyAfterFirst = await fetchHistory(choreId);
      expect(historyAfterFirst.length, equals(1));
      final firstRecordId = historyAfterFirst.single.id;

      // Second completion before the first's undo window elapses.
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.logButton));
      // The second snackbar is queued behind the first one's exit
      // animation; settle so the UNDO we tap belongs to the second
      // completion, not the outgoing first snackbar.
      await tester.pumpAndSettle();

      final historyAfterSecond = await fetchHistory(choreId);
      expect(historyAfterSecond.length, equals(2));

      // Tapping UNDO now only reverts the second completion.
      await tester.tap(find.text(strings.undoAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final historyAfterUndo = await fetchHistory(choreId);
      expect(historyAfterUndo.length, equals(1));
      expect(historyAfterUndo.single.id, equals(firstRecordId));

      await unmount(tester);
    });
  });
}
