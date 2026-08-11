import 'package:flutter/material.dart';

enum DueStatus { overdue, dueSoon, onTime, none }

DueStatus getDueStatus(DateTime? nextDue, DateTime now) {
  if (nextDue == null) return DueStatus.none;
  if (now.isAfter(nextDue)) return DueStatus.overdue;
  if (nextDue.difference(now) <= const Duration(hours: 24)) {
    return DueStatus.dueSoon;
  }
  return DueStatus.onTime;
}

/// The warm/amber accent shared by every "coming up soon" urgency cue --
/// per-card due text (`getDueColor`'s dueSoon case) and the sectioned
/// list's "Today" header alike -- so the two visual cues can never drift
/// apart by editing one and not the other. Prefers the scheme's own
/// tertiary when it already reads warm (red..yellow hue band); a cool
/// tertiary (blue/purple, common under wallpaper-derived dynamic color)
/// would misread as "safe" here, so that case blends toward a fixed amber
/// instead.
Color warmAccentColor(ColorScheme colorScheme) {
  final hue = HSLColor.fromColor(colorScheme.tertiary).hue;
  final isWarmHue = hue <= 60 || hue >= 300;
  if (isWarmHue) return colorScheme.tertiary;
  return Color.alphaBlend(
    const Color(0xFFF59E0B).withAlpha(140),
    colorScheme.tertiary,
  );
}

/// Warm-container counterpart to [warmAccentColor], for chip/badge
/// backgrounds that need a warm-hued *container* role instead of the
/// stronger tone (e.g. the streak chip in chore detail -- spec 22).
Color warmAccentContainerColor(ColorScheme colorScheme) {
  final hue = HSLColor.fromColor(colorScheme.tertiaryContainer).hue;
  final isWarmHue = hue <= 60 || hue >= 300;
  if (isWarmHue) return colorScheme.tertiaryContainer;
  return Color.alphaBlend(
    const Color(0xFFF59E0B).withAlpha(90),
    colorScheme.tertiaryContainer,
  );
}

Color? getDueColor(DateTime? nextDue, DateTime now, ColorScheme colorScheme) {
  final status = getDueStatus(nextDue, now);
  switch (status) {
    case DueStatus.overdue:
      return colorScheme.error;
    case DueStatus.dueSoon:
      return warmAccentColor(colorScheme);
    case DueStatus.onTime:
      return colorScheme.primary;
    case DueStatus.none:
      return null;
  }
}

/// Bucket used by the chores list's sectioned (urgency-sort) view.
/// Overdue is instant-based -- [nextDue] before [now] -- the same rule
/// [getDueStatus] uses, so a chore due 10 minutes ago is overdue rather
/// than sitting under "Due Today" until midnight. Today/Upcoming remain
/// calendar-day buckets for everything not yet overdue.
enum DueSection { overdue, today, upcoming, unscheduled }

DueSection getDueSection(DateTime? nextDue, DateTime now) {
  if (nextDue == null) return DueSection.unscheduled;
  if (nextDue.isBefore(now)) return DueSection.overdue;
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(nextDue.year, nextDue.month, nextDue.day);
  if (dueDay.isAtSameMomentAs(today)) return DueSection.today;
  return DueSection.upcoming;
}

/// Section-header/stat-chip color for [section] -- shares [warmAccentColor]
/// with [getDueColor]'s dueSoon case (see that function's doc) rather than
/// re-deriving the warm tone independently.
Color getDueSectionColor(DueSection section, ColorScheme colorScheme) {
  switch (section) {
    case DueSection.overdue:
      return colorScheme.error;
    case DueSection.today:
      return warmAccentColor(colorScheme);
    case DueSection.upcoming:
    case DueSection.unscheduled:
      return colorScheme.onSurfaceVariant;
  }
}
