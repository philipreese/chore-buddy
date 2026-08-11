import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/tags/presentation/tag_manager_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        home: TagManagerScreen(),
      ),
    );
  }

  group('TagManagerScreen Widget Tests', () {
    testWidgets('renders flavored empty state when no tags exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final strings = const SuperheroStrings();
      expect(find.text(strings.manageTags), findsOneWidget);
      expect(find.text(strings.emptyTagsTitle), findsOneWidget);
      expect(find.text(strings.emptyTagsDescription), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('creates a tag via field + swatch flow and displays as colored chip', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final strings = const SuperheroStrings();

      // Enter name with leading/trailing spaces & uppercase
      await tester.enterText(find.byKey(const Key('new_tag_input')), '  Urgent Task  ');
      await tester.pump();

      // Select swatch index 3
      await tester.tap(find.byKey(const Key('swatch_3')));
      await tester.pump();

      // Tap add tag button
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      // Verify tag is added (trimmed & lowercased -> 'urgent task')
      expect(find.text('urgent task'), findsOneWidget);
      expect(find.text(strings.emptyTagsTitle), findsNothing);

      // Verify text field was cleared
      final textField = tester.widget<TextField>(find.byKey(const Key('new_tag_input')));
      expect(textField.controller?.text, isEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('per-tag delete displays confirm dialog and deletes tag', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final strings = const SuperheroStrings();

      // Create tag 'kitchen'
      await tester.enterText(find.byKey(const Key('new_tag_input')), 'kitchen');
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      expect(find.text('kitchen'), findsOneWidget);

      // Get tag id without subscribing to a reactive stream
      final tagList = await db.select(db.tags).get();
      final tagId = tagList.first.id;

      await tester.tap(find.byKey(Key('delete_tag_$tagId')));
      await tester.pumpAndSettle();

      // Verify confirm dialog
      expect(find.text(strings.scrubTagTitle), findsOneWidget);
      expect(find.text(strings.scrubTagMessage('kitchen')), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text(strings.scrubTagConfirm));
      await tester.pumpAndSettle();

      // Verify tag deleted and empty state rendered
      expect(find.text('kitchen'), findsNothing);
      expect(find.text(strings.emptyTagsTitle), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('delete-all displays confirm dialog and clears all tags', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final strings = const SuperheroStrings();

      // Create 2 tags
      await tester.enterText(find.byKey(const Key('new_tag_input')), 'home');
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('new_tag_input')), 'work');
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('work'), findsOneWidget);

      // Tap delete all button
      await tester.tap(find.byKey(const Key('delete_all_tags_button')));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text(strings.deleteAllTagsTitle), findsOneWidget);
      expect(find.text(strings.deleteAllTagsMessage), findsOneWidget);

      // Confirm delete all
      await tester.tap(find.text(strings.deleteAllTagsConfirm));
      await tester.pumpAndSettle();

      // Verify all cleared
      expect(find.text('home'), findsNothing);
      expect(find.text('work'), findsNothing);
      expect(find.text(strings.emptyTagsTitle), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('surfaces duplicate conflict dialog when adding existing tag name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final strings = const SuperheroStrings();

      // Add 'garage'
      await tester.enterText(find.byKey(const Key('new_tag_input')), 'garage');
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      // Attempt to add 'GARAGE' (duplicate after normalization)
      await tester.enterText(find.byKey(const Key('new_tag_input')), 'GARAGE');
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_tag_button')));
      await tester.pumpAndSettle();

      // Verify duplicate dialog
      expect(find.text(strings.tagConflictTitle), findsOneWidget);
      expect(find.text(strings.tagConflictMessage), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text(strings.ok));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}
