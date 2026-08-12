# Chore Buddy 🦸‍

Chore Buddy is an Android app for tracking household chores — recurring tasks, completion history, tags, and due-date reminders, all fully local with no accounts or sync.

The app is a Flutter project living in `app/`. It replaced an earlier .NET MAUI implementation; see [ADR-0001](docs/adr/0001-migrate-to-flutter-android-only.md) for why, and `archive/` for the frozen MAUI reference code.

## Features

- **Chores** with tags, per-chore icons (guessed from the name, or picked from a curated grid), flexible recurrence (daily, every other day, weekly, monthly, every N days), snooze, and duplicate
- **Urgency-sorted list** — Overdue / Due Today / Upcoming sections with live stat chips, plus search, sort, and tag filtering
- **Reminders** as exact-alarm notifications with Complete / Not Yet action buttons that work even when the app is closed
- **Home-screen widget** showing overdue and due-today chores with tap-to-complete checkboxes, plus a quick-settings tile and app shortcut for jumping straight to a new chore
- **Stats** — streaks, weekly counts, and a full Mission Log of completion history
- **Nine voice packs** (Standard by default — plus Superhero, Wheel of Time, Mission Control, Noir, Butler, Drill Sergeant, Cozy, and Grandma) that reskin every string in the app
- **Backup & restore** — manual export/import plus daily rotating auto-backups, all on-device

## Installing

Grab the `arm64-v8a` APK from the latest [GitHub Release](https://github.com/philipreese/chore-buddy/releases) and sideload it (`adb install` or open it on the phone). Releases are signed with a stable key, so updates install over each other.

## Tech stack

- **Framework**: Flutter (Android only)
- **State management**: Riverpod
- **Database**: [drift](https://drift.simonbinder.eu/) over SQLite
- **Navigation**: go_router
- **Notifications**: `flutter_local_notifications`, including a background "Complete" action on due-chore notifications

See `docs/adr/` for the architecture decisions behind these choices.

## Developer setup

### Prerequisites

- Flutter SDK (stable channel)
- Android SDK + a configured `ANDROID_HOME`
- A JDK (17+) for Gradle

### Getting started

```sh
cd app
flutter pub get
flutter run
```

### Testing

```sh
cd app
flutter analyze
flutter test
```

### Building

```sh
cd app
flutter build apk --release --split-per-abi
```

Tagged pushes (`v*`) build release APKs and attach them to a GitHub Release via `.github/workflows/release.yml`, for `adb install` sideloading — see that workflow for signing setup. There is no Play Store distribution.

## Documentation

- [`docs/adr/`](docs/adr/) — architecture decision records (stack choices, data model, navigation, native features, the MAUI migration itself)
- [`docs/behavior-inventory.md`](docs/behavior-inventory.md) — the full behavior parity contract carried over from the MAUI app
- [`docs/parity-checklist.md`](docs/parity-checklist.md) — where each parity-contract behavior is implemented in `app/`
- [`CONTEXT.md`](CONTEXT.md) — domain glossary
- [`specs/`](specs/) — the slice-by-slice implementation specs for the migration

## License

What's mine is yours? For this only of course, please be reasonable.

## Contact

Developer: Philip Reese

Project Link: https://github.com/philipreese/chore-buddy
