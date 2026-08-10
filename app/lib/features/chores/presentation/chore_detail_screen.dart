import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/exceptions.dart';
import '../../../core/database/tables.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/flavor_provider.dart';
import '../../../core/theme/tag_palette.dart';
import '../domain/date_formatter.dart';
import 'widgets/completion_dialog.dart';

DateTime _defaultDueDate() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
}

class ChoreDetailScreen extends ConsumerStatefulWidget {
  final String choreId;

  const ChoreDetailScreen({
    super.key,
    required this.choreId,
  });

  @override
  ConsumerState<ChoreDetailScreen> createState() => _ChoreDetailScreenState();
}

class _ChoreDetailScreenState extends ConsumerState<ChoreDetailScreen> {
  late final TextEditingController _nameController;

  Set<int> _selectedTagIds = {};
  bool _hasDueDate = false;
  DateTime _selectedDate = _defaultDueDate();
  TimeOfDay _selectedTime = TimeOfDay.now();
  RecurrenceType _recurrence = RecurrenceType.none;
  bool _notificationEnabled = true;
  ChoreEntity? _originalChore;
  bool _loading = true;
  bool _saving = false;
  bool _notFound = false;

  bool get _isNew => widget.choreId == 'new' || widget.choreId == '0';
  int? get _choreIdInt => int.tryParse(widget.choreId);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (_isNew) {
      _loading = false;
    } else {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  Future<void> _loadExisting() async {
    final id = _choreIdInt;
    if (id == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final db = ref.read(appDatabaseProvider);
    try {
      final chore = await db.getChoreById(id);
      if (chore == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _notFound = true;
        });
        return;
      }
      final tagIds = await db.getTagIdsForChore(id);
      if (!mounted) return;

      setState(() {
        _originalChore = chore;
        _nameController.text = chore.name;
        _selectedTagIds = tagIds.toSet();
        final due = chore.nextDueDate;
        _hasDueDate = due != null;
        if (due != null) {
          _selectedDate = DateTime(due.year, due.month, due.day);
          _selectedTime = TimeOfDay(hour: due.hour, minute: due.minute);
        }
        _recurrence = chore.recurrence;
        _notificationEnabled = chore.isNotificationEnabled;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notFound = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _recurrenceLabel(AppStrings strings, RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return strings.recurrenceNone;
      case RecurrenceType.daily:
        return strings.recurrenceDaily;
      case RecurrenceType.everyOtherDay:
        return strings.recurrenceEveryOtherDay;
      case RecurrenceType.weekly:
        return strings.recurrenceWeekly;
      case RecurrenceType.monthly:
        return strings.recurrenceMonthly;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final db = ref.read(appDatabaseProvider);
    final strings = ref.read(appStringsProvider);

    DateTime? nextDueDate;
    RecurrenceType recurrence = RecurrenceType.none;
    if (_hasDueDate) {
      nextDueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      recurrence = _recurrence;
    }

    setState(() => _saving = true);

    try {
      if (_isNew) {
        await db.insertChoreWithTags(
          ChoresCompanion.insert(
            name: name,
            nextDueDate: Value(nextDueDate),
            recurrence: Value(recurrence),
            isNotificationEnabled: Value(_notificationEnabled),
          ),
          _selectedTagIds.toList(),
        );
      } else {
        final original = _originalChore;
        if (original == null) return;
        await db.updateChoreWithTags(
          original.id,
          ChoresCompanion(
            name: Value(name),
            nextDueDate: Value(nextDueDate),
            recurrence: Value(recurrence),
            isNotificationEnabled: Value(_notificationEnabled),
          ),
          _selectedTagIds.toList(),
        );
      }

      if (!mounted) return;
      context.pop();
    } on DuplicateNameException catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.registryConflictTitle),
          content: Text(strings.registryConflictMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(strings.genericError(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.ok),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editRecord(CompletionRecordEntity record) async {
    final strings = ref.read(appStringsProvider);
    final db = ref.read(appDatabaseProvider);

    final result = await showCompletionDialog(
      context: context,
      strings: strings,
      initialDateTime: record.completedAt,
      initialNote: record.note,
    );
    if (result == null) return;

    await db.updateCompletionRecord(
      CompletionRecordEntity(
        id: record.id,
        choreId: record.choreId,
        completedAt: result.completedAt,
        note: result.note,
      ),
    );
  }

  Future<bool> _confirmDeleteRecord(CompletionRecordEntity record) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.expungeRecordTitle),
        content: Text(strings.expungeRecordMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.expungeRecordKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.expungeRecordConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final db = ref.read(appDatabaseProvider);
    await db.deleteCompletionRecord(record.id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.notFoundTitle)),
        body: Center(child: Text(strings.choreNotFoundMessage)),
      );
    }

    final title = _isNew ? strings.newChoreTitle : strings.editChoreTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextField(
                  key: const Key('chore_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: strings.nameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                _buildTagPicker(context, strings),
                const SizedBox(height: 20),
                _buildDueDateCard(context, strings),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('save_chore_button'),
                  icon: const Icon(Icons.save),
                  label: Text(strings.saveChore),
                  onPressed: _saving ? null : _save,
                ),
                if (!_isNew) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    strings.completionHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildHistorySection(context, strings),
                ],
              ],
            ),
    );
  }

  Widget _buildTagPicker(BuildContext context, AppStrings strings) {
    final tagsAsync = ref.watch(tagsProvider);

    return tagsAsync.when(
      data: (tags) {
        final validTagIds = tags.map((t) => t.id).toSet();
        if (!validTagIds.containsAll(_selectedTagIds)) {
          _selectedTagIds = _selectedTagIds.intersection(validTagIds);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: tags.isEmpty
                  ? Text(
                      strings.addTagsPrompt,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final color = TagPalette.getColor(tag.colorIndex);
                        final isSelected = _selectedTagIds.contains(tag.id);
                        return FilterChip(
                          key: Key('tag_chip_${tag.id}'),
                          label: Text(tag.name),
                          selected: isSelected,
                          avatar: CircleAvatar(
                            backgroundColor: color,
                            radius: 6,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds = {..._selectedTagIds, tag.id};
                              } else {
                                _selectedTagIds = {..._selectedTagIds}
                                  ..remove(tag.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
            IconButton(
              key: const Key('add_tags_button'),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: strings.addTagsPrompt,
              onPressed: () => context.push('/tags'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildDueDateCard(BuildContext context, AppStrings strings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.addDueDatePrompt,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        strings.scheduleDueDateHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('has_due_date_switch'),
                  value: _hasDueDate,
                  onChanged: (value) => setState(() => _hasDueDate = value),
                ),
              ],
            ),
            if (_hasDueDate) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('due_date_picker_button'),
                      onPressed: _pickDate,
                      child: Text(formatDateOnly(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('due_time_picker_button'),
                      onPressed: _pickTime,
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.recurrenceLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurrenceType>(
                key: const Key('recurrence_dropdown'),
                initialValue: _recurrence,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: RecurrenceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_recurrenceLabel(strings, type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrence = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.missionReminder,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          strings.scheduleReminderHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const Key('notification_switch'),
                    value: _notificationEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationEnabled = value),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AppStrings strings) {
    final id = _choreIdInt;
    if (id == null) return const SizedBox.shrink();

    final historyAsync = ref.watch(historyForChoreProvider(id));

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Icon(
                  Icons.checklist_rtl,
                  size: 48,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  strings.emptyHistoryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.emptyHistoryDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: records.map((record) {
            return Dismissible(
              key: Key('history_record_${record.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              confirmDismiss: (_) => _confirmDeleteRecord(record),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  onTap: () => _editRecord(record),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDateTime(record.completedAt),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (record.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            record.note,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text(strings.genericError(err)),
    );
  }
}
