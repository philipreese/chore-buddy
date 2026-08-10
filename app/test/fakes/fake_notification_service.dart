import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';

/// Records calls instead of touching a platform channel, so widget tests
/// can assert which [NotificationService] methods a mutation path invoked
/// without ever exercising the real plugin.
class FakeNotificationService implements NotificationService {
  final List<ChoreEntity> scheduled = [];
  final List<int> canceled = [];
  int cancelAllCallCount = 0;
  int rescheduleAllCallCount = 0;

  @override
  Future<void> scheduleForChore(ChoreEntity chore) async {
    scheduled.add(chore);
  }

  @override
  Future<void> cancelForChore(int choreId) async {
    canceled.add(choreId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
  }

  @override
  Future<void> rescheduleAll() async {
    rescheduleAllCallCount++;
  }
}
