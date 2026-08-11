import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/strings/voice_provider.dart';
import '../../providers/settings_providers.dart';

/// App name, version/build/package (via `package_info_plus`), the "Powered
/// By" tech-stack chips, and the joke website button -- ported from the
/// MAUI `AboutPage`/`AboutViewModel`, now folded into Settings per ADR-0005.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.appTitle, style: textTheme.titleLarge),
            Text(
              strings.aboutTagline,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(strings.aboutTitle, style: textTheme.titleMedium),
            const Divider(height: 20),
            packageInfoAsync.when(
              data: (info) => _InfoGrid(strings: strings, info: info),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Text(
              strings.aboutPoweredByLabel,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: strings.aboutTechStackLabels
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('about_website_button'),
              onPressed: () => _showWebsiteDialog(context, strings),
              child: Text(strings.aboutWebsiteButton),
            ),
            const SizedBox(height: 12),
            Text(
              strings.aboutCopyright,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWebsiteDialog(BuildContext context, AppStrings strings) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.aboutWebsiteDialogTitle),
        content: Text(strings.aboutWebsiteDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.aboutWebsiteDialogAction),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final AppStrings strings;
  final PackageInfo info;

  const _InfoGrid({required this.strings, required this.info});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (strings.aboutVersionLabel, info.version),
      (strings.aboutBuildLabel, info.buildNumber),
      (strings.aboutPackageLabel, info.packageName),
      (strings.aboutDeveloperLabel, strings.aboutDeveloperName),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    row.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
