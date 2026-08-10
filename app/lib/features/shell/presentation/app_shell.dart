import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/flavor_provider.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  Future<void> _confirmPurgeArchive(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.purgeTitle),
        content: Text(strings.purgeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.purgeConfirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(appDatabaseProvider);
      await db.deleteArchivedChores();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final currentIndex = navigationShell.currentIndex;
    final isArchiveTab = currentIndex == 1;
    final title = isArchiveTab ? strings.tabArchive : strings.tabChores;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (isArchiveTab)
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: strings.purgeConfirm,
                onPressed: () => _confirmPurgeArchive(context, ref, strings),
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: strings.settingsGearTooltip,
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.task_alt_outlined),
              selectedIcon: const Icon(Icons.task_alt),
              label: strings.tabChores,
            ),
            NavigationDestination(
              icon: const Icon(Icons.archive_outlined),
              selectedIcon: const Icon(Icons.archive),
              label: strings.tabArchive,
            ),
          ],
        ),
      ),
    );
  }
}
