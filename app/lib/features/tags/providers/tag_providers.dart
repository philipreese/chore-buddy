import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../domain/tag_service.dart';

final tagServiceProvider = Provider<TagService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TagService(db);
});
