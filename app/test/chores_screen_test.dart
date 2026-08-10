import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/presentation/widgets/chore_card.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  const strings = SuperheroStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({
    DateTime? testTime,
    bool useDynamicTime = false,
  }) {
    final effectiveTime = testTime ?? DateTime(2026, 8, 10, 12, 0, 0);
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tickerProvider.overrideWith((ref) => Stream.value(effectiveTime)),
        if (useDynamicTime)
          nowProvider.overrideWith((ref) => ref.watch(testTimeProvider))
        else
          nowProvider.overrideWith((ref) => effectiveTime),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
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
        const TagsCompanion(
          name: Value('Kitchen'),
          colorIndex: Value(0),
        ),
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

    testWidgets('overdue chore shows overdue tint and a not-due chore does not',
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
        find.descendant(of: overdueCard, matching: find.byIcon(Icons.schedule)),
      );

      final futureCard = find.ancestor(
        of: find.text('Future Chore'),
        matching: find.byType(ChoreCard),
      );
      final futureIcon = tester.widget<Icon>(
        find.descendant(of: futureCard, matching: find.byIcon(Icons.schedule)),
      );

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final colorScheme = Theme.of(context).colorScheme;

      expect(overdueIcon.color, equals(colorScheme.error));
      expect(futureIcon.color, equals(colorScheme.primary));

      await unmount(tester);
    });

    testWidgets('swipe-delete shows confirm dialog and deletes chore',
        (tester) async {
      await db.insertChore(
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

      final activeChores = await (db.select(db.chores)..where((t) => t.isActive.equals(true))).get();
      expect(activeChores, isEmpty);

      await unmount(tester);
    });

    testWidgets('swipe-archive removes chore from list without confirm',
        (tester) async {
      await db.insertChore(
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

      final activeChores = await (db.select(db.chores)..where((t) => t.isActive.equals(true))).get();
      expect(activeChores, isEmpty);

      final archivedChores = await (db.select(db.chores)..where((t) => t.isActive.equals(false))).get();
      expect(archivedChores.length, equals(1));

      await unmount(tester);
    });

    testWidgets('renders total empty state vs filter empty state', (tester) async {
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

    testWidgets('ticker recolor: tint updates when chore passes due instant',
        (tester) async {
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
      container.read(testTimeProvider.notifier).setTime(
            DateTime(2026, 8, 10, 12, 0, 10),
          );
      await tester.pump();

      icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
      expect(icon.color, equals(colorScheme.error));

      await unmount(tester);
    });
  });
}
