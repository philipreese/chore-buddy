import 'package:chorebuddy/app.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/home_widget/widget_interactivity.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_widget_data_writer.dart';
import 'fakes/fake_widget_interactivity.dart';

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

  testWidgets('Shell smoke test - renders both tabs and settings navigation',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
          widgetInteractivityProvider.overrideWithValue(
            FakeWidgetInteractivity(),
          ),
        ],
        child: const ChoreBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial active chores tab is displayed with Superhero strings
    expect(find.text('Missions'), findsNWidgets(2)); // AppBar + NavigationBar
    expect(find.text('The Signal is Silent'), findsOneWidget);

    // Verify Archive tab destination exists
    expect(find.text('Hall of Rest'), findsOneWidget);

    // Tap Archive tab
    await tester.tap(find.text('Hall of Rest'));
    await tester.pumpAndSettle();

    // Verify Archive screen is displayed
    expect(find.text('Hall of Rest'), findsNWidgets(2)); // AppBar + NavigationBar
    expect(find.text('There are no archived chores here. Only retired missions are moved to the Hall of Rest.'), findsOneWidget);

    // Tap Settings gear icon in AppBar
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify Settings screen opens
    expect(find.text('Settings'), findsOneWidget); // AppBar title
    expect(find.text('Change Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget); // default ThemeMode segment

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
