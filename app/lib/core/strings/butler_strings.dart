import 'app_strings.dart';

/// Butler voice (spec 25). Impeccable manor-house politeness.
class ButlerStrings implements AppStrings {
  const ButlerStrings();

  @override
  String get appTitle => 'The Butler';

  @override
  String get voiceSignature => 'At your service, as always.';

  // Tabs & Navigation
  @override
  String get tabChores => 'The Household Ledger';
  @override
  String get tabArchive => 'The Registry';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'The Household Ledger';
  @override
  String get searchPlaceholder => 'Search the ledger...';
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
  String get emptyActiveTitle => 'All Household Duties Settled';
  @override
  String get emptyActiveDescription =>
      'Every household duty is in order. Tap the + should a new duty require attention.';
  @override
  String get emptyFilterTitle => 'No Duties Found';
  @override
  String get emptyFilterDescription =>
      'No duties match your current filters. Adjust your criteria to view the ledger.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'Awaiting Urgent Attention';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Upcoming Duties';
  @override
  String get sectionUnscheduledLabel => 'Unscheduled Duties';

  // Archive Screen
  @override
  String get archiveTitle => 'The Registry';
  @override
  String get emptyArchiveTitle => 'The Registry';
  @override
  String get emptyArchiveDescription =>
      'There are no archived duties in the registry. Shelved duties shall reside here.';
  @override
  String get restoreChore => 'Restore Duty';
  @override
  String get restoreDialogTitle => 'Restore Duty';
  @override
  String restoreDialogMessage(String choreName) =>
      "Shall I restore '$choreName' to the active household ledger?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'A New Duty';
  @override
  String get editChoreTitle => 'Edit Household Duty';
  @override
  String get nameLabel => 'Duty Title / Chore Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this duty's entry";
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule a due date for this duty';
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
  String get missionReminder => 'Duty Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for this duty';
  @override
  String get saveChore => 'Record Duty';
  @override
  String get completionHistory => 'Duty History';
  @override
  String get emptyHistoryTitle => 'No Record Yet';
  @override
  String get emptyHistoryDescription =>
      'This duty has no recorded history. Record your first completion to begin tracking.';
  @override
  String get registryConflictTitle => 'Duty Already Registered';
  @override
  String get registryConflictMessage =>
      'A duty with this title already exists in the ledger. Please select another title.';
  @override
  String get expungeRecordTitle => 'Expunge Entry';
  @override
  String get expungeRecordMessage =>
      'If you are quite certain, shall we remove this entry from the duty history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Expunge';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Duty Not Found';
  @override
  String get choreNotFoundMessage =>
      'This duty could not be located in the ledger.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'DUTY COMPLETED';
  @override
  String get completionTimeLabel => 'Completed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'RECORD';
  @override
  String get abortButton => 'PARDON';
  @override
  String get choreCompleted => 'Very good.';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Shelve Duty';
  @override
  String decommissionMessage(String choreName) =>
      "If you are quite certain, shall we move '$choreName' to the registry?";
  @override
  String get decommissionConfirm => 'Shelve Duty';
  @override
  String get scrapTitle => 'Expunge Duty';
  @override
  String scrapMessage(String choreName) =>
      "If you are quite certain, this will permanently expunge '$choreName' and all records of its execution. This action cannot be undone.";
  @override
  String get scrapConfirm => 'Expunge Duty';
  @override
  String get purgeTitle => 'Expunge All Shelved Duties?';
  @override
  String get purgeMessage =>
      'If you are quite certain, this will permanently expunge all shelved duties from the registry. This action cannot be undone.';
  @override
  String get purgeConfirm => 'Expunge All';
  @override
  String get wipeAllChoresButton => 'Expunge Entire Ledger';
  @override
  String get wipeAllChoresTitle => 'If You Are Quite Certain…';
  @override
  String get wipeAllChoresMessage =>
      'If you are quite certain, this will permanently expunge every duty from the household ledger. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Expunge Ledger';

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
      "You haven't created any tags yet. Use the fields above to categorize your household duties.";
  @override
  String get tagTooLongTitle => 'Tag Too Long';
  @override
  String get tagTooLongMessage => 'Please provide a shorter tag name.';
  @override
  String get tagConflictTitle => 'Tag Already Exists';
  @override
  String get tagConflictMessage => 'A tag with this name already exists.';
  @override
  String get scrubTagTitle => 'Remove Tag';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will remove it from all duties it is attached to. Continue?";
  @override
  String get scrubTagConfirm => 'Remove';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'Delete All Tags?';
  @override
  String get deleteAllTagsMessage =>
      'If you are quite certain, this will delete ALL tags. This action cannot be undone.';
  @override
  String get deleteAllTagsConfirm => 'Yes, Delete Everything';
  @override
  String get intelSecuredTitle => 'Ledger Saved';
  @override
  String get intelSecuredMessage =>
      'Your household data has been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'Restore Household Ledger';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current duty history. Continue?';

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
  String get voiceSectionTitle => 'House Voice';
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Household Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Household Ledger';
  @override
  String get importBackupButton => 'Import Household Ledger';
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
      'The ledger could not be saved. Your data is unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your household ledger has been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your data is unchanged.';
  @override
  String get aboutTagline => 'Your household, impeccably managed';
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
  String get aboutWebsiteDialogAction => 'Very Good';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Household Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for your household duties.';
  @override
  String notificationTitle(String choreName) =>
      'A Gentle Reminder: $choreName';
  @override
  String get notificationBody =>
      'Pardon the intrusion, but this duty requires your attention.';
  @override
  String get notificationCompleteAction => 'ATTEND TO';

