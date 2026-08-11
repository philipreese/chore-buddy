import 'package:chorebuddy/core/notifications/notification_scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers scheduleWithExactAlarmFallback (spec 28, device feedback item 7)
/// against a fake "attempt" gate rather than the real plugin/platform
/// channel, exercising the exact-alarm-denied fallback that a fresh
/// emulator install (no USE_EXACT_ALARM grant path) would actually hit.
void main() {
  group('scheduleWithExactAlarmFallback', () {
    test('schedules exact when permitted, with no fallback attempt', () async {
      final modes = <AndroidScheduleMode>[];

      await scheduleWithExactAlarmFallback((mode) async {
        modes.add(mode);
      });

      expect(modes, [AndroidScheduleMode.exactAllowWhileIdle]);
    });

    test(
      'falls back to inexact delivery when exact alarms are not permitted',
      () async {
        final modes = <AndroidScheduleMode>[];

        await scheduleWithExactAlarmFallback((mode) async {
          modes.add(mode);
          if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
            throw PlatformException(code: 'exact_alarms_not_permitted');
          }
        });

        expect(modes, [
          AndroidScheduleMode.exactAllowWhileIdle,
          AndroidScheduleMode.inexactAllowWhileIdle,
        ]);
      },
    );

    test(
      'rethrows platform exceptions unrelated to exact-alarm permission',
      () {
        Future<void> attempt(AndroidScheduleMode mode) async {
          throw PlatformException(code: 'some_other_error');
        }

        expect(
          () => scheduleWithExactAlarmFallback(attempt),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'some_other_error',
            ),
          ),
        );
      },
    );
  });
}
