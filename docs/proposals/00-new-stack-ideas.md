# Advisory Report: ChoreBuddy Architecture & Native Stack Enhancements

**Date**: August 10, 2026  
**Author**: Advisory Subagent (Antigravity)  
**Target Output**: `advice.md`  
**Stack Baseline**: Flutter 3.41 / Dart 3.11 · Riverpod · Drift · go_router · Material 3 · Android Only  

---

## Executive Summary

This report delivers concrete architectural recommendations for migrating **ChoreBuddy** from .NET MAUI to Flutter. Following the decisions in **ADR-0001** through **ADR-0004** and the behavior classification in `docs/behavior-inventory.md`, this advisory addresses four key domains:

1. **Navigation & Information Architecture (IA)**: Redesigns all `RETHINK`-tagged navigation elements using modern Material 3 Android idioms while eliminating MAUI-specific workarounds.
2. **Drift Database Schema & Hot-Swap Engine**: Eliminates denormalized fields, replaces hex strings with structured color palettes, fixes typos, and designs an instant database export/import hot-swapping mechanism without requiring app restarts.
3. **New-Stack-Native Feature Matrix**: Evaluates Android-native capabilities (Predictive Back, Notification Actions, Widgets, Shortcuts, Tiles) for value, implementation cost, and parity phase.
4. **Implementation Slice Roadmap**: Defines a sequence of 10 incremental, testable implementation slices ordered from smallest foundation to final native polish.

---

## 1. Navigation & Information Architecture (IA)

### 1.1 Review of MAUI RETHINK Items
The legacy MAUI app contained several layout and navigation patterns shaped by platform limitations:
* **Dedicated Archive Tab**: Having "Archive" as 1 of 3 top-level tabs gave read-only soft-deleted items excessive visual weight.
* **Triple-Entry Tags Surface**: Tags could be reached via a tab, push navigation, or absolute route, requiring a message-bus reload hack (`QUIRK`) to sync UI state upon return.
* **Custom Toolbar Swap**: Swapping the sort bar with a search field manually in the app bar required custom header layout logic.
* **CollectionView Header Edit Panel**: Editing a chore occurred in an expander header at the top of a `CollectionView`, leading to complex height measurements and scroll conflicts.

### 1.2 Recommended Navigation Structure

```
                      +----------------------------------+
                      |         App Shell (M3)           |
                      +----------------------------------+
                                       |
           +---------------------------+---------------------------+
           |                                                       |
+---------------------+                                 +---------------------+
|   Active Chores     |                                 |   Archived Chores   |
|   (Primary Tab)     |                                 |   (Secondary Tab)   |
+---------------------+                                 +---------------------+
  - SearchBar (M3)                                        - Read-only cards
  - Tag Filter Chips                                      - Swipe right = Restore
  - Sort Chips/Menu                                       - Empty state
  - Card List + FAB "+"
           |
           +---> Top-Bar Action: Settings Icon ----> [ SettingsScreen ]
           |                                            - Theme Picker (6 Seed + Dynamic)
           |                                            - Toggles (Haptics, Notifs, Details)
           |                                            - Database Backup / Hot-Swap Import
           |                                            - Tag Manager Access
           |                                            - About / App Info
           |
           +---> Tap Card / FAB "+" ----------> [ ChoreDetailScreen (/chores/:id) ]
                                                    - Edit Form (Name, Tags, Due, Recurrence)
                                                    - Completion History List
                                                    - Retroactive History Edit / Delete
```

#### Primary Navigation Shell (`go_router` StatefulShellRoute)
* **Bottom Navigation Bar (`NavigationBar`)** with **2 primary tabs**:
  1. **Chores** (Active chores list, primary workspace).
  2. **Archive** (Archived chores list, read-only cards, swipe to restore).
* **Settings Access**: Accessible via a high-level **Settings Gear Action** in the `SliverAppBar` / `SearchBar` on the primary screen.
* **Tags Access**: Accessible via a dedicated **"Manage Tags" Chip** at the trailing end of the Tag Filter row, as well as an entry point within `SettingsScreen`.

#### Detail & Edit Surface Design: Dedicated Screen (`/chores/:id` & `/chores/new`)
* **Recommendation**: Use a **full-screen route** (`ChoreDetailScreen`) rather than a bottom sheet for chore viewing and editing.
* **Rationale**: Chore details contain both an extensive edit form (Name, Tag Selector, Due Date/Time, Recurrence, Notification toggle) **and** a complete scrollable **Completion History List** (date/time + note cards with inline editing and swipe-to-delete). Placing nested scrollable lists inside a Material 3 bottom sheet creates scroll-chaining collisions on mobile devices. A full `CustomScrollView` with slivers provides a smooth, native user experience.

