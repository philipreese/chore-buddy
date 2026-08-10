import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Global notifications toggle. Default on; persistence/Settings UI lands
/// in slice 09. Flipping it off cancels every scheduled reminder; flipping
/// it back on re-evaluates every active chore against the gates.
class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;

    final service = ref.read(notificationServiceProvider);
    unawaited(enabled ? service.rescheduleAll() : service.cancelAll());
  }
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );
