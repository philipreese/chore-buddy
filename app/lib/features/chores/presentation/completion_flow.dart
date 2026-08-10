import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/chore_with_details.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/strings/flavor_provider.dart';
import '../providers/chore_providers.dart';
import '../providers/completion_providers.dart';
import 'widgets/completion_dialog.dart';

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

  final result = await showCompletionDialog(
    context: context,
    strings: strings,
    initialDateTime: ref.read(nowProvider),
  );
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

  // TODO(slice-08): reschedule this chore's notification for the new due date.

  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger
      .showSnackBar(
        SnackBar(
          content: Text(strings.choreCompleted),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: strings.undoAction,
            onPressed: () async {
              if (pendingNotifier.current == token) {
                pendingNotifier.clear();
                await completionService.undoCompletion(token);
              }
            },
          ),
        ),
      )
      .closed
      .then((_) {
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
