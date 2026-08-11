import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/core/strings/voice_provider.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:chorebuddy/features/settings/presentation/backup_settings_screen.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:chorebuddy/features/tags/presentation/tag_manager_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_notification_service.dart';
import 'fakes/fake_widget_data_writer.dart';

const _strings = SuperheroStrings();

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ChoreBuddy',
      packageName: 'com.philipreese.chorebuddy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
        // The Voice section's tests navigate back to the /chores route,
        // which flips choresTabVisibleProvider back to true and restarts
        // ChoresBanner's real Timer.periodic ticker (see app_router.dart's
        // updateVisibility) -- fixed to a static stream/value the same way
        // chores_screen_test.dart does, so no real timer is ever pending
        // when a test ends.
        tickerProvider.overrideWith((ref) => const Stream.empty()),
        nowProvider.overrideWith((ref) => DateTime(2026, 8, 10, 12, 0, 0)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> openSettings(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tapping the Backup & restore row navigates to the backup sub-page',
    (tester) async {
      final container = buildContainer();
      await openSettings(tester, container);

      final tile = find.byKey(const Key('settings_backup_restore_tile'));
      await scrollTo(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(BackupSettingsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'the Backup & restore subtitle shows Never with no prior backups and '
    'the most recent timestamp once one exists',
    (tester) async {
      final container = buildContainer();
      await openSettings(tester, container);

      final subtitle = find.byKey(const Key('settings_backup_restore_subtitle'));
      await scrollTo(tester, subtitle);
      expect(find.text(_strings.lastBackupNeverLabel), findsOneWidget);

      // Auto-backup landed after the manual one -- the row must show the
      // later (auto) timestamp, not just whichever kind ran first.
      container
          .read(lastBackupAtProvider.notifier)
          .set(DateTime(2026, 8, 9, 8, 0));
      container
          .read(lastAutoBackupAtProvider.notifier)
          .set(DateTime(2026, 8, 10, 3, 0));
      await tester.pumpAndSettle();

      expect(
        find.text(_strings.lastBackupAtLabel('Aug 10, 2026 @ 03:00 AM')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping the Manage tags row navigates to the tag manager screen',
    (tester) async {
      final container = buildContainer();
      await openSettings(tester, container);

      final tile = find.byKey(const Key('settings_manage_tags_tile'));
      await scrollTo(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(TagManagerScreen), findsOneWidget);
    },
  );

  testWidgets(
    'the Voice section lists every voice with its glyph, name, and '
    'signature line',
    (tester) async {
      final container = buildContainer();
      await openSettings(tester, container);

      for (final voice in AppVoice.values) {
        final row = find.byKey(Key('voice_row_${voice.name}'));
        await scrollTo(tester, row);

        final metadata = voice.metadata;
        expect(
          find.descendant(of: row, matching: find.text(metadata.glyph)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: row,
            matching: find.text(metadata.displayName),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: row,
            matching: find.text(voice.strings.voiceSignature),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'selecting a voice row applies it instantly and the chores banner '
    'title updates to match',
    (tester) async {
      final container = buildContainer();
      await openSettings(tester, container);

      expect(container.read(voiceProvider), equals(AppVoice.superhero));

      final standardRow = find.byKey(const Key('voice_row_standard'));
      await scrollTo(tester, standardRow);
      await tester.tap(standardRow);
      await tester.pumpAndSettle();

      expect(container.read(voiceProvider), equals(AppVoice.standard));

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      final bannerTitle = tester.widget<Text>(
        find.byKey(const Key('chores_banner_title')),
      );
      expect(bannerTitle.data, equals('Chores'));
    },
  );

  testWidgets(
    'Delete All Chores syncs the widget like every other mutation (review '
    'B / N4)',
    (tester) async {
      await db.insertChore(
        const ChoresCompanion(name: Value('Wash Dishes')),
      );

      final widgetDataWriter = FakeWidgetDataWriter();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          widgetDataWriterProvider.overrideWithValue(widgetDataWriter),
          tickerProvider.overrideWith((ref) => const Stream.empty()),
          nowProvider.overrideWith((ref) => DateTime(2026, 8, 10, 12, 0, 0)),
        ],
      );
      addTearDown(container.dispose);

      await openSettings(tester, container);

      final deleteAllTile = find.byKey(
        const Key('settings_delete_all_chores_tile'),
      );
      await scrollTo(tester, deleteAllTile);
      final callsBeforeDelete = widgetDataWriter.updateWidgetCallCount;

      await tester.tap(deleteAllTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_strings.wipeAllChoresConfirm));
      await tester.pumpAndSettle();

      expect(await db.getActiveChores(), isEmpty);
      expect(
        widgetDataWriter.updateWidgetCallCount,
        greaterThan(callsBeforeDelete),
      );
    },
  );
}
