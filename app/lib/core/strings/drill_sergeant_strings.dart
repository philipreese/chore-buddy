import 'app_strings.dart';

/// Drill Sergeant voice (spec 25). Bark in titles, clarity in messages.
class DrillSergeantStrings implements AppStrings {
  const DrillSergeantStrings();

  @override
  String get appTitle => 'Drill Sergeant';

  @override
  String get voiceSignature => 'NOTHING TO DO? DROP AND GIVE ME TWENTY.';

  // Tabs & Navigation
  @override
  String get tabChores => 'TASK LIST';
  @override
  String get tabArchive => 'DISCHARGED';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'TASK LIST';
  @override
  String get searchPlaceholder => 'SEARCH ORDERS...';
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
  String get emptyActiveTitle => 'NO ACTIVE ORDERS';
  @override
  String get emptyActiveDescription =>
      'NOTHING TO DO? DROP AND GIVE ME TWENTY.';
  @override
  String get emptyFilterTitle => 'NO TASKS FOUND';
  @override
  String get emptyFilterDescription =>
      'No active orders match your current filters. Adjust your filters to report for duty.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'OVERDUE! MOVE IT!';
  @override
  String get sectionTodayLabel => 'DUE TODAY';
  @override
  String get sectionUpcomingLabel => 'UPCOMING TASKS';
  @override
  String get sectionUnscheduledLabel => 'UNSCHEDULED';

  // Archive Screen
  @override
  String get archiveTitle => 'DISCHARGED';
  @override
  String get emptyArchiveTitle => 'DISCHARGED';
  @override
  String get emptyArchiveDescription =>
      'NO DISCHARGED TASKS ON RECORD. COMPLETED TASKS STAY ON FILE.';
  @override
  String get restoreChore => 'REENLIST';
  @override
  String get restoreDialogTitle => 'REENLIST TASK';
  @override
  String restoreDialogMessage(String choreName) =>
      "Reenlist '$choreName' back to active duty?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'NEW ORDERS';
  @override
  String get editChoreTitle => 'EDIT ORDERS';
  @override
  String get nameLabel => 'Task Name / Orders';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this task's card";
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule a due date for these orders';
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
  String get missionReminder => 'Task Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for these orders';
  @override
  String get saveChore => 'CONFIRM ORDERS';
  @override
  String get completionHistory => 'Service History';
  @override
  String get emptyHistoryTitle => 'NO RECORD YET';
  @override
  String get emptyHistoryDescription =>
      'This task has no service history. Complete your first task to log it on file.';
  @override
  String get registryConflictTitle => 'TASK ALREADY EXISTS';
  @override
  String get registryConflictMessage =>
      'A task with this name is already on the duty roster. Pick another name.';
  @override
  String get expungeRecordTitle => 'WIPE RECORD ENTRY';
  @override
  String get expungeRecordMessage =>
      'Delete this entry from the service history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Wipe';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'TASK NOT FOUND';
  @override
  String get choreNotFoundMessage =>
      'This task could not be located on the duty roster.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'INSPECTION REPORT';
  @override
  String get completionTimeLabel => 'Completed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'DONE!';
  @override
  String get abortButton => 'DISMISS';
  @override
  String get choreCompleted => 'OUTSTANDING!';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'DISCHARGE TASK';
  @override
  String decommissionMessage(String choreName) =>
      "Move '$choreName' to discharged status? It will be removed from active orders.";
  @override
  String get decommissionConfirm => 'DISCHARGE';
  @override
  String get scrapTitle => 'DISHONORABLE DISCHARGE';
  @override
  String scrapMessage(String choreName) =>
      "Permanently wipe '$choreName' and all service history? No excuses, this action cannot be undone!";
  @override
  String get scrapConfirm => 'WIPE TASK';
  @override
  String get purgeTitle => 'PURGE DISCHARGED TASKS?';
  @override
  String get purgeMessage =>
      'This will permanently delete all discharged tasks on file. Erase these records?';
  @override
  String get purgeConfirm => 'PURGE ALL';
  @override
  String get wipeAllChoresButton => 'WIPE ENTIRE ROSTER';
  @override
  String get wipeAllChoresTitle => 'WIPE ENTIRE ROSTER?';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently erase every task -- active and discharged alike -- along with history and reminders. This action cannot be undone!';
  @override
  String get wipeAllChoresConfirm => 'WIPE EVERYTHING';

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
      "You haven't created any tags yet. Use the fields above to organize your tasks.";
  @override
  String get tagTooLongTitle => 'Tag Too Long';
  @override
  String get tagTooLongMessage => 'Use a shorter tag name. That is an order.';
  @override
  String get tagConflictTitle => 'Tag Already Exists';
  @override
  String get tagConflictMessage => 'A tag with this name already exists.';
  @override
  String get scrubTagTitle => 'Scrub Tag';
  @override
  String scrubTagMessage(String tagName) =>
      "Scrubbing '$tagName' will remove it from all tasks it's attached to. Proceed?";
  @override
  String get scrubTagConfirm => 'Scrub Tag';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'DELETE ALL TAGS?';
  @override
  String get deleteAllTagsMessage =>
      'Are you sure you want to delete ALL tags? This action cannot be undone!';
  @override
  String get deleteAllTagsConfirm => 'YES, DELETE EVERYTHING';
  @override
  String get intelSecuredTitle => 'DATA SECURED';
  @override
  String get intelSecuredMessage =>
      'Your task data has been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'RESTORE ROSTER';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current service history. Proceed?';

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
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Duty Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Data';
  @override
  String get importBackupButton => 'Import Data';
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
      'Data could not be saved. Your roster remains unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your duty roster has been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your roster is unchanged.';
  @override
  String get aboutTagline => 'DROP AND GIVE ME TWENTY!';
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
  String get aboutWebsiteDialogAction => 'SIR YES SIR!';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Duty Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for your active tasks.';
  @override
  String notificationTitle(String choreName) => 'ATTENTION: $choreName';
  @override
  String get notificationBody =>
      'DROP WHAT YOU ARE DOING AND EXECUTE THIS TASK!';
  @override
  String get notificationCompleteAction => 'EXECUTE';

