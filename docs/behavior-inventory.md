# Behavior Inventory — MAUI reference → Flutter migration

Every observable behavior of the MAUI app (frozen at the PR #17 merge; MAUI code is the reference implementation until parity). Each behavior is tagged:

- **FEATURE** — port it (implementation free to change).
- **PRESERVE** — a behavior that *looks* like a hack but is genuinely wanted; keep the behavior, reimplement natively.
- **QUIRK** — compensation for MAUI's rendering/DI/layout problems; do **not** port. Listed so nobody "helpfully" recreates it.
- **RETHINK** — worked, but MAUI shaped it; redesign candidate for the structural UX pass.

## Navigation shell

| Behavior | Tag |
|---|---|
| 3 tabs: Chores / Archive / Tags; pushed pages: Details, Settings, About | RETHINK — tab set is up for grabs (Archive as a full tab is questionable; Settings/About via kebab menu popup is a MAUI-era pattern vs. standard Android patterns) |
| Chores tab hides the nav bar and uses a custom toolbar (title + kebab + search/sort row) | RETHINK — Material 3 has native app-bar/search patterns |
| TagsPage reachable 3 ways (tab, push, absolute route) with a message-based reload hack on return | QUIRK (the reload hack) / RETHINK (the triple entry) |

## Chore list (main surface)

| Behavior | Tag |
|---|---|
| Card: due-tinted clock icon, name, tag chips, optional last-note/last-completed, due date row, complete button | FEATURE |
| "Show details on cards" setting toggles the last-note/completed block | FEATURE |
| Swipe left = delete (confirm), swipe right = archive | FEATURE |
| Tag-filter chip row, multi-select, OR semantics | FEATURE |
| Search: toggle swaps sort bar for a search field; in-memory, name-only, case-insensitive contains; closing clears | FEATURE (name-only scope is RETHINK-able) |
| Sort: Urgency (due) / Name / Last Done; tap active chip to flip direction; switching resets to descending; nulls sort last | FEATURE |
| Complete → completion popup (date/time + note) → 5s UNDO snackbar → haptic 175ms → reschedule notification | FEATURE |
| Live overdue recoloring within ~1s of a chore crossing its due instant (timer runs only while page visible) | PRESERVE |
| Distinct empty states: no chores at all vs. filter matched nothing | FEATURE |
| FAB "+" → new chore | FEATURE |
| Scroll-to-chore when a notification is tapped | PRESERVE |
| Snackbar-anchored undo deleting the record and reloading | FEATURE |
| Manual list diffing (remove/insert/move instead of clear+repopulate) | QUIRK |
| ScrollTo suppressed except on Reset/first-Add | QUIRK |
| `IsHistoryVisible` precomputed at list-build to avoid cross-element bindings | QUIRK |
| Theme colors cached in static fields for the due-color converter | QUIRK |
| 80px footer spacer for FAB clearance | QUIRK |

## Chore details

| Behavior | Tag |
|---|---|
| Edit panel: name, tag picker, due date/time switch + pickers, recurrence picker, "Mission Reminder" (per-chore notification) switch, save | FEATURE |
| Unique name enforced, case-insensitive; violation → "Registry Conflict" alert | FEATURE |
| History list: date + note cards; tap to edit record (date and note, retroactively); swipe to delete record | FEATURE |
| New-chore mode (ChoreId=0) suppresses the empty-history state | FEATURE |
| Edit panel hidden behind an edit-toggle; panel is the CollectionView header | RETHINK — MAUI-shaped layout; likely a bottom sheet or dedicated edit screen in Material |
| Prefetch-during-slide-animation, deferred collection swap after animation, one-shot height measurement at opacity 0.01, threadpool animation commit, transient page/VM registrations | QUIRK (all — Flutter's pipeline makes these unnecessary) |
| Reliable keyboard dismissal on save/navigate (MAUI needed a forced InputMethodManager call) | PRESERVE — the *reliability* is the behavior |

## Tags

| Behavior | Tag |
|---|---|
| Create tag: name (≤22 chars, lower-cased/trimmed) + one of 12 preset colors with selection feedback | FEATURE (12-color palette may be re-derived from the new theme system) |
| Delete one tag / delete all (confirm) | FEATURE |
| One-shot load guard + frame-yield spinner hack | QUIRK |

## Archive

| Behavior | Tag |
|---|---|
| Read-only archived cards; swipe right = restore | FEATURE |
| `RemainingItemsThreshold` with no handler (dead paging attribute) | QUIRK (vestigial) |

## Settings / About

| Behavior | Tag |
|---|---|
| Theme picker (pie-wedge previews) | FEATURE — new form: 6 seed themes + Dynamic |
| Haptics toggle, global notifications toggle (off cancels all), show-details toggle | FEATURE |
| Export db via file-saver (after WAL checkpoint); import db (replace-all, restart required); last-backup timestamp on About | FEATURE — v1; restart requirement is RETHINK (drift can hot-swap) |
| About: version/build/package grid, "Powered By" chips, joke website button | FEATURE (low priority) |
| Menu popup (Settings / About / Delete All) with DI page pre-warming | QUIRK (the warming); menu itself RETHINK |

## Notifications

| Behavior | Tag |
|---|---|
| One-shot notification per chore at its due instant; notification id = chore id (cancel/replace semantics) | FEATURE |
| Not scheduled when: global off, per-chore off, no due date, or due date past | FEATURE |
| Tap → open app → scroll chore list to that chore | PRESERVE |
| Exact-alarm + boot-completed permissions | FEATURE (verify reschedule-on-boot actually works in the new impl — MAUI delegated to the plugin) |

## Cross-cutting

| Behavior | Tag |
|---|---|
| Superhero flavor copy everywhere, incl. themed empty states with bespoke copy per surface | FEATURE — moves behind the flavor-keyed string layer |
| 10 hand-built themes with light/dark variants, status bar follows theme | FEATURE — new form: 6 seeds (Chambray default, Blue Stone, Russet, Affair, Spicy Mustard, Woodland) + Dynamic, Material 3 generates palettes |
| Empty states gated on not-busy to avoid flicker | QUIRK (Flutter: model loading as a state, not a race) |
| Memory cache decorator over the data service (10-min TTL, manual invalidation) | QUIRK at the *implementation* level — drift reactive queries replace it |
| Repository + connection-factory layering | QUIRK (MAUI-era architecture; drift replaces) |
| WAL mode, tables auto-created on first run | FEATURE (implementation detail, drift handles) |

## Data model (open for redesign — see ADR-0002)

MAUI schema: `Chore` (unique name, LastCompleted, LastNote denormalized, NextDueDate, RecurranceType, IsNotificationEnabled, IsActive), `CompletionRecord` (ChoreId indexed, CompletedAt, Note), `Tag` (Name, ColorHex), `ChoreTag` (composite unique). Known warts worth fixing in the redesign: `LastCompleted`/`LastNote` denormalized onto Chore (derivable from records), `RecurranceType` misspelling, color stored as hex string despite a fixed palette.
