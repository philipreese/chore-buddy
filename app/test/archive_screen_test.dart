import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/archive/presentation/widgets/archived_chore_card.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  const strings = SuperheroStrings();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget() {
    final now = DateTime(2026, 8, 10, 12, 0, 0);
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tickerProvider.overrideWith((ref) => Stream.value(now)),
        nowProvider.overrideWith((ref) => now),
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

  Future<void> goToArchiveTab(WidgetTester tester) async {
    await tester.tap(find.text(strings.tabArchive));
    await tester.pumpAndSettle();
  }

  group('ArchiveScreen Widget Tests', () {
    testWidgets('archived chores render and active chores do not',
        (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Active Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      final archivedId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Retired Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.archiveChore(archivedId);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await goToArchiveTab(tester);

      expect(find.text('Retired Chore'), findsOneWidget);
      expect(find.text('Active Chore'), findsNothing);
      expect(find.byType(ArchivedChoreCard), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('swipe-right restores chore from archive to active list',
        (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Come Back'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.archiveChore(choreId);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await goToArchiveTab(tester);

      expect(find.text('Come Back'), findsOneWidget);

      await tester.fling(find.text('Come Back'), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Come Back'), findsNothing);

      final activeChores =
          await (db.select(db.chores)..where((t) => t.isActive.equals(true)))
              .get();
      final archivedChores =
          await (db.select(db.chores)..where((t) => t.isActive.equals(false)))
              .get();
      expect(activeChores.map((c) => c.name), contains('Come Back'));
      expect(archivedChores, isEmpty);

      await unmount(tester);
    });

    testWidgets('purge all confirms then empties archived set, active untouched',
        (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Still Active'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      final archivedId = await db.insertChore(
        const ChoresCompanion(
          name: Value('To Be Purged'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.archiveChore(archivedId);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await goToArchiveTab(tester);

      expect(find.text('To Be Purged'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      expect(find.text(strings.purgeTitle), findsOneWidget);

      await tester.tap(find.text(strings.purgeConfirm));
      await tester.pumpAndSettle();

      expect(find.text('To Be Purged'), findsNothing);

      final activeChores =
          await (db.select(db.chores)..where((t) => t.isActive.equals(true)))
              .get();
      final archivedChores =
          await (db.select(db.chores)..where((t) => t.isActive.equals(false)))
              .get();
      expect(activeChores.map((c) => c.name), contains('Still Active'));
      expect(archivedChores, isEmpty);

      await unmount(tester);
    });

    testWidgets('purge all cancel keeps archived chores', (tester) async {
      final archivedId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Keep Archived'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.archiveChore(archivedId);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await goToArchiveTab(tester);

      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      expect(find.text(strings.purgeTitle), findsOneWidget);

      await tester.tap(find.text(strings.cancel));
      await tester.pumpAndSettle();

      expect(find.text('Keep Archived'), findsOneWidget);

      final archivedChores =
          await (db.select(db.chores)..where((t) => t.isActive.equals(false)))
              .get();
      expect(archivedChores.length, equals(1));

      await unmount(tester);
    });

    testWidgets('renders flavored empty state when no archived chores',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await goToArchiveTab(tester);

      expect(find.text(strings.emptyArchiveTitle), findsOneWidget);
      expect(find.text(strings.emptyArchiveDescription), findsOneWidget);

      await unmount(tester);
    });
  });
}
