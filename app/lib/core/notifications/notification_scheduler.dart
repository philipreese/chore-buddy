import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'background_completion.dart';

/// The action id sent back in [NotificationResponse.actionId] when the
/// "Complete" button on a chore notification is tapped. `showsUserInterface:
/// false` on the action means every tap -- app running or not -- is routed
/// by the plugin to [notificationBackgroundResponseHandler] on a background
/// isolate rather than the in-app `onNotificationTapped` callback, so there
/// is exactly one code path to keep foreground and background taps in sync.
const kCompleteChoreActionId = 'complete_chore';

/// Low-level wrapper over the local-notifications plugin: platform-channel
/// calls only, no gating/domain logic. Kept separate from
/// [NotificationScheduler]'s caller so unit tests can substitute a fake and
/// never touch a platform channel.
abstract class NotificationScheduler {
  /// Sets up the plugin and the notification channel. Safe to call more
  /// than once; only the first call takes effect.
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
    required String channelName,
    required String channelDescription,
  });

  /// The payload of the notification that launched the app from a
  /// terminated state, if any.
  Future<String?> getLaunchPayload();

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    required String completeActionLabel,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Shows [title]/[body] immediately, with no due date -- used for
  /// one-off confirmations (e.g. a voice command acted on while the app is
  /// backgrounded) rather than the due-date reminder [zonedSchedule] fires.
  Future<void> showNow({required int id, required String title, required String body});
}

/// Real implementation backed by `flutter_local_notifications`.
///
/// Every plugin call is wrapped so a platform failure (missing platform
/// channel under `flutter test`, a denied permission, a plugin quirk on an
/// unusual OEM build) degrades to "no notification" instead of crashing the
/// mutation flow that triggered it — completing/saving/deleting a chore
/// must never fail because a reminder couldn't be scheduled.
class PluginNotificationScheduler implements NotificationScheduler {
  static const _channelId = 'chore_due_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionRequested = false;
  String _channelName = 'Reminders';
  String _channelDescription = 'Reminders for chores that are due.';

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
    required String channelName,
    required String channelDescription,
  }) async {
    if (_initialized) return;
    _channelName = channelName;
    _channelDescription = channelDescription;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('ic_notification');
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          onNotificationTapped(response.payload);
        },
        // The "Complete" action is showsUserInterface: false, so the
        // plugin always routes it here regardless of whether the app is
        // running -- registering the callback is what lets the OS invoke
        // it on a background isolate later, including after the app has
        // been fully terminated.
        onDidReceiveBackgroundNotificationResponse:
            notificationBackgroundResponseHandler,
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      // Only latch on success: if initialize threw, the notification-tap
      // callback was never registered, so the next call must retry rather
      // than silently no-op for the rest of the process.
      _initialized = true;
    } catch (e, st) {
      debugPrint('NotificationScheduler.initialize failed: $e\n$st');
    }
  }

  @override
  Future<String?> getLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        return details?.notificationResponse?.payload;
      }
    } catch (e, st) {
      debugPrint('NotificationScheduler.getLaunchPayload failed: $e\n$st');
    }
    return null;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    required String completeActionLabel,
  }) async {
    try {
      await _requestPermissionsOnce();

      // No device-timezone-detection package is in scope for this slice, so
      // the absolute instant is computed via `.toUtc()` and represented
      // under the UTC location. TZDateTime.from() converts through the
      // instant, not the wall-clock fields, so this fires at the correct
      // moment regardless of what `tz.local` is set to.
      final tzDate = tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              kCompleteChoreActionId,
              completeActionLabel,
              // Never launch the app for this action: completion happens
              // entirely in the background handler, on-device or not.
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } on PlatformException catch (e) {
        if (e.code == 'exact_alarms_not_permitted') {
          // Android 14+ default-denies exact alarms until the user grants
          // them via system settings; fall back to inexact delivery rather
          // than losing the reminder entirely.
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } else {
          rethrow;
        }
      }
    } catch (e, st) {
      debugPrint('NotificationScheduler.zonedSchedule failed: $e\n$st');
    }
  }

  Future<void> _requestPermissionsOnce() async {
    if (_permissionRequested) return;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      // Only latch on success, so a throwing/interrupted request is retried
      // on the next schedule attempt instead of never asking again.
      _permissionRequested = true;
    } catch (e, st) {
      debugPrint('NotificationScheduler.requestPermissions failed: $e\n$st');
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e, st) {
      debugPrint('NotificationScheduler.cancel failed: $e\n$st');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      debugPrint('NotificationScheduler.cancelAll failed: $e\n$st');
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e, st) {
      debugPrint('NotificationScheduler.showNow failed: $e\n$st');
    }
  }
}
