import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

/// Seam over `home_widget`'s launch/interactivity platform statics
/// (register callback, click stream, initial launch URI), the counterpart
/// of [WidgetDataWriter] for the read/registration side. app.dart goes
/// through this provider so widget tests can fake it the same way
/// notificationServiceProvider is faked -- the real statics open platform
/// channels that never complete in the test environment.
abstract class WidgetInteractivity {
  Future<void> registerInteractivityCallback(
    Future<void> Function(Uri?) callback,
  );
  Stream<Uri?> get widgetClicked;
  Future<Uri?> initiallyLaunchedFromHomeWidget();
}

class HomeWidgetInteractivity implements WidgetInteractivity {
  @override
  Future<void> registerInteractivityCallback(
    Future<void> Function(Uri?) callback,
  ) {
    return HomeWidget.registerInteractivityCallback(callback);
  }

  @override
  Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }
}

final widgetInteractivityProvider = Provider<WidgetInteractivity>(
  (ref) => HomeWidgetInteractivity(),
);
