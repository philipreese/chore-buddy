import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/theme/seed_colors.dart';

/// In-memory [SettingsPrefsService] for hydration/widget tests that don't
/// want to depend on the real `shared_preferences` mock channel.
class FakeSettingsPrefsService implements SettingsPrefsService {
  AppThemeId? themeId;
  bool hapticsEnabled;
  bool notificationsEnabled;
  bool showDetailsOnCards;
  DateTime? lastBackupAt;

  FakeSettingsPrefsService({
    this.themeId,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.showDetailsOnCards = true,
    this.lastBackupAt,
  });

  @override
  Future<SettingsSnapshot> load() async {
    return SettingsSnapshot(
      themeId: themeId,
      hapticsEnabled: hapticsEnabled,
      notificationsEnabled: notificationsEnabled,
      showDetailsOnCards: showDetailsOnCards,
      lastBackupAt: lastBackupAt,
    );
  }

  @override
  Future<void> setThemeId(AppThemeId value) async => themeId = value;

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
}
