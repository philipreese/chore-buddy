import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/voice_provider.dart';
import 'widgets/archived_chore_card.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final archivedAsync = ref.watch(archivedChoresProvider);

    return Scaffold(
      body: archivedAsync.when(
        data: (chores) {
          if (chores.isEmpty) {
            return _EmptyArchive(strings: strings);
          }
          return ListView.builder(
            itemCount: chores.length,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemBuilder: (context, index) {
              final item = chores[index];
              return ArchivedChoreCard(
                key: ValueKey(item.chore.id),
                chore: item,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(strings.genericError(err))),
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  final AppStrings strings;

  const _EmptyArchive({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyArchiveTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings.emptyArchiveDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
