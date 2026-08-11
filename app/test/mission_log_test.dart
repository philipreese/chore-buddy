import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/presentation/mission_log_screen.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;
  const strings = SuperheroStrings();
  // Wednesday, in the week starting Monday Aug 10, 2026.
  final now = DateTime(2026, 8, 12, 12, 0, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpToRoute(WidgetTester tester, String path) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          tickerProvider.overrideWith((ref) => Stream.value(now)),
          nowProvider.overrideWith((ref) => now),
          notificationServiceProvider.overrideWithValue(notificationService),
          widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (path != '/chores') {
      container.read(routerProvider).push(path);
      await tester.pumpAndSettle();
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<int> insertChore(String name, RecurrenceType recurrence) {
    return db.insertChore(
      ChoresCompanion.insert(
        name: name,
        recurrence: Value(recurrence),
      ),
    );
  }

  Future<void> complete(int choreId, DateTime at) async {
    await db.insertCompletionRecord(
      CompletionRecordsCompanion.insert(choreId: choreId, completedAt: at),
    );
  }

  group('Banner weekly line', () {
    testWidgets('zero completions ever shows the zero-state line',
        (tester) async {
      await pumpToRoute(tester, '/chores');

      expect(find.byKey(const Key('banner_weekly_line')), findsOneWidget);
      expect(find.text(strings.bannerStatsZeroState), findsOneWidget);

      await unmount(tester);
    });

    testWidgets(
        'shows the count and first-week wording, and tapping it opens the '
        'Mission Log', (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.daily);
      await complete(choreId, DateTime(2026, 8, 11));
      await complete(choreId, DateTime(2026, 8, 12));

      await pumpToRoute(tester, '/chores');

      expect(find.text(strings.bannerStatsFirstWeek(2)), findsOneWidget);

      await tester.tap(find.byKey(const Key('banner_weekly_line')));
      await tester.pumpAndSettle();

      expect(find.byType(MissionLogScreen), findsOneWidget);
      expect(find.text(strings.missionLogTitle), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('shows "more than last" wording when this week beats last',
        (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.daily);
      await complete(choreId, DateTime(2026, 8, 3)); // last week: 1
      await complete(choreId, DateTime(2026, 8, 11)); // this week: 3
      await complete(choreId, DateTime(2026, 8, 12));
      await complete(choreId, DateTime(2026, 8, 12));

      await pumpToRoute(tester, '/chores');

      expect(find.text(strings.bannerStatsMore(3, 2)), findsOneWidget);

      await unmount(tester);
    });
  });

  group('Streak chip (chore detail)', () {
    testWidgets(
        'no chip below streak 2 for a chore with an expected period',
        (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.daily);
      await complete(choreId, DateTime(2026, 8, 11));

      await pumpToRoute(tester, '/chores/$choreId');

      expect(find.byKey(const Key('streak_chip')), findsNothing);
      expect(find.byKey(const Key('total_count_chip')), findsNothing);

      await unmount(tester);
    });

    testWidgets('streak chip appears once the streak reaches 2',
        (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.daily);
      await complete(choreId, DateTime(2026, 8, 11));
      await complete(choreId, DateTime(2026, 8, 12));

      await pumpToRoute(tester, '/chores/$choreId');

      expect(find.byKey(const Key('streak_chip')), findsOneWidget);
      expect(find.text(strings.streakChipLabel(2)), findsOneWidget);

      await unmount(tester);
    });

    testWidgets(
        'a no-period chore shows a total-count chip instead of a streak',
        (tester) async {
      final choreId = await insertChore('One-off Task', RecurrenceType.none);
      await complete(choreId, DateTime(2026, 8, 1));
      await complete(choreId, DateTime(2026, 8, 5));

      await pumpToRoute(tester, '/chores/$choreId');

      expect(find.byKey(const Key('total_count_chip')), findsOneWidget);
      expect(find.text(strings.totalCompletionsChipLabel(2)), findsOneWidget);
      expect(find.byKey(const Key('streak_chip')), findsNothing);

      await unmount(tester);
    });

    testWidgets('cadence line appears once 3+ completions exist',
        (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.weekly);
      await complete(choreId, DateTime(2026, 7, 1));
      await complete(choreId, DateTime(2026, 7, 8));
      await complete(choreId, DateTime(2026, 7, 15));

      await pumpToRoute(tester, '/chores/$choreId');

      expect(find.byKey(const Key('cadence_line')), findsOneWidget);
      expect(find.text(strings.cadenceLineOnSchedule(7)), findsOneWidget);

      await unmount(tester);
    });
  });

  group('Mission Log page', () {
    testWidgets('renders with data: week count, best streak, three blocks',
        (tester) async {
      final choreId = await insertChore('Dishes', RecurrenceType.daily);
      await complete(choreId, DateTime(2026, 8, 11));
      await complete(choreId, DateTime(2026, 8, 12));

      await pumpToRoute(tester, '/stats');

      expect(find.text(strings.missionLogTitle), findsOneWidget);
      expect(find.text(strings.missionLogThisWeekLabel), findsOneWidget);
      expect(find.text(strings.missionLogLastFiveWeeksTitle), findsOneWidget);
      expect(find.text(strings.missionLogThisMonthTitle), findsOneWidget);

      final weekCountText = tester.widget<Text>(
        find.byKey(const Key('mission_log_week_count')),
      );
      expect(weekCountText.data, equals('2'));

      expect(
        find.text(strings.missionLogBestStreakLabel('Dishes', 2)),
        findsOneWidget,
      );

      await unmount(tester);
    });

    testWidgets('renders gracefully with no data at all', (tester) async {
      await pumpToRoute(tester, '/stats');

      expect(find.text(strings.missionLogTitle), findsOneWidget);

      final weekCountText = tester.widget<Text>(
        find.byKey(const Key('mission_log_week_count')),
      );
      expect(weekCountText.data, equals('0'));

      expect(find.byKey(const Key('mission_log_best_streak')), findsNothing);

      await unmount(tester);
    });
  });
}
