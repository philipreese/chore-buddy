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
  String get wipeAllChoresButton;
  String get wipeAllChoresTitle;
  String get wipeAllChoresMessage;
  String get wipeAllChoresConfirm;

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

  // Settings / About
  String get themeSectionTitle;
  String get themePickerHint;
  String get themeModeSystem;
  String get themeModeLight;
  String get themeModeDark;
  String get dangerZoneSectionTitle;
  String get hapticsToggleTitle;
  String get notificationsToggleTitle;
  String get showDetailsToggleTitle;
  String get backupSectionTitle;
  String get exportBackupButton;
  String get importBackupButton;
  String get lastBackupNeverLabel;
  String lastBackupAtLabel(String date);
  String get restoreConfirmAction;
  String get backupFailedTitle;
  String get backupFailedMessage;
  String get restoreSuccessTitle;
  String get restoreSuccessMessage;
  String get restoreFailedTitle;
  String get restoreFailedMessage;
  String get aboutTagline;
  String get aboutVersionLabel;
  String get aboutBuildLabel;
  String get aboutPackageLabel;
  String get aboutDeveloperLabel;
  String get aboutDeveloperName;
  String get aboutPoweredByLabel;
  List<String> get aboutTechStackLabels;
  String get aboutWebsiteButton;
  String get aboutWebsiteDialogTitle;
  String get aboutWebsiteDialogMessage;
  String get aboutWebsiteDialogAction;
  String get aboutCopyright;

  // Notifications
  String get notificationChannelName;
  String get notificationChannelDescription;
  String notificationTitle(String choreName);
  String get notificationBody;
  String get notificationCompleteAction;

  // Common
  String get archiveAction;
  String get deleteAction;
  String lastCompletedLabel(String date);
  String dueLabel(String date);
  String genericError(Object error);
  String get cancel;
  String get ok;

  // App shortcuts / quick-settings tile
  String get shortcutNewMissionLabel;
  String get shortcutOverdueLabel;

  // Home-screen Widget
  String overdueLabel(String date);

  // Auto-Backup (Settings)
  String get autoBackupSectionTitle;
  String get autoBackupToggleTitle;
  String get autoBackupToggleSubtitle;
  String autoBackupDestinationLabel(String path);
  String get autoBackupNeverLabel;
  String autoBackupAtLabel(String date);
  String get autoBackupNowButton;
  String get autoBackupNowSuccessTitle;
  String get autoBackupNowSuccessMessage;
  String get autoBackupNowFailedTitle;
  String get autoBackupNowFailedMessage;

  // Snooze / Duplicate
  String get snoozeAction;
  String get choreSnoozed;
  String get notificationSnoozeAction;
  String get duplicateAction;

  // Voice commands (spec 16)
  String voiceChoreAddedMessage(String choreName);
  String voiceChoreCompletedMessage(String choreName);
  String voiceChoreDuplicateMessage(String choreName);
  String voiceChoreNotFoundMessage(String choreName);
  String voiceChoreAmbiguousMessage(String choreName);
  String get voiceCommandInvalidMessage;
}
