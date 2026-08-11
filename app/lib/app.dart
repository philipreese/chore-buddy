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
import 'core/notifications/notifications_enabled_provider.dart';
import 'core/router/app_router.dart';
import 'core/shortcuts/app_shortcut_action.dart';
import 'core/shortcuts/app_shortcuts.dart';
import 'core/shortcuts/pending_shortcut_route_provider.dart';
import 'core/strings/app_strings.dart';
import 'core/strings/flavor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/voice/voice_command_channel.dart';
import 'core/voice/voice_command_service.dart';
import 'features/chores/domain/chore_filter_sort.dart';
import 'features/chores/providers/chore_providers.dart';

class ChoreBuddyApp extends ConsumerStatefulWidget {
  const ChoreBuddyApp({super.key});

  @override
  ConsumerState<ChoreBuddyApp> createState() => _ChoreBuddyAppState();
}

// Notification id for the "voice command acted on while backgrounded"
// confirmation -- namespaced well above chore autoincrement ids (which stay
// small) so it can never collide with a chore's due-date reminder id.
const _kVoiceFeedbackNotificationId = 2100000000;

class _ChoreBuddyAppState extends ConsumerState<ChoreBuddyApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClickSubscription;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initShortcuts());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeWidget());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVoiceCommands());
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
    // stale until the process restarts. Poking every table's update
    // notification makes each watch stream re-run its query over the SAME
    // connection, which reads the current file state (WAL) and picks up the
    // external write.
    //
    // Deliberately NOT ref.invalidate(appDatabaseProvider): closing and
    // reopening the connection here races anything mid-query on the old
    // instance -- every intent delivery (voice command, shortcut, widget
    // tap) re-fires `resumed`, so an invalidate reliably killed the very
    // command the intent carried ("Channel was closed before receiving a
    // response"). Only the backup-import hot-swap needs a real reopen, and
    // it owns that explicitly.
    //
    // The widget itself isn't watching a drift stream -- it only reflects
    // whatever was last pushed to its shared storage -- so pause and resume
    // both re-sync it here: pause covers a foreground edit that raced the
    // app being backgrounded before its own post-mutation sync call
    // finished, and resume covers a background completion (widget or
    // notification) that landed while this instance was suspended.
    if (state == AppLifecycleState.resumed) {
      final db = ref.read(appDatabaseProvider);
      db.markTablesUpdated(db.allTables);
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
    if (action == null || !mounted) return;

    if (action == AppShortcutAction.overdue) {
      // "Overdue" should actually surface the overdue chores, not just open
      // the list as it stood: force urgency-ascending (most urgent on top)
      // and drop any active search so nothing hides them.
      ref
          .read(sortStateProvider.notifier)
          .setOrder(ChoreSortOrder.urgency, SortDirection.ascending);
      ref.read(choreSearchQueryProvider.notifier).setQuery('');
    }

    ref.read(pendingShortcutRouteProvider.notifier).set(action.route);
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
            // Same stack guarantee as the pending-shortcut listener: go to
            // /chores first so back from the form always lands there
            // instead of exiting the app.
            final router = ref.read(routerProvider);
            router.go('/chores');
            router.push('/chores/new');
          }
        });
    }
  }

  // Registers the live-command callback (MainActivity.onNewIntent, while
  // the app is already running) and picks up any command that cold-launched
  // the app, mirroring _initNotifications' getLaunchPayload() pull for the
  // same "push while running, pull once at startup" split.
  Future<void> _initVoiceCommands() async {
    final channel = ref.read(voiceCommandChannelProvider);
    await channel.initialize(onCommand: _handleVoiceCommand);
    final launchCommand = await channel.getLaunchCommand();
    if (launchCommand != null) {
      _handleVoiceCommand(launchCommand);
    }
  }

  void _handleVoiceCommand(Map<String, dynamic> command) {
    unawaited(_runVoiceCommand(command));
  }

  Future<void> _runVoiceCommand(Map<String, dynamic> command) async {
    final result = await executeVoiceCommand(
      db: ref.read(appDatabaseProvider),
      scheduler: ref.read(notificationSchedulerProvider),
      widgetSyncService: ref.read(widgetSyncServiceProvider),
      notificationsEnabled: ref.read(notificationsEnabledProvider),
      strings: ref.read(appStringsProvider),
      command: command,
    );
    if (!mounted) return;
    await _presentVoiceCommandFeedback(result);
  }

  // A voice command is never silent: a snackbar while the app is in the
  // foreground -- the common case, since firing either intent brings
  // MainActivity to the top -- or a local notification otherwise, e.g. a
  // Tasker-fired intent handled before the first frame has a
  // ScaffoldMessenger mounted.
  Future<void> _presentVoiceCommandFeedback(VoiceCommandResult result) async {
    final strings = ref.read(appStringsProvider);
    final message = _voiceResultMessage(strings, result);

    final messenger = _scaffoldMessengerKey.currentState;
    final resumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (resumed && messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    await ref.read(notificationSchedulerProvider).showNow(
          id: _kVoiceFeedbackNotificationId,
          title: strings.appTitle,
          body: message,
        );
  }

  String _voiceResultMessage(AppStrings strings, VoiceCommandResult result) {
    return switch (result) {
      VoiceCommandAdded(:final name) => strings.voiceChoreAddedMessage(name),
      VoiceCommandCompleted(:final name) =>
        strings.voiceChoreCompletedMessage(name),
      VoiceCommandFailed(:final reason, :final name) => switch (reason) {
          VoiceCommandFailureReason.duplicateName =>
            strings.voiceChoreDuplicateMessage(name ?? ''),
          VoiceCommandFailureReason.notFound =>
            strings.voiceChoreNotFoundMessage(name ?? ''),
          VoiceCommandFailureReason.ambiguous =>
            strings.voiceChoreAmbiguousMessage(name ?? ''),
          VoiceCommandFailureReason.invalidCommand =>
            strings.voiceCommandInvalidMessage,
        },
    };
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
        // Land on the chores list first so every shortcut/tile entry path
        // pushes on top of a non-empty stack -- a bare go(next) would
        // replace the whole stack with just next, so cold-launching into
        // e.g. /chores/new left back with nowhere to go but out of the app.
        router.go('/chores');
        if (next != '/chores') {
          router.push(next);
        }
        ref.read(pendingShortcutRouteProvider.notifier).clear();
      }
    });

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: strings.appTitle,
          scaffoldMessengerKey: _scaffoldMessengerKey,
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
