import 'app_strings.dart';

class SuperheroStrings implements AppStrings {
  const SuperheroStrings();

  @override
  String get appTitle => 'Chore Buddy';

  // Tabs & Navigation
  @override
  String get tabChores => 'Missions';
  @override
  String get tabArchive => 'Hall of Rest';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'Application Info';
  @override
  String get settingsGearTooltip => 'Settings';

  // Active Chores Screen
  @override
  String get choresTitle => 'Active Missions';
  @override
  String get searchPlaceholder => 'Search missions...';
  @override
  String get sortUrgency => 'Urgency';
  @override
  String get sortName => 'Name';
  @override
  String get sortLastCompleted => 'Last Done';
  @override
  String get emptyActiveTitle => 'The Signal is Silent';
  @override
  String get emptyActiveDescription =>
      'The household is at peace. No missions currently require your attention. Tap the + to find a new challenge.';
  @override
  String get emptyFilterTitle => 'No Missions in Sector';
  @override
  String get emptyFilterDescription =>
      'There are chores recorded, but none match your current filters. Adjust your gear to see more missions.';

  // Archive Screen
  @override
  String get archiveTitle => 'The Hall of Rest';
  @override
  String get emptyArchiveTitle => 'The Hall of Rest';
  @override
  String get emptyArchiveDescription =>
      'There are no archived chores here. Only retired missions are moved to the Hall of Rest.';
  @override
  String get restoreChore => 'Reactivate';
  @override
  String get restoreDialogTitle => 'Reactivate Signal';
  @override
  String restoreDialogMessage(String choreName) =>
      "Bring '$choreName' back to active duty?";

  // Chore Details / Form
  @override
  String get newChoreTitle => 'New Mission';
  @override
  String get editChoreTitle => 'Edit Mission';
  @override
  String get nameLabel => 'Callsign / Chore Name';
  @override
  String get addTagsPrompt => 'Add some tags';
  @override
  String get addDueDatePrompt => 'Add due date';
  @override
  String get scheduleDueDateHint =>
      'Schedule a next due date for your mission';
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
  String get missionReminder => 'Mission Reminder';
  @override
  String get scheduleReminderHint =>
      'Schedule a reminder for your mission';
  @override
  String get saveChore => 'Save Mission';
  @override
  String get completionHistory => 'Completion History';
  @override
  String get emptyHistoryTitle => 'A Clean Slate';
  @override
  String get emptyHistoryDescription =>
      'This chore has no recorded history. Log your first completion to start tracking your heroics!';
  @override
  String get registryConflictTitle => 'Registry Conflict';
  @override
  String get registryConflictMessage =>
      'A mission with this callsign already exists. Please choose a unique identifier for this chore.';
  @override
  String get expungeRecordTitle => 'Expunge Heroics';
  @override
  String get expungeRecordMessage =>
      'Shall we remove this entry from the official record of your heroics? This action cannot be undone.';
  @override
  String get expungeRecordConfirm => 'Expunge';
  @override
  String get expungeRecordKeep => 'Keep Record';
  @override
  String get notFoundTitle => 'Signal Lost';
  @override
  String get choreNotFoundMessage =>
      'This mission could not be located in the registry.';

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'MISSION REPORT';
  @override
  String get completionTimeLabel => 'Completion Time';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'LOG';
  @override
  String get abortButton => 'ABORT';
  @override
  String get choreCompleted => 'Chore completed';
  @override
  String get undoAction => 'UNDO';

