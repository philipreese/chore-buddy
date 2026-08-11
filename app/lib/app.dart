import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/database/database_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_tap_provider.dart';
import 'core/router/app_router.dart';
import 'core/shortcuts/app_shortcut_action.dart';
import 'core/shortcuts/app_shortcuts.dart';
import 'core/shortcuts/pending_shortcut_route_provider.dart';
import 'core/strings/flavor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class ChoreBuddyApp extends ConsumerStatefulWidget {
  const ChoreBuddyApp({super.key});

  @override
  ConsumerState<ChoreBuddyApp> createState() => _ChoreBuddyAppState();
}

class _ChoreBuddyAppState extends ConsumerState<ChoreBuddyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initShortcuts());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The "Complete" notification action can write to the database from a
    // separate isolate/connection while this app is merely backgrounded
    // (not killed) -- drift's watch() streams only notice writes made
    // through the same connection, so they'd otherwise stay stale until the
    // process restarts. Invalidating reconnects every stream against the
    // current file, the same pattern the backup-import hot-swap uses.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appDatabaseProvider);
    }
  }

  Future<void> _initNotifications() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final strings = ref.read(appStringsProvider);

    await scheduler.initialize(
      onNotificationTapped: _handleTapPayload,
      channelName: strings.notificationChannelName,
      channelDescription: strings.notificationChannelDescription,
    );

    final launchPayload = await scheduler.getLaunchPayload();
    _handleTapPayload(launchPayload);
  }

  void _handleTapPayload(String? payload) {
    final choreId = payload == null ? null : int.tryParse(payload);
    if (choreId != null && mounted) {
      ref.read(notificationTapChoreIdProvider.notifier).set(choreId);
    }
  }

  Future<void> _initShortcuts() async {
    final shortcuts = ref.read(appShortcutsProvider);
    final strings = ref.read(appStringsProvider);

    await shortcuts.initialize(onAction: _handleShortcutAction);
    await shortcuts.setShortcutItems([
      ShortcutItem(
        type: AppShortcutAction.newMission.id,
        localizedTitle: strings.shortcutNewMissionLabel,
        icon: 'ic_notification',
      ),
      ShortcutItem(
        type: AppShortcutAction.overdue.id,
        localizedTitle: strings.shortcutOverdueLabel,
        icon: 'ic_notification',
      ),
    ]);
  }

  void _handleShortcutAction(String actionId) {
    final action = AppShortcutAction.fromId(actionId);
    if (action != null && mounted) {
      ref.read(pendingShortcutRouteProvider.notifier).set(action.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final strings = ref.watch(appStringsProvider);

    ref.listen<int?>(notificationTapChoreIdProvider, (previous, next) {
      if (next != null) {
        router.go('/chores');
      }
    });

    ref.listen<String?>(pendingShortcutRouteProvider, (previous, next) {
      if (next != null) {
        router.go(next);
        ref.read(pendingShortcutRouteProvider.notifier).clear();
      }
    });

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.buildDarkTheme(dynamicScheme: darkDynamic),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
