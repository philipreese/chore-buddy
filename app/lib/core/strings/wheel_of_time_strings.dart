import 'app_strings.dart';

/// Robert Jordan's Wheel of Time, played straight and loving (spec 24).
/// Every string still has to be instantly parseable -- flavor in tone, never
/// in riddles, so a user always knows what a button does. Anchor vocabulary:
/// chores are threads in the Pattern, tags are Ajahs, archive is the
/// Stilled, and permanent delete is Balefire. See changes.md for the small
/// set of slots that deliberately stay literal rather than reaching for a
/// WoT term (snooze options, recurrence values, Due Today) -- those are the
/// spots parseability wins outright over flavor.
class WheelOfTimeStrings implements AppStrings {
  const WheelOfTimeStrings();

  // Distinct from the other two voices' appTitle -- see the
  // per-voice-appTitle completeness test in voice_registry_test.dart.
  @override
  String get appTitle => 'The Wheel of Chores';

  // Voice (spec 24)
  @override
  String get voiceSignature => 'The Wheel weaves as the Wheel wills.';

  // Tabs & Navigation
  @override
  String get tabChores => 'The Pattern';
  @override
  String get tabArchive => 'The Stilled';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Threads of the Pattern';
  @override
  String get searchPlaceholder => 'Search the Pattern...';
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
  String get filterByTagsTitle => 'Filter by Ajah';
  @override
  String get emptyActiveTitle => 'The Pattern Is Still';
  @override
  String get emptyActiveDescription =>
      'No threads need weaving right now. Tap the + to spin a new one.';
  @override
  String get emptyFilterTitle => 'No Threads Found';
  @override
  String get emptyFilterDescription =>
      'There are chores recorded, but none match your current filters. Adjust your Ajah filters to see more threads.';

  // Banner stat chips & sectioned list (spec 19)
  @override
  String get statOverdueLabel => 'Overdue';
  @override
  String get statDueTodayLabel => 'Today';
  @override
  String get statUpcomingLabel => 'Upcoming';
  @override
  String get sectionOverdueLabel => 'The Shadow Grows';
  @override
  String get sectionTodayLabel => 'Due Today';
  @override
  String get sectionUpcomingLabel => 'Threads to Come';
  @override
  String get sectionUnscheduledLabel => 'Unwoven';

  // Archive Screen
  @override
  String get archiveTitle => 'The Stilled';
  @override
  String get emptyArchiveTitle => 'The Stilled';
  @override
  String get emptyArchiveDescription =>
      'There are no stilled threads here. Only chores you archive are set aside from the Pattern.';
  @override
  String get restoreChore => 'Restore';
  @override
  String get restoreDialogTitle => 'Restore Thread';
  @override
  String restoreDialogMessage(String choreName) =>
      "Weave '$choreName' back into the Pattern?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'Weave a New Thread';
  @override
  String get editChoreTitle => 'Edit Thread';
  @override
  String get nameLabel => 'Thread Name';
  @override
  String get choreIconLabel => 'Icon';
  @override
  String get choreIconHelper => "Shown on this thread's card";
  @override
  String get addTagsPrompt => 'Add some Ajahs';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint => 'Schedule when this thread comes due';
  @override
  String get recurrenceLabel => 'Recurrence';
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
  String get scheduleReminderHint => 'Schedule a reminder for this thread';
  @override
  String get saveChore => 'Weave Thread';
  @override
  String get completionHistory => 'Weaving History';
  @override
  String get emptyHistoryTitle => 'An Unspun Thread';
  @override
  String get emptyHistoryDescription =>
      'This thread has no recorded history. Log your first weave to start tracking it in the Pattern.';
  @override
  String get registryConflictTitle => 'Thread Already Spun';
  @override
  String get registryConflictMessage =>
      'A thread with this name already exists in the Pattern. Please choose a different name.';
  @override
  String get expungeRecordTitle => 'Cut This Thread';
  @override
  String get expungeRecordMessage =>
      'Remove this entry from the weaving history? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Cut';
  @override
  String get expungeRecordKeep => 'Keep';
  @override
  String get notFoundTitle => 'Thread Lost';
  @override
  String get choreNotFoundMessage =>
      'This thread could not be found in the Pattern.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'The Weaving';
  @override
  String get completionTimeLabel => 'Completion Time';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'Weave';
  @override
  String get abortButton => 'Cancel';
  @override
  String get choreCompleted => 'Woven.';
  @override
  String get undoAction => 'UNRAVEL';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Still This Thread';
  @override
  String decommissionMessage(String choreName) =>
      "Set '$choreName' aside as Stilled? It will be removed from the active Pattern.";
  @override
  String get decommissionConfirm => 'Still It';
  @override
  String get scrapTitle => 'Balefire This Thread';
  @override
  String scrapMessage(String choreName) =>
      "Balefire '$choreName'? It will be as if it never was -- this permanently erases the thread and all its history. This action cannot be undone.";
  @override
  String get scrapConfirm => 'Balefire';
  @override
  String get purgeTitle => 'Balefire All Stilled Threads';
  @override
  String get purgeMessage =>
      'This will permanently erase every stilled thread. Erase these records from the Pattern?';
  @override
  String get purgeConfirm => 'Balefire All';
  @override
  String get wipeAllChoresButton => 'Delete All Chores';
  @override
  String get wipeAllChoresTitle => 'Balefire the Entire Pattern';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently erase every thread ever spun -- active and stilled alike -- along with their weaving history and reminders. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Balefire Everything';

