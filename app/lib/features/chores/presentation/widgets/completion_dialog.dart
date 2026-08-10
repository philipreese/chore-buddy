import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../domain/date_formatter.dart';

class CompletionResult {
  final DateTime completedAt;
  final String note;

  const CompletionResult({required this.completedAt, required this.note});
}

/// "Mission Report" dialog: date/time (defaulting to now) plus an optional
/// note. Returns null when cancelled.
Future<CompletionResult?> showCompletionDialog({
  required BuildContext context,
  required AppStrings strings,
  DateTime? initialDateTime,
}) {
  return showDialog<CompletionResult>(
    context: context,
    builder: (context) => CompletionDialog(
      strings: strings,
      initialDateTime: initialDateTime,
    ),
  );
}

class CompletionDialog extends StatefulWidget {
  final AppStrings strings;
  final DateTime? initialDateTime;

  const CompletionDialog({super.key, required this.strings, this.initialDateTime});

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDateTime ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  void _confirm() {
    final completedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    Navigator.of(context).pop(
      CompletionResult(
        completedAt: completedAt,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(strings.completionReportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.completionTimeLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(formatDateOnly(_selectedDate)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: strings.noteLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.abortButton),
        ),
        FilledButton(onPressed: _confirm, child: Text(strings.logButton)),
      ],
    );
  }
}
