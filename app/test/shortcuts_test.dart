import 'package:chorebuddy/app.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/shortcuts/app_shortcut_action.dart';
import 'package:chorebuddy/core/shortcuts/app_shortcuts.dart';
import 'package:chorebuddy/core/shortcuts/pending_shortcut_route_provider.dart';
import 'package:chorebuddy/features/chores/domain/chore_filter_sort.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_app_shortcuts.dart';

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

  group('AppShortcutAction', () {
    test('fromId resolves the known action ids to their routes', () {
      expect(
        AppShortcutAction.fromId('new_mission'),
        AppShortcutAction.newMission,
      );
      expect(AppShortcutAction.newMission.route, '/chores/new');

      expect(AppShortcutAction.fromId('overdue'), AppShortcutAction.overdue);
      expect(AppShortcutAction.overdue.route, '/chores');
    });

    test('fromId returns null for an unrecognized id', () {
      expect(AppShortcutAction.fromId('unknown_action'), isNull);
    });
  });

  group('PendingShortcutRouteNotifier', () {
    test('set stores the route and clear resets it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingShortcutRouteProvider.notifier).set('/chores/new');
      expect(container.read(pendingShortcutRouteProvider), '/chores/new');

      container.read(pendingShortcutRouteProvider.notifier).clear();
      expect(container.read(pendingShortcutRouteProvider), isNull);
    });

    test('setting the same route twice still notifies listeners', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var notifyCount = 0;
      container.listen<String?>(
        pendingShortcutRouteProvider,
        (previous, next) {
          if (next != null) notifyCount++;
        },
      );

      container.read(pendingShortcutRouteProvider.notifier).set('/chores');
      container.read(pendingShortcutRouteProvider.notifier).clear();
      container.read(pendingShortcutRouteProvider.notifier).set('/chores');

      expect(notifyCount, 2);
    });
  });

  group('Shortcut launch routing (app.dart wiring)', () {
    testWidgets(
      'a "New Mission" launch action navigates straight to the new-chore form',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts(launchAction: 'new_mission');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: const ChoreBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Mission'), findsOneWidget); // form AppBar title
        expect(find.text('Save Mission'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );

    testWidgets(
      'an "Overdue" launch action leaves the app on the chores list',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts(launchAction: 'overdue');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: const ChoreBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('The Signal is Silent'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );

    testWidgets(
      'an "Overdue" launch action forces urgency-ascending sort and clears search',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts(launchAction: 'overdue');
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return const ChoreBuddyApp();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final sortState = container.read(sortStateProvider);
        expect(sortState.order, ChoreSortOrder.urgency);
        expect(sortState.direction, SortDirection.ascending);
        expect(container.read(choreSearchQueryProvider), isEmpty);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );

    testWidgets(
      'popping the New-Mission form (shortcut launch) lands on the chores '
      'list, not an exited app',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts(launchAction: 'new_mission');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: const ChoreBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Mission'), findsOneWidget); // form AppBar title

        await tester.pageBack();
        await tester.pumpAndSettle();

        // Back landed on the chores list (FAB visible), not an exited app.
        expect(find.text('New Mission'), findsNothing);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );

    testWidgets(
      'an unrecognized launch action id is ignored',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts(launchAction: 'not_a_real_action');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: const ChoreBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('The Signal is Silent'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );

    testWidgets(
      'registers the New Mission and Overdue shortcut items on startup',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final fakeShortcuts = FakeAppShortcuts();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              appShortcutsProvider.overrideWithValue(fakeShortcuts),
            ],
            child: const ChoreBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          fakeShortcuts.registeredItems.map((i) => i.type),
          containsAll(['new_mission', 'overdue']),
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
      },
    );
  });
}
