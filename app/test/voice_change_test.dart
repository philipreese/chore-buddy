import 'package:chorebuddy/app.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/shortcuts/app_shortcuts.dart';
import 'package:chorebuddy/core/strings/voice_provider.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_app_shortcuts.dart';
import 'fakes/fake_notification_scheduler.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers app.dart's _onVoiceChanged (spec 27, review B / S3): switching
/// voice must restate already-scheduled notifications and re-register the
/// launcher shortcuts, not just recreate the (invisible) notification
/// channel.
void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ChoreBuddy',
      packageName: 'com.philipreese.chorebuddy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets(
    'switching voice reschedules every active chore reminder with the new '
    "voice's copy",
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      // scheduleChoreNotification's future-due-date gate reads the real
      // wall clock (notification_service.dart), not the injected
      // nowProvider -- so the fixture's due date has to be genuinely far in
      // the future rather than relative to the fake `now` above.
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Water Plants'),
          nextDueDate: Value(DateTime(2030, 1, 1, 12, 0, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );
      final scheduler = FakeNotificationScheduler();
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            tickerProvider.overrideWith((ref) => Stream.value(now)),
            nowProvider.overrideWith((ref) => now),
            notificationSchedulerProvider.overrideWithValue(scheduler),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
            appShortcutsProvider.overrideWithValue(FakeAppShortcuts()),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const ChoreBuddyApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing schedules on cold start with no prior scheduling call, so
      // the fake starts empty.
      expect(scheduler.scheduled, isEmpty);

      container.read(voiceProvider.notifier).setVoice(AppVoice.grandma);
      await tester.pumpAndSettle();

      expect(scheduler.scheduled, hasLength(1));
      final restated = scheduler.scheduled.single;
      expect(restated.id, equals(choreId));
      final grandmaStrings = AppVoice.grandma.strings;
      expect(restated.title, equals(grandmaStrings.notificationTitle('Water Plants')));
      expect(
        restated.completeActionLabel,
        equals(grandmaStrings.notificationCompleteAction),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );

  testWidgets(
    'switching voice re-registers the launcher shortcuts with the new '
    "voice's labels",
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeShortcuts = FakeAppShortcuts();
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
            appShortcutsProvider.overrideWithValue(fakeShortcuts),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const ChoreBuddyApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        fakeShortcuts.registeredItems
            .firstWhere((i) => i.type == 'overdue')
            .localizedTitle,
        equals('Overdue'),
      );

      container.read(voiceProvider.notifier).setVoice(AppVoice.grandma);
      await tester.pumpAndSettle();

      expect(
        fakeShortcuts.registeredItems
            .firstWhere((i) => i.type == 'overdue')
            .localizedTitle,
        equals("Still Haven't Done"),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );
}