#### Search & Sort Presentation
* **Search**: Use the Material 3 `SearchBar` anchored at the top of the Active Chores tab. Typing filters active chores live by name (case-insensitive contains). Tapping the clear icon resets the query.
* **Sort**: A compact `FilterChip` / `SegmentedButton` strip positioned directly under the search bar:
  * Options: **Urgency (Due Date)** [Default] | **Name** | **Last Completed**.
  * Tapping the currently selected active chip toggles sort direction (Ascending / Descending).
  * Null due dates / completion dates automatically sort last.

### 1.3 Alternatives Considered

| Dimension | Option A (Recommended) | Option B (Alternative) | Why Option A Was Chosen |
|---|---|---|---|
| **Edit Surface** | Full-Screen Route (`/chores/:id`) | Modal Bottom Sheet | Bottom sheets collide with the scrollable Completion History list. Full screen gives dedicated space for history management. |
| **Tab Configuration** | 2 Tabs (Active / Archive) | 3 Tabs (Active / Archive / Tags) | Tag management is an administrative task; elevation to a primary bottom navigation tab wastes prime screen real estate. |
| **Settings Access** | Top App Bar Gear Icon -> Full Screen | Overflow Kebab Menu Popup | Standard M3 Android top app bar action icon is cleaner and more discoverable than MAUI-style popup menus. |

---

## 2. Drift Database Schema & Hot-Swap Egress

### 2.1 Schema Redesign (Resolving Legacy Warts)
The legacy MAUI SQLite schema contained several anti-patterns addressed in this redesign:
1. **Denormalized `LastCompleted` & `LastNote`**: Removed from the `Chores` table. Derived dynamically via reactive Drift queries joining `CompletionRecords`.
2. **`RecurranceType` Typo**: Corrected to `RecurrenceType` enum stored as an integer (`0=none`, `1=daily`, `2=everyOtherDay`, `3=weekly`, `4=monthly`).
3. **Hex String Colors**: Replaced string hex codes (e.g. `#007ACC`) with a `color_index` integer (`0..11`) mapping to Material 3 theme-derived color swatches.
4. **Cascade Deletes**: Foreign keys configured with `ON DELETE CASCADE` so deleting a chore automatically removes its completion records and join entries.

### 2.2 Drift Table Definitions (Dart)

```dart
import 'drift/drift.dart';

enum RecurrenceType {
  none,
  daily,
  everyOtherDay,
  weekly,
  monthly,
}

@DataClassName('ChoreEntity')
class Chores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  IntColumn get recurrence => intEnum<RecurrenceType>().withDefault(Constant(RecurrenceType.none.index))();
  BoolColumn get isNotificationEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CompletionRecordEntity')
class CompletionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get choreId => integer().references(Chores, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('TagEntity')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().customConstraint('NOT NULL UNIQUE')(); // Lower-cased, <= 22 chars
  IntColumn get colorIndex => integer().withDefault(const Constant(0))(); // Swatch index 0..11
}

@DataClassName('ChoreTagEntity')
class ChoreTags extends Table {
  IntColumn get choreId => integer().references(Chores, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {choreId, tagId};
}
```

### 2.3 Reactive Queries & Derived Attributes
Instead of storing `LastCompleted` and `LastNote` on `Chores`, a Drift DAO or compiled view computes them on the fly:

```dart
class ChoreWithDetails {
  final ChoreEntity chore;
  final List<TagEntity> tags;
  final DateTime? lastCompleted;
  final String? lastNote;

  ChoreWithDetails({
    required this.chore,
    required this.tags,
    this.lastCompleted,
    this.lastNote,
  });
}

// Reactive query watching active chores with tags and latest completion
Stream<List<ChoreWithDetails>> watchActiveChoresWithDetails() {
  // Select Chores joined with Tags and subquery for MAX(completedAt) & latest note
  // Drift streams update subscribers instantly whenever Chores or CompletionRecords change.
}
```

### 2.4 Database Hot-Swap Architecture (Backup Export / Import)
MAUI required an app restart after importing a backup because static database singletons could not safely swap connections. Drift and Riverpod support hot-swapping:

