import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/seed_colors.dart';

/// Every persisted settings value, loaded in one shot at startup.
class SettingsSnapshot {
  final AppThemeId? themeId;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final bool showDetailsOnCards;
  final DateTime? lastBackupAt;

  const SettingsSnapshot({
    this.themeId,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.showDetailsOnCards = true,
    this.lastBackupAt,
  });
}

/// Persists the settings surfaced on [SettingsScreen]. Kept separate from the
/// providers it hydrates (see `settings_hydration.dart`) so those providers'
/// APIs stay storage-agnostic and widget tests can override this with a fake.
abstract class SettingsPrefsService {
  Future<SettingsSnapshot> load();
  Future<void> setThemeId(AppThemeId themeId);
  Future<void> setHapticsEnabled(bool value);
  Future<void> setNotificationsEnabled(bool value);
  Future<void> setShowDetailsOnCards(bool value);
  Future<void> setLastBackupAt(DateTime? value);
}

class SharedPreferencesSettingsService implements SettingsPrefsService {
  static const _themeIdKey = 'settings.themeId';
  static const _hapticsKey = 'settings.hapticsEnabled';
  static const _notificationsKey = 'settings.notificationsEnabled';
  static const _showDetailsKey = 'settings.showDetailsOnCards';
  static const _lastBackupAtKey = 'settings.lastBackupAtMillis';

  @override
  Future<SettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIdName = prefs.getString(_themeIdKey);
    AppThemeId? themeId;
    if (themeIdName != null) {
      for (final candidate in AppThemeId.values) {
        if (candidate.name == themeIdName) {
          themeId = candidate;
          break;
        }
      }
    }

    final lastBackupMillis = prefs.getInt(_lastBackupAtKey);

    return SettingsSnapshot(
      themeId: themeId,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      showDetailsOnCards: prefs.getBool(_showDetailsKey) ?? true,
      lastBackupAt: lastBackupMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastBackupMillis),
    );
  }

  @override
  Future<void> setThemeId(AppThemeId themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, themeId.name);
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
}

final settingsPrefsServiceProvider = Provider<SettingsPrefsService>((ref) {
  return SharedPreferencesSettingsService();
});
