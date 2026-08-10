import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/flavor_provider.dart';

class ChoreDetailScreen extends ConsumerWidget {
  final String choreId;

  const ChoreDetailScreen({
    super.key,
    required this.choreId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isNew = choreId == 'new' || choreId == '0';
    final title = isNew ? strings.newChoreTitle : strings.editChoreTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Placeholder (ID: $choreId)',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
