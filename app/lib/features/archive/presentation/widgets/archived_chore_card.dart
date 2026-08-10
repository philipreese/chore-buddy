import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/chore_with_details.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/strings/flavor_provider.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../../chores/domain/date_formatter.dart';

class ArchivedChoreCard extends ConsumerWidget {
  final ChoreWithDetails chore;

  const ArchivedChoreCard({super.key, required this.chore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant;

    return Dismissible(
      key: ValueKey('archived_chore_${chore.chore.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: colorScheme.tertiaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.unarchive, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Text(
              strings.restoreChore,
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        final db = ref.read(appDatabaseProvider);
        await db.restoreChore(chore.chore.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: mutedColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chore.chore.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (chore.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chore.tags.map((tag) {
                    final tagColor = TagPalette.getColor(tag.colorIndex);
                    return Chip(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: tagColor.withAlpha(20),
                      side: BorderSide(color: tagColor.withAlpha(80)),
                      avatar: CircleAvatar(
                        backgroundColor: tagColor.withAlpha(160),
                        radius: 5,
                      ),
                      label: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: mutedColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (chore.lastCompleted != null) ...[
                const SizedBox(height: 8),
                Text(
                  strings.lastCompletedLabel(
                    formatChoreDate(chore.lastCompleted),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
