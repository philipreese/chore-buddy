abstract class AppStrings {
  String get appTitle;

  // Tabs & Navigation
  String get tabChores;
  String get tabArchive;
  String get settingsTitle;
  String get aboutTitle;
  String get settingsGearTooltip;

  // Active Chores Screen
  String get choresTitle;
  String get searchPlaceholder;
  String get sortUrgency;
  String get sortName;
  String get sortLastCompleted;
  String get emptyActiveTitle;
  String get emptyActiveDescription;
  String get emptyFilterTitle;
  String get emptyFilterDescription;

  // Archive Screen
  String get archiveTitle;
  String get emptyArchiveTitle;
  String get emptyArchiveDescription;
  String get restoreChore;
  String get restoreDialogTitle;
  String restoreDialogMessage(String choreName);

  // Chore Details / Form
  String get newChoreTitle;
  String get editChoreTitle;
  String get nameLabel;
  String get addTagsPrompt;
  String get addDueDatePrompt;
  String get scheduleDueDateHint;
  String get recurrenceLabel;
  String get recurrenceNone;
  String get recurrenceDaily;
  String get recurrenceEveryOtherDay;
  String get recurrenceWeekly;
  String get recurrenceMonthly;
  String get missionReminder;
  String get scheduleReminderHint;
  String get saveChore;
  String get completionHistory;
  String get emptyHistoryTitle;
  String get emptyHistoryDescription;
  String get registryConflictTitle;
  String get registryConflictMessage;
  String get expungeRecordTitle;
  String get expungeRecordMessage;
  String get expungeRecordConfirm;
  String get expungeRecordKeep;
  String get notFoundTitle;
  String get choreNotFoundMessage;

  // Completion Popup / Actions
  String get completionReportTitle;
  String get completionTimeLabel;
  String get noteLabel;
  String get logButton;
  String get abortButton;
  String get choreCompleted;
  String get undoAction;

  // Decommission / Scrap / Purge Dialogs
  String get decommissionTitle;
  String decommissionMessage(String choreName);
  String get decommissionConfirm;
  String get scrapTitle;
  String scrapMessage(String choreName);
  String get scrapConfirm;
  String get purgeTitle;
  String get purgeMessage;
  String get purgeConfirm;

  // Tags & Settings
  String get manageTags;
  String get newTagPlaceholder;
  String get addTag;
  String get existingTags;
  String get emptyTagsTitle;
  String get emptyTagsDescription;
  String get tagTooLongTitle;
  String get tagTooLongMessage;
  String get tagConflictTitle;
  String get tagConflictMessage;
  String get scrubTagTitle;
  String scrubTagMessage(String tagName);
  String get scrubTagConfirm;
  String get scrubTagKeep;
  String get deleteAllTagsTitle;
  String get deleteAllTagsMessage;
  String get deleteAllTagsConfirm;
  String get intelSecuredTitle;
  String get intelSecuredMessage;
  String get restoreArchivesTitle;
  String get restoreArchivesMessage;

  // Common
  String get archiveAction;
  String get deleteAction;
  String lastCompletedLabel(String date);
  String dueLabel(String date);
  String genericError(Object error);
  String get cancel;
  String get ok;
}
