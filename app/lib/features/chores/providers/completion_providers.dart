import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/completion_service.dart';

final completionServiceProvider = Provider<CompletionService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CompletionService(db);
});

/// The most recently completed chore's undo token, while its 5s undo
/// window is open. A new completion replaces this before its own undo
/// window opens, which is what makes the prior completion commit instead
/// of stacking.
class PendingCompletionNotifier extends Notifier<UndoToken?> {
  @override
  UndoToken? build() => null;

  void set(UndoToken token) {
    state = token;
  }

  void clear() {
    state = null;
  }
}

final pendingCompletionProvider =
    NotifierProvider<PendingCompletionNotifier, UndoToken?>(
      PendingCompletionNotifier.new,
    );
