import 'package:flutter/material.dart';

enum DueStatus {
  overdue,
  dueSoon,
  onTime,
  none,
}

DueStatus getDueStatus(DateTime? nextDue, DateTime now) {
  if (nextDue == null) return DueStatus.none;
  if (now.isAfter(nextDue)) return DueStatus.overdue;
  if (nextDue.difference(now) <= const Duration(hours: 24)) return DueStatus.dueSoon;
  return DueStatus.onTime;
}

Color? getDueColor(DateTime? nextDue, DateTime now, ColorScheme colorScheme) {
  final status = getDueStatus(nextDue, now);
  switch (status) {
    case DueStatus.overdue:
      return colorScheme.error;
    case DueStatus.dueSoon:
      return colorScheme.tertiary;
    case DueStatus.onTime:
      return colorScheme.primary;
    case DueStatus.none:
      return null;
  }
}
