import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chore id from a tapped notification, while the tap is still being
/// handled — set from a foreground tap callback or from the app's launch
/// details, consumed by the chores list to scroll to that chore and then
/// cleared.
class NotificationTapChoreIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int choreId) {
    // Riverpod suppresses no-op same-value updates, so a repeat tap on the
    // same chore (e.g. the previous tap's clear() never ran because the
    // chores screen was disposed mid-handling) would otherwise notify no
    // one. Routing through null first guarantees a real state change every
    // time, even when choreId is unchanged.
    state = null;
    state = choreId;
  }

  void clear() {
    state = null;
  }
}

final notificationTapChoreIdProvider =
    NotifierProvider<NotificationTapChoreIdNotifier, int?>(
      NotificationTapChoreIdNotifier.new,
    );
