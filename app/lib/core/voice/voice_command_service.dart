import 'package:drift/drift.dart';

import '../../features/chores/domain/completion_service.dart';
import '../database/app_database.dart';
import '../database/exceptions.dart';
import '../database/tables.dart';
import '../home_widget/widget_sync_service.dart';
import '../notifications/notification_scheduler.dart';
import '../notifications/notification_service.dart';
import '../strings/app_strings.dart';

/// Why a voice command didn't take effect -- surfaced to the user via
/// [AppStrings]'s `voiceChore*Message` getters rather than a raw exception,
/// since the source is an intent (ADB/Tasker/AppFunctions), not a UI form
/// that can show a validation error inline.
enum VoiceCommandFailureReason { invalidCommand, duplicateName, notFound, ambiguous }

/// Outcome of [executeVoiceCommand], always producible without throwing so
/// the caller (`app.dart`) has one flavored confirmation to show regardless
/// of how the command ends.
sealed class VoiceCommandResult {
  const VoiceCommandResult();
}

class VoiceCommandAdded extends VoiceCommandResult {
  final String name;
  const VoiceCommandAdded(this.name);
}

class VoiceCommandCompleted extends VoiceCommandResult {
  final String name;
  const VoiceCommandCompleted(this.name);
}

class VoiceCommandFailed extends VoiceCommandResult {
  final VoiceCommandFailureReason reason;
  final String? name;
  const VoiceCommandFailed(this.reason, [this.name]);
}

/// Executes an add/complete voice command through the same domain services
/// the UI uses (chore insert respecting the UNIQUE name constraint,
/// [CompletionService] for completes, notification reschedule + widget sync
/// after both) -- fired from either the ADD_CHORE/COMPLETE_CHORE intents
/// (see `VoiceCommandIntents.kt`) or an AppFunctions call, both of which
/// dispatch the exact same intent, so this is the single path that ever
/// mutates a chore on behalf of a voice/Tasker command.
///
/// [command] is the map decoded off the MethodChannel/launch-command
/// payload: `{'command': 'add'|'complete', 'name': ..., 'recurrence': ...,
/// 'due': ...}`. Every field is read defensively -- a malformed or missing
/// value degrades to a [VoiceCommandFailed] rather than throwing, since the
/// source is outside the app's own UI validation.
Future<VoiceCommandResult> executeVoiceCommand({
  required AppDatabase db,
  required NotificationScheduler scheduler,
  required WidgetSyncService widgetSyncService,
  required bool notificationsEnabled,
  required AppStrings strings,
  required Map<String, dynamic> command,
  DateTime? now,
}) async {
  switch (command['command']) {
    case 'add':
      return _handleAdd(
        db: db,
        scheduler: scheduler,
        widgetSyncService: widgetSyncService,
        notificationsEnabled: notificationsEnabled,
        strings: strings,
        command: command,
      );
    case 'complete':
      return _handleComplete(
        db: db,
        scheduler: scheduler,
        widgetSyncService: widgetSyncService,
        notificationsEnabled: notificationsEnabled,
        strings: strings,
        command: command,
        completedAt: now ?? DateTime.now(),
      );
    default:
      return const VoiceCommandFailed(VoiceCommandFailureReason.invalidCommand);
  }
}

Future<VoiceCommandResult> _handleAdd({
  required AppDatabase db,
  required NotificationScheduler scheduler,
  required WidgetSyncService widgetSyncService,
  required bool notificationsEnabled,
  required AppStrings strings,
  required Map<String, dynamic> command,
}) async {
  final name = (command['name'] as String?)?.trim();
  if (name == null || name.isEmpty) {
    return const VoiceCommandFailed(VoiceCommandFailureReason.invalidCommand);
  }

  final recurrence = _parseRecurrence(command['recurrence'] as String?);
  final due = _parseDue(command['due'] as String?);

  final int choreId;
  try {
    choreId = await db.insertChore(
      ChoresCompanion.insert(
        name: name,
        recurrence: Value(recurrence),
        nextDueDate: Value(due),
      ),
    );
  } on DuplicateNameException {
    return VoiceCommandFailed(VoiceCommandFailureReason.duplicateName, name);
  }

  final chore = await db.getChoreById(choreId);
  if (chore != null) {
    await scheduleChoreNotification(
      scheduler: scheduler,
      chore: chore,
      notificationsEnabled: notificationsEnabled,
      strings: strings,
    );
  }
  await widgetSyncService.sync();

  return VoiceCommandAdded(name);
}

Future<VoiceCommandResult> _handleComplete({
  required AppDatabase db,
  required NotificationScheduler scheduler,
  required WidgetSyncService widgetSyncService,
  required bool notificationsEnabled,
  required AppStrings strings,
  required Map<String, dynamic> command,
  required DateTime completedAt,
}) async {
  final name = (command['name'] as String?)?.trim();
  if (name == null || name.isEmpty) {
    return const VoiceCommandFailed(VoiceCommandFailureReason.invalidCommand);
  }

  final active = await db.getActiveChores();
  final resolved = _resolveActiveChore(active, name);
  if (resolved.ambiguous) {
    return VoiceCommandFailed(VoiceCommandFailureReason.ambiguous, name);
  }
  final chore = resolved.chore;
  if (chore == null) {
    return VoiceCommandFailed(VoiceCommandFailureReason.notFound, name);
  }

  await CompletionService(db).completeChore(chore: chore, completedAt: completedAt);

  // Re-read rather than patch the chore captured above -- completeChore()
  // only advances nextDueDate, and every other reschedule call site in the
  // app schedules from a fresh row for the same reason (see
  // background_completion.dart).
  final updated = await db.getChoreById(chore.id);
  if (updated != null) {
    await scheduleChoreNotification(
      scheduler: scheduler,
      chore: updated,
      notificationsEnabled: notificationsEnabled,
      strings: strings,
    );
  }
  await widgetSyncService.sync();

  return VoiceCommandCompleted(chore.name);
}

/// Case-insensitive exact match first, then unique-prefix match, against
/// [active] -- mirrors how a spoken or Tasker-supplied name is never
/// guaranteed to be the chore's exact stored name. Doing nothing
/// destructive on "no match" or "more than one match" is the point: acting
/// on the wrong chore is worse than a no-op the user has to retry.
({ChoreEntity? chore, bool ambiguous}) _resolveActiveChore(
  List<ChoreEntity> active,
  String name,
) {
  final lower = name.toLowerCase();

  // The UNIQUE name constraint is COLLATE NOCASE, so at most one active
  // chore can ever match here -- .toList() only to keep this and the
  // prefix branch symmetric.
  final exact = active.where((c) => c.name.toLowerCase() == lower).toList();
  if (exact.length == 1) return (chore: exact.single, ambiguous: false);

  final prefixMatches = active.where((c) => c.name.toLowerCase().startsWith(lower)).toList();
  if (prefixMatches.length == 1) {
    return (chore: prefixMatches.single, ambiguous: false);
  }
  if (prefixMatches.length > 1) return (chore: null, ambiguous: true);

  return (chore: null, ambiguous: false);
}

RecurrenceType _parseRecurrence(String? raw) {
  if (raw == null) return RecurrenceType.none;
  for (final value in RecurrenceType.values) {
    if (value.name == raw) return value;
  }
  return RecurrenceType.none;
}

DateTime? _parseDue(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
