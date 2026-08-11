import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/router/app_router.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/settings/presentation/backup_settings_screen.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:chorebuddy/features/tags/presentation/tag_manager_screen.dart';
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
}
