# Task: Remediate code-review blockers and harden verification

## Goal
Prevent reward overflow and partial Save-load mutation, then close the four actionable review suggestions without changing gameplay rewards or the Save V3 schema.

## Current behavior
- src/domain/progression.zig adds cash, Reputation, and XP with unchecked u32 arithmetic and marks the runtime payout guard before calculations/output complete.
- src/application/game.zig marks a mission completed before applying the payout.
- src/persistence/save.zig resets equipment and mission flags before confirming that a recognized Save is complete.
- The objective tracker is a 32-entry ID-based structure, but .agent/known-issues.md still describes an eight-bit mask.
- Operation save coverage bypasses the actual save command path.
- CI runs only the default Debug optimization and references mutable Action tags.

## Acceptance criteria
- [x] Cash, Reputation, and XP payout totals use checked arithmetic; overflow leaves player state and the payout guard unchanged.
- [x] Mission completion is recorded only after a successful eligible payout.
- [x] V3/V2/V1/legacy input is fully validated before any player or mission mutation; truncated/malformed input preserves all prior state.
- [x] Existing V3 writer layout and V2/V1/legacy migrations remain compatible, including a missing appended mission flag.
- [x] Tests cover overflow for all three reward fields and truncated/malformed Save non-mutation.
- [x] Operation save integration coverage invokes the actual game save command with an isolated directory and verifies active index -1.
- [x] Known-issues documentation describes the 32-entry objective tracker accurately.
- [x] CI runs Debug and ReleaseSafe and pins third-party Actions to reviewed immutable commit SHAs.

## Likely scope
- src/domain/progression.zig
- src/application/game.zig
- src/persistence/save.zig
- tests/progression_test.zig
- tests/equipment_test.zig
- tests/operation_test.zig
- docs/save-format.md
- .agent/known-issues.md
- AGENTS.md
- .agent/conventions.md
- .github/workflows/ci.yml

## Constraints and non-goals
- Save-format impact: none; keep V3 field order and all legacy readers.
- Compatibility and safety constraints: Zig 0.13.0; direct work on main; no external host/network/shell behavior.
- Explicitly out of scope: gameplay balancing, new features, Save version migration, and unrelated refactoring.

## Verification
- [x] Focused regression tests
- [ ] Zig formatting, build, and complete test suite in Debug and ReleaseSafe via GitHub Actions
- [x] Agent documentation check
- [ ] Independent review or explicitly documented self-review
