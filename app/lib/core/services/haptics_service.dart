import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around platform haptic feedback so call sites don't touch
/// `flutter/services.dart` directly and tests can substitute a fake.
abstract class HapticsService {
  Future<void> completionFeedback();
}

/// Flutter has no built-in API for a custom-duration vibration (the MAUI
/// reference fired an explicit 175ms pulse); `HapticFeedback.vibrate()` is
/// the closest built-in equivalent and avoids adding a new package for a
/// single call site.
class SystemHapticsService implements HapticsService {
  const SystemHapticsService();

  @override
  Future<void> completionFeedback() {
    return HapticFeedback.vibrate();
  }
}

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return const SystemHapticsService();
});

class HapticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool enabled) {
    state = enabled;
  }
}

/// Default on; persistence lands in slice 09.
final hapticsEnabledProvider = NotifierProvider<HapticsEnabledNotifier, bool>(
  HapticsEnabledNotifier.new,
);