  // Common
  @override
  String get archiveAction => 'Shelve';
  @override
  String get deleteAction => 'Expunge';
  @override
  String lastCompletedLabel(String date) => 'Last attended to: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get iconPickerNoneLabel => 'None';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'Very Good';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'A New Duty';
  @override
  String get shortcutOverdueLabel => 'Awaiting Attention';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Awaiting Attention: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Ledger Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically saves a copy of the household ledger daily.';
  @override
  String autoBackupDestinationLabel(String path) => 'Ledger path: $path';
  @override
  String get autoBackupNeverLabel => 'No ledger backups yet';
  @override
  String autoBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get autoBackupNowButton => 'Back Up Ledger Now';
  @override
  String get autoBackupNowSuccessTitle => 'Ledger Saved';
  @override
  String get autoBackupNowSuccessMessage =>
      'Your household ledger has been backed up.';
  @override
  String get autoBackupNowFailedTitle => 'Backup Failed';
  @override
  String get autoBackupNowFailedMessage =>
      'Ledger backup failed. Try again in a moment.';

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Perhaps later';
  @override
  String choreSnoozedUntil(String date) => 'Duty postponed until $date';
  @override
  String get notificationSnoozeAction => 'PERHAPS LATER';
  @override
  String get duplicateAction => 'Duplicate Duty';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Postpone Duty';
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
  String voiceChoreAddedMessage(String choreName) => 'Recorded duty: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Duty attended to: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A duty named '$choreName' already exists in the ledger.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No duty matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple duties match '$choreName' -- please specify.";
  @override
  String get voiceCommandInvalidMessage =>
      'Pardon, command not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No duties recorded yet — tap to open Household Records';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_dutiesCount(count)} this week — your first week!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_dutiesCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_dutiesCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_dutiesCount(count)} this week — same as last';
  @override
  String streakChipLabel(int streak) => '$streak duties in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count duties logged';
  @override
  String cadenceLinePlain(int days) => 'Typically attended to every ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typically attended to every ~$days days · on schedule';
  @override
  String cadenceLineBehind(int days) =>
      'Typically attended to every ~$days days · running behind';
  @override
  String get missionLogTitle => 'The Household Records';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'duties';
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

  static String _dutiesCount(int count) =>
      count == 1 ? '1 duty' : '$count duties';
}
