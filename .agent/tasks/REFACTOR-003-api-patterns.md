# Task: Phase 3 — API and design-pattern refinement

Status: Completed; verified by GitHub Actions run 42054512169.

## Goal
Refine the existing public model APIs and remove duplicated domain policy without changing gameplay, command behavior, import compatibility, or persistence.

## Current behavior
- `UtilityEquipment` is the typed utility catalog in `src/domain/player.zig`.
- `Equipment.movementDetectionCost` and `Equipment.incorrectAuthenticationDetectionCost` encoded the utility/upgrade cost tables.
- `MissionLoadout` in `src/domain/mission_state.zig` duplicated those same cost tables so an active mission could use its launch-time snapshot.
- `game.runCommand` remains the single public command-dispatch entry point. Its command branches share mission/player/session state and terminal output; extracting them into separate handlers without a clear ownership boundary would increase coupling.
- `MissionSession.progress` and `MissionSession.connected` represent independent state dimensions: disconnecting must not undo completed mission stages.

## Accepted design
- `UtilityEquipment` is the single source of truth for the pure cost profile associated with each utility and upgrade level.
- `Equipment` and `MissionLoadout` remain small adapters: one reads live equipped equipment, the other reads the immutable per-run snapshot.
- Existing public method names and signatures remain unchanged; only additive enum-level cost methods were introduced. Original numeric results and defaults are preserved.
- Mission progress and connection were not converted into one tagged union because their states are intentionally orthogonal.
- The command dispatcher was not split and no Options Structs/indirection were added without a demonstrated independent boundary or excessive parameter set.
- Compatibility facade modules and existing public declarations remain available.
- Save serialization and compatibility were not modified.

## Acceptance criteria
- [x] Utility cost tables exist in one implementation only.
- [x] Equipment and MissionLoadout delegate to the shared UtilityEquipment calculations.
- [x] Tests cover both utilities at every supported upgrade level, base costs, non-matching utility behavior, and snapshot isolation.
- [x] Existing Equipment and MissionLoadout public APIs remain source-compatible.
- [x] Mission state semantics, command behavior, and Detection outcomes remain unchanged.
- [x] Save V3 writing and V2/V1/legacy reads remain untouched.
- [x] Architecture/convention docs and an accepted ADR record the ownership rule.
- [x] Zig 0.13.0 formatting, build, and full test suite pass in CI.
- [x] Self-review against `.agent/review-checklist.md` is recorded; independent review was unavailable.

## Likely scope
- `src/domain/player.zig`
- `src/domain/mission_state.zig`
- `tests/equipment_test.zig`
- `.agent/conventions.md`, `.agent/decisions/0008-shared-detection-profiles.md`
- `docs/architecture.md`, `docs/development.md`

## Constraints and non-goals
- Save-format impact: none.
- Compatibility and safety: Zig 0.13.0; retain old `src/*.zig` facades; retain public APIs; all behavior remains fictional and offline.
- Explicitly out of scope: gameplay balancing, command syntax changes, save schema changes, mission-state union redesign, dispatcher decomposition, speculative abstractions, and unrelated cleanup.

## Verification
- [x] Focused Detection-cost tests
- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig build test`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Diff and API compatibility self-review
- [x] Independent reviewer unavailable; self-review performed.

## Self-review notes
- The cost values remain movement 5/4/3/2 and incorrect-authentication 15/12/9/6 for no matching utility / upgrade levels 0/1/2.
- Existing Equipment and MissionLoadout method signatures remain unchanged; only additive UtilityEquipment methods were introduced.
- The mission loadout continues to use its captured utility and level even if live equipment changes later.
- MissionSession progress and connection remain independent, preserving disconnect semantics.
- No save or command-dispatch source was changed. The V3 writer and V2/V1/legacy loaders are untouched.
- No independent second reviewer was available; this is explicitly a self-review, not an independent review.
- GitHub Actions run 42054512169 completed successfully: Zig 0.13.0 install, formatting, build, full tests, and agent-doc structure check all passed.
