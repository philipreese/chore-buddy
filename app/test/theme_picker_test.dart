import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/settings/settings_hydration.dart';
import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:chorebuddy/features/settings/presentation/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_settings_prefs_service.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ChoreBuddy',
      packageName: 'com.philipreese.chorebuddy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets(
    'selecting a theme mode segment updates themeProvider and persists it',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final prefs = FakeSettingsPrefsService();
      final container = ProviderContainer(
        overrides: [
          settingsPrefsServiceProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await container.read(settingsHydrationProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeProvider), equals(ThemeMode.system));

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeProvider), equals(ThemeMode.dark));
      expect(prefs.themeMode, equals(ThemeMode.dark));
    },
  );

  testWidgets('renders one segment per ThemeMode value',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        settingsPrefsServiceProvider.overrideWithValue(
          FakeSettingsPrefsService(),
        ),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    await container.read(settingsHydrationProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings_theme_mode_selector')),
      findsOneWidget,
    );
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });
}
