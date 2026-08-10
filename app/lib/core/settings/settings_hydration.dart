import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chores/providers/chore_providers.dart';
import '../../features/settings/providers/settings_providers.dart';
import '../notifications/notifications_enabled_provider.dart';
import '../services/haptics_service.dart';
import '../theme/theme_provider.dart';
import 'settings_prefs_service.dart';

/// Reads every persisted setting once at startup, applies it to the relevant
/// provider, then keeps storage in sync with each provider's future changes.
/// The four legacy providers (theme, haptics, notifications, show-details)
/// keep their existing APIs -- this only wires persistence around them, no
/// consumer of those providers needs to change.
///
/// `main()` awaits `ref.read(settingsHydrationProvider.future)` before
/// `runApp` so the first frame already reflects persisted settings. Because
/// this provider is never disposed, its `ref.listen` calls keep running for
/// the lifetime of the app.
final settingsHydrationProvider = FutureProvider<void>((ref) async {
  final prefs = ref.watch(settingsPrefsServiceProvider);
  final snapshot = await prefs.load();

  if (snapshot.themeId != null) {
    ref.read(themeProvider.notifier).setThemeId(snapshot.themeId!);
  }
  ref.read(hapticsEnabledProvider.notifier).setEnabled(snapshot.hapticsEnabled);
  ref
      .read(notificationsEnabledProvider.notifier)
      .setEnabled(snapshot.notificationsEnabled);
  ref
      .read(showDetailsOnCardsProvider.notifier)
      .setVisible(snapshot.showDetailsOnCards);
  ref.read(lastBackupAtProvider.notifier).set(snapshot.lastBackupAt);

  ref.listen(themeProvider.select((state) => state.themeId), (
    previous,
    next,
  ) {
    if (previous != next) {
      unawaited(prefs.setThemeId(next));
    }
  });

  ref.listen<bool>(hapticsEnabledProvider, (previous, next) {
    if (previous != next) unawaited(prefs.setHapticsEnabled(next));
  });

  ref.listen<bool>(notificationsEnabledProvider, (previous, next) {
    if (previous != next) unawaited(prefs.setNotificationsEnabled(next));
  });

  ref.listen<bool>(showDetailsOnCardsProvider, (previous, next) {
    if (previous != next) unawaited(prefs.setShowDetailsOnCards(next));
  });

  ref.listen<DateTime?>(lastBackupAtProvider, (previous, next) {
    if (previous != next) unawaited(prefs.setLastBackupAt(next));
  });
});
