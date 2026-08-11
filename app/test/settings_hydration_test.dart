import 'package:chorebuddy/core/notifications/notifications_enabled_provider.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/settings/settings_hydration.dart';
import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/services/haptics_service.dart';
import 'package:chorebuddy/core/strings/voice_provider.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:chorebuddy/features/settings/domain/auto_backup_scheduler.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auto_backup_scheduler.dart';
import 'fakes/fake_settings_prefs_service.dart';

void main() {
  late AppDatabase db;
  late FakeAutoBackupScheduler autoBackupScheduler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    autoBackupScheduler = FakeAutoBackupScheduler();
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer buildContainer(FakeSettingsPrefsService prefs) {
    final container = ProviderContainer(
      overrides: [
        settingsPrefsServiceProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        autoBackupSchedulerProvider.overrideWithValue(autoBackupScheduler),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('settingsHydrationProvider', () {
    test('applies persisted values to every provider at startup', () async {
      final prefs = FakeSettingsPrefsService(
        themeMode: ThemeMode.dark,
        hapticsEnabled: false,
        notificationsEnabled: false,
        showDetailsOnCards: false,
        lastBackupAt: DateTime(2026, 1, 2, 3, 4),
        autoBackupEnabled: false,
        lastAutoBackupAt: DateTime(2026, 1, 3, 4, 5),
        voice: AppVoice.wheelOfTime,
      );
      final container = buildContainer(prefs);

      await container.read(settingsHydrationProvider.future);

      expect(container.read(themeProvider), equals(ThemeMode.dark));
      expect(container.read(hapticsEnabledProvider), isFalse);
      expect(container.read(notificationsEnabledProvider), isFalse);
      expect(container.read(showDetailsOnCardsProvider), isFalse);
      expect(container.read(lastBackupAtProvider), equals(DateTime(2026, 1, 2, 3, 4)));
      expect(container.read(autoBackupEnabledProvider), isFalse);
      expect(container.read(lastAutoBackupAtProvider), equals(DateTime(2026, 1, 3, 4, 5)));
      expect(container.read(voiceProvider), equals(AppVoice.wheelOfTime));
    });

    test('leaves providers at their defaults when nothing was persisted',
        () async {
      final container = buildContainer(FakeSettingsPrefsService());

      await container.read(settingsHydrationProvider.future);

      expect(container.read(themeProvider), equals(ThemeMode.system));
      expect(container.read(hapticsEnabledProvider), isTrue);
      expect(container.read(notificationsEnabledProvider), isTrue);
      expect(container.read(showDetailsOnCardsProvider), isTrue);
      expect(container.read(lastBackupAtProvider), isNull);
      expect(container.read(autoBackupEnabledProvider), isTrue);
      expect(container.read(lastAutoBackupAtProvider), isNull);
      expect(container.read(voiceProvider), equals(AppVoice.superhero));
    });

    test('persists provider changes made after hydration', () async {
      final prefs = FakeSettingsPrefsService();
      final container = buildContainer(prefs);
      await container.read(settingsHydrationProvider.future);

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
      container.read(hapticsEnabledProvider.notifier).setEnabled(false);
      container.read(showDetailsOnCardsProvider.notifier).setVisible(false);
      container.read(lastBackupAtProvider.notifier).set(DateTime(2026, 5, 6));
      container.read(lastAutoBackupAtProvider.notifier).set(DateTime(2026, 5, 7));
      container.read(voiceProvider.notifier).setVoice(AppVoice.standard);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.themeMode, equals(ThemeMode.light));
      expect(prefs.hapticsEnabled, isFalse);
      expect(prefs.showDetailsOnCards, isFalse);
      expect(prefs.lastBackupAt, equals(DateTime(2026, 5, 6)));
      expect(prefs.lastAutoBackupAt, equals(DateTime(2026, 5, 7)));
      expect(prefs.voice, equals(AppVoice.standard));
    });

    test(
        'voice choice round-trips: set, then a fresh provider container '
        '(simulating an app restart) hydrates it back', () async {
      // FakeSettingsPrefsService's state lives outside any ProviderContainer,
      // the same way SharedPreferences' backing store outlives the app
      // process -- reusing one instance across two containers is what
      // stands in for an app restart here. Both containers are built and
      // disposed by hand (not via buildContainer's addTearDown) so the
      // first can be disposed mid-test without a second, teardown-time
      // dispose() throwing on an already-disposed container.
      final prefs = FakeSettingsPrefsService();

      ProviderContainer makeContainer() => ProviderContainer(
            overrides: [
              settingsPrefsServiceProvider.overrideWithValue(prefs),
              appDatabaseProvider.overrideWithValue(db),
              autoBackupSchedulerProvider.overrideWithValue(
                autoBackupScheduler,
              ),
            ],
          );

      final firstContainer = makeContainer();
      await firstContainer.read(settingsHydrationProvider.future);
      firstContainer
          .read(voiceProvider.notifier)
          .setVoice(AppVoice.wheelOfTime);
      await Future<void>.delayed(Duration.zero);
      firstContainer.dispose();

      final secondContainer = makeContainer();
      addTearDown(secondContainer.dispose);
      await secondContainer.read(settingsHydrationProvider.future);

      expect(
        secondContainer.read(voiceProvider),
        equals(AppVoice.wheelOfTime),
      );
    });

    test('schedules the auto-backup job at startup when persisted enabled (the default)',
        () async {
      final container = buildContainer(FakeSettingsPrefsService());

      await container.read(settingsHydrationProvider.future);

      expect(autoBackupScheduler.scheduleCallCount, equals(1));
      expect(autoBackupScheduler.cancelCallCount, equals(0));
    });

    test('cancels the auto-backup job at startup when persisted disabled',
        () async {
      final container = buildContainer(
        FakeSettingsPrefsService(autoBackupEnabled: false),
      );

      await container.read(settingsHydrationProvider.future);

      expect(autoBackupScheduler.cancelCallCount, equals(1));
      expect(autoBackupScheduler.scheduleCallCount, equals(0));
    });

    test('toggling autoBackupEnabledProvider persists it and (re)schedules the job',
        () async {
      final prefs = FakeSettingsPrefsService();
      final container = buildContainer(prefs);
      await container.read(settingsHydrationProvider.future);
      expect(autoBackupScheduler.scheduleCallCount, equals(1));

      container.read(autoBackupEnabledProvider.notifier).setEnabled(false);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.autoBackupEnabled, isFalse);
      expect(autoBackupScheduler.cancelCallCount, equals(1));
    });

    test('toggling notifications off and persisting it does not throw',
        () async {
      final prefs = FakeSettingsPrefsService();
      final container = buildContainer(prefs);
      await container.read(settingsHydrationProvider.future);
      // Force notificationServiceProvider to build against the overridden
      // db so cancelAll() has a real (fake-scheduler) service to call.
      container.read(notificationServiceProvider);

      container
          .read(notificationsEnabledProvider.notifier)
          .setEnabled(false);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.notificationsEnabled, isFalse);
    });
  });
}
