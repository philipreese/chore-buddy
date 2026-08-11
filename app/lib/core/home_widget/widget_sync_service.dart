import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/chores/domain/chore_filter_sort.dart';
import '../../features/chores/domain/date_formatter.dart';
import '../../features/chores/domain/due_status.dart';
import '../../features/chores/domain/icon_guesser.dart';
import '../database/app_database.dart';
import '../database/chore_with_details.dart';
import '../database/database_provider.dart';
import '../strings/app_strings.dart';
import '../strings/flavor_provider.dart';

/// Key the widget's chore list is stored under via `home_widget`'s shared
/// storage; must match the key `ChoreWidgetRemoteViewsFactory` reads on the
/// Android side.
const kWidgetChoresDataKey = 'widget_chores_json';

/// Fully-qualified Android class name of the AppWidgetProvider, passed to
/// `HomeWidget.updateWidget` so it can resolve the provider to redraw.
const kChoreWidgetAndroidName =
    'com.philipreese.chorebuddy.widget.ChoreWidgetProvider';

/// The widget shows at most this many chores -- enough to be useful on a
/// typical widget size without scrolling forever.
const kWidgetMaxEntries = 6;

/// One row of the home-screen widget's chore list -- just what the native
/// RemoteViews row needs to render, no tags.
class WidgetChoreEntry {
  final int id;
  final String name;
  final String dueLabel;
  final bool overdue;

  const WidgetChoreEntry({
    required this.id,
    required this.name,
    required this.dueLabel,
    required this.overdue,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'dueLabel': dueLabel,
    'overdue': overdue,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetChoreEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          dueLabel == other.dueLabel &&
          overdue == other.overdue;

  @override
  int get hashCode => Object.hash(id, name, dueLabel, overdue);
}

/// Picks the chores the widget shows -- every active chore WITH a due date,
/// most urgent first, capped to [kWidgetMaxEntries]. Deliberately no
/// "due soon" window: a personal list rarely has anything due within 24h,
/// and an empty widget most of the time is useless (first on-device
/// feedback). The empty state now genuinely means "nothing scheduled".
/// Reuses [sortChores] (the same ordering and name tie-break the in-app
/// list uses) rather than re-deriving it, wrapping each [ChoreEntity] in an
/// empty-tags [ChoreWithDetails] since the widget has no use for tags.
List<WidgetChoreEntry> selectWidgetChores(
  List<ChoreEntity> activeChores, {
  required AppStrings strings,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();

  final relevant =
      activeChores.where((chore) => chore.nextDueDate != null).toList();

  final asDetails = relevant
      .map((chore) => ChoreWithDetails(chore: chore, tags: const []))
      .toList();

  final sorted = sortChores(
    chores: asDetails,
    sortOrder: ChoreSortOrder.urgency,
    direction: SortDirection.ascending,
  );

  return sorted.take(kWidgetMaxEntries).map((item) {
    final chore = item.chore;
    final overdue =
        getDueStatus(chore.nextDueDate, effectiveNow) == DueStatus.overdue;
    final formattedDate = formatChoreDate(chore.nextDueDate);
    // Same resolution chain as the card's icon chip (chore.emoji ?? a
    // name-based guess), prepended to the title text since the widget's
    // RemoteViews row has no separate glyph slot to wire up.
    final emoji = chore.emoji ?? guessChoreEmoji(chore.name);
    final title = (emoji != null && emoji.isNotEmpty)
        ? '$emoji ${chore.name}'
        : chore.name;
    return WidgetChoreEntry(
      id: chore.id,
      name: title,
      dueLabel: overdue
          ? strings.overdueLabel(formattedDate)
          : strings.dueLabel(formattedDate),
      overdue: overdue,
    );
  }).toList();
}

/// Low-level wrapper over the `home_widget` plugin's platform-channel calls,
/// kept separate so tests can substitute a fake and never touch a platform
/// channel (mirrors [NotificationScheduler]'s split from its caller).
abstract class WidgetDataWriter {
  Future<void> saveChores(String json);
  Future<void> updateWidget();
}

class HomeWidgetDataWriter implements WidgetDataWriter {
  @override
  Future<void> saveChores(String json) async {
    try {
      await HomeWidget.saveWidgetData<String>(kWidgetChoresDataKey, json);
    } catch (e, st) {
      debugPrint('HomeWidgetDataWriter.saveChores failed: $e\n$st');
    }
  }

  @override
  Future<void> updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: kChoreWidgetAndroidName,
      );
    } catch (e, st) {
      debugPrint('HomeWidgetDataWriter.updateWidget failed: $e\n$st');
    }
  }
}

/// Serializes the current top chores to the widget's shared storage and
/// asks the OS to redraw every placed instance. Called from every call
/// site that already reschedules notifications after a db mutation (see
/// chore_detail_screen, completion_flow, chore_card, archived_chore_card,
/// backup_service) -- those sites share no single post-mutation hook beyond
/// the database itself, so this rides alongside the existing notification
/// calls rather than introducing a new one.
///
/// Free of platform channels beyond [writer]: [db] and [strings] are the
/// only other dependencies, so this is unit-testable with an in-memory
/// database and a fake writer, and constructible from the background
/// isolate the same way [completeChoreFromNotification] is.
class WidgetSyncService {
  final AppDatabase db;
  final AppStrings strings;
  final WidgetDataWriter writer;

  WidgetSyncService(this.db, {required this.strings, WidgetDataWriter? writer})
    : writer = writer ?? HomeWidgetDataWriter();

  Future<void> sync({DateTime? now}) async {
    final activeChores = await db.getActiveChores();
    final entries = selectWidgetChores(
      activeChores,
      strings: strings,
      now: now,
    );
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await writer.saveChores(json);
    await writer.updateWidget();
  }
}

/// Seam for tests: everything reaches the `home_widget` platform channel
/// through this provider, so a single [WidgetDataWriter] override keeps
/// widget tests off the real channel (whose calls never complete in the
/// test environment), mirroring how notificationServiceProvider is faked.
final widgetDataWriterProvider = Provider<WidgetDataWriter>(
  (ref) => HomeWidgetDataWriter(),
);

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final strings = ref.watch(appStringsProvider);
  final writer = ref.watch(widgetDataWriterProvider);
  return WidgetSyncService(db, strings: strings, writer: writer);
});
