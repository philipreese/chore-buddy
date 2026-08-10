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

  // Completion Popup / Actions
  @override
  String get completionReportTitle => 'Mission Report';
  @override
  String get completionTimeLabel => 'Completion Time';
  @override
  String get noteLabel => 'Note';
  @override
  String get logButton => 'Log';
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

  // Tags & Settings
  @override
  String get manageTags => 'Manage Tags';
  @override
  String get emptyTagsTitle => 'No Gear Labeled';
  @override
  String get emptyTagsDescription =>
      "You haven't created any tags yet. Use the fields above to categorize your missions by room or urgency.";
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

  // Common
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'Roger That';
}
