# HT-001 — Detection & Risk System

**Status:** Planned  
**Priority:** 1 (first feature in the approved gameplay program)  
**Approved:** 2026-11-05  
**Depends on:** Existing mission/session model; no other new feature.

## Goal
Introduce a readable, testable, entirely fictional detection/risk mechanic that makes player actions carry different strategic costs. The player should be able to understand current exposure, see how actions affect it, and manage risk during a mission.

## Design direction
- Model detection as game state, not as real-world security telemetry.
- Define a small set of risk-producing simulated actions and explicit state transitions.
- Make thresholds and consequences legible to the player; avoid opaque or arbitrary punishment.
- Prefer deterministic rules initially so behavior is reproducible and easy to test. Randomness, if later justified, must be injectable/testable.
- Consider how detection resets or persists across missions before implementation; do not silently add persistence.
- Difficulty metadata may eventually influence risk, but current mission difficulty is descriptive only. Do not change that implicitly.

## Likely scope (verify before implementation)
- `src/mission_state.zig` or a focused new domain module for per-session exposure state.
- `src/game.zig` for applying action costs and validating consequences.
- `src/terminal.zig` and help/command docs for status presentation.
- Focused tests under `tests/`, registered in `tests/test_all.zig`.
- `.agent/conventions.md`, `AGENTS.md`, `docs/architecture.md`, `docs/gameplay.md`, and `docs/commands.md` only where the final design changes their contracts.

## Acceptance criteria
- [ ] A dedicated, testable representation of simulated detection/risk exists with documented initial and maximum values.
- [ ] At least the relevant mission actions have explicit, tested risk effects; safe/no-op actions do not accidentally increase risk.
- [ ] Threshold behavior and consequences are defined, communicated, and tested at boundary values.
- [ ] The player can inspect current detection/risk through an existing or deliberately added terminal command/status output.
- [ ] Reset behavior on mission start, mission completion, failure, and restart is explicit and tested.
- [ ] No real network, host, shell, credential, or external-system interaction is introduced.
- [ ] Save compatibility is preserved unless a separate, explicitly justified migration is designed.
- [ ] User/developer docs, task status, and roadmap reflect the implemented behavior.

## Non-goals
- No branching narrative or mission outcomes.
- No real intrusion detection, scanning, packet analysis, or host interaction.
- No equipment modifiers in this task; equipment integration belongs to HT-003.
- No network-node traversal; that belongs to HT-002.

## Verification
- [ ] Unit tests for action risk changes, thresholds, resets, and edge cases.
- [ ] Zig 0.13.0 formatting, build, and complete test suite.
- [ ] Agent documentation structure check.
- [ ] Independent review (or explicitly labelled self-review).
- [ ] Inspect CI result before marking Implemented.

## Agent progress notes
- Initial handoff: scope and acceptance criteria recorded; implementation has not started.
