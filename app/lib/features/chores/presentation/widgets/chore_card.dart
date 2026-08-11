import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/chore_with_details.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/home_widget/widget_sync_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/strings/voice_provider.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../domain/date_formatter.dart';
import '../../domain/due_status.dart';
import '../../domain/icon_guesser.dart';
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
          // Archiving used to be a bare swipe, but a vertical scroll grazes
          // horizontal dismissibles constantly (first on-device feedback:
          // accidental archives while scrolling) — so it confirms now, with
          // the same copy the MAUI app used for this exact action.
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(strings.decommissionTitle),
              content: Text(strings.decommissionMessage(chore.chore.name)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.decommissionConfirm),
                ),
              ],
            ),
          );
          return confirm ?? false;
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
        // elevation 0 + one tonal step read as imperceptible under dynamic
        // color on real devices (round 2 feedback). A real shadow plus a
        // hairline border plus a two-step tonal jump gives dark mode (no
        // shadow) and light mode (shadow washed out by dynamic palettes)
        // independent ways to read the card boundary.
        elevation: 1,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
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
                          _ChoreIconChip(chore: chore),
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
                                    // The clock icon used to carry urgency;
                                    // now this line is the only per-card
                                    // signal, so it takes the full
                                    // getDueColor mapping -- overdue is the
                                    // one state that should also pop in
                                    // weight.
                                    color: getDueColor(
                                          chore.chore.nextDueDate,
                                          now,
                                          colorScheme,
                                        ) ??
                                        colorScheme.onSurfaceVariant,
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

/// Replaces the due-urgency clock icon as the card's leading glyph -- the
/// due-date text line is now the only per-card urgency carrier (see
/// due_status.dart). Tinted by the chore's first tag using the same
/// alpha-blend-over-secondaryContainer recipe the tag chips below already
/// use, so a chip and its card's leading glyph always read as the same
/// color family.
class _ChoreIconChip extends StatelessWidget {
  final ChoreWithDetails chore;

  const _ChoreIconChip({required this.chore});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstTag = chore.tags.isNotEmpty ? chore.tags.first : null;

    final background = firstTag == null
        ? colorScheme.secondaryContainer
        : Color.alphaBlend(
            TagPalette.getColor(firstTag.colorIndex).withAlpha(90),
            colorScheme.secondaryContainer,
          );

    // Icons belong to the chore, not the tag (spec 23) -- tags.emoji is
    // dormant. A chore's own emoji wins, falling back to a name-based guess
    // and finally the chore name's first letter.
    final choreEmoji = chore.chore.emoji;
    final glyph = (choreEmoji != null && choreEmoji.isNotEmpty)
        ? choreEmoji
        : (guessChoreEmoji(chore.chore.name) ??
            (chore.chore.name.isNotEmpty
                ? chore.chore.name[0].toUpperCase()
                : '?'));

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
