import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/settings/settings_hydration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(settingsHydrationProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ChoreBuddyApp(),
    ),
  );
}
