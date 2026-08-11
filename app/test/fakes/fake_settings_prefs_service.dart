import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:flutter/material.dart';

/// In-memory [SettingsPrefsService] for hydration/widget tests that don't
/// want to depend on the real `shared_preferences` mock channel.
class FakeSettingsPrefsService implements SettingsPrefsService {
  ThemeMode? themeMode;
  bool hapticsEnabled;
  bool notificationsEnabled;
  bool showDetailsOnCards;
  DateTime? lastBackupAt;
  bool autoBackupEnabled;
  DateTime? lastAutoBackupAt;

  FakeSettingsPrefsService({
    this.themeMode,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.showDetailsOnCards = true,
    this.lastBackupAt,
    this.autoBackupEnabled = true,
    this.lastAutoBackupAt,
  });

  @override
  Future<SettingsSnapshot> load() async {
    return SettingsSnapshot(
      themeMode: themeMode,
      hapticsEnabled: hapticsEnabled,
      notificationsEnabled: notificationsEnabled,
      showDetailsOnCards: showDetailsOnCards,
      lastBackupAt: lastBackupAt,
      autoBackupEnabled: autoBackupEnabled,
      lastAutoBackupAt: lastAutoBackupAt,
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode value) async => themeMode = value;

  @override
  Future<void> setHapticsEnabled(bool value) async => hapticsEnabled = value;

  @override
  Future<void> setNotificationsEnabled(bool value) async =>
      notificationsEnabled = value;

  @override
  Future<void> setShowDetailsOnCards(bool value) async =>
      showDetailsOnCards = value;

  @override
  Future<void> setLastBackupAt(DateTime? value) async => lastBackupAt = value;

  @override
  Future<void> setAutoBackupEnabled(bool value) async =>
      autoBackupEnabled = value;

  @override
  Future<void> setLastAutoBackupAt(DateTime? value) async =>
      lastAutoBackupAt = value;
}
