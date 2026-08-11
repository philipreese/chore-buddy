# ChoreBuddy — Domain Glossary

The ubiquitous language for this project. Use these terms exactly in issues, specs, code, and tests. The app's user-facing copy uses a superhero **Flavor** on top of these terms (e.g. a Completion Record renders as a "Mission Report") — the flavored strings are presentation, not domain vocabulary.

| Term | Meaning |
|---|---|
| **Chore** | A recurring or one-off task. Has a unique name (case-insensitive), optional next due date, optional recurrence, per-chore notification toggle. Active or Archived. |
| **Completion Record** | One completion event for a chore: timestamp + optional note. Retroactively editable (date and note) and deletable. |
| **Recurrence** | None / Daily / Every Other Day / Weekly / Monthly. On completion, next due = completion date + interval, **preserving the existing due time-of-day**. |
| **Tag** | A label with a name (lower-cased, ≤22 chars) and a preset color. Many-to-many with chores. |
| **Tag Filter** | Multi-select chips on the chore list; OR semantics (a chore matches if it has *any* selected tag). No selection = show all. |
| **Archive** | Soft-delete state for chores. Archived chores are read-only and restorable; completion history survives archiving. |
| **Undo Window** | The 5-second snackbar after completing a chore that reverts the completion (deletes the record, restores prior due date). |
| **Overdue** | A chore whose next due date is in the past. Overdue state recolors live (within ~1s of crossing the due instant), not just on refresh. |
| **Theme** | A seed color the UI palette is generated from (Material 3), with light/dark variants. Six named themes + Dynamic (Material You wallpaper color). |
| **Flavor** | A named voice pack: the complete set of user-facing copy in a particular tone. All copy is flavor-keyed. V1 ships one flavor, "Superhero". Themes may later bind to flavors. |
| **Backup** | User-initiated export of the database to a file, and import of such a file (replaces all data). The only data egress in the app. |

## Non-goals

- No accounts, sync, network, or telemetry — fully local, single-user.
- No iOS/Windows targets. Android only.
- No migration of legacy MAUI data (no surviving installs).
