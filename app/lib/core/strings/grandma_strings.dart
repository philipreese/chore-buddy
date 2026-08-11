import 'app_strings.dart';

/// Grandma voice (spec 25). Loving passive-aggression, guilt as garnish.
class GrandmaStrings implements AppStrings {
  const GrandmaStrings();

  @override
  String get appTitle => "Grandma's House";

  @override
  String get voiceSignature =>
      "Sweetheart, the house isn't going to clean itself.";

  // Tabs & Navigation
  @override
  String get tabChores => "Things You've Been Meaning To Do";
  @override
  String get tabArchive => 'The Pile';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => "Things You've Been Meaning To Do";
  @override
  String get searchPlaceholder => 'Search your chores, dear...';
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
  String get emptyActiveTitle => 'Look At You, All Done';
  @override
  String get emptyActiveDescription =>
      "You actually finished everything? I'm shocked. Tap + before you get lazy again.";
  @override
  String get emptyFilterTitle => 'No Chores Found';
  @override
  String get emptyFilterDescription =>
      "None of your chores match those filters, dear. Try changing them.";

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => "Still Haven't Done These";
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => "Don't Forget These";
  @override
  String get sectionUnscheduledLabel => 'Someday, Maybe';

  // Archive Screen
  @override
  String get archiveTitle => 'The Pile';
  @override
  String get emptyArchiveTitle => 'The Pile';
  @override
  String get emptyArchiveDescription =>
      "Nothing in the pile yet. I suppose that's something.";
  @override
  String get restoreChore => 'Bring Back';
  @override
  String get restoreDialogTitle => 'Bring Back Chore';
  @override
  String restoreDialogMessage(String choreName) =>
      "Oh, so now you want '$choreName' back on your list?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'Another one?';
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
  String get scheduleDueDateHint => 'Schedule a due date for this chore';
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
  String get missionReminder => 'Chore Reminder';
  @override
  String get scheduleReminderHint => 'Schedule a reminder for this chore';
  @override
  String get saveChore => 'Add to the List';
  @override
  String get completionHistory => 'Completion History';
  @override
  String get emptyHistoryTitle => 'No Record Yet';
  @override
  String get emptyHistoryDescription =>
      "You haven't finished this even once yet, sweetheart. Log it when you finally do.";
  @override
  String get registryConflictTitle => 'Chore Already Exists';
  @override
  String get registryConflictMessage =>
      "You've already got a chore with that name, dear. Try another one.";
  @override
  String get expungeRecordTitle => 'Delete Entry';
  @override
  String get expungeRecordMessage =>
      'Remove this entry from the record? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Delete';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Chore Not Found';
  @override
  String get choreNotFoundMessage => 'I couldn\'t find that chore anywhere, dear.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'FINALLY DONE';
  @override
  String get completionTimeLabel => 'Completed At';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'FINALLY';
  @override
  String get abortButton => 'NEVERMIND';
  @override
  String get choreCompleted => 'Well, finally.';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Put In The Attic';
  @override
  String decommissionMessage(String choreName) =>
      "Put '$choreName' up in the attic for now? I knew you'd get tired of it.";
  @override
  String get decommissionConfirm => 'Put Away';
  @override
  String get scrapTitle => 'Throw Out Chore';
  @override
  String scrapMessage(String choreName) =>
      "Throw out '$choreName' for good? Don't come crying to me when you need it later!";
  @override
  String get scrapConfirm => 'Throw Out';
  @override
  String get purgeTitle => 'Throw Out All Archived Chores?';
  @override
  String get purgeMessage =>
      "This will permanently throw out everything in the pile. Are you sure, dear?";
  @override
  String get purgeConfirm => 'Throw Out All';
  @override
  String get wipeAllChoresButton => 'Throw Out All Chores';
  @override
  String get wipeAllChoresTitle => 'Throw Out Every Single Chore?';
  @override
  String get wipeAllChoresMessage =>
      "This will permanently erase every chore you have -- active and archived -- along with their history. Don't say I didn't warn you!";
  @override
  String get wipeAllChoresConfirm => 'Throw Out Everything';

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
      "You haven't created any tags yet, dear. Use the fields above to organize things.";
  @override
  String get tagTooLongTitle => 'Tag Too Long';
  @override
  String get tagTooLongMessage => 'That tag name is much too long, sweetheart.';
  @override
  String get tagConflictTitle => 'Tag Already Exists';
  @override
  String get tagConflictMessage => 'You already have a tag with that name.';
  @override
  String get scrubTagTitle => 'Delete Tag';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will take it off all your chores. Continue, dear?";
  @override
  String get scrubTagConfirm => 'Delete';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'Delete All Tags?';
  @override
  String get deleteAllTagsMessage =>
      'Are you sure you want to delete ALL tags? This cannot be undone!';
  @override
  String get deleteAllTagsConfirm => 'Yes, Delete Everything';
  @override
  String get intelSecuredTitle => 'Backup Saved';
  @override
  String get intelSecuredMessage =>
      'Your chores have been safely backed up.';
  @override
  String get restoreArchivesTitle => 'Restore Backup';
  @override
  String get restoreArchivesMessage =>
      'Warning: Restoring this backup will replace your current chores. Continue?';

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
  String get voiceSectionTitle => "Who's Talking";
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Tags';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Reminders';
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
      "The backup couldn't be saved, dear. Your data is unchanged.";
  @override
  String get restoreSuccessTitle => 'Restore Complete';
  @override
  String get restoreSuccessMessage =>
      'Your backup has been restored successfully, sweetheart.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'That backup file doesn\'t look right. Your data is unchanged.';
  @override
  String get aboutTagline =>
      'Sweetheart, the house isn\'t going to clean itself.';
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
  String get aboutWebsiteDialogAction => 'If You Say So';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Grandma\'s Reminders';
  @override
  String get notificationChannelDescription =>
      'Reminders for your unfinished chores.';
  @override
  String notificationTitle(String choreName) =>
      "Sweetheart, the $choreName isn't going to do itself.";
  @override
  String get notificationBody =>
      "I've been waiting all day for you to handle this.";
  @override
  String get notificationCompleteAction => 'FINALLY';

