# ADR-0005: Navigation/IA and v1 native features

Date: 2026-08-10 · Status: accepted

## Decision

Adopt the advisor proposal (`docs/proposals/00-new-stack-ideas.md` §1) as the app's information architecture:

- **Two bottom tabs** (`NavigationBar` via go_router `StatefulShellRoute`): Chores (primary) and Archive. Tags is *not* a tab.
- **Tags management**: a trailing "manage tags" chip on the filter row + an entry in Settings. This dissolves the MAUI triple-entry-point quirk and its return-reload hack.
- **Settings**: app-bar gear icon → full-screen route (replaces the MAUI kebab menu popup). About lives inside Settings.
- **Chore view/edit**: full-screen route `/chores/:id` (`/chores/new`), not a bottom sheet — the edit form plus scrollable completion history would scroll-chain badly in a sheet.
- **Search**: M3 `SearchBar` on the Chores tab; **Sort**: chip strip beneath it (Urgency default / Name / Last Completed; tap active chip to flip direction).

**V1 native features** (beyond parity): predictive back gestures, and a "Complete" action button on chore notifications (background completion write + reschedule without opening the app — costed M, not the advisor's S). Deferred post-parity: home-screen widget, app shortcuts, quick-settings tile, Wear.

## Consequences

- The drift schema and hot-swap import design from the same proposal (§2) are adopted under ADR-0002's schema-redesign mandate.
- Implementation follows the 10-slice roadmap (§4); slice specs live in `specs/`.
- The Flutter app lives in `app/` at the repo root; the MAUI code stays at `ChoreBuddy/` until the final cleanup slice archives/deletes it.
