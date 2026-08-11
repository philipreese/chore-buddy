import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/strings/voice_provider.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../providers/chore_providers.dart';

/// Tag-filter picker shown in a bottom sheet from the chores header's filter
/// button (see [SearchAndSortBar]) rather than as a permanently visible row,
/// so the header stays one dense line at rest.
class TagFilterSheet extends ConsumerWidget {
  const TagFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final selectedIds = ref.watch(selectedTagFilterIdsProvider);
    final strings = ref.watch(appStringsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.filterByTagsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () => ref
                        .read(selectedTagFilterIdsProvider.notifier)
                        .setTags({}),
                    child: Text(strings.cancel),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            tagsAsync.when(
              data: (tags) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...tags.map((tag) {
                      final isSelected = selectedIds.contains(tag.id);
                      final color = TagPalette.getColor(tag.colorIndex);

                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        avatar: CircleAvatar(
                          backgroundColor: color,
                          radius: 6,
                        ),
                        // The M3 selected-state checkmark draws on top of
                        // the custom leading avatar dot instead of
                        // replacing it, so a selected chip showed two
                        // overlapping glyphs. Keeping the colored dot as
                        // the tag's identity and suppressing the checkmark
                        // leaves a single, unambiguous indicator.
                        showCheckmark: false,
                        onSelected: (_) {
                          ref
                              .read(selectedTagFilterIdsProvider.notifier)
                              .toggleTag(tag.id);
                        },
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: Text(strings.manageTags),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/tags');
                      },
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
