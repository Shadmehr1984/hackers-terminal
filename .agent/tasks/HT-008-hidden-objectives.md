# HT-008 — Hidden Objectives

**Status:** Implemented on `main` (2026-11-05)  
**Program:** EXPANSION-001, Phase 1  
**Depends on:** HT-006 Contract Board, HT-007 Mission Modifiers, current mission/objective lifecycle

## Goal

Reward careful exploration and analysis with optional objectives that are not fully disclosed in the initial briefing. Players discover them through fictional in-game evidence and actions, then choose whether to complete them.

This brief is the approved design contract. The project owner authorized implementation on 2026-11-05; work is being performed directly on `main`.

## Owner-approved design

### Objective identity and storage

- Replace the current MissionObjectiveKind-keyed eight-bit completion mask as the authoritative progress representation with per-objective identity and state.
- Every authored objective has a stable, mission-local ID, independent of its gameplay/event kind. Multiple objectives may use the same event kind and must remain independently trackable.
- Each objective has one of four runtime states:
  - undiscovered: hidden from player-facing objective lists and not yet available to complete.
  - discovered: revealed and available to complete.
  - completed: successfully completed.
  - unavailable: can no longer be completed in this run.
- Use a bounded, allocation-free per-session representation with a maximum of 32 objectives per mission. Validate catalog definitions against this limit; reject invalid definitions safely rather than indexing out of bounds.
- Existing five objective event kinds remain supported: scan_target, authenticate, decrypt_file, extract_file, and analyze_metadata.
- Do not simply add more bits to the existing mask or use an enum ordinal as objective identity.

### Discovery triggers

Support three typed, deterministic trigger families in fictional game content:

1. **Node discovery:** reaching a configured topology node reveals the objective.
2. **File discovery:** inspecting/reading a configured fictional file or evidence item reveals it.
3. **Action discovery:** performing a configured in-game action reveals the objective.

Discovery conditions must be authored in mission catalog data, testable without terminal I/O, and idempotent. A trigger must not reveal unrelated objectives. The exact command/event integration should follow the current source audit during implementation; do not broaden the command parser without a demonstrated need.

### Visibility and briefing

- Hidden objective descriptions and rewards must not appear in Preparation, the initial briefing, Contract Board, or any pre-discovery output.
- The objective list shows only discovered objectives and their current states.
- Discovery produces clear terminal feedback and makes the newly discovered objective visible.
- Do not reveal hidden objective IDs, trigger conditions, answers, or rewards before discovery.

### Completion and rewards

- Every hidden objective in HT-008 is optional. Hidden objectives never gate successful contract completion.
- A discovered objective can be completed only through its authored event kind and only once.
- An objective that becomes impossible to complete in the current run transitions to unavailable; do not mark it completed or pay its reward.
- Existing visible required and optional objectives retain their current gameplay meaning.
- Preserve existing optional cash reward behavior. Hidden objective cash rewards are included exactly once in the normal successful-completion payout.
- Preserve the existing optional-objective Reputation rule: the additional Reputation is granted only when all authored optional objectives for the contract are completed. This includes hidden objectives. An undiscovered or unavailable hidden objective therefore prevents the all-optional bonus, but never blocks contract completion.
- No duplicate cash, XP, or Reputation payout on repeated events or completion paths.

### State lifetime and persistence

- Objective discovery and progress are runtime-only and per mission run.
- Starting a fresh run, retrying after compromise, or resetting a session resets every objective to its authored initial state.
- A visible objective starts as discovered; a hidden objective starts as undiscovered.
- Restart/load behavior remains unchanged: an active contract restored from a save starts at the accepted stage with objective progress reset.
- Do not change Save V3 writes or V2/V1/legacy reads. No Save V4 or persistent Data Archive behavior is part of HT-008.

### Scope boundaries

- No hidden mandatory objectives.
- No branching narrative, dialogue trees, or story-choice consequences.
- No persistent discovery/archive records; that belongs to the separately planned Data Archive feature (HT-022).
- No real network, host, filesystem, shell, or credential interaction. All evidence and actions are fictional game simulation.
- Do not change existing mission IDs/order, base rewards, XP thresholds, Detection costs, modifier behavior, or unrelated command behavior.
- Do not begin HT-009 or another feature as part of this work.

## Likely implementation ownership

Confirm current source before coding. Expected areas:

- src/domain/mission.zig or a focused objective domain module: objective IDs, event kinds, visibility/initial state, and typed discovery trigger definitions.
- src/domain/mission_state.zig or a focused objective-state module: bounded per-session state array, reset behavior, discovery/completion/unavailable transitions, and queries.
- src/catalog/mission_data.zig: authored visible and hidden objective definitions/triggers.
- src/application/game.zig and focused application services: translate successful simulated game events into objective discovery/completion events.
- src/presentation/terminal.zig: safe visibility-aware objective output and discovery feedback.
- tests/: focused domain and integration tests, registered in tests/test_all.zig.
- .agent/ and docs/: synchronized task, architecture, gameplay, command, and agent handoff documentation where contracts change.

