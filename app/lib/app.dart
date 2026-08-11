import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/database/database_provider.dart';
import 'core/home_widget/widget_interactivity.dart';
import 'core/home_widget/widget_sync_service.dart';
import 'core/notifications/background_completion.dart';
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
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initShortcuts());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeWidget());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_widgetClickSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The "Complete" notification/widget action can write to the database
    // from a separate isolate/connection while this app is merely
    // backgrounded (not killed) -- drift's watch() streams only notice
    // writes made through the same connection, so they'd otherwise stay
    // stale until the process restarts. Invalidating reconnects every
    // stream against the current file, the same pattern the backup-import
    // hot-swap uses.
    //
    // The widget itself isn't watching a drift stream -- it only reflects
    // whatever was last pushed to its shared storage -- so pause and resume
    // both re-sync it here: pause covers a foreground edit that raced the
    // app being backgrounded before its own post-mutation sync call
    // finished, and resume covers a background completion (widget or
    // notification) that landed while this instance was suspended.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appDatabaseProvider);
      unawaited(ref.read(widgetSyncServiceProvider).sync());
    } else if (state == AppLifecycleState.paused) {
      unawaited(ref.read(widgetSyncServiceProvider).sync());
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

  // Registers the checkbox-tap background callback and picks up any tap
  // that launched or resumed the app from the widget, mirroring how
  // _initNotifications wires the equivalent notification-tap path. Also
  // performs one sync so a freshly-pinned widget shows current data rather
  // than waiting for the next db mutation.
  Future<void> _initHomeWidget() async {
    final interactivity = ref.read(widgetInteractivityProvider);
    await interactivity.registerInteractivityCallback(
      widgetInteractivityHandler,
    );
    _widgetClickSubscription = interactivity.widgetClicked.listen(
      _handleWidgetUri,
    );
    final launchUri = await interactivity.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(launchUri);
    unawaited(ref.read(widgetSyncServiceProvider).sync());
  }

  // [uri] is `chorebuddy://open/<choreId>`, `chorebuddy://open`, or
  // `chorebuddy://new`, set by ChoreWidgetProvider/ChoreWidgetActionReceiver
  // on the Android side. The chore-scroll case is routed through the same
  // notificationTapChoreIdProvider the notification-tap flow uses, so the
  // chores list only needs one "scroll to this chore" listener.
  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    switch (uri.host) {
      case 'open':
        final choreId = uri.pathSegments.isNotEmpty
            ? int.tryParse(uri.pathSegments.first)
            : null;
        if (choreId != null) {
          // Also lands on /chores: see the notificationTapChoreIdProvider
          // listener in build() below.
          ref.read(notificationTapChoreIdProvider.notifier).set(choreId);
        } else {
          ref.read(routerProvider).go('/chores');
        }
      case 'new':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(routerProvider).push('/chores/new');
          }
        });
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
