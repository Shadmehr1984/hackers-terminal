# QUALITY-006 — Reject out-of-range active Save indices atomically

- Status: Implemented
- Origin: Follow-up to the comprehensive code review of commit `60e8ad971118ec9c50b369c23616fddb8312a2af`
- Owner approval: Explicitly approved on 2026-11-06.

## Goal

Reject V3, V2, and V1 saves whose non-negative active mission index is outside the current mission catalog, without partially mutating caller-owned player or mission state.

## Current behavior

`src/persistence/save.zig` parses active indices and rejects values below -1, but it does not check non-negative indices against `missions.len` during the preflight validation pass. The loader can therefore commit player/equipment/completion state before normalizing the out-of-range active candidate to no active mission.

An in-range active index pointing to a mission marked completed in the same save is an existing compatibility behavior: completion state is loaded, but the mission is not restored as active. QUALITY-003 explicitly established this behavior and it remains unchanged.

## Acceptance criteria

- [x] Validate active mission indices against the current mission count during `validateSave`, before any caller-owned state is mutated.
- [x] Apply the same bounds rule to V3, V2, and V1; legacy format has no active mission field.
- [x] Preserve the `-1` no-active-mission sentinel.
- [x] Preserve the existing behavior for an in-range active index pointing to a completed mission.
- [x] Add regression coverage for out-of-range active indices in V3, V2, and V1.
- [x] Verify rejection preserves Player balance, Reputation, XP, decryptor, utility ownership/equipment/level, and all mission completion flags.
- [x] Preserve Save V3 field order, version markers, writer behavior, and all legacy migration rules.
- [x] Update `docs/save-format.md` and this handoff brief.
- [x] Zig formatting, build, full tests, and agent-doc check passed in both Debug and ReleaseSafe CI jobs.
- [x] Actual GitHub Actions run [#799](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42212869142) completed with `success` for commit `553cf4e488621afb5610d02b72e5583b8226a0a0`.
- [x] Self-review against `.agent/review-checklist.md` completed; no independent reviewer was available.

## Scope

- `src/persistence/save.zig`
- `tests/equipment_test.zig`
- `docs/save-format.md`
- `.agent/tasks/README.md`
- This task brief

## Constraints and non-goals

- No Save schema or serialization changes.
- No change to the established completed-active-mission normalization behavior.
- No gameplay or progression changes.
- Target Zig 0.13.0 and work directly on `main`.
- No unrelated refactoring.

## Implementation notes

- Added a shared active-candidate validator that accepts `-1`, rejects values below `-1`, and checks every non-negative index against the supplied mission count.
- V3/V2/V1 validation invokes the helper in the preflight pass, before `loadGameFromBytes` constructs and commits the loaded state.
- Added one table-driven regression test covering all three versioned formats and asserting complete preservation of pre-existing player/equipment/mission state.
- The existing QUALITY-003 regression for an in-range index pointing to a completed mission remains unchanged.

## Verification

- [x] `zig fmt --check test_root.zig build.zig src tests` (CI, Debug and ReleaseSafe)
- [x] `zig build` (CI, Debug and ReleaseSafe)
- [x] `zig build test` (CI, Debug and ReleaseSafe)
- [x] `sh scripts/check-agent-docs.sh` (CI, Debug and ReleaseSafe)
- [x] Inspect actual GitHub Actions result for the resulting `main` commit.
- [ ] Self-review against `.agent/review-checklist.md`; state whether an independent reviewer was available.
