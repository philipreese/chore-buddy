# Spec 16 — Voice commands: intent API + AppFunctions for Gemini (issue #23)

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (`flutter test`, builds) — run them to completion in the foreground.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`
- Target device: Pixel 10a, Android 17 (API level ≥ 36). minSdk may be raised for the AppFunctions module ONLY if unavoidable — prefer runtime/API-level gating.

## Context

Goal: "add chore …" / "complete chore …" / "snooze chore …" spoken to Gemini (or fired by Tasker/adb) reach ChoreBuddy. Two layers: a plain intent command surface (works today, testable via adb), and androidx AppFunctions declarations on top (Gemini's on-device tool-calling surface on Android 16+; its Gemini-side rollout is a limited preview, so local verification is compile + function indexing, NOT an end-to-end Gemini call).

Existing building blocks to REUSE (no duplicated domain logic): `completeChoreFromNotification` core in `background_completion.dart` (own-connection background pattern), `CompletionService`, `calculateNextDueDate`, the quick_actions pending-navigation pattern in `app.dart`/`core/shortcuts/`, `WidgetSyncService`. If a snooze core exists (spec 15 may be landing in parallel in another worktree — it will NOT be in your checkout; do not depend on it, and do not implement snooze semantics beyond what this spec needs — if there's no snooze core, support only add/complete and note it).

NOTE: parallel-worktree rules — touch only `app/`; strings at END of strings files; expect your AndroidManifest/app.dart edits to be merged with siblings, keep them additive and tight.

## Scope (all inside `app/`)

### Layer 1 — intent command API (must land)

1. **Intents**: MainActivity (or a dedicated exported activity-alias that finishes immediately) handles:
   - `com.philipreese.chorebuddy.action.ADD_CHORE` with extras `name` (required), `recurrence` (optional: none|daily|everyOtherDay|weekly|monthly), `due` (optional ISO-8601 local datetime)
   - `com.philipreese.chorebuddy.action.COMPLETE_CHORE` with extra `name` (required; case-insensitive exact match first, then unique-prefix match against ACTIVE chores; ambiguous/no match → do nothing destructive, surface the failure)
   Exported, no custom permission (personal sideloaded device; Tasker must be able to fire them) — but validate every input; malformed extras must never crash or write garbage.
2. **Bridge to Dart**: a dedicated MethodChannel (pattern-match how quick_actions wires MainActivity → Dart, but keep it separate and minimal). Dart side: a `core/voice/voice_command_service.dart` that executes commands through the SAME domain services the UI uses (db insert respecting the UNIQUE name constraint, CompletionService for completes, notification reschedule + widget sync after both). If the app is cold-started by the intent, the command runs after first frame via the pending-action pattern (like pending shortcut routes).
3. **User feedback**: a flavored confirmation (snackbar if the app is foregrounded; otherwise a local notification "Mission logged: X") so a voice command is never silent.
4. **adb verification**: document in changes.md the exact `adb shell am start` commands that exercise both intents, and verify them against a debug build if an emulator/device is available; if none is, say so and rely on tests.

### Layer 2 — AppFunctions (land the declarations; runtime is preview-gated)

5. Add the `androidx.appfunctions` (app functions) dependency to the Android module and declare two functions — `addChore(name, recurrence?, dueDate?)` and `completeChore(name)` — whose Kotlin implementations fire the SAME intents from Layer 1 internally (or call the same MainActivity plumbing), so there is exactly one command path. Follow the current androidx.appfunctions release's schema/annotation model (check the version available on google() maven; it is alpha — pin the version).
6. If the alpha APIs are incompatible with the current AGP/Kotlin toolchain after a genuine attempt, implement Layer 1 fully, leave Layer 2 as a compiling stub behind a build flag or omit it, and state exactly what blocked it in changes.md. Do NOT let Layer 2 break the build.
7. Verification for Layer 2 = the app compiles with the functions declared + whatever local indexing check the SDK offers (`adb shell dumpsys appfunctions` or equivalent per current docs); an actual Gemini invocation is out of scope (preview-gated server-side).

### Tests

8. Dart-side: `voice_command_service` unit tests against in-memory db — add (with/without recurrence/due, duplicate name rejected gracefully), complete (exact match, unique-prefix match, ambiguous no-op), and the pending-cold-start path with fakes. No platform channels in tests; the MethodChannel handler goes behind a thin fakeable wrapper.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds (proves manifest + Kotlin incl. any AppFunctions declarations compile); changes.md lists files, the adb commands, the AppFunctions version pinned (or the blocker), and deviations.