  // Decommission / Scrap / Purge Dialogs
  @override
  String get decommissionTitle => 'Decommission Mission';
  @override
  String decommissionMessage(String choreName) =>
      "Transfer '$choreName' to the Hall of Rest? It will be removed from active signals.";
  @override
  String get decommissionConfirm => 'Decommission';
  @override
  String get scrapTitle => 'Scrap Mission';
  @override
  String scrapMessage(String choreName) =>
      "Are you sure you want to permanently decommission '$choreName' and scrub all historical intel from the registry? This action cannot be undone.";
  @override
  String get scrapConfirm => 'Scrap';
  @override
  String get purgeTitle => 'DANGER: Delete All Chores';
  @override
  String get purgeMessage =>
      'This will permanently purge all decommissioned missions. Erase these records from the archives?';
  @override
  String get purgeConfirm => 'Purge All';
  @override
  String get wipeAllChoresButton => 'Delete All Chores';
  @override
  String get wipeAllChoresTitle => 'DANGER: Wipe Entire Registry';
  @override
  String get wipeAllChoresMessage =>
      'This will permanently erase every mission ever logged -- active and retired alike -- along with their heroics history and reminders. This action cannot be undone.';
  @override
  String get wipeAllChoresConfirm => 'Wipe Everything';

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
  String get emptyTagsTitle => 'No Gear Labeled';
  @override
  String get emptyTagsDescription =>
      "You haven't created any tags yet. Use the fields above to categorize your missions by room or urgency.";
  @override
  String get tagTooLongTitle => 'Signal Overload';
  @override
  String get tagTooLongMessage =>
      'This designation is too extensive for the mission registry. Please provide a shorter tag name for optimal field identification.';
  @override
  String get tagConflictTitle => 'Tag Conflict';
  @override
  String get tagConflictMessage =>
      'A tag with this designation already exists in the armory.';
  @override
  String get scrubTagTitle => 'Scrub Designation';
  @override
  String scrubTagMessage(String tagName) =>
      "Removing '$tagName' will detach it from all associated missions. Proceed with the scrub?";
  @override
  String get scrubTagConfirm => 'Scrub';
  @override
  String get scrubTagKeep => 'Keep';
  @override
  String get deleteAllTagsTitle => 'DANGER: Delete All Tags';
  @override
  String get deleteAllTagsMessage =>
      'Are you absolutely sure you want to delete ALL tags? This action cannot be undone.';
  @override
  String get deleteAllTagsConfirm => 'Yes, Delete Everything';
  @override
  String get intelSecuredTitle => 'Intel Secured';
  @override
  String get intelSecuredMessage =>
      'Mission data has been successfully encrypted and moved to the secure vault.';
  @override
  String get restoreArchivesTitle => 'Restore Archives';
  @override
  String get restoreArchivesMessage =>
      'Warning: Importing external intel will overwrite your current mission history. Proceed with data sync?';

  // Settings / About
  @override
  String get themeSectionTitle => 'Change Theme';
  @override
  String get themePickerHint => 'Calibrate your display for any mission environment';
  @override
  String get themeModeSystem => 'System';
  @override
  String get themeModeLight => 'Light';
  @override
  String get themeModeDark => 'Dark';
  @override
  String get dangerZoneSectionTitle => 'Danger Zone';
  @override
  String get hapticsToggleTitle => 'Haptic Feedback';
  @override
  String get notificationsToggleTitle => 'Mission Alerts';
  @override
  String get showDetailsToggleTitle => 'Show Details on Cards';
  @override
  String get backupSectionTitle => 'Data & Backup';
  @override
  String get exportBackupButton => 'Secure Intel (Export)';
  @override
  String get importBackupButton => 'Restore Archives (Import)';
  @override
  String get lastBackupNeverLabel => 'Never';
  @override
  String lastBackupAtLabel(String date) => 'Last backup: $date';
  @override
  String get restoreConfirmAction => 'Sync Data';
  @override
  String get backupFailedTitle => 'Backup Aborted';
  @override
  String get backupFailedMessage =>
      'The system was unable to secure mission data. Intel remains local.';
  @override
  String get restoreSuccessTitle => 'System Restored';
  @override
  String get restoreSuccessMessage =>
      'The archive has been successfully restored. Mission logs are live.';
  @override
  String get restoreFailedTitle => 'Sync Failed';
  @override
  String get restoreFailedMessage =>
      'The archive file is corrupted or incompatible. Mission logs are unchanged.';
  @override
  String get aboutTagline => 'Your household superhero';
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
  List<String> get aboutTechStackLabels =>
      const ['Flutter', 'Drift', 'Riverpod', 'Material 3'];
  @override
  String get aboutWebsiteButton => 'Visit Website';
  @override
  String get aboutWebsiteDialogTitle => 'My Website';
  @override
  String get aboutWebsiteDialogMessage => 'Coming... soon?';
  @override
  String get aboutWebsiteDialogAction => 'OH - OK';
  @override
  String get aboutCopyright => '© 2026 Chore Buddy Inc.';

  // Notifications
  @override
  String get notificationChannelName => 'Mission Alerts';
  @override
  String get notificationChannelDescription =>
      'Reminders for your active missions.';
  @override
  String notificationTitle(String choreName) => 'Mission Alert: $choreName';
  @override
  String get notificationBody => "It's time to engage your next mission.";
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
  String get cancel => 'Cancel';
  @override
  String get ok => 'Roger That';

  // App shortcuts / quick-settings tile
  @override
  String get shortcutNewMissionLabel => 'New Mission';
  @override
  String get shortcutOverdueLabel => 'Overdue';

  // Home-screen Widget
  @override
  String overdueLabel(String date) => 'Overdue: $date';

  // Snooze / Duplicate
  @override
  String get snoozeAction => 'Not Today';
  @override
  String get choreSnoozed => 'Mission postponed to tomorrow';
  @override
  String get notificationSnoozeAction => 'NOT TODAY';
  @override
  String get duplicateAction => 'Duplicate Mission';
}
