import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings/voice_provider.dart';

/// Calendar-day addition, matching `recurrence_calculator.dart`'s
/// `_addDays`: `Duration`-based `add` on a local DateTime adds elapsed
/// time, which can land on the wrong calendar day across a DST
/// transition.
DateTime _addDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Bottom sheet offering the fixed snooze targets plus a full date picker,
/// opened from [snoozeChoreFlow] in place of the old instant
/// "snooze to tomorrow" tap. Resolves to the chosen calendar day (time-of-
/// day is added later by SnoozeService, anchored to the chore's existing
/// due time) or null if dismissed without a choice.
Future<DateTime?> showSnoozeOptionsSheet({
  required BuildContext context,
  required DateTime now,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    builder: (context) => _SnoozeOptionsSheet(now: now),
  );
}

class _SnoozeOptionsSheet extends ConsumerWidget {
  final DateTime now;

  const _SnoozeOptionsSheet({required this.now});

  Future<void> _pickDate(BuildContext context, DateTime today) async {
    final tomorrow = _addDays(today, 1);
    final maxDate = DateTime(today.year + 1, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: maxDate,
    );
    if (picked == null || !context.mounted) return;
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final today = _dateOnly(now);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.snoozeSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const Key('snooze_option_tomorrow'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.wb_sunny_outlined),
                title: Text(strings.snoozeOptionTomorrow),
                onTap: () => Navigator.of(context).pop(_addDays(today, 1)),
              ),
              ListTile(
                key: const Key('snooze_option_in_3_days'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.today_outlined),
                title: Text(strings.snoozeOptionIn3Days),
                onTap: () => Navigator.of(context).pop(_addDays(today, 3)),
              ),
              ListTile(
                key: const Key('snooze_option_next_week'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_outlined),
                title: Text(strings.snoozeOptionNextWeek),
                onTap: () => Navigator.of(context).pop(_addDays(today, 7)),
              ),
              ListTile(
                key: const Key('snooze_option_pick_date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(strings.snoozeOptionPickDate),
                onTap: () => _pickDate(context, today),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
