import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/strings/voice_provider.dart';
import '../../domain/due_status.dart';

/// Sectioned list header row (urgency sort only): a small uppercase label
/// plus a count pill, both colored by [getDueSectionColor] so this and the
/// per-card due-urgency signal can never visually disagree.
class ChoreSectionHeader extends ConsumerWidget {
  final DueSection section;
  final int count;

  const ChoreSectionHeader({
    super.key,
    required this.section,
    required this.count,
  });

  String _labelFor(AppStrings strings) {
    switch (section) {
      case DueSection.overdue:
        return strings.sectionOverdueLabel;
      case DueSection.today:
        return strings.sectionTodayLabel;
      case DueSection.upcoming:
        return strings.sectionUpcomingLabel;
      case DueSection.unscheduled:
        return strings.sectionUnscheduledLabel;
    }
  }

  // Upcoming/Unscheduled used surfaceContainerHighest -- an adjacent tonal
  // step off `surface` that reads as imperceptible under dynamic color on
  // real devices (device feedback, spec 27). secondaryContainer is a real
  // color swap rather than a tonal step, matching how the banner's stat
  // chips already solve the identical "pill on a busy background" problem
  // (see luminance tripwire in theme_test.dart).
  Color _pillBackground(ColorScheme colorScheme) {
    switch (section) {
      case DueSection.overdue:
        return colorScheme.errorContainer;
      case DueSection.today:
        return colorScheme.tertiaryContainer;
      case DueSection.upcoming:
      case DueSection.unscheduled:
        return colorScheme.secondaryContainer;
    }
  }

  Color _pillForeground(ColorScheme colorScheme) {
    switch (section) {
      case DueSection.overdue:
        return colorScheme.onErrorContainer;
      case DueSection.today:
        return colorScheme.onTertiaryContainer;
      case DueSection.upcoming:
      case DueSection.unscheduled:
        return colorScheme.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = getDueSectionColor(section, colorScheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            _labelFor(strings).toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _pillBackground(colorScheme),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _pillForeground(colorScheme),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
