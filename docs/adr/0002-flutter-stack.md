# ADR-0002: Flutter stack — Riverpod, drift, go_router, Material 3

Date: 2026-08-10 · Status: accepted

## Decision

- **State**: Riverpod (current generation, code-gen providers).
- **Persistence**: drift over SQLite. Reactive queries replace both the MAUI repository layering and the `IMemoryCache` decorator — watching queries makes manual cache invalidation unnecessary.
- **Navigation**: go_router.
- **Notifications**: flutter_local_notifications (exact alarms; verify reschedule-on-boot explicitly).
- **UI**: Material 3.

## Context

Owner is new to Flutter and asked for the most modern, stable, idiomatic stack. The MAUI data layer's complexity (repository + factory + cache decorator with TTL/invalidation rules) existed to serve MAUI's synchronous binding model; drift's streams are the idiomatic replacement.

## Consequences

- The database schema is **open for redesign** (not a 1:1 port). Known warts to fix: `LastCompleted`/`LastNote` denormalized onto Chore, `RecurranceType` misspelling, hex-string colors for a fixed palette. Export/import operates on the new schema.
- No hand-rolled caching layer; anything that feels like it needs one is a query-design problem first.
