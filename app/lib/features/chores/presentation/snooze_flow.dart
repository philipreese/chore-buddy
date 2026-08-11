import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/chore_with_details.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/home_widget/widget_sync_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/strings/flavor_provider.dart';
import '../providers/chore_providers.dart';
import '../providers/snooze_providers.dart';

/// "Not Today": defers [chore]'s due date to tomorrow with no dialog and no
/// undo (see SnoozeService) -- cheap enough that re-editing the chore is a
/// sufficient escape hatch. Mirrors completeChoreFlow's re-read-then-
/// reschedule-then-sync tail without the completion record or undo
/// snackbar.
Future<void> snoozeChoreFlow({
  required BuildContext context,
  required WidgetRef ref,
  required ChoreWithDetails chore,
}) async {
  final strings = ref.read(appStringsProvider);
  final snoozeService = ref.read(snoozeServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  final widgetSyncService = ref.read(widgetSyncServiceProvider);
  final db = ref.read(appDatabaseProvider);
  final now = ref.read(nowProvider);

  final snoozed = await snoozeService.snoozeChore(
    choreId: chore.chore.id,
    now: now,
  );
  if (!snoozed) return;

  // Re-read rather than patch the captured snapshot, same as every other
  // reschedule call site (see completion_flow.dart).
  final updated = await db.getChoreById(chore.chore.id);
  if (updated != null) {
    await notificationService.scheduleForChore(updated);
    await widgetSyncService.sync();
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(strings.choreSnoozed)));
}
