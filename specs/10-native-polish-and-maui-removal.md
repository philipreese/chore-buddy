# Spec 10 — Native polish, release CI, MAUI removal

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- ADR-0001 (archive-then-delete plan, GH Actions releases), ADR-0005 (complete-from-notification is v1; predictive back already done in slice 01).
- `docs/behavior-inventory.md` — the final parity checklist; every FEATURE/PRESERVE row should now exist in `app/`.
- Existing: notification service/scheduler (slice 08), CompletionService (slice 05), `docs/reviews/08` F2 lesson (always schedule from a fresh DB read).

## Scope

### A. Complete-from-notification (inside `app/`)

1. Add a "Complete" action button to chore notifications (`AndroidNotificationAction`).
2. Background handler (`onDidReceiveBackgroundNotificationResponse` — top-level/`@pragma('vm:entry-point')` function): opens its own database connection (the app may not be running), inserts a CompletionRecord (now, empty note), advances the due date via the existing `calculateNextDueDate`, cancels the shown notification, schedules the next one from the freshly-written row, closes the connection. Reuse domain code (CompletionService/recurrence calculator) — do not duplicate the math.
3. Foreground tap on the action must behave identically (foreground response handler with actionId).
4. The main app's streams pick up the change when next opened/resumed (drift re-reads on resume are automatic since the write went through sqlite; document any caveat found).
5. Tests: the background-completion logic factored testably (in-memory db): record inserted, due advanced, next notification scheduled from fresh state; no test touches platform channels.

### B. Release CI (repo root — the ONE exception to "nothing outside app/", plus section C)

6. `.github/workflows/release.yml`: on tag push `v*` — flutter stable setup, `flutter test` in `app/`, `flutter build apk --release --split-per-abi`, attach the arm64 (and armeabi) APKs to a GitHub Release. Signing: use the debug keystore checked in CI-side via secrets if configured; otherwise build with the default debug signing and note it (personal sideload per ADR-0001; keystore secret setup is a human step — emit clear TODO comments naming the secrets).

### C. MAUI removal

7. `git mv ChoreBuddy/ archive/ChoreBuddy-maui/` plus `ChoreBuddy.sln`, `.agent/` → `archive/`. Add `archive/README.md`: one paragraph — frozen MAUI reference implementation, superseded by `app/` per ADR-0001, delete after confidence period.
8. Update root `README.md`: the project is now the Flutter app in `app/`; how to build/run/test; link to docs/adr and the behavior inventory.
9. Do NOT delete the archive folder itself — that's a later human decision.

### D. Final parity sweep

10. Walk `docs/behavior-inventory.md` FEATURE/PRESERVE rows; for each, name the implementing file in a new `docs/parity-checklist.md` (row → status → file). Anything missing or intentionally changed gets flagged, not silently skipped.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green in `app/`; `flutter build apk --debug` succeeds; output in changes.md.
- `docs/parity-checklist.md` complete with zero unexplained gaps.
- changes.md lists files and deviations.
