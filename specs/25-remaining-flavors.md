# Spec 25 — Six more voice flavors

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` in the FOREGROUND. Healthy suite = 15–30s; minutes = failures (each stalls ~10 min in teardown). Stream test output to a file; never pipe through `tail`/`head`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Spec 24 (just merged) built the flavor system: `AppFlavor` enum + persisted picker + `Map<AppFlavor, AppStrings>` registry, with Superhero, Standard, and Wheel of Time implemented. This spec adds six more flavors. Each is: one new strings file implementing `AppStrings`, one enum value, one registry entry, one display name. The compiler enforces completeness (~190 members each).

## Universal rules for every flavor

- Flavor lives in TONE; every string stays instantly parseable — a user must always know what a button does. Destructive confirm buttons stay unambiguous.
- Parameterized strings keep their parameters meaningful (`decommissionMessage(choreName)` etc. must still name the chore).
- Section labels (Overdue/Today/Upcoming/Unscheduled), snooze options, and validation/error messages may be flavored but never obscured.

## The six flavors

1. **Mission Control** (`missionControlStrings.dart`, enum `missionControl`, display "Mission Control") — NASA/spaceflight: "Flight Plan", "Schedule Launch", "Mission success", "Decommissioned", "Flight Log", "Go for launch", "Holding at T-minus…" (snooze register), notifications "Mission update: <chore>".
2. **Noir Detective** (`noirStrings.dart`, `noir`, "Noir") — dry, understated, moody: "Open Cases", "New Case", "Case closed.", "Cold Cases", "Case Files", delete = "Burn the file", empty state: "Quiet night. Too quiet."
3. **Butler** (`butlerStrings.dart`, `butler`, "Butler") — impeccable manor-house politeness: "The Household Ledger", "A New Duty", "Very good.", "The Registry", snooze = "Perhaps later", danger zone rendered as regretful formality ("If you are quite certain…").
4. **Drill Sergeant** (`drillSergeantStrings.dart`, `drillSergeant`, "Drill Sergeant") — ALL-CAPS bark where it lands, but keep dialogs/errors readable (bark in titles, clarity in messages): "TASK LIST", "NEW ORDERS", "OUTSTANDING!", "DISCHARGED", stats = "AFTER-ACTION REPORT", empty state = "NOTHING TO DO? DROP AND GIVE ME TWENTY."
5. **Cozy Cottage** (`cozyStrings.dart`, `cozy`, "Cozy") — gentle and warm, no shouting, occasional 🌿/🫖 where tasteful: "Little Tasks", "Add a little task", "Lovely.", "Resting", stats = "The Almanac", overdue section softened but honest ("Waiting patiently").
6. **Grandma** (`grandmaStrings.dart`, `grandma`, "Grandma") — loving passive-aggression: "Things You've Been Meaning To Do", "Another one?", "Well, finally.", "The Pile", stats = "The Record", notification: "Sweetheart, the <chore> isn't going to do itself." Guilt as garnish, never mean.

## Tests

- Extend spec 24's completeness canary to cover all nine flavors.
- One picker test update if the option list is asserted anywhere.
- Everything existing stays green (default flavor unchanged).

## Done criteria

- `flutter analyze` clean; `flutter test` green in normal time; `flutter build apk --debug` succeeds.
- changes.md: the six files, any strings where a flavor deliberately stays literal, deviations.
- Nothing outside `app/`.
