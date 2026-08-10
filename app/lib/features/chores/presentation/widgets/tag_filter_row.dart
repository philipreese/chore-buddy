import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/strings/flavor_provider.dart';
import '../../../../core/theme/tag_palette.dart';
import '../../providers/chore_providers.dart';

class TagFilterRow extends ConsumerWidget {
  const TagFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final selectedIds = ref.watch(selectedTagFilterIdsProvider);
    final strings = ref.watch(appStringsProvider);

    return tagsAsync.when(
      data: (tags) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              ...tags.map((tag) {
                final isSelected = selectedIds.contains(tag.id);
                final color = TagPalette.getColor(tag.colorIndex);

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
                    avatar: CircleAvatar(
                      backgroundColor: color,
                      radius: 6,
                    ),
                    onSelected: (_) {
                      ref
                          .read(selectedTagFilterIdsProvider.notifier)
                          .toggleTag(tag.id);
                    },
                  ),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: Text(strings.manageTags),
                onPressed: () {
                  context.push('/tags');
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
