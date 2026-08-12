import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/standard_strings.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers the "Duplicate" action on an existing chore's detail screen --
/// see chore_detail_screen.dart's _duplicate() and
/// domain/duplicate_name.dart.
void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;
  const strings = StandardStrings();
  final now = DateTime(2026, 8, 10, 12, 0, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpToDetail(WidgetTester tester, String path) async {
    // See chore_detail_screen_test.dart: the chore-icon field (spec 23)
    // added a row that pushes the save button below the default 800x600
    // test viewport for every direct (non-scrolling) tap.
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

  group('Duplicate chore', () {
    testWidgets(
        'opens the new-chore form pre-filled with a suffixed name, tags, recurrence, and notification flag; writes nothing until saved',
        (tester) async {
      final tagId = await db.insertTag(
        const TagsCompanion(name: Value('garden'), colorIndex: Value(1)),
      );
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Water Plants'),
          nextDueDate: Value(DateTime(2026, 8, 15, 9, 30)),
          recurrence: const Value(RecurrenceType.weekly),
          isNotificationEnabled: const Value(false),
        ),
      );
      await db.setChoreTags(choreId, [tagId]);

      await pumpToDetail(tester, '/chores/$choreId');

      final countBefore = await (db.select(db.chores)).get();

      await tester.tap(find.byKey(const Key('duplicate_chore_button')));
      await tester.pumpAndSettle();

      // Nothing written yet -- only navigation happened.
      final countAfterOpen = await (db.select(db.chores)).get();
      expect(countAfterOpen.length, equals(countBefore.length));

      final nameField = tester.widget<TextField>(
        find.byKey(const Key('chore_name_field')),
      );
      expect(nameField.controller?.text, equals('Water Plants II'));

      final tagChip = tester.widget<FilterChip>(
        find.byKey(Key('tag_chip_$tagId')),
      );
      expect(tagChip.selected, isTrue);

      // Due date left empty by default, per spec.
      final dueSwitch = tester.widget<Switch>(
        find.byKey(const Key('has_due_date_switch')),
      );
      expect(dueSwitch.value, isFalse);

      // Turning the due-date switch on reveals the carried-over recurrence
      // and notification flag rather than the fresh-chore defaults.
      await tester.tap(find.byKey(const Key('has_due_date_switch')));
      await tester.pump();

      expect(find.text(strings.recurrenceWeekly), findsOneWidget);
      final notificationSwitch = tester.widget<Switch>(
        find.byKey(const Key('notification_switch')),
      );
      expect(notificationSwitch.value, isFalse);

      await tester.tap(find.byKey(const Key('save_chore_button')));
      await tester.pumpAndSettle();

      final duplicated = await fetchChoreByName('Water Plants II');
      expect(duplicated.recurrence, equals(RecurrenceType.weekly));
      expect(duplicated.isNotificationEnabled, isFalse);
      final duplicatedTagIds = await db.getTagIdsForChore(duplicated.id);
      expect(duplicatedTagIds, equals([tagId]));

      // The original chore is untouched.
      final original = await fetchChoreByName('Water Plants');
      expect(original.nextDueDate, equals(DateTime(2026, 8, 15, 9, 30)));

      await unmount(tester);
    });

    testWidgets('increments the suffix past II when it is already taken',
        (tester) async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Water Plants'),
          recurrence: Value(RecurrenceType.none),
        ),
      );
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Water Plants II'),
          recurrence: Value(RecurrenceType.none),
        ),
      );

      await pumpToDetail(tester, '/chores/$choreId');

      await tester.tap(find.byKey(const Key('duplicate_chore_button')));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(
        find.byKey(const Key('chore_name_field')),
      );
      expect(nameField.controller?.text, equals('Water Plants III'));

      await unmount(tester);
    });
  });
}
