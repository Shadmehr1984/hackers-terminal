# Task: Phase 3 — API and design-pattern refinement

Status: In Progress.

## Goal
Refine the existing public model APIs and remove duplicated domain policy without changing gameplay, command behavior, import compatibility, or persistence.

## Current behavior
- `UtilityEquipment` is the typed utility catalog in `src/domain/player.zig`.
- `Equipment.movementDetectionCost` and `Equipment.incorrectAuthenticationDetectionCost` encode the utility/upgrade cost tables.
- `MissionLoadout` in `src/domain/mission_state.zig` duplicates those same cost tables so an active mission can use its launch-time snapshot.
- `game.runCommand` is the single public command-dispatch entry point. Its command branches share mission/player/session state and terminal output; extracting them into separate handlers without a clear ownership boundary would increase coupling.
- `MissionSession.progress` and `MissionSession.connected` represent independent state dimensions: disconnecting must not undo completed mission stages.

## Accepted design
- Make `UtilityEquipment` the single source of truth for the pure cost profile associated with each utility and upgrade level.
- Keep `Equipment` and `MissionLoadout` as small adapters: one reads live equipped equipment, the other reads the immutable per-run snapshot.
- Keep the existing public method names and signatures; add only the enum-level cost methods. Preserve the original numeric results and defaults.
- Do not convert mission progress and connection into one tagged union: their states are intentionally orthogonal.
- Do not split the command dispatcher or add Options Structs/indirection without a demonstrated independent boundary or excessive parameter set.
- Preserve the compatibility facade modules and all existing public declarations.
- Do not modify save serialization or save compatibility.

## Acceptance criteria
- [ ] Utility cost tables exist in one implementation only.
- [ ] Equipment and MissionLoadout delegate to the shared UtilityEquipment calculations.
- [ ] Tests cover both utilities at every supported upgrade level, base costs, and non-matching utility behavior.
- [ ] Existing Equipment and MissionLoadout public APIs remain source-compatible.
- [ ] Mission state semantics, command behavior, and Detection outcomes remain unchanged.
- [ ] Save V3 writing and V2/V1/legacy reads remain untouched.
- [ ] Architecture/convention docs and an accepted ADR record the ownership rule.
- [ ] Zig 0.13.0 formatting, build, and full test suite pass in CI.
- [ ] Self-review against `.agent/review-checklist.md` is recorded; independent review limitation is stated if applicable.

## Likely scope
- `src/domain/player.zig`
- `src/domain/mission_state.zig`
- `tests/equipment_test.zig`
- `AGENTS.md`, `.agent/conventions.md`, `.agent/decisions/0008-shared-detection-profiles.md`
- `docs/architecture.md`, `docs/development.md`

## Constraints and non-goals
- Save-format impact: none.
- Compatibility and safety: Zig 0.13.0; retain old `src/*.zig` facades; retain public APIs; all behavior remains fictional and offline.
- Explicitly out of scope: gameplay balancing, command syntax changes, save schema changes, mission-state union redesign, dispatcher decomposition, speculative abstractions, and unrelated cleanup.

## Verification
- [ ] Focused Detection-cost tests
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig build test`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] Diff and API compatibility self-review
- [ ] Independent review completed or unavailable status recorded
