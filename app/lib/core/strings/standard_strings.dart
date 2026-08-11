import 'app_strings.dart';

/// Plain, friendly, zero-theatrics voice (spec 24). Every member says
/// exactly what it does -- no metaphors, no in-universe vocabulary.
class StandardStrings implements AppStrings {
  const StandardStrings();

  // Distinct from SuperheroStrings' "Chore Buddy" -- see the
  // per-voice-appTitle completeness test in voice_registry_test.dart.
  @override
  String get appTitle => 'Chores';

  // Voice (spec 24)
  @override
  String get voiceSignature => 'Simple, clear, no costumes.';

  // Tabs & Navigation
  @override
  String get tabChores => 'Chores';
  @override
  String get tabArchive => 'Archive';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Chores';
  @override
  String get searchPlaceholder => 'Search chores...';
  @override
  String get sortUrgency => 'Urgency';
  @override
  String get sortName => 'Name';
  @override
  String get sortLastCompleted => 'Last Done';
  @override
  String get sortButtonLabel => 'Sort';
  @override
  String get filterButtonLabel => 'Filter';
  @override
  String get filterByTagsTitle => 'Filter by Tags';
  @override
  String get emptyActiveTitle => 'All Caught Up';
  @override
  String get emptyActiveDescription =>
      'You have no chores that need attention right now. Tap the + to add one.';
  @override
  String get emptyFilterTitle => 'No Chores Found';
  @override
  String get emptyFilterDescription =>
      'You have chores, but none match your current filters. Try adjusting them.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'Overdue';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Upcoming';
  @override
  String get sectionUnscheduledLabel => 'Unscheduled';

  // Archive Screen
  @override
  String get archiveTitle => 'Archive';
  @override
  String get emptyArchiveTitle => 'Archive';
  @override
  String get emptyArchiveDescription =>
      'There are no archived chores here. Chores you archive will show up in this list.';
  @override
  String get restoreChore => 'Restore';
  @override
  String get restoreDialogTitle => 'Restore Chore';
  @override
  String restoreDialogMessage(String choreName) =>
      "Bring '$choreName' back to your active chores?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'New Chore';
  @override
  String get editChoreTitle => 'Edit Chore';
  @override
  String get nameLabel => 'Chore Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this chore's card";
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule a next due date for this chore';
  @override
  String get recurrenceLabel => 'Repeat';
  @override
  String get recurrenceNone => 'None';
  @override
  String get recurrenceDaily => 'Daily';
  @override
  String get recurrenceEveryOtherDay => 'Every Other Day';
  @override
  String get recurrenceWeekly => 'Weekly';
  @override
  String get recurrenceMonthly => 'Monthly';
  @override
  String get recurrenceCustomDays => 'Every N Days…';
  @override
  String recurrenceCustomDaysLabel(int days) => 'Every $days days';
  @override
  String get recurrenceIntervalRangeError =>
      'Enter an interval between 1 and 365 days.';
  @override
  String get missionReminder => 'Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for this chore';
  @override
  String get saveChore => 'Save Chore';
  @override
  String get completionHistory => 'Completion History';
  @override
  String get emptyHistoryTitle => 'No History Yet';
  @override
  String get emptyHistoryDescription =>
      'This chore has no recorded history. Log your first completion to start tracking it.';
  @override
  String get registryConflictTitle => 'Name Already Used';
  @override
  String get registryConflictMessage =>
      'A chore with this name already exists. Please choose a different name.';
  @override
  String get expungeRecordTitle => 'Delete Entry';
  @override
  String get expungeRecordMessage =>
      'Remove this entry from the completion history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Delete';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Not Found';
  @override
  String get choreNotFoundMessage => 'This chore could not be found.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'Chore Complete';
  @override
  String get completionTimeLabel => 'Completed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'Save';
  @override
  String get abortButton => 'Cancel';
  @override
  String get choreCompleted => 'Chore complete';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Archive Chore';
  @override
  String decommissionMessage(String choreName) =>
      "Move '$choreName' to the archive? It will be removed from your active chores.";
  @override
  String get decommissionConfirm => 'Archive';
  @override
  String get scrapTitle => 'Delete Chore';
  @override
  String scrapMessage(String choreName) =>
      "Are you sure you want to permanently delete '$choreName' and all of its history? This action cannot be undone.";
  @override
  String get scrapConfirm => 'Delete';
  @override
  String get purgeTitle => 'Delete All Archived Chores?';
  @override
  String get purgeMessage =>
      'This will permanently delete all archived chores. Erase these records?';
  @override
  String get purgeConfirm => 'Delete All';
  @override
  String get wipeAllChoresButton => 'Delete All Chores';
  @override
  String get wipeAllChoresTitle => 'Delete All Chores?';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently delete every chore -- active and archived alike -- along with their history and reminders. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Delete Everything';

  // Tags & Settings
  @override
  String get manageTags => 'Manage Tags';
  @override
  String get newTagPlaceholder => 'New Tag Name';
  @override
  String get addTag => 'Add Tag';
  @override
  String get existingTags => 'Existing Tags';
  @override
  String get emptyTagsTitle => 'No Tags Yet';
  @override
  String get emptyTagsDescription =>
      "You haven't created any tags yet. Use the fields above to categorize your chores.";
  @override
  String get tagTooLongTitle => 'Tag Too Long';
  @override
  String get tagTooLongMessage => 'Please use a shorter tag name.';
  @override
  String get tagConflictTitle => 'Tag Already Exists';
  @override
  String get tagConflictMessage => 'A tag with this name already exists.';
  @override
  String get scrubTagTitle => 'Delete Tag';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will remove it from all chores it's attached to. Continue?";
  @override
  String get scrubTagConfirm => 'Delete';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'Delete All Tags?';
  @override
  String get deleteAllTagsMessage =>
      'Are you sure you want to delete ALL tags? This action cannot be undone.';
  @override
  String get deleteAllTagsConfirm => 'Yes, Delete Everything';
  @override
  String get intelSecuredTitle => 'Backup Saved';
  @override
  String get intelSecuredMessage =>
      'Your chore data has been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'Restore Backup';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current chore history. Continue?';

