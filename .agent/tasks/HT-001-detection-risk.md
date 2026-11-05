# HT-001 — Detection & Risk System

**Status:** Implemented  
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

## Accepted implementation decisions

- Detection is a runtime-only integer meter from 0 to 100; it resets on mission start, completion, failure, and application restart (including restored active missions).
- Bands: Quiet 0–24, Noticed 25–49, Traced 50–74, Critical 75–99, Compromised 100.
- Action costs: first successful scan +10; first successful authentication +5; each incorrect password +15; first successful decryption +10; each incorrect decryption key +10; first successful metadata analysis +5; first successful extraction +5. Connect/disconnect, invalid commands, rejected prerequisites, and repeated successful actions cost 0.
- Reaching 100 immediately fails the contract, grants no contract rewards/XP/reputation, and applies a fixed $50 penalty capped at the current balance. The contract remains available for retry.
- No save-format change; V2, V1, and legacy formats remain untouched.

## Acceptance criteria
- [x] A dedicated, testable representation of simulated detection/risk exists with documented initial and maximum values.
- [x] At least the relevant mission actions have explicit, tested risk effects; safe/no-op actions do not accidentally increase risk.
- [x] Threshold behavior and consequences are defined, communicated, and tested at boundary values.
- [x] The player can inspect current detection/risk through an existing or deliberately added terminal command/status output.
- [x] Reset behavior on mission start, mission completion, failure, and restart is explicit and tested.
- [x] No real network, host, shell, credential, or external-system interaction is introduced.
- [x] Save compatibility is preserved unless a separate, explicitly justified migration is designed.
- [x] User/developer docs, task status, and roadmap reflect the implemented behavior.

## Non-goals
- No branching narrative or mission outcomes.
- No real intrusion detection, scanning, packet analysis, or host interaction.
- No equipment modifiers in this task; equipment integration belongs to HT-003.
- No network-node traversal; that belongs to HT-002.

## Verification
- [x] Unit tests for action risk changes, thresholds, resets, and edge cases.
- [x] Zig 0.13.0 formatting, build, and complete test suite (GitHub Actions run 42001487382 succeeded).
- [x] Agent documentation structure check (included in successful CI run).
- [ ] Independent review (or explicitly labelled self-review).
- [x] Inspect CI result before marking Implemented.

## Agent progress notes
- Implementation complete: detection state, action costs, threshold warnings, compromise failure, bounded cash penalty, retry behavior, status output, tests, and gameplay/architecture documentation are in place. Formatting, build, full tests, and agent-docs check passed in CI run [42001487382](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42001487382). Review was performed against the acceptance criteria; no separate reviewer agent was available, so this was a self-review.
