import 'package:chorebuddy/core/strings/app_strings.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/core/strings/voice_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Voice-Keyed Strings Tests', () {
    test('SuperheroStrings resolves every defined key to a non-empty string', () {
      final AppStrings strings = const SuperheroStrings();

      expect(strings.appTitle.isNotEmpty, isTrue);
      expect(strings.tabChores.isNotEmpty, isTrue);
      expect(strings.tabArchive.isNotEmpty, isTrue);
      expect(strings.settingsTitle.isNotEmpty, isTrue);
      expect(strings.aboutTitle.isNotEmpty, isTrue);
      expect(strings.settingsGearTooltip.isNotEmpty, isTrue);

      expect(strings.choresTitle.isNotEmpty, isTrue);
      expect(strings.searchPlaceholder.isNotEmpty, isTrue);
      expect(strings.sortUrgency.isNotEmpty, isTrue);
      expect(strings.sortName.isNotEmpty, isTrue);
      expect(strings.sortLastCompleted.isNotEmpty, isTrue);
      expect(strings.sortButtonLabel.isNotEmpty, isTrue);
      expect(strings.filterButtonLabel.isNotEmpty, isTrue);
      expect(strings.filterByTagsTitle.isNotEmpty, isTrue);
      expect(strings.emptyActiveTitle.isNotEmpty, isTrue);
      expect(strings.emptyActiveDescription.isNotEmpty, isTrue);
      expect(strings.emptyFilterTitle.isNotEmpty, isTrue);
      expect(strings.emptyFilterDescription.isNotEmpty, isTrue);

      expect(strings.archiveTitle.isNotEmpty, isTrue);
      expect(strings.emptyArchiveTitle.isNotEmpty, isTrue);
      expect(strings.emptyArchiveDescription.isNotEmpty, isTrue);
      expect(strings.restoreChore.isNotEmpty, isTrue);
      expect(strings.restoreDialogTitle.isNotEmpty, isTrue);
      expect(strings.restoreDialogMessage('Test Chore').isNotEmpty, isTrue);

      expect(strings.newChoreTitle.isNotEmpty, isTrue);
      expect(strings.editChoreTitle.isNotEmpty, isTrue);
      expect(strings.nameLabel.isNotEmpty, isTrue);
      expect(strings.addTagsPrompt.isNotEmpty, isTrue);
      expect(strings.addDueDatePrompt.isNotEmpty, isTrue);
      expect(strings.scheduleDueDateHint.isNotEmpty, isTrue);
      expect(strings.recurrenceLabel.isNotEmpty, isTrue);
      expect(strings.missionReminder.isNotEmpty, isTrue);
      expect(strings.scheduleReminderHint.isNotEmpty, isTrue);
      expect(strings.saveChore.isNotEmpty, isTrue);
      expect(strings.completionHistory.isNotEmpty, isTrue);
      expect(strings.emptyHistoryTitle.isNotEmpty, isTrue);
      expect(strings.emptyHistoryDescription.isNotEmpty, isTrue);
      expect(strings.registryConflictTitle.isNotEmpty, isTrue);
      expect(strings.registryConflictMessage.isNotEmpty, isTrue);

      expect(strings.completionReportTitle.isNotEmpty, isTrue);
      expect(strings.completionTimeLabel.isNotEmpty, isTrue);
      expect(strings.noteLabel.isNotEmpty, isTrue);
      expect(strings.logButton.isNotEmpty, isTrue);
      expect(strings.abortButton.isNotEmpty, isTrue);
      expect(strings.choreCompleted.isNotEmpty, isTrue);
      expect(strings.undoAction.isNotEmpty, isTrue);

      expect(strings.decommissionTitle.isNotEmpty, isTrue);
      expect(strings.decommissionMessage('Test Chore').isNotEmpty, isTrue);
      expect(strings.decommissionConfirm.isNotEmpty, isTrue);
      expect(strings.scrapTitle.isNotEmpty, isTrue);
      expect(strings.scrapMessage('Test Chore').isNotEmpty, isTrue);
      expect(strings.scrapConfirm.isNotEmpty, isTrue);
      expect(strings.purgeTitle.isNotEmpty, isTrue);
      expect(strings.purgeMessage.isNotEmpty, isTrue);
      expect(strings.purgeConfirm.isNotEmpty, isTrue);

      expect(strings.manageTags.isNotEmpty, isTrue);
      expect(strings.emptyTagsTitle.isNotEmpty, isTrue);
      expect(strings.emptyTagsDescription.isNotEmpty, isTrue);
      expect(strings.intelSecuredTitle.isNotEmpty, isTrue);
      expect(strings.intelSecuredMessage.isNotEmpty, isTrue);
      expect(strings.restoreArchivesTitle.isNotEmpty, isTrue);
      expect(strings.restoreArchivesMessage.isNotEmpty, isTrue);

      expect(strings.cancel.isNotEmpty, isTrue);
      expect(strings.ok.isNotEmpty, isTrue);

      expect(strings.notificationChannelName.isNotEmpty, isTrue);
      expect(strings.notificationChannelDescription.isNotEmpty, isTrue);
      expect(strings.notificationTitle('Test Chore').isNotEmpty, isTrue);
      expect(strings.notificationBody.isNotEmpty, isTrue);
    });

    test('Superhero voice resolves specific MAUI copy', () {
      final strings = const SuperheroStrings();
      expect(strings.tabChores, equals('Missions'));
      expect(strings.tabArchive, equals('Hall of Rest'));
      expect(strings.emptyActiveTitle, equals('The Signal is Silent'));
      expect(strings.decommissionTitle, equals('Decommission Mission'));
      expect(strings.restoreDialogTitle, equals('Reactivate Signal'));
      expect(strings.decommissionMessage('Vacuum Floor'),
          contains("Transfer 'Vacuum Floor' to the Hall of Rest?"));
    });

    test('All nine voices resolve specific copy', () {
      for (final voice in AppVoice.values) {
        final strings = voice.strings;
        expect(strings.appTitle, isNotEmpty);
        expect(strings.voiceSignature, isNotEmpty);
        expect(strings.tabChores, isNotEmpty);
        expect(strings.tabArchive, isNotEmpty);
        expect(strings.choresTitle, isNotEmpty);
        expect(strings.newChoreTitle, isNotEmpty);
        expect(strings.choreCompleted, isNotEmpty);
        expect(strings.decommissionMessage('Vacuum'), contains('Vacuum'));
      }
    });

    test('appStringsProvider resolves to active voice strings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final strings = container.read(appStringsProvider);
      expect(strings, isA<SuperheroStrings>());
      expect(strings.tabChores, equals('Missions'));
    });
  });

  group('Voice registry completeness (spec 24)', () {
    test(
        'every AppVoice resolves distinct, non-empty appTitle and '
        'choresTitle -- a cheap canary; the compiler already enforces the '
        'interface', () {
      final appTitles = <String>{};
      final choresTitles = <String>{};

      for (final voice in AppVoice.values) {
        final strings = voice.strings;

        expect(strings.appTitle, isNotEmpty, reason: '$voice.appTitle');
        expect(strings.choresTitle, isNotEmpty, reason: '$voice.choresTitle');

        expect(
          appTitles.add(strings.appTitle),
          isTrue,
          reason: '${voice.name} appTitle duplicates another voice\'s',
        );
        expect(
          choresTitles.add(strings.choresTitle),
          isTrue,
          reason: '${voice.name} choresTitle duplicates another voice\'s',
        );
      }
    });

    test('every AppVoice has non-empty metadata and a non-empty signature '
        'line drawn from its own strings', () {
      for (final voice in AppVoice.values) {
        expect(voice.metadata.displayName, isNotEmpty);
        expect(voice.metadata.glyph, isNotEmpty);
        expect(voice.strings.voiceSignature, isNotEmpty);
      }
    });
  });
}
