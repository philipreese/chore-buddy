import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Every completion record across every chore, for the household-wide
/// aggregates the banner line and Mission Log page (spec 22) render.
final allCompletionsProvider = StreamProvider<List<CompletionRecordEntity>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllCompletionRecords();
});

/// Every chore, active or archived, for the Mission Log's cross-chore
/// best-streak lookup (spec 22).
final allChoresForStatsProvider = StreamProvider<List<ChoreEntity>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllChores();
});
