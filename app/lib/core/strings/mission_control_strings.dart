import 'app_strings.dart';

/// NASA / spaceflight voice (spec 25).
class MissionControlStrings implements AppStrings {
  const MissionControlStrings();

  @override
  String get appTitle => 'Mission Control';

  @override
  String get voiceSignature => 'Go for launch.';

  // Tabs & Navigation
  @override
  String get tabChores => 'Flight Plan';
  @override
  String get tabArchive => 'Decommissioned';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Flight Plan';
  @override
  String get searchPlaceholder => 'Search flight plan...';
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
  String get emptyActiveTitle => 'Holding at T-minus Zero';
  @override
  String get emptyActiveDescription =>
      'No payloads currently scheduled for launch. Tap the + to add a mission.';
  @override
  String get emptyFilterTitle => 'No Flight Plans Found';
  @override
  String get emptyFilterDescription =>
      'No flight plans match your current filters. Try adjusting them.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'Past Launch Window';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Upcoming Launches';
  @override
  String get sectionUnscheduledLabel => 'Unscheduled';

  // Archive Screen
  @override
  String get archiveTitle => 'Decommissioned';
  @override
  String get emptyArchiveTitle => 'Decommissioned';
  @override
  String get emptyArchiveDescription =>
      'There are no decommissioned flight plans here. Payloads set aside will show up in this registry.';
  @override
  String get restoreChore => 'Re-launch';
  @override
  String get restoreDialogTitle => 'Re-activate Flight Plan';
  @override
  String restoreDialogMessage(String choreName) =>
      "Re-activate '$choreName' into active flight plans?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'Schedule Launch';
  @override
  String get editChoreTitle => 'Edit Flight Plan';
  @override
  String get nameLabel => 'Mission / Chore Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add launch date';
  @override
  String get scheduleDueDateHint => 'Schedule a launch date for this mission';
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
  String get missionReminder => 'Launch Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for this launch';
  @override
  String get saveChore => 'Schedule Launch';
  @override
  String get completionHistory => 'Flight Log';
  @override
  String get emptyHistoryTitle => 'No Flight Log Yet';
  @override
  String get emptyHistoryDescription =>
      'This mission has no recorded launch history. Log your first completion to start tracking telemetry.';
  @override
  String get registryConflictTitle => 'Mission Name Conflict';
  @override
  String get registryConflictMessage =>
      'A mission with this name is already registered. Choose a different callsign.';
  @override
  String get expungeRecordTitle => 'Delete Telemetry Entry';
  @override
  String get expungeRecordMessage =>
      'Remove this entry from the flight log? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Delete';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Payload Not Found';
  @override
  String get choreNotFoundMessage => 'This flight plan could not be located.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'LAUNCH REPORT';
  @override
  String get completionTimeLabel => 'Launch Time';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'LAUNCH';
  @override
  String get abortButton => 'ABORT';
  @override
  String get choreCompleted => 'Mission success';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Decommission Payload';
  @override
  String decommissionMessage(String choreName) =>
      "Decommission '$choreName'? It will be removed from active flight plans.";
  @override
  String get decommissionConfirm => 'Decommission';
  @override
  String get scrapTitle => 'Scrap Payload';
  @override
  String scrapMessage(String choreName) =>
      "Are you sure you want to permanently scrap '$choreName' and erase all telemetry? This action cannot be undone.";
  @override
  String get scrapConfirm => 'Scrap Payload';
  @override
  String get purgeTitle => 'Scrap All Decommissioned Payloads?';
  @override
  String get purgeMessage =>
      'This will permanently delete all decommissioned flight plans. Erase these records?';
  @override
  String get purgeConfirm => 'Scrap All';
  @override
  String get wipeAllChoresButton => 'Scrap All Flight Plans';
  @override
  String get wipeAllChoresTitle => 'Scrap Entire Registry?';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently delete every flight plan -- active and decommissioned alike -- along with telemetry and reminders. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Scrap Everything';

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
      "You haven't created any tags yet. Use the fields above to categorize your flight plans.";
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
      "Removing '$tagName' will remove it from all flight plans it's attached to. Continue?";
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
  String get intelSecuredTitle => 'Telemetry Saved';
  @override
  String get intelSecuredMessage =>
      'Your mission data has been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'Restore Telemetry';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current flight log. Continue?';

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
  String get voiceSectionTitle => 'Comms Voice';
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Mission Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Telemetry';
  @override
  String get importBackupButton => 'Import Telemetry';
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
      'The telemetry could not be saved. Your data is unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your telemetry has been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The telemetry file is corrupted or incompatible. Your data is unchanged.';
  @override
  String get aboutTagline => 'Houston, we have a chore tracker';
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
  String get aboutWebsiteDialogAction => 'Roger';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Mission Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for your active flight plans.';
  @override
  String notificationTitle(String choreName) => 'Mission update: $choreName';
  @override
  String get notificationBody => 'T-minus zero: time to launch.';
  @override
  String get notificationCompleteAction => 'LAUNCH';