  // Common
  @override
  String get archiveAction => 'Discharge';
  @override
  String get deleteAction => 'Wipe Task';
  @override
  String lastCompletedLabel(String date) => 'Last executed: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'SIR YES SIR!';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'NEW ORDERS';
  @override
  String get shortcutOverdueLabel => 'OVERDUE!';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'OVERDUE: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Auto-Backup Roster';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically backs up your duty roster every day.';
  @override
  String autoBackupDestinationLabel(String path) => 'Backup path: $path';
  @override
  String get autoBackupNeverLabel => 'No backups on record';
  @override
  String autoBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get autoBackupNowButton => 'BACK UP ROSTER NOW';
  @override
  String get autoBackupNowSuccessTitle => 'ROSTER SECURED';
  @override
  String get autoBackupNowSuccessMessage =>
      'Your duty roster has been backed up.';
  @override
  String get autoBackupNowFailedTitle => 'BACKUP FAILED';
  @override
  String get autoBackupNowFailedMessage =>
      'Backup failed. Try again immediately!';

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'STAND DOWN';
  @override
  String get choreSnoozed => 'Task deferred to tomorrow';
  @override
  String get notificationSnoozeAction => 'STAND DOWN';
  @override
  String get duplicateAction => 'DUPLICATE TASK';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'DEFER ORDERS';
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
      'ORDERS RECEIVED: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'TASK EXECUTED: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A task named '$choreName' is already on roster!";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No active task matches '$choreName'!";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple tasks match '$choreName' -- BE SPECIFIC!";
  @override
  String get voiceCommandInvalidMessage =>
      'COMMAND NOT UNDERSTOOD! REPEAT!';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'NO TASKS LOGGED YET — REPORT TO AFTER-ACTION REPORT';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_tasksCount(count)} this week — YOUR FIRST WEEK ON DUTY!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_tasksCount(count)} this week — $delta MORE THAN LAST!';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_tasksCount(count)} this week — $delta FEWER THAN LAST!';
  @override
  String bannerStatsSame(int count) =>
      '${_tasksCount(count)} this week — SAME AS LAST!';
  @override
  String streakChipLabel(int streak) => '$streak tasks in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count logged';
  @override
  String cadenceLinePlain(int days) => 'Typically executed every ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typically executed every ~$days days · ON SCHEDULE';
  @override
  String cadenceLineBehind(int days) =>
      'Typically executed every ~$days days · FALLING BEHIND!';
  @override
  String get missionLogTitle => 'AFTER-ACTION REPORT';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'tasks';
  @override
  String missionLogBestStreakLabel(String choreName, int streak) =>
      'BEST STREAK: $streak — $choreName';
  @override
  String get missionLogLastFiveWeeksTitle => 'Last 5 Weeks';
  @override
  String get missionLogThisMonthTitle => 'This Month';

  static String _tasksCount(int count) =>
      count == 1 ? '1 task' : '$count tasks';
}
