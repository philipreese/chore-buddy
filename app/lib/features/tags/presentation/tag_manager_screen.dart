import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/exceptions.dart';
import '../../../core/strings/flavor_provider.dart';
import '../../../core/theme/tag_palette.dart';
import '../domain/tag_service.dart';
import '../providers/tag_providers.dart';

class TagManagerScreen extends ConsumerStatefulWidget {
  const TagManagerScreen({super.key});

  @override
  ConsumerState<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends ConsumerState<TagManagerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateTag() async {
    final strings = ref.read(appStringsProvider);
    final name = _nameController.text;
    try {
      await ref.read(tagServiceProvider).createTag(
            name: name,
            colorIndex: _selectedColorIndex,
            emoji: _emojiController.text,
          );
      _nameController.clear();
      _emojiController.clear();
      if (mounted) {
        setState(() {});
      }
    } on TagValidationException catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.tagTooLongTitle),
          content: Text(strings.tagTooLongMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.ok),
            ),
          ],
        ),
      );
    } on DuplicateNameException catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.tagConflictTitle),
          content: Text(strings.tagConflictMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmDeleteTag(TagEntity tag) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.scrubTagTitle),
        content: Text(strings.scrubTagMessage(tag.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.scrubTagKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.scrubTagConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(tagServiceProvider).deleteTag(tag.id);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteAllTagsTitle),
        content: Text(strings.deleteAllTagsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.deleteAllTagsConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(tagServiceProvider).deleteAllTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.manageTags),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('new_tag_input'),
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: strings.newTagPlaceholder,
                              hintText: strings.newTagPlaceholder,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            key: const Key('new_tag_emoji_input'),
                            controller: _emojiController,
                            maxLength: 2,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              counterText: '',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(TagPalette.swatches.length, (index) {
                        final color = TagPalette.swatches[index];
                        final isSelected = index == _selectedColorIndex;
                        return GestureDetector(
                          key: Key('swatch_$index'),
                          onTap: () {
                            setState(() {
                              _selectedColorIndex = index;
                            });
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('add_tag_button'),
                      icon: const Icon(Icons.add),
                      label: Text(strings.addTag),
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : _submitCreateTag,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            tagsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
              data: (tags) {
                if (tags.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label_off_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.emptyTagsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.emptyTagsDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.existingTags,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              key: const Key('delete_all_tags_button'),
                              icon: const Icon(Icons.delete_sweep_outlined),
                              onPressed: _confirmDeleteAll,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final tag in tags)
                          _TagRow(
                            key: ValueKey('tag_row_${tag.id}'),
                            tag: tag,
                            onDelete: () => _confirmDeleteTag(tag),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the existing-tags list: color swatch, name, an optional
/// emoji field committed on change, and delete. Kept as its own
/// ConsumerStatefulWidget so each row owns its own emoji TextEditingController
/// (seeded from the tag's current emoji) instead of sharing state across
/// rows.
class _TagRow extends ConsumerStatefulWidget {
  final TagEntity tag;
  final VoidCallback onDelete;

  const _TagRow({super.key, required this.tag, required this.onDelete});

  @override
  ConsumerState<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends ConsumerState<_TagRow> {
  late final TextEditingController _emojiController;

  @override
  void initState() {
    super.initState();
    _emojiController = TextEditingController(text: widget.tag.emoji ?? '');
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = TagPalette.getColor(widget.tag.colorIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.tag.name,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextField(
              key: Key('tag_emoji_field_${widget.tag.id}'),
              controller: _emojiController,
              maxLength: 2,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(tagServiceProvider).setTagEmoji(widget.tag.id, value);
              },
            ),
          ),
          IconButton(
            key: Key('delete_tag_${widget.tag.id}'),
            icon: const Icon(Icons.close),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
