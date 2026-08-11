import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/presentation/archive_screen.dart';
import '../../features/chores/presentation/chore_detail_screen.dart';
import '../../features/chores/presentation/chores_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/tags/presentation/tag_manager_screen.dart';

import '../../features/chores/providers/chore_providers.dart';
import '../strings/flavor_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/chores',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chores',
                builder: (context, state) => const ChoresScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/archive',
                builder: (context, state) => const ArchiveScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/tags',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TagManagerScreen(),
      ),
      GoRoute(
        path: '/chores/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChoreDetailScreen(
          choreId: 'new',
          duplicatePrefill: state.extra as ChoreDuplicatePrefill?,
        ),
      ),
      GoRoute(
        path: '/chores/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          if (id != 'new' && int.tryParse(id) == null) {
            return Consumer(
              builder: (context, ref, _) {
                final strings = ref.watch(appStringsProvider);
                return Scaffold(
                  appBar: AppBar(title: Text(strings.notFoundTitle)),
                  body: Center(child: Text(strings.choreNotFoundMessage)),
                );
              },
            );
          }
          return ChoreDetailScreen(choreId: id);
        },
      ),
    ],
  );

  void updateVisibility() {
    final matches = router.routerDelegate.currentConfiguration.matches;
    if (matches.isNotEmpty) {
      final lastLocation = matches.last.matchedLocation;
      final isChoresTab = lastLocation == '/chores';
      Future.microtask(() {
        ref.read(choresTabVisibleProvider.notifier).setVisible(isChoresTab);
      });
    }
  }

  router.routerDelegate.addListener(updateVisibility);
  ref.onDispose(() {
    router.routerDelegate.removeListener(updateVisibility);
  });

  return router;
});


