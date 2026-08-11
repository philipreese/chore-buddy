import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/chore_with_details.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/home_widget/widget_sync_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/strings/flavor_provider.dart';
import '../providers/chore_providers.dart';
import '../providers/completion_providers.dart';
import 'widgets/completion_dialog.dart';

/// How long the undo snackbar stays up and its undo token stays valid.
///
/// `SnackBar.persist` defaults to `action != null` (see
/// `packages/flutter/lib/src/material/snack_bar.dart`), so a snackbar with
/// an action -- ours has UNDO -- makes `ScaffoldMessengerState`'s own
/// auto-dismiss timer bail out unconditionally
/// (`if (snackBar.persist) return;` in `scaffold.dart`, unrelated to
/// `MediaQuery.accessibleNavigation`). The framework will never close such
/// a snackbar on its own, so ours passes `persist: false` explicitly: the
/// undo window must expire with the snackbar, and it is already bounded by
/// this constant.
const _undoWindow = Duration(seconds: 5);

/// Shared complete-chore flow used by chore cards: shows the completion
/// dialog, commits the completion, fires haptics, and surfaces the undo
/// snackbar. A completion that lands while a prior one's undo window is
/// still open commits the prior one instead of stacking (see
/// PendingCompletionNotifier).
Future<void> completeChoreFlow({
  required BuildContext context,
  required WidgetRef ref,
  required ChoreWithDetails chore,
}) async {
  // Everything the flow needs is captured before the first await: the
  // snackbar action and .closed callbacks run up to 5s later, when the
  // originating card (and its WidgetRef) may already be unmounted.
  final strings = ref.read(appStringsProvider);
  final completionService = ref.read(completionServiceProvider);
  final pendingNotifier = ref.read(pendingCompletionProvider.notifier);
  final hapticsEnabled = ref.read(hapticsEnabledProvider);
  final hapticsService = ref.read(hapticsServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  final widgetSyncService = ref.read(widgetSyncServiceProvider);
  final db = ref.read(appDatabaseProvider);

  final result = await showCompletionDialog(
    context: context,
    strings: strings,
    initialDateTime: ref.read(nowProvider),
  );

  // Unconditionally drop focus once the dialog route is gone, regardless of
  // outcome: popping it can otherwise hand focus back to whatever
  // text-capable node the FocusScope restores it to (e.g. the chores list's
  // search bar), reopening the soft keyboard even though nothing on screen
  // is meant to have focus right now.
  if (context.mounted) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  if (result == null) return;
  if (!context.mounted) return;

  // Any pending completion is already committed in the database; dropping
  // its token here just closes its undo window.
  pendingNotifier.clear();

  final token = await completionService.completeChore(
    chore: chore.chore,
    completedAt: result.completedAt,
    note: result.note,
  );
  pendingNotifier.set(token);

  // Re-read rather than patch the captured snapshot: it may already be
  // stale by the time this runs, and every other reschedule call site
  // (save, undo below) schedules from a fresh row for the same reason.
  final completedChore = await db.getChoreById(token.choreId);
  if (completedChore != null) {
    await notificationService.scheduleForChore(completedChore);
    await widgetSyncService.sync();
  }

  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(strings.choreCompleted),
      duration: _undoWindow,
      // See _undoWindow: without this, an action-bearing snackbar defaults
      // to persist: true and never times out.
      persist: false,
      action: SnackBarAction(
        label: strings.undoAction,
        onPressed: () async {
          if (pendingNotifier.current == token) {
            pendingNotifier.clear();
            await completionService.undoCompletion(token);
            // The undo window is long enough (5s) for the chore to have
            // been edited in the meantime, so schedule from a fresh
            // read rather than the snapshot captured when the card
            // that started this flow last built.
            final revertedChore = await db.getChoreById(token.choreId);
            if (revertedChore != null) {
              await notificationService.scheduleForChore(revertedChore);
              await widgetSyncService.sync();
            }
          }
        },
      ),
    ),
  );

  controller.closed.then((_) {
    if (pendingNotifier.current == token) {
      pendingNotifier.clear();
    }
  });

  // After the snackbar: a hung or throwing vibration must never cost the
  // user the undo affordance (the completion is already committed).
  if (hapticsEnabled) {
    unawaited(hapticsService.completionFeedback().catchError((_) {}));
  }
}