  // Tags & Settings
  @override
  String get manageTags => 'The Ajahs';
  @override
  String get newTagPlaceholder => 'New Ajah Name';
  @override
  String get addTag => 'Add Ajah';
  @override
  String get existingTags => 'Existing Ajahs';
  @override
  String get emptyTagsTitle => 'No Ajahs Sworn';
  @override
  String get emptyTagsDescription =>
      "You haven't created any Ajahs yet. Use the fields above to sort your threads by room or urgency.";
  @override
  String get tagTooLongTitle => 'Name Too Long';
  @override
  String get tagTooLongMessage =>
      'This Ajah name is too long for the Pattern. Please provide a shorter name.';
  @override
  String get tagConflictTitle => 'Ajah Already Sworn';
  @override
  String get tagConflictMessage => 'An Ajah with this name already exists.';
  @override
  String get scrubTagTitle => 'Disband Ajah';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will detach it from every thread that carries it. Proceed?";
  @override
  String get scrubTagConfirm => 'Disband';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'Delete All Ajahs?';
  @override
  String get deleteAllTagsMessage =>
      'Are you absolutely sure you want to delete ALL Ajahs? This action cannot be undone.';
  @override
  String get deleteAllTagsConfirm => 'Yes, Delete Everything';
  @override
  String get intelSecuredTitle => 'Pattern Recorded';
  @override
  String get intelSecuredMessage =>
      'Your threads have been safely recorded to the backup file.';
  @override
  String get restoreArchivesTitle => 'Restore the Pattern';
  @override
  String get restoreArchivesMessage =>
      'Warning: Restoring this backup will overwrite your current thread history. Proceed?';

  // Settings / About
  @override
  String get themeSectionTitle => 'Change Theme';
  @override
  String get themePickerHint => 'Choose how the Pattern appears to you';
  @override
  String get themeModeSystem => 'System';
  @override
  String get themeModeLight => 'Light';
  @override
  String get themeModeDark => 'Dark';
  @override
  String get dangerZoneSectionTitle => 'Danger Zone';
  @override
  String get voiceSectionTitle => 'Voice of the Pattern';
  @override
  String get behaviorSectionTitle => 'Behavior';
  @override
  String get tagsSectionTitle => 'Ajahs';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Wheel Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupRestoreRowTitle => 'Backup & Restore';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Record the Pattern (Export)';
  @override
  String get importBackupButton => 'Restore the Pattern (Import)';
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
      'The Pattern could not be recorded. Your threads remain unchanged.';
  @override
  String get restoreSuccessTitle => 'The Pattern Is Restored';
  @override
  String get restoreSuccessMessage =>
      'Your threads have been successfully restored.';
  @override
  String get restoreFailedTitle => 'Restore Failed';
  @override
  String get restoreFailedMessage =>
      'The backup file is corrupted or incompatible. Your threads are unchanged.';
  @override
  String get aboutTagline => 'The Wheel weaves as the Wheel wills.';
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
  String get notificationChannelName => 'Wheel Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for threads that are due.';
  @override
  String notificationTitle(String choreName) => 'The Wheel turns: $choreName';
  @override
  String get notificationBody => 'A thread of the Pattern is due.';
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
  String get ok => 'As the Wheel Wills';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'New Thread';
  @override
  String get shortcutOverdueLabel => 'Overdue';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Overdue: $date';

