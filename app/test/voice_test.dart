import 'package:chorebuddy/core/strings/app_strings.dart';
import 'package:chorebuddy/core/strings/cozy_strings.dart';
import 'package:chorebuddy/core/strings/mission_control_strings.dart';
import 'package:chorebuddy/core/strings/noir_strings.dart';
import 'package:chorebuddy/core/strings/standard_strings.dart';
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
      expect(strings, isA<StandardStrings>());
      expect(strings.tabChores, equals('Chores'));
    });
  });

  group('Voice copy defects (review B / spec 27)', () {
    test(
        "Mission Control's overdue section header is distinct from its "
        'snooze label -- the two used to be identical', () {
      const strings = MissionControlStrings();
      expect(strings.sectionOverdueLabel, isNot(equals(strings.snoozeAction)));
    });

    test(
        "Cozy's archive swipe label is distinct from its snooze label, and "
        'the four Remove-labeled operations no longer share one word', () {
      const strings = CozyStrings();
      expect(strings.archiveAction, isNot(equals(strings.snoozeAction)));

      final removeLabels = {
        strings.scrapConfirm,
        strings.deleteAction,
        strings.expungeRecordConfirm,
        strings.scrubTagConfirm,
      };
      // scrapConfirm and deleteAction are the same operation (swipe-left bg
      // label, then its own confirm dialog button) so those two may match
      // each other -- but the record-level and tag-level deletes must read
      // differently from both.
      expect(strings.expungeRecordConfirm, isNot(equals(strings.scrapConfirm)));
      expect(strings.scrubTagConfirm, isNot(equals(strings.scrapConfirm)));
      expect(
        strings.expungeRecordConfirm,
        isNot(equals(strings.scrubTagConfirm)),
      );
      expect(removeLabels.length, greaterThan(1));
    });

    test(
        "Superhero's backup-import confirm reads as a destructive overwrite, "
        'not a non-destructive sync', () {
      const strings = SuperheroStrings();
      expect(strings.restoreConfirmAction, isNot(equals('Sync Data')));
      expect(strings.restoreConfirmAction, isNot(contains('Sync')));
    });

    test(
        "Noir's completion and archive confirm strings are distinct -- they "
        'used to both be "Close Case"', () {
      const strings = NoirStrings();
      expect(strings.logButton, isNot(equals(strings.decommissionConfirm)));
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

    test(
        'the four strings that used to bypass AppStrings (N1) resolve via '
        "AppStrings for every voice, differing per voice or at least "
        'non-empty', () {
      final voiceSectionTitles = <String>{};
      for (final voice in AppVoice.values) {
        final strings = voice.strings;

        expect(strings.voiceSectionTitle, isNotEmpty, reason: '$voice');
        expect(strings.iconPickerNoneLabel, isNotEmpty, reason: '$voice');
        expect(strings.missionLogChartNowLabel, isNotEmpty, reason: '$voice');
        expect(
          strings.missionLogChartWeeksAgoLabel(3),
          isNotEmpty,
          reason: '$voice',
        );
        voiceSectionTitles.add(strings.voiceSectionTitle);
      }
      // voiceSectionTitle is voiced distinctly per voice; the other three
      // (icon picker "None", chart axis labels) are allowed to share text
      // across voices as long as they resolve through AppStrings.
      expect(voiceSectionTitles.length, equals(AppVoice.values.length));
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