  // Common
  @override
  String get archiveAction => 'Decommission';
  @override
  String get deleteAction => 'Scrap';
  @override
  String lastCompletedLabel(String date) => 'Last launch: $date';
  @override
  String dueLabel(String date) => 'Launch window: $date';
  @override
  String genericError(Object error) => 'Telemetry error: $error';
  @override
  String get iconPickerNoneLabel => 'None';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'Go For Launch';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'Schedule Launch';
  @override
  String get shortcutOverdueLabel => 'Holding T-Minus';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Holding T-Minus: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Telemetry Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically archives flight plans and telemetry daily.';
  @override
  String autoBackupDestinationLabel(String path) => 'Archive path: $path';
  @override
  String get autoBackupNeverLabel => 'No telemetry backups yet';
  @override
  String autoBackupAtLabel(String date) => 'Last telemetry backup: $date';
  @override
  String get autoBackupNowButton => 'Back Up Telemetry Now';
  @override
  String get autoBackupNowSuccessTitle => 'Telemetry Archived';
  @override
  String get autoBackupNowSuccessMessage =>
      'Flight plans and telemetry have been archived.';
  @override
  String get autoBackupNowFailedTitle => 'Archive Failed';
  @override
  String get autoBackupNowFailedMessage =>
      'Telemetry backup failed. Try again in a moment.';

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Holding at T-minus…';
  @override
  String choreSnoozedUntil(String date) => 'Launch held until $date';
  @override
  String get notificationSnoozeAction => 'HOLD LAUNCH';
  @override
  String get duplicateAction => 'Duplicate Flight Plan';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Hold Launch';
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
  String voiceChoreAddedMessage(String choreName) =>
      'Scheduled launch: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Mission success: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A flight plan named '$choreName' already exists.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No flight plan matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple flight plans match '$choreName' -- specify callsign.";
  @override
  String get voiceCommandInvalidMessage => 'Transmission not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No launches logged yet — tap to open Flight Log';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_launchesCount(count)} this week — first week operational!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_launchesCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_launchesCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_launchesCount(count)} this week — same as last';
  @override
  String streakChipLabel(int streak) => '$streak launches in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count launches';
  @override
  String cadenceLinePlain(int days) => 'Typical launch interval: ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typical launch interval: ~$days days · on schedule';
  @override
  String cadenceLineBehind(int days) =>
      'Typical launch interval: ~$days days · launch delayed';
  @override
  String get missionLogTitle => 'Flight Log';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'launches';
  @override
  String missionLogBestStreakLabel(String choreName, int streak) =>
      'Longest streak: $streak — $choreName';
  @override
  String get missionLogLastFiveWeeksTitle => 'Last 5 Weeks';
  @override
  String get missionLogThisMonthTitle => 'This Month';
  @override
  String get missionLogChartNowLabel => 'Now';
  @override
  String missionLogChartWeeksAgoLabel(int weeks) => '-${weeks}w';

  static String _launchesCount(int count) =>
      count == 1 ? '1 launch' : '$count launches';
}
