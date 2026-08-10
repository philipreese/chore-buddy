import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/chore_with_details.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/strings/superhero_strings.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../domain/date_formatter.dart';
import '../../domain/due_status.dart';
import '../../providers/chore_providers.dart';

class ChoreCard extends ConsumerWidget {
  final ChoreWithDetails chore;
  final VoidCallback? onTap;

  const ChoreCard({
    super.key,
    required this.chore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final showDetails = ref.watch(showDetailsOnCardsProvider);
    final dueStatus = getDueStatus(chore.chore.nextDueDate, now);
    final dueColor = getDueColor(chore.chore.nextDueDate, now, Theme.of(context).colorScheme);
    const strings = SuperheroStrings();

    return Dismissible(
      key: ValueKey('chore_${chore.chore.id}'),
      background: Container(
        color: Colors.amber.shade700,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.archive, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Archive',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return true;
        }
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.scrapTitle),
            content: Text(strings.scrapMessage(chore.chore.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.scrapConfirm),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (direction) async {
        final db = ref.read(appDatabaseProvider);
        if (direction == DismissDirection.startToEnd) {
          await db.archiveChore(chore.chore.id);
        } else if (direction == DismissDirection.endToStart) {
          await db.deleteChore(chore.chore.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: dueColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chore.chore.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                        backgroundColor: tagColor.withAlpha(40),
                        side: BorderSide(color: tagColor.withAlpha(120)),
                        avatar: CircleAvatar(
                          backgroundColor: tagColor,
                          radius: 5,
                        ),
                        label: Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (showDetails &&
                    (chore.lastCompleted != null || chore.lastNote != null)) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chore.lastCompleted != null)
                          Text(
                            'Last completed: ${formatChoreDate(chore.lastCompleted)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        if (chore.lastNote != null &&
                            chore.lastNote!.isNotEmpty) ...[
                          if (chore.lastCompleted != null)
                            const SizedBox(height: 4),
                          Text(
                            'Note: "${chore.lastNote}"',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Due: ${formatChoreDate(chore.chore.nextDueDate)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dueColor,
                            fontWeight: dueStatus == DueStatus.overdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
