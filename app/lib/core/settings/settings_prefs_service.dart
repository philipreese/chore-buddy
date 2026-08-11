import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every persisted settings value, loaded in one shot at startup.
class SettingsSnapshot {
  final ThemeMode? themeMode;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final bool showDetailsOnCards;
  final DateTime? lastBackupAt;
  final bool autoBackupEnabled;
  final DateTime? lastAutoBackupAt;

  const SettingsSnapshot({
    this.themeMode,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.showDetailsOnCards = true,
    this.lastBackupAt,
    this.autoBackupEnabled = true,
    this.lastAutoBackupAt,
  });
}

/// Persists the settings surfaced on [SettingsScreen]. Kept separate from the
/// providers it hydrates (see `settings_hydration.dart`) so those providers'
/// APIs stay storage-agnostic and widget tests can override this with a fake.
abstract class SettingsPrefsService {
  Future<SettingsSnapshot> load();
  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setHapticsEnabled(bool value);
  Future<void> setNotificationsEnabled(bool value);
  Future<void> setShowDetailsOnCards(bool value);
  Future<void> setLastBackupAt(DateTime? value);
  Future<void> setAutoBackupEnabled(bool value);
  Future<void> setLastAutoBackupAt(DateTime? value);
}

class SharedPreferencesSettingsService implements SettingsPrefsService {
  static const _themeModeKey = 'settings.themeMode';
  static const _hapticsKey = 'settings.hapticsEnabled';
  static const _notificationsKey = 'settings.notificationsEnabled';
  static const _showDetailsKey = 'settings.showDetailsOnCards';
  static const _lastBackupAtKey = 'settings.lastBackupAtMillis';
  static const _autoBackupEnabledKey = 'settings.autoBackupEnabled';
  static const _lastAutoBackupAtKey = 'settings.lastAutoBackupAtMillis';

  @override
  Future<SettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();

    // The retired seed-theme picker persisted under 'settings.themeId'
    // (e.g. 'chambray', 'woodland'); those names don't map onto ThemeMode,
    // so that key is simply never read anymore -- it's dead, harmless data
    // in existing installs rather than something to migrate.
    final themeModeName = prefs.getString(_themeModeKey);
    ThemeMode? themeMode;
    if (themeModeName != null) {
      for (final candidate in ThemeMode.values) {
        if (candidate.name == themeModeName) {
          themeMode = candidate;
          break;
        }
      }
    }

    final lastBackupMillis = prefs.getInt(_lastBackupAtKey);
    final lastAutoBackupMillis = prefs.getInt(_lastAutoBackupAtKey);

    return SettingsSnapshot(
      themeMode: themeMode,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      showDetailsOnCards: prefs.getBool(_showDetailsKey) ?? true,
      lastBackupAt: lastBackupMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastBackupMillis),
      autoBackupEnabled: prefs.getBool(_autoBackupEnabledKey) ?? true,
      lastAutoBackupAt: lastAutoBackupMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastAutoBackupMillis),
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  @override
  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  @override
  Future<void> setShowDetailsOnCards(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDetailsKey, value);
  }

  @override
  Future<void> setLastBackupAt(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_lastBackupAtKey);
    } else {
      await prefs.setInt(_lastBackupAtKey, value.millisecondsSinceEpoch);
    }
  }

  @override
  Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, value);
  }

  @override
  Future<void> setLastAutoBackupAt(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_lastAutoBackupAtKey);
    } else {
      await prefs.setInt(_lastAutoBackupAtKey, value.millisecondsSinceEpoch);
    }
  }
}

final settingsPrefsServiceProvider = Provider<SettingsPrefsService>((ref) {
  return SharedPreferencesSettingsService();
});
