import 'app_strings.dart';

/// Noir Detective voice (spec 25).
class NoirStrings implements AppStrings {
  const NoirStrings();

  @override
  String get appTitle => 'Noir Detective';

  @override
  String get voiceSignature => 'Quiet night. Too quiet.';

  // Tabs & Navigation
  @override
  String get tabChores => 'Open Cases';
  @override
  String get tabArchive => 'Case Files';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Open Cases';
  @override
  String get searchPlaceholder => 'Search case files...';
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
  String get emptyActiveTitle => 'Quiet Night';
  @override
  String get emptyActiveDescription => 'Quiet night. Too quiet.';
  @override
  String get emptyFilterTitle => 'No Cases Found';
  @override
  String get emptyFilterDescription =>
      'No open cases match your current filters. Keep searching.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'Cold Cases';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Upcoming Cases';
  @override
  String get sectionUnscheduledLabel => 'Unfiled Cases';

  // Archive Screen
  @override
  String get archiveTitle => 'Case Files';
  @override
  String get emptyArchiveTitle => 'Case Files';
  @override
  String get emptyArchiveDescription =>
      'No case files in the cabinet. Closed cases will be filed here.';
  @override
  String get restoreChore => 'Reopen';
  @override
  String get restoreDialogTitle => 'Reopen Case';
  @override
  String restoreDialogMessage(String choreName) =>
      "Reopen case '$choreName' and put it back on the active board?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'New Case';
  @override
  String get editChoreTitle => 'Edit Case';
  @override
  String get nameLabel => 'Case Title / Chore Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this case's card";
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule a due date for this case';
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
  String get missionReminder => 'Case Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for this case';
  @override
  String get saveChore => 'File Case';
  @override
  String get completionHistory => 'Case History';
  @override
  String get emptyHistoryTitle => 'No Evidence Logged';
  @override
  String get emptyHistoryDescription =>
      'This case has no recorded history. Close your first case to start building the file.';
  @override
  String get registryConflictTitle => 'Case Already Open';
  @override
  String get registryConflictMessage =>
      'A case with this title already exists. Pick another title.';
  @override
  String get expungeRecordTitle => 'Burn Entry';
  @override
  String get expungeRecordMessage =>
      'Burn this entry from the case history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Burn Entry';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Case File Missing';
  @override
  String get choreNotFoundMessage => 'This case file could not be located.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'CASE REPORT';
  @override
  String get completionTimeLabel => 'Closed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'CLOSE CASE';
  @override
  String get abortButton => 'DROP IT';
  @override
  String get choreCompleted => 'Case closed.';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Close Case';
  @override
  String decommissionMessage(String choreName) =>
      "Archive case '$choreName' and move it off the active board?";
  @override
  String get decommissionConfirm => 'File Away';
  @override
  String get scrapTitle => 'Burn Case File';
  @override
  String scrapMessage(String choreName) =>
      "Are you sure you want to burn '$choreName' and erase all evidence? This action cannot be undone.";
  @override
  String get scrapConfirm => 'Burn the File';
  @override
  String get purgeTitle => 'Burn All Closed Files?';
  @override
  String get purgeMessage =>
      'This will permanently burn all closed case files. Erase these records?';
  @override
  String get purgeConfirm => 'Burn All Files';
  @override
  String get wipeAllChoresButton => 'Burn Every File';
  @override
  String get wipeAllChoresTitle => 'Burn All Case Files?';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently burn every case file -- open and closed alike -- along with all evidence and history. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Burn Everything';

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
      "You haven't created any tags yet. Use the fields above to categorize your cases.";
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
      "Removing '$tagName' will remove it from all cases it's attached to. Continue?";
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
  String get intelSecuredTitle => 'Evidence Saved';
  @override
  String get intelSecuredMessage =>
      'Your case files have been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'Restore Case Files';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current case history. Continue?';

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
  String get voiceSectionTitle => 'The Narrator';
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Case Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Case Files';
  @override
  String get importBackupButton => 'Import Case Files';
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
      'The case files could not be saved. Your data is unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your case files have been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your data is unchanged.';
  @override
  String get aboutTagline => 'Just another rainy night in the city';
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
  String get aboutWebsiteDialogAction => 'Understood';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Case Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for your open cases.';
  @override
  String notificationTitle(String choreName) => 'Case update: $choreName';
  @override
  String get notificationBody => 'Time to work the case.';
  @override
  String get notificationCompleteAction => 'CLOSE CASE';

  // Common
  @override
  String get archiveAction => 'Archive';
  @override
  String get deleteAction => 'Burn File';
  @override
  String lastCompletedLabel(String date) => 'Last closed: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get iconPickerNoneLabel => 'None';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'Understood';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'New Case';
  @override
  String get shortcutOverdueLabel => 'Cold Cases';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Cold Case: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Case File Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically archives open and closed case files daily.';
  @override
  String autoBackupDestinationLabel(String path) => 'Archive path: $path';
  @override
  String get autoBackupNeverLabel => 'No case backups yet';
  @override
  String autoBackupAtLabel(String date) => 'Last case backup: $date';
  @override
  String get autoBackupNowButton => 'Back Up Cases Now';
  @override
  String get autoBackupNowSuccessTitle => 'Cases Archived';
  @override
  String get autoBackupNowSuccessMessage =>
      'Your case files have been archived.';
  @override
  String get autoBackupNowFailedTitle => 'Archive Failed';
  @override
  String get autoBackupNowFailedMessage =>
      'Case backup failed. Try again in a moment.';

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Not Tonight';
  @override
  String choreSnoozedUntil(String date) => 'Case shelved until $date';
  @override
  String get notificationSnoozeAction => 'NOT TONIGHT';
  @override
  String get duplicateAction => 'Duplicate Case';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Shelve Case';
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
  String voiceChoreAddedMessage(String choreName) => 'Filed case: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Case closed: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A case named '$choreName' already exists.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No open case matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple cases match '$choreName' -- specify title.";
  @override
  String get voiceCommandInvalidMessage => 'Statement not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No cases closed yet — tap to open Case History';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_casesCount(count)} this week — your first week on the beat!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_casesCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_casesCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_casesCount(count)} this week — same as last';
  @override
  String streakChipLabel(int streak) => '$streak cases in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count cases closed';
  @override
  String cadenceLinePlain(int days) => 'Typically closed every ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typically closed every ~$days days · on schedule';
  @override
  String cadenceLineBehind(int days) =>
      'Typically closed every ~$days days · running behind';
  @override
  String get missionLogTitle => 'Case History';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'cases';
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

  static String _casesCount(int count) =>
      count == 1 ? '1 case' : '$count cases';
}
