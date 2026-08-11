import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/exceptions.dart';
import '../../../core/database/tables.dart';
import '../../../core/home_widget/widget_sync_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/flavor_provider.dart';
import '../../../core/theme/tag_palette.dart';
import '../domain/date_formatter.dart';
import '../domain/duplicate_name.dart';
import 'widgets/completion_dialog.dart';

DateTime _defaultDueDate() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
}

/// The values a "Duplicate" action carries over to the new-chore form via
/// the `/chores/new` route's `extra`. Due date is deliberately absent --
/// left for the user to set, per the duplicate spec.
class ChoreDuplicatePrefill {
  final String name;
  final Set<int> tagIds;
  final RecurrenceType recurrence;
  final int? recurrenceInterval;
  final bool notificationEnabled;

  const ChoreDuplicatePrefill({
    required this.name,
    required this.tagIds,
    required this.recurrence,
    this.recurrenceInterval,
    required this.notificationEnabled,
  });
}

class ChoreDetailScreen extends ConsumerStatefulWidget {
  final String choreId;
  final ChoreDuplicatePrefill? duplicatePrefill;

  const ChoreDetailScreen({
    super.key,
    required this.choreId,
    this.duplicatePrefill,
  });

  @override
  ConsumerState<ChoreDetailScreen> createState() => _ChoreDetailScreenState();
}

class _ChoreDetailScreenState extends ConsumerState<ChoreDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _intervalController;

  Set<int> _selectedTagIds = {};
  bool _hasDueDate = false;
  DateTime _selectedDate = _defaultDueDate();
  TimeOfDay _selectedTime = TimeOfDay.now();
  RecurrenceType _recurrence = RecurrenceType.none;
  String? _intervalErrorText;
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
    final prefill = widget.duplicatePrefill;
    _nameController = TextEditingController(text: prefill?.name ?? '');
    _intervalController = TextEditingController(
      text: prefill?.recurrence == RecurrenceType.customDays
          ? (prefill?.recurrenceInterval ?? 3).toString()
          : '',
    );
    if (_isNew) {
      if (prefill != null) {
        _selectedTagIds = prefill.tagIds;
        _recurrence = prefill.recurrence;
        _notificationEnabled = prefill.notificationEnabled;
      }
      _loading = false;
    } else {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
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
        _intervalController.text = chore.recurrence == RecurrenceType.customDays
            ? (chore.recurrenceInterval ?? 3).toString()
            : '';
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
      case RecurrenceType.customDays:
        return strings.recurrenceCustomDaysLabel(_displayedInterval);
    }
  }

  /// The interval to render in "Every N days" labels while the field is
  /// being edited -- falls back to the default of 3 for an empty/unparsable
  /// value rather than showing a broken label; [_save] does the real
  /// validation and blocks on an out-of-range value.
  int get _displayedInterval {
    final parsed = int.tryParse(_intervalController.text.trim());
    if (parsed == null || parsed < 1 || parsed > 365) return 3;
    return parsed;
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final strings = ref.read(appStringsProvider);

    DateTime? nextDueDate;
    RecurrenceType recurrence = RecurrenceType.none;
    int? recurrenceInterval;
    if (_hasDueDate) {
      nextDueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      recurrence = _recurrence;
      if (recurrence == RecurrenceType.customDays) {
        final parsed = int.tryParse(_intervalController.text.trim());
        if (parsed == null || parsed < 1 || parsed > 365) {
          setState(() => _intervalErrorText = strings.recurrenceIntervalRangeError);
          return;
        }
        recurrenceInterval = parsed;
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final db = ref.read(appDatabaseProvider);

    setState(() {
      _intervalErrorText = null;
      _saving = true;
    });

    try {
      int savedId;
      if (_isNew) {
        savedId = await db.insertChoreWithTags(
          ChoresCompanion.insert(
            name: name,
            nextDueDate: Value(nextDueDate),
            recurrence: Value(recurrence),
            recurrenceInterval: Value(recurrenceInterval),
            isNotificationEnabled: Value(_notificationEnabled),
          ),
          _selectedTagIds.toList(),
        );
      } else {
        final original = _originalChore;
        if (original == null) return;
        savedId = original.id;
        await db.updateChoreWithTags(
          original.id,
          ChoresCompanion(
            name: Value(name),
            nextDueDate: Value(nextDueDate),
            recurrence: Value(recurrence),
            recurrenceInterval: Value(recurrenceInterval),
            isNotificationEnabled: Value(_notificationEnabled),
          ),
          _selectedTagIds.toList(),
        );
      }

      final saved = await db.getChoreById(savedId);
      if (saved != null) {
        await ref.read(notificationServiceProvider).scheduleForChore(saved);
        await ref.read(widgetSyncServiceProvider).sync();
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

  Future<void> _duplicate() async {
    final db = ref.read(appDatabaseProvider);
    final baseName = _nameController.text.trim();
    if (baseName.isEmpty) return;

    final name = await uniqueDuplicateName(
      baseName,
      db.choreNameExists,
    );
    if (!mounted) return;

    context.push(
      '/chores/new',
      extra: ChoreDuplicatePrefill(
        name: name,
        tagIds: _selectedTagIds,
        recurrence: _recurrence,
        recurrenceInterval:
            _recurrence == RecurrenceType.customDays ? _displayedInterval : null,
        notificationEnabled: _notificationEnabled,
      ),
    );
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
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_isNew && !_loading)
            IconButton(
              key: const Key('duplicate_chore_button'),
              icon: const Icon(Icons.copy),
              tooltip: strings.duplicateAction,
              onPressed: _duplicate,
            ),
        ],
      ),
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
      // Zero out Card's default 4dp margin so this card's outer edges align
      // with the un-margined TextField/tag row above and the history cards
      // below, all of which rely solely on the ListView's own padding.
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                // The open menu shows the generic "Every N Days…" item, but
                // once picked the collapsed field must show the actual
                // interval -- selectedItemBuilder is the only way to make
                // those diverge for the same value.
                selectedItemBuilder: (context) => RecurrenceType.values
                    .map(
                      (type) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(_recurrenceLabel(strings, type)),
                      ),
                    )
                    .toList(),
                items: RecurrenceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == RecurrenceType.customDays
                              ? strings.recurrenceCustomDays
                              : _recurrenceLabel(strings, type),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _recurrence = value;
                    _intervalErrorText = null;
                    if (value == RecurrenceType.customDays &&
                        _intervalController.text.trim().isEmpty) {
                      _intervalController.text = '3';
                    }
                  });
                },
              ),
              if (_recurrence == RecurrenceType.customDays) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('recurrence_interval_field'),
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: strings.recurrenceCustomDays,
                    border: const OutlineInputBorder(),
                    errorText: _intervalErrorText,
                  ),
                  // Keeps the collapsed dropdown's "Every N days" label (see
                  // selectedItemBuilder above) live as the user types, and
                  // clears a stale out-of-range error once they edit again.
                  onChanged: (_) => setState(() => _intervalErrorText = null),
                ),
              ],
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
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
                  // Zero margin (see _buildDueDateCard) so this card's outer
                  // edges align with the form fields above; vertical spacing
                  // between records comes from the wrapping Padding instead.
                  margin: EdgeInsets.zero,
                  // See ChoreCard: elevation-0 + one tonal step is
                  // imperceptible under dynamic color on real devices.
                  elevation: 1,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
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