```
  +-----------------------------------------------------------------------+
  |                        Backup Import Flow                             |
  +-----------------------------------------------------------------------+
     1. User selects backup file via File Picker.
     2. App verifies file integrity & schema compatibility.
     3. App checkpoints WAL: `PRAGMA wal_checkpoint(FULL);`
     4. App closes active Drift database executor: `await db.close()`.
     5. App replaces `chore_buddy.sqlite` file atomically.
     6. App invalidates Riverpod database provider: `ref.invalidate(databaseProvider)`.
     7. UI streams automatically reconnect to the new database file.
     8. Reschedule all active notifications from the imported database state.
```

* **Zero App Restart**: The user receives a success notification, and the entire UI updates to reflect the imported database instantly.

---

## 3. New-Stack-Native Feature Ideas

With Flutter and native Android integrations, several features that were difficult or impractical in MAUI become straightforward.

### 3.1 Feature Evaluation Matrix

| Feature Idea | User Value | Implementation Cost | Scope / Phase | Brief Rationale |
|---|---|---|---|---|
| **Predictive Back Gestures** | **High** | **S (Small)** | **v1 Scope** | Standard in Android 14+ / Flutter 3.16+ `PopScope`. Seamless back transition. |
| **Notification Action: "Complete"** | **High** | **S (Small)** | **v1 Scope** | Direct action button on notifications allowing chore completion without opening the app. |
| **App Shortcuts (Launcher Quick Actions)** | **Medium** | **S (Small)** | **Post-Parity** | Long-press app icon to access "Add Chore" or "View Overdue". |
| **Home-Screen Widget** | **High** | **M (Medium)** | **Post-Parity** | Home screen Glance/AppWidget displaying overdue/today chores with interactive complete checkboxes. |
| **Quick-Settings Tile** | **Low** | **M (Medium)** | **Post-Parity** | Pull-down status bar tile for quick chore creation. Niche utility. |
| **Wear OS Companion / Tile** | **Low** | **L (Large)** | **Post-Parity** | Smartwatch app/tile. High engineering overhead relative to single-user target. |

### 3.2 Deep-Dive: Selected Native Features

#### 1. Notification Action: Complete-from-Notification (v1 Scope)
* **Behavior**: When a chore reminder notification fires, it includes a "Complete" action button alongside the notification body.
* **Mechanism**: Using `flutter_local_notifications` with background action callbacks. Tapping "Complete" executes a background task that inserts a `CompletionRecord`, updates/calculates the next due date, cancels the notification, and reschedules the next recurrence.
* **Why v1**: Low engineering friction with high daily utility for a personal task manager.

#### 2. Home-Screen Widget (Post-Parity)
* **Behavior**: An Android home screen widget listing chores sorted by urgency, with interactive checkboxes.
* **Mechanism**: Implemented via `home_widget` package + native Android `AppWidgetProvider` or Jetpack Glance in Kotlin. Synchronized whenever Drift database writes occur.

---

## 4. Implementation Slice Roadmap

To maintain bisectability, minimal scope risk, and strict adherence to **ADR-0004** (Baton multi-vendor execution), the migration is broken down into **10 ordered implementation slices**, ordered from smallest foundation to final native polish.

```
  [Slice 01] Project Setup, Theme Engine & Superhero Strings
      |
  [Slice 02] Drift Database Schema & Core Reactive DAO
      |
  [Slice 03] Tag Domain & Tag Management UI
      |
  [Slice 04] Active Chore List Surface, Search & Sort
      |
  [Slice 05] Chore Completion, Undo Snackbar & Haptics
      |
  [Slice 06] Chore Detail/Edit Surface & History Management
      |
  [Slice 07] Archive & Restoration Surface
      |
  [Slice 08] Local Notifications & Alarm Rescheduling
      |
  [Slice 09] Settings, Theme Picker & Database Hot-Swap Backup
      |
  [Slice 10] Android Native Enhancements (Predictive Back, Notif Actions) & MAUI Cleanup
```

### Slice Details & Deliverables

#### Slice 01 — Project Setup, Theme Engine & Superhero Strings
* **Scope**: Initialize Flutter project structure, configure `Riverpod` root, implement Material 3 seed-color theme engine (6 named seed colors + Dynamic wallpaper color), and create the flavor-keyed string dictionary architecture (`Superhero` voice pack).
* **Deliverables**: `pubspec.yaml`, theme providers, flavor string provider, basic app bar skeleton.
* **Verification**: `flutter test` validating theme seed generation and flavor key resolution.

