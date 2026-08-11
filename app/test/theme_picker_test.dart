import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/settings/settings_hydration.dart';
import 'package:chorebuddy/core/settings/settings_prefs_service.dart';
import 'package:chorebuddy/core/theme/seed_colors.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:chorebuddy/features/settings/presentation/widgets/theme_picker_row.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_settings_prefs_service.dart';

void main() {
  testWidgets(
    'selecting a theme swatch updates themeProvider and persists it',
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
          child: const MaterialApp(home: Scaffold(body: ThemePickerRow())),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeProvider).themeId, equals(AppThemeId.chambray));

      await tester.tap(find.byKey(const Key('theme_swatch_woodland')));
      await tester.pumpAndSettle();

      expect(container.read(themeProvider).themeId, equals(AppThemeId.woodland));
      expect(prefs.themeId, equals(AppThemeId.woodland));
    },
  );

  testWidgets('renders one swatch per seed theme plus Dynamic',
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
        child: const MaterialApp(home: Scaffold(body: ThemePickerRow())),
      ),
    );
    await tester.pumpAndSettle();

    for (final themeId in AppThemeId.values) {
      expect(
        find.byKey(Key('theme_swatch_${themeId.name}')),
        findsOneWidget,
        reason: 'missing swatch for ${themeId.name}',
      );
    }
  });
}
