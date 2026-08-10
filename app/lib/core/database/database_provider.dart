import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'chore_with_details.dart';

bool _isTestEnvironment() {
  if (Zone.current[#test.description] != null ||
      Zone.current[Symbol('test.description')] != null) {
    return true;
  }
  try {
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().toLowerCase().contains('test');
  } catch (_) {
    return true;
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    _isTestEnvironment() ? NativeDatabase.memory() : null,
  );
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final activeChoresWithDetailsProvider =
    StreamProvider<List<ChoreWithDetails>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveChoresWithDetails();
});

final archivedChoresProvider = StreamProvider<List<ChoreEntity>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchArchivedChores();
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
