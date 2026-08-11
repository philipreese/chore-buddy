import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/settings/settings_hydration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  try {
    await container.read(settingsHydrationProvider.future);
  } catch (e, st) {
    // The persistence layer being broken must degrade settings, not
    // startup -- fall back to defaults and let the app come up regardless.
    debugPrint('Settings hydration failed, falling back to defaults: $e\n$st');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ChoreBuddyApp(),
    ),
  );
}
