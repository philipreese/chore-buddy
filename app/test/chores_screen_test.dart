import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/notifications/notification_tap_provider.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/domain/chore_filter_sort.dart';
import 'package:chorebuddy/features/chores/domain/due_status.dart';
import 'package:chorebuddy/features/chores/presentation/widgets/chore_card.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:chorebuddy/features/tags/presentation/tag_manager_screen.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:fake_async/fake_async.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

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
        widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
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

  // Search now collapses to an icon at rest (see SearchAndSortBar), so tests
  // that used to type directly into an always-present SearchBar have to
  // expand it first.
  Future<void> expandSearch(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('search_icon_button')));
    await tester.pumpAndSettle();
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
        'card glyph resolves chore.emoji, then a name-based guess, then the '
        'first letter (spec 23)', (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Explicit Icon Chore'),
          recurrence: Value(RecurrenceType.none),
          emoji: Value('🎉'),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Take Out Trash'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Zzyzx Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(ChoreCard), matching: find.text('🎉')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ChoreCard),
          matching: find.text('🗑️'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(ChoreCard), matching: find.text('Z')),
        findsOneWidget,
      );

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

        // The clock icon that used to carry urgency is gone (replaced by
        // the tinted icon chip); the due-date text line is now the only
        // per-card urgency signal.
        final overdueText = tester.widget<Text>(
          find.textContaining(strings.dueLabel('')).first,
        );
        final futureText = tester.widget<Text>(
          find.textContaining(strings.dueLabel('')).last,
        );

        final BuildContext context = tester.element(find.byType(MaterialApp));
        final colorScheme = Theme.of(context).colorScheme;

        expect(overdueText.style?.color, equals(colorScheme.error));
        expect(futureText.style?.color, equals(colorScheme.primary));

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

    testWidgets(
        'swipe-archive asks for confirmation and archives on confirm', (
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

      // A stray horizontal graze while scrolling must never archive
      // silently — the swipe now surfaces the decommission dialog first.
      await tester.fling(find.text('Archive Me'), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(strings.decommissionTitle), findsOneWidget);
      await tester.tap(find.text(strings.decommissionConfirm));
      await tester.pumpAndSettle();
      await tester.pump();

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

      await expandSearch(tester);
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

      await expandSearch(tester);
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

      // The clock icon that used to carry this tint is gone; the due-date
      // text line is now the only per-card urgency signal (see
      // getDueColor).
      Text dueText() =>
          tester.widget<Text>(find.textContaining(strings.dueLabel('')));

      expect(dueText().style?.color, equals(warmAccentColor(colorScheme)));

      final container = ProviderScope.containerOf(context);
      container
          .read(testTimeProvider.notifier)
          .setTime(DateTime(2026, 8, 10, 12, 0, 10));
      await tester.pump();

      expect(dueText().style?.color, equals(colorScheme.error));

      await unmount(tester);
    });

    testWidgets(
      'tapped-notification chore far below the fold scrolls into view then clears',
      (tester) async {
        final baseDue = DateTime(2026, 8, 10, 12, 0);
        int? targetChoreId;
        // Urgency-ascending is the screen's default sort (most urgent --
        // i.e. earliest due date -- first), so the furthest-out due date
        // (chore 39) sorts last and starts off-screen in a 40-row list.
        for (var i = 0; i < 40; i++) {
          final id = await db.insertChore(
            ChoresCompanion(
              name: Value('Chore $i'),
              nextDueDate: Value(baseDue.add(Duration(days: i))),
              recurrence: const Value(RecurrenceType.none),
            ),
          );
          if (i == 39) targetChoreId = id;
        }

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Confirms the row genuinely isn't built yet, so the assertion below
        // can only pass if the tap actually scrolled to it.
        expect(find.text('Chore 39'), findsNothing);

        final context = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(context);

        container
            .read(notificationTapChoreIdProvider.notifier)
            .set(targetChoreId!);
        await tester.pumpAndSettle();

        expect(find.text('Chore 39'), findsOneWidget);
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

  group('Banner stat chips', () {
    String countTextIn(WidgetTester tester, Key chipKey) {
      final texts = tester.widgetList<Text>(
        find.descendant(of: find.byKey(chipKey), matching: find.byType(Text)),
      );
      // Row order inside the chip is [dot, label, count] -- the count is
      // always the last Text.
      return texts.last.data!;
    }

    testWidgets(
        'counts overdue/today/upcoming from every active chore, ignoring '
        'search/tag filters, and excludes unscheduled chores', (tester) async {
      final now = DateTime(2026, 8, 10, 12, 0);
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Overdue A'),
          nextDueDate: Value(now.subtract(const Duration(days: 1))),
          recurrence: const Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Overdue B'),
          nextDueDate: Value(now.subtract(const Duration(days: 2))),
          recurrence: const Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Today A'),
          nextDueDate: Value(now),
          recurrence: const Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Upcoming A'),
          nextDueDate: Value(now.add(const Duration(days: 3))),
          recurrence: const Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('No Date'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget(testTime: now));
      await tester.pumpAndSettle();

      // Search narrows the visible list but must not change the banner's
      // own counts, which are computed from every active chore.
      await expandSearch(tester);
      await tester.enterText(find.byType(SearchBar), 'Overdue A');
      await tester.pumpAndSettle();

      expect(countTextIn(tester, const Key('stat_chip_overdue')), equals('2'));
      expect(countTextIn(tester, const Key('stat_chip_today')), equals('1'));
      expect(
        countTextIn(tester, const Key('stat_chip_upcoming')),
        equals('1'),
      );

      await unmount(tester);
    });

    testWidgets(
        'tapping a stat chip forces urgency-ascending sort (same mechanism '
        'as the Overdue shortcut)', (tester) async {
      final now = DateTime(2026, 8, 10, 12, 0);
      await db.insertChore(
        ChoresCompanion(
          name: const Value('Overdue Chore'),
          nextDueDate: Value(now.subtract(const Duration(days: 1))),
          recurrence: const Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Zebra Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget(testTime: now));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(context);

      container.read(sortStateProvider.notifier).selectOrder(ChoreSortOrder.name);
      await tester.pumpAndSettle();
      expect(container.read(sortStateProvider).order, equals(ChoreSortOrder.name));

      await tester.tap(find.byKey(const Key('stat_chip_overdue')));
      await tester.pumpAndSettle();

      expect(
        container.read(sortStateProvider).order,
        equals(ChoreSortOrder.urgency),
      );
      expect(
        container.read(sortStateProvider).direction,
        equals(SortDirection.ascending),
      );

      await unmount(tester);
    });

    testWidgets('a zero-count stat chip is disabled and does not force a sort',
        (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('No Date Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(context);

      container.read(sortStateProvider.notifier).selectOrder(ChoreSortOrder.name);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('stat_chip_overdue')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(container.read(sortStateProvider).order, equals(ChoreSortOrder.name));

      await unmount(tester);
    });
  });

  group('Tag filter sheet', () {
    testWidgets(
      'Manage tags closes the sheet and opens the tag manager screen',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tag_filter_button')));
        await tester.pumpAndSettle();

        expect(find.text(strings.filterByTagsTitle), findsOneWidget);

        await tester.tap(find.text(strings.manageTags));
        await tester.pumpAndSettle();

        expect(find.byType(TagManagerScreen), findsOneWidget);
        expect(find.text(strings.filterByTagsTitle), findsNothing);

        await unmount(tester);
      },
    );
  });

  group('Snooze picker', () {
    testWidgets('tapping Not Today shows all four snooze options', (tester) async {
      await db.insertChore(
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

      expect(find.text(strings.snoozeOptionTomorrow), findsOneWidget);
      expect(find.text(strings.snoozeOptionIn3Days), findsOneWidget);
      expect(find.text(strings.snoozeOptionNextWeek), findsOneWidget);
      expect(find.text(strings.snoozeOptionPickDate), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('cancelling the sheet leaves the chore untouched', (tester) async {
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

      // Dismiss the sheet by tapping the scrim rather than picking an option.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      final chore = await (db.select(db.chores)
            ..where((c) => c.id.equals(choreId)))
          .getSingle();
      expect(chore.nextDueDate, equals(DateTime(2026, 8, 9, 14, 0)));

      await unmount(tester);
    });

    final fixedOptions = <(String, DateTime)>[
      ('snooze_option_tomorrow', DateTime(2026, 8, 11, 14, 0)),
      ('snooze_option_in_3_days', DateTime(2026, 8, 13, 14, 0)),
      ('snooze_option_next_week', DateTime(2026, 8, 17, 14, 0)),
    ];

    for (final (key, expectedDueDate) in fixedOptions) {
      testWidgets(
        '$key snoozes to the expected date, preserving time-of-day',
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

          await tester.tap(find.byKey(Key(key)));
          await tester.pumpAndSettle();

          final chore = await (db.select(db.chores)
                ..where((c) => c.id.equals(choreId)))
              .getSingle();
          expect(chore.nextDueDate, equals(expectedDueDate));

          await unmount(tester);
        },
      );
    }
  });
}
