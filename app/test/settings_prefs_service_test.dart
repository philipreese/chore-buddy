import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/theme/seed_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesSettingsService', () {
    test('load() returns defaults when nothing has been persisted', () async {
      final service = SharedPreferencesSettingsService();

      final snapshot = await service.load();

      expect(snapshot.themeId, isNull);
      expect(snapshot.hapticsEnabled, isTrue);
      expect(snapshot.notificationsEnabled, isTrue);
      expect(snapshot.showDetailsOnCards, isTrue);
      expect(snapshot.lastBackupAt, isNull);
    });

    test('themeId round-trips', () async {
      final service = SharedPreferencesSettingsService();

      await service.setThemeId(AppThemeId.woodland);

      expect((await service.load()).themeId, equals(AppThemeId.woodland));
    });

    test('hapticsEnabled round-trips', () async {
      final service = SharedPreferencesSettingsService();

      await service.setHapticsEnabled(false);

      expect((await service.load()).hapticsEnabled, isFalse);
    });

    test('notificationsEnabled round-trips', () async {
      final service = SharedPreferencesSettingsService();

      await service.setNotificationsEnabled(false);

      expect((await service.load()).notificationsEnabled, isFalse);
    });

    test('showDetailsOnCards round-trips', () async {
      final service = SharedPreferencesSettingsService();

      await service.setShowDetailsOnCards(false);

      expect((await service.load()).showDetailsOnCards, isFalse);
    });

    test('lastBackupAt round-trips at millisecond precision', () async {
      final service = SharedPreferencesSettingsService();
      final timestamp = DateTime(2026, 8, 10, 15, 30, 45);

      await service.setLastBackupAt(timestamp);

      expect(
        (await service.load()).lastBackupAt,
        equals(DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch,
        )),
      );
    });

    test('lastBackupAt can be cleared back to null', () async {
      final service = SharedPreferencesSettingsService();
      await service.setLastBackupAt(DateTime(2026, 1, 1));

      await service.setLastBackupAt(null);

      expect((await service.load()).lastBackupAt, isNull);
    });

    test('an unrecognized persisted theme name is ignored, not thrown',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.themeId': 'not-a-real-theme',
      });
      final service = SharedPreferencesSettingsService();

      expect((await service.load()).themeId, isNull);
    });
  });
}
