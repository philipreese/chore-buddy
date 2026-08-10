import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/notifications/notification_tap_provider.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/presentation/widgets/chore_card.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:fake_async/fake_async.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';

class TestTimeNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(2026, 8, 10, 12, 0, 0);

  void setTime(DateTime time) {
    state = time;
  }
}

final testTimeProvider = NotifierProvider<TestTimeNotifier, DateTime>(
  TestTimeNotifier.new,
);

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;
  const strings = SuperheroStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({DateTime? testTime, bool useDynamicTime = false}) {
    final effectiveTime = testTime ?? DateTime(2026, 8, 10, 12, 0, 0);
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tickerProvider.overrideWith((ref) => Stream.value(effectiveTime)),
        notificationServiceProvider.overrideWithValue(notificationService),
        if (useDynamicTime)
          nowProvider.overrideWith((ref) => ref.watch(testTimeProvider))
        else
          nowProvider.overrideWith((ref) => effectiveTime),
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

  group('ChoresScreen Widget Tests', () {
    testWidgets('cards render name, tags, and due date', (tester) async {
      final tagId = await db.insertTag(
        const TagsCompanion(name: Value('Kitchen'), colorIndex: Value(0)),
      );
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Wash Dishes'),
          nextDueDate: Value(DateTime(2026, 8, 10, 14, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );
      await db.setChoreTags(choreId, [tagId]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Wash Dishes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChoreCard),
          matching: find.text('Kitchen'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Aug 10, 2026'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets(
      'overdue chore shows overdue tint and a not-due chore does not',
      (tester) async {
        final now = DateTime(2026, 8, 10, 12, 0);

        await db.insertChore(
          ChoresCompanion(
            name: const Value('Overdue Chore'),
            nextDueDate: Value(now.subtract(const Duration(hours: 2))),
            recurrence: const Value(RecurrenceType.daily),
          ),
        );

        await db.insertChore(
          ChoresCompanion(
            name: const Value('Future Chore'),
            nextDueDate: Value(now.add(const Duration(days: 3))),
            recurrence: const Value(RecurrenceType.daily),
          ),
        );

        await tester.pumpWidget(buildTestWidget(testTime: now));
        await tester.pumpAndSettle();

        final overdueCard = find.ancestor(
          of: find.text('Overdue Chore'),
          matching: find.byType(ChoreCard),
        );
        final overdueIcon = tester.widget<Icon>(
          find.descendant(
            of: overdueCard,
            matching: find.byIcon(Icons.schedule),
          ),
        );

        final futureCard = find.ancestor(
          of: find.text('Future Chore'),
          matching: find.byType(ChoreCard),
        );
        final futureIcon = tester.widget<Icon>(
          find.descendant(
            of: futureCard,
            matching: find.byIcon(Icons.schedule),
          ),
        );

        final BuildContext context = tester.element(find.byType(MaterialApp));
        final colorScheme = Theme.of(context).colorScheme;

        expect(overdueIcon.color, equals(colorScheme.error));
        expect(futureIcon.color, equals(colorScheme.primary));

        await unmount(tester);
      },
    );

    testWidgets('swipe-delete shows confirm dialog and deletes chore', (
      tester,
    ) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Scrap Me'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Scrap Me'), findsOneWidget);

      await tester.fling(find.text('Scrap Me'), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(strings.scrapTitle), findsOneWidget);

      await tester.tap(find.text(strings.scrapConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scrap Me'), findsNothing);

      final activeChores = await (db.select(
        db.chores,
      )..where((t) => t.isActive.equals(true))).get();
      expect(activeChores, isEmpty);
      expect(notificationService.canceled, contains(choreId));

      await unmount(tester);
    });

    testWidgets('swipe-delete cancel retains chore in list and database', (
      tester,
    ) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Keep Me'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keep Me'), findsOneWidget);

      await tester.fling(find.text('Keep Me'), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(strings.scrapTitle), findsOneWidget);

      await tester.tap(find.text(strings.cancel));
      await tester.pumpAndSettle();

      expect(find.text('Keep Me'), findsOneWidget);

      final activeChores = await (db.select(
        db.chores,
      )..where((t) => t.isActive.equals(true))).get();
      expect(activeChores.length, equals(1));
      expect(activeChores.first.name, equals('Keep Me'));

      await unmount(tester);
    });

    testWidgets('swipe-archive removes chore from list without confirm', (
      tester,
    ) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Archive Me'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Archive Me'), findsOneWidget);

      await tester.fling(find.text('Archive Me'), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text(strings.scrapTitle), findsNothing);
      expect(find.text('Archive Me'), findsNothing);

      final activeChores = await (db.select(
        db.chores,
      )..where((t) => t.isActive.equals(true))).get();
      expect(activeChores, isEmpty);

      final archivedChores = await (db.select(
        db.chores,
      )..where((t) => t.isActive.equals(false))).get();
      expect(archivedChores.length, equals(1));
      expect(notificationService.canceled, contains(choreId));

      await unmount(tester);
    });

    testWidgets('renders total empty state vs filter empty state', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(strings.emptyActiveTitle), findsOneWidget);
      expect(find.text(strings.emptyActiveDescription), findsOneWidget);

      await db.insertChore(
        const ChoresCompanion(
          name: Value('Fold Laundry'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(strings.emptyActiveTitle), findsNothing);
      expect(find.text('Fold Laundry'), findsOneWidget);

      await tester.enterText(find.byType(SearchBar), 'NonexistentQuery');
      await tester.pumpAndSettle();

      expect(find.text(strings.emptyFilterTitle), findsOneWidget);
      expect(find.text(strings.emptyFilterDescription), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('search narrows the chore list', (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Clean Kitchen'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Mow Lawn'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Clean Kitchen'), findsOneWidget);
      expect(find.text('Mow Lawn'), findsOneWidget);

      await tester.enterText(find.byType(SearchBar), 'kitchen');
      await tester.pumpAndSettle();

      expect(find.text('Clean Kitchen'), findsOneWidget);
      expect(find.text('Mow Lawn'), findsNothing);

      await unmount(tester);
    });

    testWidgets('ticker recolor: tint updates when chore passes due instant', (
      tester,
    ) async {
      final dueInstant = DateTime(2026, 8, 10, 12, 0, 5);

      await db.insertChore(
        ChoresCompanion(
          name: const Value('Ticker Chore'),
          nextDueDate: Value(dueInstant),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );

      await tester.pumpWidget(buildTestWidget(useDynamicTime: true));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final colorScheme = Theme.of(context).colorScheme;

      var icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(icon.color, equals(colorScheme.tertiary));

      final container = ProviderScope.containerOf(context);
      container
          .read(testTimeProvider.notifier)
          .setTime(DateTime(2026, 8, 10, 12, 0, 10));
      await tester.pump();

      icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(icon.color, equals(colorScheme.error));

      await unmount(tester);
    });

    testWidgets(
      'tapped-notification chore far below the fold scrolls into view then clears',
      (tester) async {
        final baseDue = DateTime(2026, 8, 10, 12, 0);
        int? targetChoreId;
        // Urgency-descending is the screen's default sort, which orders by
        // due date furthest-first, so the earliest due date (chore 0) sorts
        // last and starts off-screen in a 40-row list.
        for (var i = 0; i < 40; i++) {
          final id = await db.insertChore(
            ChoresCompanion(
              name: Value('Chore $i'),
              nextDueDate: Value(baseDue.add(Duration(days: i))),
              recurrence: const Value(RecurrenceType.none),
            ),
          );
          if (i == 0) targetChoreId = id;
        }

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Confirms the row genuinely isn't built yet, so the assertion below
        // can only pass if the tap actually scrolled to it.
        expect(find.text('Chore 0'), findsNothing);

        final context = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(context);

        container
            .read(notificationTapChoreIdProvider.notifier)
            .set(targetChoreId!);
        await tester.pumpAndSettle();

        expect(find.text('Chore 0'), findsOneWidget);
        expect(container.read(notificationTapChoreIdProvider), isNull);

        await unmount(tester);
      },
    );

    testWidgets(
      'tapped-notification chore hidden by an active search is revealed by clearing the search',
      (tester) async {
        final choreId = await db.insertChore(
          const ChoresCompanion(
            name: Value('Tapped Chore'),
            recurrence: Value(RecurrenceType.none),
          ),
        );
        await db.insertChore(
          const ChoresCompanion(
            name: Value('Unrelated Chore'),
            recurrence: Value(RecurrenceType.none),
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(context);

        container.read(choreSearchQueryProvider.notifier).setQuery('Unrelated');
        await tester.pumpAndSettle();

        // The active search hides the target chore from the filtered list.
        expect(find.text('Tapped Chore'), findsNothing);

        container.read(notificationTapChoreIdProvider.notifier).set(choreId);
        await tester.pumpAndSettle();

        // Resolving the tap clears the search that was hiding the target so
        // it's actually visible, rather than giving up on a chore that
        // exists.
        expect(container.read(choreSearchQueryProvider), isEmpty);
        expect(find.text('Tapped Chore'), findsOneWidget);
        expect(container.read(notificationTapChoreIdProvider), isNull);

        await unmount(tester);
      },
    );

    testWidgets(
      'tapped-notification chore that no longer exists clears the pending id without scrolling',
      (tester) async {
        await db.insertChore(
          const ChoresCompanion(
            name: Value('Still Here'),
            recurrence: Value(RecurrenceType.none),
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(context);

        // Simulates a stale notification for a chore archived/deleted since
        // it fired: this id was never inserted, so it can never resolve.
        container.read(notificationTapChoreIdProvider.notifier).set(999999);
        await tester.pumpAndSettle();

        expect(container.read(notificationTapChoreIdProvider), isNull);

        await unmount(tester);
      },
    );
  });

  group('Ticker & Visibility Provider Tests', () {
    test('tickerStreamProvider emits periodic ticks under fake time', () {
      fakeAsync((async) {
        final container = ProviderContainer();

        final ticks = <DateTime>[];
        // Hold a provider subscription: tickerStreamProvider is autoDispose,
        // so a bare read() lets riverpod dispose it (cancelling the timer)
        // before the first tick.
        final keepAlive = container.listen(tickerStreamProvider, (_, _) {});
        final sub = keepAlive.read().listen(ticks.add);

        async.elapse(const Duration(seconds: 1));
        expect(ticks.length, equals(1));

        async.elapse(const Duration(seconds: 1));
        expect(ticks.length, equals(2));

        sub.cancel();
        keepAlive.close();
        container.dispose();
        async.flushMicrotasks();
      });
    });

    test('ticker subscription drops when chores tab visibility is false', () {
      fakeAsync((async) {
        final container = ProviderContainer();

        expect(container.read(choresTabVisibleProvider), isTrue);

        final sub = container.listen(tickerProvider, (_, _) {});

        async.elapse(const Duration(seconds: 1));
        expect(container.exists(tickerStreamProvider), isTrue);

        container.read(choresTabVisibleProvider.notifier).setVisible(false);
        async.elapse(const Duration(milliseconds: 100));

        expect(container.exists(tickerStreamProvider), isFalse);

        sub.close();
        container.dispose();
        async.flushMicrotasks();
      });
    });

    testWidgets('ticker subscription drops on tab switch in router', (
      tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
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

      expect(container.read(choresTabVisibleProvider), isTrue);

      await tester.tap(find.text('Hall of Rest'));
      await tester.pumpAndSettle();

      expect(container.read(choresTabVisibleProvider), isFalse);

      await unmount(tester);
    });

    testWidgets('non-numeric chore id displays not found screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(context);
      container.read(routerProvider).push('/chores/not-a-number');
      await tester.pumpAndSettle();

      expect(find.text(strings.notFoundTitle), findsOneWidget);
      expect(find.text(strings.choreNotFoundMessage), findsOneWidget);

      await unmount(tester);
    });
  });
}