Avoid creating a generic event framework or introducing unnecessary allocations. Keep domain rules independent of terminal I/O and dependencies one-way.

## Acceptance criteria

### Model and safety
- [x] Each objective has a stable mission-local ID distinct from its event kind.
- [x] Two objectives sharing one event kind can be independently discovered and completed.
- [x] Per-session state supports up to 32 objectives; 33+ authored objectives are rejected safely.
- [x] No bit shifts, indexing, or enum assumptions can overflow or alias objective state.
- [x] Existing five objective kinds remain correctly supported.

### Discovery and visibility
- [x] Node, file, and action triggers are typed, deterministic, idempotent, and independently tested.
- [x] Hidden objectives are absent from all pre-discovery player-facing output.
- [x] Discovery reveals the objective and produces clear feedback exactly once.
- [x] Invalid actions, rejected commands, and unrelated events do not reveal objectives.

### Completion and lifecycle
- [x] Discovered objectives complete only on their configured event and only once.
- [x] Hidden objectives never block required contract completion.
- [x] Unavailable objectives cannot be completed or rewarded.
- [x] Optional cash and all-optional Reputation behavior is explicit and tested, including undiscovered/unavailable objectives.
- [x] Retry, compromise, cancel, fresh accept, and restored-save behavior reset runtime objective state correctly.
- [x] Repeated events/completion paths never duplicate rewards.

### Compatibility and quality
- [x] Existing mission outcomes and visible objective behavior remain correct.
- [x] Save V3 writer and V2/V1/legacy readers remain unchanged and covered by tests.
- [x] No real-world system interaction is introduced.
- [x] Zig 0.13.0 formatting, build, and full test suite pass.
- [x] Documentation and agent handoffs are synchronized.
- [x] Code review findings are addressed; independent review availability is recorded honestly.
- [x] Actual GitHub Actions CI on the final main commit passes before status becomes Implemented.

Verification note: the original acceptance checklist was reconciled against the implemented tracker, catalog validation, discovery/reward integration, regression tests, compatibility coverage, and the recorded CI run. The review was a self-review; no independent reviewer was available.\n\n## Implementation milestones

1. **[x] Audit and model:** re-audited current main, tests, event flow, objective rendering, rewards, and reset lifecycle; finalized type/data shape and capacity validation.
2. **[x] State engine:** implemented bounded objective state and pure transitions; preserved existing behavior with focused tests.
3. **[x] Discovery integration:** added deterministic node/file/action triggers and visibility-safe terminal feedback.
4. **[x] Reward integration:** integrated optional rewards and all-optional Reputation semantics with idempotent completion.
5. **[x] Regression and handoff:** focused tests, documentation, self-review, and final GitHub Actions verification are complete.

Implementation is complete on `main`. No PR or merge was created; this follows the owner's main-first workflow.

## Progress log

- 2026-11-05: Owner approved the design and separately authorized implementation.
- 2026-11-05: Re-audited current `main`, including mission/session/catalog/application/presentation/reward/persistence paths and relevant tests. Confirmed the former eight-bit kind mask, objective event integration, optional reward aggregation, all-optional Reputation rule, reset-on-load behavior, and Save V3 boundaries.
- 2026-11-05: Added `mission_objectives.zig`: fixed-capacity 32-entry tracker, stable ID lookup, four states, typed Node/File/Action triggers, idempotent discovery/completion, unavailable transition, and optional reward/required/optional queries.
- 2026-11-05: Added stable IDs to built-in objectives and four hidden optional examples (node, file, action, and node triggers); integrated objective state initialization, successful-action/node/file discovery, `inspect <filename>`, safe objective visibility, and hidden reward exclusion from Contract Board estimates.
- 2026-11-05: Added/updated focused tests for tracker behavior, discovery trigger isolation, duplicate IDs, hidden objective validation, reward/reputation rules, reset behavior, and catalog validation.
- 2026-11-05: Updated gameplay, command, architecture, save-boundary, AGENTS, and module convention documentation.
- 2026-11-05: Kept the four built-in hidden-objective cash values at zero so the feature does not introduce unapproved cash-balance changes; the tracker and payout path support authored hidden cash rewards, and focused domain tests verify exactly-once reward aggregation. Existing visible optional rewards and base rewards remain unchanged.
- 2026-11-05: GitHub Actions run #674 passed on commit `27775f96f7e4b1536f12c23d578c13b7dd2c0d36`: Zig formatting, project build, all 111 Zig tests, and agent-documentation structure check succeeded. An earlier run exposed one incorrect expected payout in the new exactly-once test; the assertion was corrected and the full suite then passed.
- 2026-11-05: Self-review completed. No independent reviewer was available, and no manual interactive playtest was possible in the current workflow. The final documentation sync will be re-verified by CI.
