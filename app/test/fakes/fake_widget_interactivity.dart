import 'package:chorebuddy/core/home_widget/widget_interactivity.dart';

/// No-op stand-in for the `home_widget` launch/interactivity statics: no
/// callback registration, an empty click stream, and no launch URI, so the
/// full-app harness never touches a platform channel.
class FakeWidgetInteractivity implements WidgetInteractivity {
  FakeWidgetInteractivity({this.launchUri});

  /// Uri to hand back from [initiallyLaunchedFromHomeWidget], mirroring how
  /// FakeAppShortcuts.launchAction replays a cold-launch action.
  final Uri? launchUri;

  Future<void> Function(Uri?)? registeredCallback;

  @override
  Future<void> registerInteractivityCallback(
    Future<void> Function(Uri?) callback,
  ) async {
    registeredCallback = callback;
  }

  @override
  Stream<Uri?> get widgetClicked => const Stream<Uri?>.empty();

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() async => launchUri;
}