#### Slice 02 — Drift Database Schema & Core Reactive DAO
* **Scope**: Implement Drift SQLite schema (`Chores`, `CompletionRecords`, `Tags`, `ChoreTags`), auto-migrations, cascades, and reactive streams for derived fields (`LastCompleted`, `LastNote`).
* **Deliverables**: Drift table definitions, generated code, database provider, unit test suite covering CRUD & reactive updates.
* **Verification**: `flutter test test/database_test.dart` passing 100%.

#### Slice 03 — Tag Domain & Tag Management UI
* **Scope**: Implement Tag CRUD, preset 12-color swatch palette selector, tag filter chip row, and multi-select OR filter state logic.
* **Deliverables**: `TagManagerScreen`, tag filter chip bar component, tag unit & widget tests.
* **Verification**: Widget tests verifying tag creation, lower-casing enforcement, max 22 char limit, and selection toggles.

#### Slice 04 — Active Chore List Surface, Search & Sort
* **Scope**: Implement main chore list UI with M3 `SearchBar`, sort chip selector (Urgency / Name / Last Done), card due-color tinting, live overdue timer ticker (1s interval when active), swipe-to-archive / swipe-to-delete, and distinct empty states.
* **Deliverables**: `ChoreListScreen`, `ChoreCard`, search/sort providers, widget tests.
* **Verification**: Widget tests validating live overdue recoloring and search/sort filtering logic.

#### Slice 05 — Chore Completion, Undo Snackbar & Haptics
* **Scope**: Implement complete action handler, completion dialog (date/time + note), 5-second `Undo` snackbar with record deletion, haptic feedback integration, and next due date calculation.
* **Deliverables**: Completion dialog, snackbar undo manager, recurrence calculator tests.
* **Verification**: Unit tests for recurrence date calculation (preserving time-of-day) and snackbar undo state restoration.

#### Slice 06 — Chore Detail/Edit Surface & History Management
* **Scope**: Implement dedicated full-screen `/chores/:id` route for chore editing (name conflict validation, tag picker, due date/time pickers, recurrence selector, notification toggle) and full interactive Completion History list (date/note editing and swipe deletion).
* **Deliverables**: `ChoreDetailScreen`, form validation logic, history list components.
* **Verification**: Widget tests verifying unique name conflict alerts and history record mutation.

#### Slice 07 — Archive & Restoration Surface
* **Scope**: Implement read-only `ArchiveScreen`, swipe-right to restore chore action, empty archive state, and navigation tab integration.
* **Deliverables**: `ArchiveScreen`, archive tab in `NavigationBar`.
* **Verification**: Widget tests for restoring chores and verifying read-only details in archive mode.

#### Slice 08 — Local Notifications & Alarm Rescheduling
* **Scope**: Integrate `flutter_local_notifications`, exact alarm scheduling at due instant, global and per-chore notification toggles, tap-to-open with scroll-to-chore, and boot receiver rescheduling logic.
* **Deliverables**: Notification service, boot receiver configuration (`AndroidManifest.xml`).
* **Verification**: Integration tests verifying notification payload handling and scheduling gates.

#### Slice 09 — Settings, Theme Picker & Database Hot-Swap Backup
* **Scope**: Implement `SettingsScreen`, theme selector (pie-wedge swatches), haptic/notification toggles, and instant database export/import with Drift stream hot-swapping (zero restart).
* **Deliverables**: `SettingsScreen`, backup service, hot-swap connection provider.
* **Verification**: Unit test verifying SQLite file replacement, WAL checkpointing, and stream re-subscription.

#### Slice 10 — Android Native Enhancements & Final MAUI Cleanup
* **Scope**: Implement Predictive Back transitions, Complete action button on notifications, App Shortcuts, complete final end-to-end regression testing, and delete legacy `ChoreBuddy/` MAUI codebase in a single commit per ADR-0001.
* **Deliverables**: Android native configuration, final repository cleanup commit.
* **Verification**: `flutter build apk --release` clean build, 100% test suite pass, zero legacy MAUI code remaining.

---

## 5. Conclusion & Action Items for the Lead

1. **Adopt Section 1 IA**: Configure `go_router` with 2 bottom tabs (Active / Archive) and full-screen `/chores/:id` editing.
2. **Adopt Section 2 Schema**: Write the initial Drift schema without denormalized fields and with integer color swatches.
3. **Execute Slices via Baton**: Begin creating slice specs starting with `specs/01-project-setup-and-theme-engine.md`.
