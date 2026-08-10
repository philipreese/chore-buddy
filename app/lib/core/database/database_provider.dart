import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'chore_with_details.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    // Fire-and-forget: onDispose is synchronous, so this can't be awaited.
    // The backup import flow closes the connection explicitly (and awaits
    // it) before touching the database file, so by the time this runs on
    // `ref.invalidate` the connection is normally already closed -- guard
    // against that redundant close throwing and going unhandled.
    unawaited(
      database.close().catchError((Object e, StackTrace st) {
        debugPrint('appDatabaseProvider dispose: close failed: $e\n$st');
      }),
    );
  });
  return database;
});

final activeChoresWithDetailsProvider =
    StreamProvider<List<ChoreWithDetails>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveChoresWithDetails();
});

final archivedChoresProvider = StreamProvider<List<ChoreWithDetails>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchArchivedChoresWithDetails();
});

final tagsProvider = StreamProvider<List<TagEntity>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTags();
});

final historyForChoreProvider =
    StreamProvider.family<List<CompletionRecordEntity>, int>((ref, choreId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchHistoryForChore(choreId);
});
