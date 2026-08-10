import 'app_database.dart';

class ChoreWithDetails {
  final ChoreEntity chore;
  final List<TagEntity> tags;
  final DateTime? lastCompleted;
  final String? lastNote;

  const ChoreWithDetails({
    required this.chore,
    required this.tags,
    this.lastCompleted,
    this.lastNote,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoreWithDetails &&
          runtimeType == other.runtimeType &&
          chore == other.chore &&
          _listEquals(tags, other.tags) &&
          lastCompleted == other.lastCompleted &&
          lastNote == other.lastNote;

  @override
  int get hashCode => Object.hash(
        chore,
        Object.hashAll(tags),
        lastCompleted,
        lastNote,
      );
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
