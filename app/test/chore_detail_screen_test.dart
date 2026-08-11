import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/chores/presentation/chore_detail_screen.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

// Keyboard dismissal on system back / gesture pop is a known widget-test
// coverage gap: it can't be observed through pumpAndSettle without a live
// platform text-input connection. See docs/reviews/06-editor-review.md (F8).
void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;
  const strings = SuperheroStrings();
  final now = DateTime(2026, 8, 10, 12, 0, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpToDetail(WidgetTester tester, String path) async {
    // The chore-icon field (spec 23) added a row above the tag picker,
    // pushing the save button below the default 800x600 test viewport --
    // taller than any single field this form grows by, so every existing
    // direct (non-scrolling) tap on save_chore_button still hits.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

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

      // Saving with a due date schedules a reminder for the new chore.
      expect(notificationService.scheduled, hasLength(1));
      expect(notificationService.scheduled.single.id, equals(chore.id));

      await unmount(tester);
    });

    testWidgets(
        'picking "Every N days", entering 10, and saving persists the '
        'interval and reopening the chore shows it', (tester) async {
      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Change Sheets',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('recurrence_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.recurrenceCustomDays).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('recurrence_interval_field')),
        '10',
      );
      await tester.pump();

      // The interval field makes the form taller than the test viewport, so
      // the ListView hasn't built the save button yet -- scroll until it
      // exists (ensureVisible can't reach an unbuilt child).
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_chore_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await fetchChoreByName('Change Sheets');
      expect(chore.recurrence, equals(RecurrenceType.customDays));
      expect(chore.recurrenceInterval, equals(10));

      await pumpToDetail(tester, '/chores/${chore.id}');
      expect(find.text(strings.recurrenceCustomDaysLabel(10)), findsOneWidget);
      final intervalField = tester.widget<TextFormField>(
        find.byKey(const Key('recurrence_interval_field')),
      );
      expect(intervalField.controller?.text, equals('10'));

      await unmount(tester);
    });

    testWidgets(
        'an out-of-range interval shows a validation error and blocks save',
        (tester) async {
      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Change Sheets',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('recurrence_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.recurrenceCustomDays).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('recurrence_interval_field')),
        '400',
      );
      await tester.pump();

      // The interval field makes the form taller than the test viewport --
      // scroll the save button into existence first (lazy ListView).
      await tester.scrollUntilVisible(
        find.byKey(const Key('save_chore_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      expect(find.text(strings.recurrenceIntervalRangeError), findsOneWidget);
      // Still on the editor -- save was blocked.
      expect(find.byType(ChoreDetailScreen), findsOneWidget);
      final matches = await (db.select(db.chores)
            ..where((c) => c.name.equals('Change Sheets')))
          .get();
      expect(matches, isEmpty);

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

    testWidgets(
        'creating a chore with an existing name shows Registry Conflict '
        'and preserves input', (tester) async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Existing Name'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await pumpToDetail(tester, '/chores/new');

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

      // Screen still open, input preserved, and no duplicate was inserted.
      expect(find.byType(ChoreDetailScreen), findsOneWidget);
      final nameField = tester.widget<TextField>(
        find.byKey(const Key('chore_name_field')),
      );
      expect(nameField.controller?.text, equals('Existing Name'));
      final matches = await (db.select(db.chores)
            ..where((c) => c.name.equals('Existing Name')))
          .get();
      expect(matches.length, equals(1));

      await unmount(tester);
    });

    testWidgets('Mission Reminder flag is persisted on new-chore save',
        (tester) async {
      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Feed Cat',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('notification_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await fetchChoreByName('Feed Cat');
      expect(chore.isNotificationEnabled, isFalse);

      // Save always re-evaluates scheduling for the chore; the gating on
      // the reminder flag itself is exercised in notification_service_test.
      expect(notificationService.scheduled, hasLength(1));
      expect(notificationService.scheduled.single.isNotificationEnabled, isFalse);

      await unmount(tester);
    });

    testWidgets('Mission Reminder flag is persisted on edit-mode save',
        (tester) async {
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Walk Dog'),
          nextDueDate: Value(DateTime(2026, 8, 12, 8, 0)),
          recurrence: const Value(RecurrenceType.daily),
          isNotificationEnabled: const Value(true),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      await tester.tap(find.byKey(const Key('notification_switch')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await (db.select(db.chores)
            ..where((c) => c.id.equals(choreId)))
          .getSingle();
      expect(chore.isNotificationEnabled, isFalse);
      expect(notificationService.scheduled.single.id, equals(choreId));

      await unmount(tester);
    });

    testWidgets(
        'a tag deleted while the form is open is dropped instead of '
        'half-writing the chore', (tester) async {
      final tagId = await db.insertTag(
        const TagsCompanion(name: Value('kitchen'), colorIndex: Value(0)),
      );

      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Take Out Trash',
      );
      await tester.pump();

      await tester.tap(find.byKey(Key('tag_chip_$tagId')));
      await tester.pump();

      // Simulates deleting the tag via the tag manager (reachable through
      // the + button) while this editor stays alive in the background.
      await db.deleteTag(tagId);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      // Save succeeds (the stale tag id was reconciled away) rather than
      // failing on the chore_tags -> tags foreign key.
      expect(find.byType(ChoreDetailScreen), findsNothing);

      final chore = await fetchChoreByName('Take Out Trash');
      final tagIds = await db.getTagIdsForChore(chore.id);
      expect(tagIds, isEmpty);

      // One-shot check: no orphaned chore_tags rows anywhere, i.e. no
      // half-written link table state from the failed tag reference.
      final choreTagRows = await db.select(db.choreTags).get();
      expect(choreTagRows, isEmpty);

      await unmount(tester);
    });

    testWidgets(
        'opening a deleted chore shows the not-found state, not a blank '
        'form', (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Ghost Chore'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.deleteChore(choreId);

      await pumpToDetail(tester, '/chores/$choreId');

      expect(find.text(strings.notFoundTitle), findsOneWidget);
      expect(find.text(strings.choreNotFoundMessage), findsOneWidget);
      expect(find.byKey(const Key('save_chore_button')), findsNothing);

      await unmount(tester);
    });

    testWidgets(
        'typing a name live-guesses an icon until the icon field is edited '
        'directly, after which further name edits stop overwriting it',
        (tester) async {
      await pumpToDetail(tester, '/chores/new');

      final iconField = find.byKey(const Key('chore_icon_field'));
      expect(tester.widget<TextField>(iconField).controller?.text, isEmpty);

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Take Out Trash',
      );
      await tester.pump();
      expect(tester.widget<TextField>(iconField).controller?.text, '🗑️');

      // A name edit that still matches a keyword keeps live-guessing.
      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Water Plants',
      );
      await tester.pump();
      expect(tester.widget<TextField>(iconField).controller?.text, '🪴');

      // Editing the icon field directly marks it dirty -- further name
      // edits must not clobber the user's own choice.
      await tester.enterText(iconField, '🎉');
      await tester.pump();
      expect(tester.widget<TextField>(iconField).controller?.text, '🎉');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Take Out Trash',
      );
      await tester.pump();
      expect(tester.widget<TextField>(iconField).controller?.text, '🎉');

      await unmount(tester);
    });

    testWidgets(
        'a name with no keyword match leaves the icon field blank, and '
        'saving with it blank persists a null emoji', (tester) async {
      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Sharpen Pencils',
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chore_icon_field')))
            .controller
            ?.text,
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await fetchChoreByName('Sharpen Pencils');
      expect(chore.emoji, isNull);

      await unmount(tester);
    });

    testWidgets('saving trims the icon field before persisting',
        (tester) async {
      await pumpToDetail(tester, '/chores/new');

      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Custom Icon Chore',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('chore_icon_field')),
        '  🎉  ',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await fetchChoreByName('Custom Icon Chore');
      expect(chore.emoji, equals('🎉'));

      await unmount(tester);
    });

    testWidgets(
        'editing an existing chore shows its stored icon without '
        'auto-overwriting it as the name changes', (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Walk Dog'),
          recurrence: Value(RecurrenceType.none),
          emoji: Value('🐕'),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      final iconField = find.byKey(const Key('chore_icon_field'));
      expect(tester.widget<TextField>(iconField).controller?.text, '🐕');

      // Renaming to something that would guess a different icon must not
      // clobber the chore's already-stored one.
      await tester.enterText(
        find.byKey(const Key('chore_name_field')),
        'Take Out Trash',
      );
      await tester.pump();
      expect(tester.widget<TextField>(iconField).controller?.text, '🐕');

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final chore = await (db.select(db.chores)
            ..where((c) => c.id.equals(choreId)))
          .getSingle();
      expect(chore.emoji, equals('🐕'));

      await unmount(tester);
    });
  });
}
