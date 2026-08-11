import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/chore_with_details.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/home_widget/widget_sync_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/strings/flavor_provider.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../domain/date_formatter.dart';
import '../../domain/due_status.dart';
import '../../providers/chore_providers.dart';
import '../completion_flow.dart';
import '../snooze_flow.dart';

class ChoreCard extends ConsumerWidget {
  final ChoreWithDetails chore;
  final VoidCallback? onTap;

  const ChoreCard({super.key, required this.chore, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final showDetails = ref.watch(showDetailsOnCardsProvider);
    final dueStatus = getDueStatus(chore.chore.nextDueDate, now);
    final dueColor = getDueColor(
      chore.chore.nextDueDate,
      now,
      Theme.of(context).colorScheme,
    );
    final strings = ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('chore_${chore.chore.id}'),
      background: Container(
        color: colorScheme.tertiaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.archive, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Text(
              strings.archiveAction,
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              strings.deleteAction,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: colorScheme.onErrorContainer),
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
                child: Text(strings.cancel),
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
        final notificationService = ref.read(notificationServiceProvider);
        if (direction == DismissDirection.startToEnd) {
          await db.archiveChore(chore.chore.id);
          await notificationService.cancelForChore(chore.chore.id);
        } else if (direction == DismissDirection.endToStart) {
          await db.deleteChore(chore.chore.id);
          await notificationService.cancelForChore(chore.chore.id);
        }
        await ref.read(widgetSyncServiceProvider).sync();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, color: dueColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              chore.chore.name,
                              style: Theme.of(context).textTheme.titleMedium,
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
                            final tagColor = TagPalette.getColor(
                              tag.colorIndex,
                            );
                            return Chip(
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              // Contained chip: the secondaryContainer family
                              // tinted by the tag's own hue so chips read as
                              // solid tonal pills (not flat outlined text)
                              // while still telling tags apart at a glance.
                              backgroundColor: Color.alphaBlend(
                                tagColor.withAlpha(90),
                                colorScheme.secondaryContainer,
                              ),
                              side: BorderSide.none,
                              avatar: CircleAvatar(
                                backgroundColor: tagColor,
                                radius: 5,
                              ),
                              label: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (showDetails &&
                          (chore.lastCompleted != null ||
                              chore.lastNote != null)) ...[
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
                                  strings.lastCompletedLabel(
                                    formatChoreDate(chore.lastCompleted),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.outline),
                                ),
                              if (chore.lastNote != null &&
                                  chore.lastNote!.isNotEmpty) ...[
                                if (chore.lastCompleted != null)
                                  const SizedBox(height: 4),
                                Text(
                                  '${strings.noteLabel}: "${chore.lastNote}"',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: colorScheme.outline,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      if (chore.chore.nextDueDate != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              strings.dueLabel(
                                formatChoreDate(chore.chore.nextDueDate),
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    // Secondary/muted by default; overdue is
                                    // the one state that should pop.
                                    color: dueStatus == DueStatus.overdue
                                        ? colorScheme.error
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: dueStatus == DueStatus.overdue
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (chore.chore.nextDueDate != null)
                  IconButton(
                    icon: const Icon(Icons.snooze),
                    color: colorScheme.secondary,
                    tooltip: strings.snoozeAction,
                    onPressed: () => snoozeChoreFlow(
                      context: context,
                      ref: ref,
                      chore: chore,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: colorScheme.primary,
                  tooltip: strings.logButton,
                  onPressed: () => completeChoreFlow(
                    context: context,
                    ref: ref,
                    chore: chore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