  // Common
  @override
  String get archiveAction => 'Put Away';
  @override
  String get deleteAction => 'Throw Out';
  @override
  String lastCompletedLabel(String date) => 'Last done: $date';
  @override
  String dueLabel(String date) => 'Due: $date';
  @override
  String genericError(Object error) => 'Error: $error';
  @override
  String get iconPickerNoneLabel => 'None';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'If You Say So';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'Another One?';
  @override
  String get shortcutOverdueLabel => 'Still Haven\'t Done';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Still Haven\'t Done: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'Automatically backs up your chores every day so you don\'t lose them.';
  @override
  String autoBackupDestinationLabel(String path) => 'Backup path: $path';
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
      'Your chores have been backed up, dear.';
  @override
  String get autoBackupNowFailedTitle => 'Backup Failed';
  @override
  String get autoBackupNowFailedMessage =>
      "The backup didn't go through. Try again in a moment.";

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Put It Off';
  @override
  String choreSnoozedUntil(String date) => 'Pushed off until $date... as expected.';
  @override
  String get notificationSnoozeAction => 'PUT IT OFF';
  @override
  String get duplicateAction => 'Duplicate Chore';

  // Snooze picker (spec 20)
  @override
  String get snoozeSheetTitle => 'Push It Off';
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
      'Added to the list: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) =>
      'Well, finally: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "You already have '$choreName' on your list, dear.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "I couldn't find '$choreName' on your list.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Which '$choreName' do you mean, sweetheart? Be specific.";
  @override
  String get voiceCommandInvalidMessage =>
      'I didn\'t catch that, dear.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No chores completed yet — tap to check The Record';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_choresCount(count)} this week — your first week!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_choresCount(count)} this week — $delta more than last!';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_choresCount(count)} this week — $delta fewer than last...';
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
      'Typically done every ~$days days · running behind...';
  @override
  String get missionLogTitle => 'The Record';
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
