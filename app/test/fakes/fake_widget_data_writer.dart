import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';

/// Records every call instead of touching the `home_widget` platform
/// channel, so [WidgetSyncService] can be unit tested without a device.
class FakeWidgetDataWriter implements WidgetDataWriter {
  final List<String> savedJson = [];
  int updateWidgetCallCount = 0;

  @override
  Future<void> saveChores(String json) async {
    savedJson.add(json);
  }

  @override
  Future<void> updateWidget() async {
    updateWidgetCallCount++;
  }
}
