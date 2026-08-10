# ADR-0004: Migration execution via baton (`aer`) multi-vendor workers

Date: 2026-08-10 · Status: accepted

## Decision

The migration is executed by dispatching baton (`aer` ≥0.19.0) workers, with the lead session (Claude Code) writing specs, verifying results, and merging. Default role → vendor mapping:

| Role | Adapter / model / effort |
|---|---|
| Advise / planning | `agy` / `gemini-flash-3.6` / high |
| Implement | `agy` |
| Review (non-trivial slices) | `claude` / `claude-opus-4.8` / medium |

The workflow flexes per slice — different shapes/sizes may use different role chains. Goals: exploit multi-vendor strengths (implementer and reviewer are never the same vendor) and minimize the lead session's own token spend by delegating heavy reading/writing to workers.

## Operating rules

1. Worker env is stripped: specs must carry required env (`ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`) or the lead verifies builds after return.
2. `--room-dir` always outside the repo (`C:\Users\pbree\.aer\rooms\<slice>`), one fresh room per dispatch; room bookkeeping is never committed.
3. Worker output is a claim, not evidence — the lead builds/tests after every dispatch and reads review verdicts itself.
4. Specs are the steering wheel: exact scope, files, done-criteria, do-not-touch list, env. Small slices over big ones. Specs live in `specs/NN-<slice>.md`.
5. Announce expected subscription spend before each dispatch.
6. Commits per slice on the issue branch; migration stays bisectable.
