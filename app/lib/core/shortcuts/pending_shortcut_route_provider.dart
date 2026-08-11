import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The route to navigate to from a tapped app shortcut or quick-settings
/// tile, while the tap is still being handled -- set from the shortcut
/// callback or the app's initial launch action, consumed by [ChoreBuddyApp]
/// to navigate and then cleared. Mirrors `NotificationTapChoreIdNotifier`'s
/// shape, so shortcuts route through the same pending-navigation pattern
/// notification taps already use.
class PendingShortcutRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String route) {
    // Routing through null first guarantees a real state change even when
    // the same route is set twice in a row (see
    // NotificationTapChoreIdNotifier.set for the same reasoning).
    state = null;
    state = route;
  }

  void clear() {
    state = null;
  }
}

final pendingShortcutRouteProvider =
    NotifierProvider<PendingShortcutRouteNotifier, String?>(
      PendingShortcutRouteNotifier.new,
    );
