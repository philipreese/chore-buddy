import 'package:chorebuddy/core/notifications/notifications_enabled_provider.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/settings/settings_hydration.dart';
import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/services/haptics_service.dart';
import 'package:chorebuddy/core/theme/seed_colors.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_settings_prefs_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer buildContainer(FakeSettingsPrefsService prefs) {
    final container = ProviderContainer(
      overrides: [
        settingsPrefsServiceProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('settingsHydrationProvider', () {
    test('applies persisted values to every provider at startup', () async {
      final prefs = FakeSettingsPrefsService(
        themeId: AppThemeId.russet,
        hapticsEnabled: false,
        notificationsEnabled: false,
        showDetailsOnCards: false,
        lastBackupAt: DateTime(2026, 1, 2, 3, 4),
      );
      final container = buildContainer(prefs);

      await container.read(settingsHydrationProvider.future);

      expect(container.read(themeProvider).themeId, equals(AppThemeId.russet));
      expect(container.read(hapticsEnabledProvider), isFalse);
      expect(container.read(notificationsEnabledProvider), isFalse);
      expect(container.read(showDetailsOnCardsProvider), isFalse);
      expect(container.read(lastBackupAtProvider), equals(DateTime(2026, 1, 2, 3, 4)));
    });

    test('leaves providers at their defaults when nothing was persisted',
        () async {
      final container = buildContainer(FakeSettingsPrefsService());

      await container.read(settingsHydrationProvider.future);

      expect(container.read(themeProvider).themeId, equals(AppThemeId.chambray));
      expect(container.read(hapticsEnabledProvider), isTrue);
      expect(container.read(notificationsEnabledProvider), isTrue);
      expect(container.read(showDetailsOnCardsProvider), isTrue);
      expect(container.read(lastBackupAtProvider), isNull);
    });

    test('persists provider changes made after hydration', () async {
      final prefs = FakeSettingsPrefsService();
      final container = buildContainer(prefs);
      await container.read(settingsHydrationProvider.future);

      container.read(themeProvider.notifier).setThemeId(AppThemeId.affair);
      container.read(hapticsEnabledProvider.notifier).setEnabled(false);
      container.read(showDetailsOnCardsProvider.notifier).setVisible(false);
      container.read(lastBackupAtProvider.notifier).set(DateTime(2026, 5, 6));
      await Future<void>.delayed(Duration.zero);

      expect(prefs.themeId, equals(AppThemeId.affair));
      expect(prefs.hapticsEnabled, isFalse);
      expect(prefs.showDetailsOnCards, isFalse);
      expect(prefs.lastBackupAt, equals(DateTime(2026, 5, 6)));
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
