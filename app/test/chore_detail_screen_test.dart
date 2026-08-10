import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/presentation/chore_detail_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  Future<void> pumpToDetail(WidgetTester tester, String path) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
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
    container.read(routerProvider).push(path);
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<ChoreEntity> fetchChoreByName(String name) {
    return (db.select(db.chores)..where((c) => c.name.equals(name)))
        .getSingle();
  }

  group('ChoreDetailScreen Widget Tests', () {
    testWidgets(
        'new-chore save creates with chosen tags/due/recurrence and pops',
        (tester) async {
      final tagId = await db.insertTag(
        const TagsCompanion(name: Value('kitchen'), colorIndex: Value(0)),
      );

      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Wash Dishes',
      );
      await tester.pump();

      await tester.tap(find.byKey(Key('tag_chip_$tagId')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('recurrence_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.recurrenceWeekly).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      // Popped back to the chores list.
      expect(find.byType(ChoreDetailScreen), findsNothing);
      expect(find.text('Wash Dishes'), findsOneWidget);

      final chore = await fetchChoreByName('Wash Dishes');
      expect(chore.nextDueDate, isNotNull);
      expect(chore.recurrence, equals(RecurrenceType.weekly));

      final tagIds = await db.getTagIdsForChore(chore.id);
      expect(tagIds, equals([tagId]));

      await unmount(tester);
    });

    testWidgets('edit-mode loads existing values', (tester) async {
      final tagId = await db.insertTag(
        const TagsCompanion(name: Value('garden'), colorIndex: Value(1)),
      );
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Mow Lawn'),
          nextDueDate: Value(DateTime(2026, 8, 15, 9, 30)),
          recurrence: const Value(RecurrenceType.monthly),
        ),
      );
      await db.setChoreTags(choreId, [tagId]);

      await pumpToDetail(tester, '/chores/$choreId');

      final nameField = tester.widget<TextField>(
        find.byKey(const Key('chore_name_field')),
      );
      expect(nameField.controller?.text, equals('Mow Lawn'));

      final dueSwitch = tester.widget<Switch>(
        find.byKey(const Key('has_due_date_switch')),
      );
      expect(dueSwitch.value, isTrue);

      expect(find.text(strings.recurrenceMonthly), findsOneWidget);

      final tagChip = tester.widget<FilterChip>(
        find.byKey(Key('tag_chip_$tagId')),
      );
      expect(tagChip.selected, isTrue);

      await unmount(tester);
    });

    testWidgets(
        'rename to an existing name shows Registry Conflict and preserves input',
        (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Existing Name'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      final choreBId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Chore B'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreBId');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Existing Name',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      expect(find.text(strings.registryConflictTitle), findsOneWidget);
      expect(find.text(strings.registryConflictMessage), findsOneWidget);

      await tester.tap(find.text(strings.ok));
      await tester.pumpAndSettle();

      // Screen still open, input preserved.
      expect(find.byType(ChoreDetailScreen), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.byKey(const Key('chore_name_field')),
      );
      expect(nameField.controller?.text, equals('Existing Name'));

      await unmount(tester);
    });

    testWidgets('due-date switch off clears the due date on save',
        (tester) async {
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Water Plants'),
          nextDueDate: Value(DateTime(2026, 8, 12, 8, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await fetchChoreByName('Water Plants');
      expect(chore.nextDueDate, isNull);
      expect(chore.recurrence, equals(RecurrenceType.none));

      await unmount(tester);
    });

    testWidgets('history renders records', (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Vacuum'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: choreId,
          completedAt: DateTime(2026, 8, 1, 9, 30),
          note: const Value('did a great job'),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      expect(find.text(strings.completionHistory), findsOneWidget);
      expect(find.textContaining('Aug 01, 2026'), findsOneWidget);
      expect(find.text('did a great job'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('editing a record via the dialog persists new date+note',
        (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Dust Shelves'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      final recordId = await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: choreId,
          completedAt: DateTime(2026, 8, 1, 9, 30),
          note: const Value('old note'),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      await tester.tap(find.byKey(Key('history_record_$recordId')));
      await tester.pumpAndSettle();

      expect(find.text(strings.completionReportTitle), findsOneWidget);

      final noteField = find.widgetWithText(TextField, strings.noteLabel);
      expect(
        tester.widget<TextField>(noteField).controller?.text,
        equals('old note'),
      );

      await tester.enterText(noteField, 'updated note');
      await tester.pump();

      await tester.tap(find.text(strings.logButton));
      await tester.pumpAndSettle();

      final record = await (db.select(db.completionRecords)
            ..where((r) => r.id.equals(recordId)))
          .getSingle();
      expect(record.note, equals('updated note'));

      await unmount(tester);
    });

    testWidgets(
        'swipe-delete a record with confirm removes it and cancel keeps it',
        (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Clean Garage'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      final keepId = await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: choreId,
          completedAt: DateTime(2026, 7, 1, 10, 0),
          note: const Value('keep me'),
        ),
      );
      final deleteId = await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: choreId,
          completedAt: DateTime(2026, 7, 5, 11, 0),
          note: const Value('delete me'),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      // Cancel path: swipe the "keep" record, tap Keep Record.
      await tester.ensureVisible(find.byKey(Key('history_record_$keepId')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(Key('history_record_$keepId')),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.expungeRecordTitle), findsOneWidget);
      await tester.tap(find.text(strings.expungeRecordKeep));
      await tester.pumpAndSettle();

      expect(find.text('keep me'), findsOneWidget);
      var remaining =
          await (db.select(db.completionRecords)).get();
      expect(remaining.length, equals(2));

      // Confirm path: swipe the "delete" record, tap Expunge.
      await tester.ensureVisible(find.byKey(Key('history_record_$deleteId')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(Key('history_record_$deleteId')),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.expungeRecordTitle), findsOneWidget);
      await tester.tap(find.text(strings.expungeRecordConfirm));
      await tester.pumpAndSettle();

      expect(find.text('delete me'), findsNothing);
      expect(find.text('keep me'), findsOneWidget);
      remaining = await (db.select(db.completionRecords)).get();
      expect(remaining.length, equals(1));
      expect(remaining.single.id, equals(keepId));

      await unmount(tester);
    });

    testWidgets('new-chore mode shows no history section', (tester) async {
      await pumpToDetail(tester, '/chores/new');

      expect(find.text(strings.completionHistory), findsNothing);
      expect(find.text(strings.emptyHistoryTitle), findsNothing);

      await unmount(tester);
    });
  });
}
