import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/snooze_service.dart';

final snoozeServiceProvider = Provider<SnoozeService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SnoozeService(db);
});
