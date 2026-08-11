import 'package:chorebuddy/app.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:chorebuddy/core/voice/voice_command_channel.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_notification_scheduler.dart';
import 'fakes/fake_voice_command_channel.dart';
import 'fakes/fake_widget_data_writer.dart';

/// Covers app.dart's voice-command wiring end to end: the pending-cold-start
/// path (channel.getLaunchCommand(), mirroring the shortcut/notification
/// launch-payload pattern) and a live command pushed while the app is
/// already running (MainActivity.onNewIntent). Domain-logic edge cases
/// (recurrence parsing, prefix matching, duplicates) are covered in
/// voice_command_service_test.dart -- this file only asserts the wiring
/// reaches [executeVoiceCommand] and that feedback is never silent.
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
    'a cold-start ADD_CHORE launch command inserts the chore and shows a snackbar once resumed',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeChannel = FakeVoiceCommandChannel(
        launchCommand: {'command': 'add', 'name': 'Water Plants'},
      );
      final scheduler = FakeNotificationScheduler();

      // Set resumed before the first pump: the cold-start launch command
      // runs from a postFrameCallback fired during pumpWidget itself, which
      // can race a lifecycle change made afterwards.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            voiceCommandChannelProvider.overrideWithValue(fakeChannel),
            notificationSchedulerProvider.overrideWithValue(scheduler),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
          ],
          child: const ChoreBuddyApp(),
        ),
      );
      await tester.pumpAndSettle();

      final chores = await db.getActiveChores();
      expect(chores.map((c) => c.name), contains('Water Plants'));
      expect(find.text('Mission logged: Water Plants'), findsOneWidget);
      // Foregrounded: the snackbar is the confirmation, not a notification.
      expect(scheduler.shown, isEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );

  testWidgets(
    'a live COMPLETE_CHORE command while the app is running completes the chore',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.insertChore(ChoresCompanion(name: Value('Water Plants')));
      final fakeChannel = FakeVoiceCommandChannel();
      final scheduler = FakeNotificationScheduler();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            voiceCommandChannelProvider.overrideWithValue(fakeChannel),
            notificationSchedulerProvider.overrideWithValue(scheduler),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
          ],
          child: const ChoreBuddyApp(),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      fakeChannel.fireLiveCommand({'command': 'complete', 'name': 'Water Plants'});
      await tester.pumpAndSettle();

      final history = await (db.select(db.completionRecords)).get();
      expect(history, hasLength(1));
      expect(find.text('Mission complete: Water Plants'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );

  testWidgets(
    'a command handled before the app is resumed falls back to a notification instead of a snackbar',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeChannel = FakeVoiceCommandChannel(
        launchCommand: {'command': 'add', 'name': 'Feed Cat'},
      );
      final scheduler = FakeNotificationScheduler();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            voiceCommandChannelProvider.overrideWithValue(fakeChannel),
            notificationSchedulerProvider.overrideWithValue(scheduler),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
          ],
          child: const ChoreBuddyApp(),
        ),
      );
      // Deliberately never resumed -- simulates the intent being handled
      // before Android has reported the activity as resumed.
      await tester.pumpAndSettle();

      final chores = await db.getActiveChores();
      expect(chores.map((c) => c.name), contains('Feed Cat'));
      expect(find.text('Mission logged: Feed Cat'), findsNothing);
      expect(scheduler.shown, hasLength(1));
      expect(scheduler.shown.single.body, 'Mission logged: Feed Cat');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );

  testWidgets(
    'an unrecognized live command is a no-op, not a crash',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeChannel = FakeVoiceCommandChannel();
      final scheduler = FakeNotificationScheduler();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            voiceCommandChannelProvider.overrideWithValue(fakeChannel),
            notificationSchedulerProvider.overrideWithValue(scheduler),
            widgetDataWriterProvider.overrideWithValue(FakeWidgetDataWriter()),
          ],
          child: const ChoreBuddyApp(),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      fakeChannel.fireLiveCommand({'command': 'complete', 'name': 'Nonexistent'});
      await tester.pumpAndSettle();

      expect(await db.getActiveChores(), isEmpty);
      expect(find.text("No active mission matches 'Nonexistent'."), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    },
  );
}
