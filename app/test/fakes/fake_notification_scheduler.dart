import 'package:chorebuddy/core/notifications/notification_scheduler.dart';

class ScheduledCall {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;
  final String completeActionLabel;
  final String snoozeActionLabel;

  ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
    required this.completeActionLabel,
    required this.snoozeActionLabel,
  });
}

/// Records every call instead of touching a platform channel, so the
/// gating logic in [NotificationServiceImpl] can be unit tested without a
/// device.
class ShownCall {
  final int id;
  final String title;
  final String body;

  ShownCall({required this.id, required this.title, required this.body});
}

class ChannelUpdateCall {
  final String channelName;
  final String channelDescription;

  ChannelUpdateCall({required this.channelName, required this.channelDescription});
}

class FakeNotificationScheduler implements NotificationScheduler {
  final List<ScheduledCall> scheduled = [];
  final List<int> canceled = [];
  final List<ShownCall> shown = [];
  final List<ChannelUpdateCall> channelUpdates = [];
  int cancelAllCallCount = 0;

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> updateChannel({
    required String channelName,
    required String channelDescription,
  }) async {
    channelUpdates.add(
      ChannelUpdateCall(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
    );
  }

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    required String completeActionLabel,
    required String snoozeActionLabel,
  }) async {
    scheduled.add(
      ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        completeActionLabel: completeActionLabel,
        snoozeActionLabel: snoozeActionLabel,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add(ShownCall(id: id, title: title, body: body));
  }
}