  // Auto-Backup (Settings)
  @override
  String get autoBackupSectionTitle => 'Pattern Sync';
  @override
  String get autoBackupToggleTitle => 'Auto-Backup';
  @override
  String get autoBackupToggleSubtitle =>
      'The Pattern quietly records your threads every day.';
  @override
  String autoBackupDestinationLabel(String path) => 'Backup location: $path';
  @override
  String get autoBackupNeverLabel => 'No backup yet';
  @override
  String autoBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get autoBackupNowButton => 'Record the Pattern Now';
  @override
  String get autoBackupNowSuccessTitle => 'Pattern Recorded';
  @override
  String get autoBackupNowSuccessMessage =>
      'Your threads are safely recorded.';
  @override
  String get autoBackupNowFailedTitle => 'Backup Failed';
  @override
  String get autoBackupNowFailedMessage =>
      "The backup didn't go through. Try again in a moment.";

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Not Yet';
  @override
  String choreSnoozedUntil(String date) => 'Thread postponed to $date';
  @override
  String get notificationSnoozeAction => 'NOT YET';
  @override
  String get duplicateAction => 'Duplicate Thread';

  // Snooze picker (spec 20) -- options themselves stay literal
  // (Tomorrow / In 3 Days / Next Week / Pick a Date) for parseability.
  @override
  String get snoozeSheetTitle => 'Not Yet';
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
  String voiceChoreAddedMessage(String choreName) => 'Spun: $choreName';
  @override
  String voiceChoreCompletedMessage(String choreName) => 'Woven: $choreName';
  @override
  String voiceChoreDuplicateMessage(String choreName) =>
      "A thread named '$choreName' already exists.";
  @override
  String voiceChoreNotFoundMessage(String choreName) =>
      "No active thread matches '$choreName'.";
  @override
  String voiceChoreAmbiguousMessage(String choreName) =>
      "Multiple threads match '$choreName' -- be more specific.";
  @override
  String get voiceCommandInvalidMessage => 'Voice command not understood.';

  // Stats: banner weekly line, streak chips, Mission Log (spec 22)
  @override
  String get bannerStatsZeroState =>
      'No threads woven yet — tap to open the Great Weave';
  @override
  String bannerStatsFirstWeek(int count) =>
      '${_threadsCount(count)} this week — your first week!';
  @override
  String bannerStatsMore(int count, int delta) =>
      '${_threadsCount(count)} this week — $delta more than last';
  @override
  String bannerStatsFewer(int count, int delta) =>
      '${_threadsCount(count)} this week — $delta fewer than last';
  @override
  String bannerStatsSame(int count) =>
      '${_threadsCount(count)} this week — same as last';
  // Kept plain per spec: "ta'veren streak" risks reading as a riddle rather
  // than a number, so this stays literal like every other voice's.
  @override
  String streakChipLabel(int streak) => '$streak in a row';
  @override
  String totalCompletionsChipLabel(int count) => '$count logged';
  @override
  String cadenceLinePlain(int days) => 'Typically woven every ~$days days';
  @override
  String cadenceLineOnSchedule(int days) =>
      'Typically woven every ~$days days · on schedule';
  @override
  String cadenceLineBehind(int days) =>
      'Typically woven every ~$days days · running behind';
  @override
  String get missionLogTitle => 'The Great Weave';
  @override
  String get missionLogThisWeekLabel => 'This Week';
  @override
  String get missionLogMissionsUnitLabel => 'threads';
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

  static String _threadsCount(int count) =>
      count == 1 ? '1 thread' : '$count threads';
}
