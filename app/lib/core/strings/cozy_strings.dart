import 'app_strings.dart';

/// Cozy Cottage voice (spec 25). Gentle, warm, no shouting, tasteful 🌿/🫖.
class CozyStrings implements AppStrings {
  const CozyStrings();

  @override
  String get appTitle => 'Cozy Cottage';

  @override
  String get voiceSignature => 'Resting is just as important as doing. 🫖';

  // Tabs & Navigation
  @override
  String get tabChores => 'Little Tasks';
  @override
  String get tabArchive => 'Resting';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Little Tasks';
  @override
  String get searchPlaceholder => 'Search little tasks... 🌿';
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
  String get emptyActiveTitle => 'All Is Peaceful';
  @override
  String get emptyActiveDescription =>
      'No little tasks need your attention right now. Take a sip of tea and rest 🫖';
  @override
  String get emptyFilterTitle => 'No Tasks Found';
  @override
  String get emptyFilterDescription =>
      'No little tasks match your current filters. Adjust your filters to see more.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'Waiting patiently 🌿';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Coming Up';
  @override
  String get sectionUnscheduledLabel => "Whenever You're Ready";

  // Archive Screen
  @override
  String get archiveTitle => 'Resting';
  @override
  String get emptyArchiveTitle => 'Resting';
  @override
  String get emptyArchiveDescription =>
      'No resting tasks right now. Tasks you put away will stay cozy here.';
  @override
  String get restoreChore => 'Awaken';
  @override
  String get restoreDialogTitle => 'Awaken Task';
  @override
  String restoreDialogMessage(String choreName) =>
      "Bring '$choreName' back to your active little tasks?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'Add a little task';
  @override
  String get editChoreTitle => 'Edit little task';
  @override
  String get nameLabel => 'Task Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this task's card";
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule a due date for this task';
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
  String get scheduleReminderHint => 'Schedule a gentle reminder for this task';
  @override
  String get saveChore => 'Save Little Task';
  @override
  String get completionHistory => 'Completion History';
  @override
  String get emptyHistoryTitle => 'A Fresh Start 🌿';
  @override
  String get emptyHistoryDescription =>
      'This task has no recorded history yet. Complete it once to begin tracking.';
  @override
  String get registryConflictTitle => 'Task Already Exists';
  @override
  String get registryConflictMessage =>
      'A task with this name already exists. Please pick a different name.';
  @override
  String get expungeRecordTitle => 'Remove Entry';
  @override
  String get expungeRecordMessage =>
      'Remove this entry from history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Remove';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Task Not Found';
  @override
  String get choreNotFoundMessage => 'This task could not be found.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'A LITTLE PROGRESS';
  @override
  String get completionTimeLabel => 'Completed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'Done 🫖';
  @override
  String get abortButton => 'Later';
  @override
  String get choreCompleted => 'Lovely.';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Put Away Task';
  @override
  String decommissionMessage(String choreName) =>
      "Move '$choreName' to resting? It will gently step back from your active list.";
  @override
  String get decommissionConfirm => 'Put Away';
  @override
  String get scrapTitle => 'Remove Task';
  @override
  String scrapMessage(String choreName) =>
      "Are you sure you want to completely remove '$choreName'? It will be gently erased.";
  @override
  String get scrapConfirm => 'Remove';
  @override
  String get purgeTitle => 'Clear All Resting Tasks?';
  @override
  String get purgeMessage =>
      'This will permanently remove all resting tasks. Erase these records?';
  @override
  String get purgeConfirm => 'Remove All';
  @override
  String get wipeAllChoresButton => 'Remove All Tasks';
  @override
  String get wipeAllChoresTitle => 'Clear All Tasks?';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently remove every task -- active and resting alike -- along with history and reminders. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Remove Everything';

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
  String get tagTooLongMessage => 'Please use a shorter tag name.';
  @override
  String get tagConflictTitle => 'Tag Already Exists';
  @override
  String get tagConflictMessage => 'A tag with this name already exists.';
  @override
  String get scrubTagTitle => 'Remove Tag';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will remove it from all tasks it's attached to. Continue?";
  @override
  String get scrubTagConfirm => 'Remove';
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
  String get intelSecuredTitle => 'Progress Saved';
  @override
  String get intelSecuredMessage =>
      'Your task data has been saved to a backup file.';
  @override
  String get restoreArchivesTitle => 'Restore Tasks';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing a backup will overwrite your current task history. Continue?';

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
  String get notificationsToggleTitle => 'Gentle Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Export Tasks';
  @override
  String get importBackupButton => 'Import Tasks';
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
      'The backup could not be saved. Your tasks remain unchanged.';
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your backup has been restored successfully.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your tasks are unchanged.';
  @override
  String get aboutTagline => 'Resting is just as important as doing 🫖';
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
  String get aboutWebsiteDialogAction => 'Lovely';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Gentle Alerts';
  @override
  String get notificationChannelDescription =>
      'Gentle reminders for your active tasks.';
  @override
  String notificationTitle(String choreName) =>
      'A gentle reminder: $choreName 🌿';
  @override
  String get notificationBody =>
      'Whenever you have a quiet moment, this little task awaits.';
  @override
  String get notificationCompleteAction => 'COMPLETE';

  // Common
  @override
  String get archiveAction => 'Rest';
  @override
  String get deleteAction => 'Remove';
  @override
  String lastCompletedLabel(String date) => 'Last done: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'Lovely';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'Add a Little Task';
  @override
  String get shortcutOverdueLabel => 'Waiting Patiently';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Waiting Patiently: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Gently saves a backup of your tasks every day.';
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
      'Your tasks have been safely backed up.';
  @override
  String get autoBackupNowFailedTitle => 'Backup Failed';
  @override
  String get autoBackupNowFailedMessage =>
      "The backup didn't go through. Try again in a moment.";

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Rest Until Tomorrow';
  @override
  String get choreSnoozed => 'Tucked away until tomorrow 🫖';
  @override
  String get notificationSnoozeAction => 'REST UNTIL TOMORROW';
  @override
  String get duplicateAction => 'Duplicate Task';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Tuck Away Task';
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
      'Added little task: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Completed task: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A task named '$choreName' already exists.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No task matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple tasks match '$choreName' -- please specify.";
  @override
  String get voiceCommandInvalidMessage =>
      'Voice command not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No tasks completed yet — tap to open The Almanac';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_tasksCount(count)} this week — your first week!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_tasksCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_tasksCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_tasksCount(count)} this week — same as last';
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
  String get missionLogTitle => 'The Almanac';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'tasks';
  @override
  String missionLogBestStreakLabel(String choreName, int streak) =>
      'Best streak: $streak — $choreName';
  @override
  String get missionLogLastFiveWeeksTitle => 'Last 5 Weeks';
  @override
  String get missionLogThisMonthTitle => 'This Month';

  static String _tasksCount(int count) =>
      count == 1 ? '1 task' : '$count tasks';
}
