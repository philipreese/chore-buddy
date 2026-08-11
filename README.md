# Chore Buddy 🦸‍

Chore Buddy is an Android app for tracking household chores with a "superhero" aesthetic — recurring tasks, completion history, tags, and due-date reminders, all fully local with no accounts or sync.

The app is a Flutter project living in `app/`. It replaced an earlier .NET MAUI implementation; see [ADR-0001](docs/adr/0001-migrate-to-flutter-android-only.md) for why, and `archive/` for the frozen MAUI reference code.

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
