import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/strings/voice_provider.dart';
import 'package:flutter/material.dart';
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

      expect(snapshot.themeMode, isNull);
      expect(snapshot.hapticsEnabled, isTrue);
      expect(snapshot.notificationsEnabled, isTrue);
      expect(snapshot.showDetailsOnCards, isTrue);
      expect(snapshot.lastBackupAt, isNull);
    });

    test('themeMode round-trips', () async {
      final service = SharedPreferencesSettingsService();

      await service.setThemeMode(ThemeMode.dark);

      expect((await service.load()).themeMode, equals(ThemeMode.dark));
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

    test('autoBackupEnabled defaults to true and round-trips', () async {
      final service = SharedPreferencesSettingsService();
      expect((await service.load()).autoBackupEnabled, isTrue);

      await service.setAutoBackupEnabled(false);
      expect((await service.load()).autoBackupEnabled, isFalse);

      await service.setAutoBackupEnabled(true);
      expect((await service.load()).autoBackupEnabled, isTrue);
    });

    test('lastAutoBackupAt round-trips at millisecond precision', () async {
      final service = SharedPreferencesSettingsService();
      final timestamp = DateTime(2026, 8, 11, 9, 15, 0);

      await service.setLastAutoBackupAt(timestamp);

      expect(
        (await service.load()).lastAutoBackupAt,
        equals(DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch,
        )),
      );
    });

    test('lastAutoBackupAt can be cleared back to null', () async {
      final service = SharedPreferencesSettingsService();
      await service.setLastAutoBackupAt(DateTime(2026, 1, 1));

      await service.setLastAutoBackupAt(null);

      expect((await service.load()).lastAutoBackupAt, isNull);
    });

    test('an unrecognized persisted theme mode name is ignored, not thrown',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.themeMode': 'not-a-real-mode',
      });
      final service = SharedPreferencesSettingsService();

      expect((await service.load()).themeMode, isNull);
    });

    test('a stale seed-theme-picker key from before the ThemeMode switch is '
        'ignored, not thrown', () async {
      SharedPreferences.setMockInitialValues({
        'settings.themeId': 'woodland',
      });
      final service = SharedPreferencesSettingsService();

      expect((await service.load()).themeMode, isNull);
    });

    test('voice defaults to null (superhero) and round-trips once set',
        () async {
      final service = SharedPreferencesSettingsService();
      expect((await service.load()).voice, isNull);

      await service.setVoice(AppVoice.wheelOfTime);

      expect((await service.load()).voice, equals(AppVoice.wheelOfTime));
    });

    test('an unrecognized persisted voice name is ignored, not thrown',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.voice': 'not-a-real-voice',
      });
      final service = SharedPreferencesSettingsService();

      expect((await service.load()).voice, isNull);
    });
  });
}