  // Settings / About
  @override
  String get themeSectionTitle => 'Appearance';
  @override
  String get themePickerHint => 'Choose how the app looks';
  @override
  String get themeModeSystem => 'System';
  @override
  String get themeModeLight => 'Light';
  @override
  String get themeModeDark => 'Dark';
  @override
  String get dangerZoneSectionTitle => 'Danger Zone';
  @override
  String get voiceSectionTitle => 'Voice';
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Notifications';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Backup';
  @override
  String get importBackupButton => 'Import Backup';
  @override
  String get lastBackupNeverLabel => 'Never';
  @override
  String lastBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get restoreConfirmAction => 'Restore';
  @override
  String get backupFailedTitle => 'Backup Failed';
  @override
  String get backupFailedMessage =>
      'The backup could not be saved. Your data is unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your backup has been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your data is unchanged.';
  @override
  String get aboutTagline => 'Your household chore tracker';
  @override
  String get aboutVersionLabel => 'Version';
  @override
  String get aboutBuildLabel => 'Build';
  @override
  String get aboutPackageLabel => 'Package';
  @override
  String get aboutDeveloperLabel => 'Developer';
  @override
  String get aboutDeveloperName => 'Philip Reese';
  @override
  String get aboutPoweredByLabel => 'Powered By';
  @override
  List<String> get aboutTechStackLabels => const [
    'Flutter',
    'Drift',
    'Riverpod',
    'Material 3',
  ];
  @override
  String get aboutWebsiteButton => 'Visit Website';
  @override
  String get aboutWebsiteDialogTitle => 'My Website';
  @override
  String get aboutWebsiteDialogMessage => 'Coming... soon?';
  @override
  String get aboutWebsiteDialogAction => 'OK';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Chore Reminders';
  @override
  String get notificationChannelDescription =>
      'Reminders for your active chores.';
  @override
  String notificationTitle(String choreName) => 'Reminder: $choreName';
  @override
  String get notificationBody => "It's time to do this chore.";
  @override
  String get notificationCompleteAction => 'COMPLETE';

  // Common
  @override
  String get archiveAction => 'Archive';
  @override
  String get deleteAction => 'Delete';
  @override
  String lastCompletedLabel(String date) => 'Last completed: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get iconPickerNoneLabel => 'None';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'New Chore';
  @override
  String get shortcutOverdueLabel => 'Overdue';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Overdue: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically saves a backup of your chores every day.';
  @override
  String autoBackupDestinationLabel(String path) => 'Backup location: $path';
  @override
  String get autoBackupNeverLabel => 'No backups yet';
  @override
  String autoBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get autoBackupNowButton => 'Back Up Now';
  @override
  String get autoBackupNowSuccessTitle => 'Backup Complete';
  @override
  String get autoBackupNowSuccessMessage =>
      'Your chores have been backed up.';
  @override
  String get autoBackupNowFailedTitle => 'Backup Failed';
  @override
  String get autoBackupNowFailedMessage =>
      "The backup didn't go through. Try again in a moment.";

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Not Today';
  @override
  String choreSnoozedUntil(String date) => 'Chore postponed to $date';
  @override
  String get notificationSnoozeAction => 'NOT TODAY';
  @override
  String get duplicateAction => 'Duplicate Chore';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Reschedule Chore';
  @override
  String get snoozeOptionTomorrow => 'Tomorrow';
  @override
  String get snoozeOptionIn3Days => 'In 3 Days';
  @override
  String get snoozeOptionNextWeek => 'Next Week';
  @override
  String get snoozeOptionPickDate => 'Pick a Date...';

  // Voice commands (spec 16)
  @override
  String voiceChoreAddedMessage(String choreName) => 'Added: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Completed: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A chore named '$choreName' already exists.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No active chore matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple chores match '$choreName' -- be more specific.";
  @override
  String get voiceCommandInvalidMessage => 'Voice command not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No chores completed yet — tap to open your Stats';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_choresCount(count)} this week — your first week!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_choresCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_choresCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_choresCount(count)} this week — same as last';
  @override
  String streakChipLabel(int streak) => '$streak in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count logged';
  @override
  String cadenceLinePlain(int days) => 'Typically done every ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typically done every ~$days days · on schedule';
  @override
  String cadenceLineBehind(int days) =>
      'Typically done every ~$days days · running behind';
  @override
  String get missionLogTitle => 'Stats';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'chores';
  @override
  String missionLogBestStreakLabel(String choreName, int streak) =>
      'Best streak: $streak — $choreName';
  @override
  String get missionLogLastFiveWeeksTitle => 'Last 5 Weeks';
  @override
  String get missionLogThisMonthTitle => 'This Month';
  @override
  String get missionLogChartNowLabel => 'Now';
  @override
  String missionLogChartWeeksAgoLabel(int weeks) => '-${weeks}w';

  static String _choresCount(int count) =>
      count == 1 ? '1 chore' : '$count chores';
}
