import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/voice_provider.dart';

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
      final notificationService = ref.read(notificationServiceProvider);
      final purgedIds = await db.getArchivedChoreIds();
      await db.deleteArchivedChores();
      for (final id in purgedIds) {
        await notificationService.cancelForChore(id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final currentIndex = navigationShell.currentIndex;
    final isArchiveTab = currentIndex == 1;

    return PopScope(
      canPop: true,
      child: Scaffold(
        // The chores tab absorbs the shell's AppBar into its own banner
        // canvas (see ChoresBanner) -- every other tab keeps this one.
        appBar: isArchiveTab
            ? AppBar(
                title: Text(strings.tabArchive),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    tooltip: strings.purgeTitle,
                    onPressed: () =>
                        _confirmPurgeArchive(context, ref, strings),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: strings.settingsGearTooltip,
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              )
            : null,
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
