import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings/flavor_provider.dart';

class ChoresEmptyState extends ConsumerWidget {
  final bool isTotalEmpty;

  const ChoresEmptyState({
    super.key,
    required this.isTotalEmpty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    final title =
        isTotalEmpty ? strings.emptyActiveTitle : strings.emptyFilterTitle;
    final description = isTotalEmpty
        ? strings.emptyActiveDescription
        : strings.emptyFilterDescription;
    final icon = isTotalEmpty ? Icons.task_alt : Icons.filter_alt_off;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
