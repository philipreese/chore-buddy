import 'package:flutter/material.dart';

/// Section header for the main settings screen: the same uppercase/bold/
/// letter-spaced label treatment `ChoreSectionHeader` introduced for the
/// chores list (spec 19), minus the count pill -- settings sections don't
/// have a count to show.
class SettingsSectionHeader extends StatelessWidget {
  final String label;
  final Color? color;

  const SettingsSectionHeader({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color ?? colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
