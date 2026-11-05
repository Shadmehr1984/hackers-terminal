# Phase 1 — Contract and Mission Content

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** HT-006 implemented; HT-007 implemented and merged (PR #11; CI passed); HT-008 implementation in progress (design ADR 0010; owner authorization 2026-11-05); HT-009 planned  
**Goal:** Increase contract variety and replayability before expanding the wider world.

## Shared baseline and constraints

Current contract data is defined by `Mission` in `src/domain/mission.zig` and authored in `src/catalog/mission_data.zig`. Runtime progress lives in `src/domain/mission_state.zig`; command coordination is in `src/application/game.zig`; terminal output is in `src/presentation/terminal.zig`. At the planning baseline, objective progress used an eight-bit mask; HT-008 implementation replaces it with a bounded 32-entry per-objective tracker. Current command parsing accepts only a command and first argument. Re-audit before implementation.

Do not alter existing four mission IDs/order, rewards, puzzle answers, Detection costs, or save format incidentally. No branching story or dialogue trees.

## HT-006 — Contract Board

### Goal
Replace the impression of a short fixed mission list with a coherent in-game board of available, locked, completed, exclusive, and special contracts.

### Design direction
- Preserve the existing `missions` command unchanged and add a separate `board` command for the full overview.
- Add typed static categories to Mission; current authored categories are Data Recovery, Intelligence, Extraction, and Infiltration. Faction metadata remains deferred to HT-010.
- Board entries show identity, category, difficulty, base-to-maximum cash reward, XP, derived availability, and exact level/Reputation or busy-state reason. Faction/client metadata remains out of scope until its own system is approved.
- Keep contract definitions static; calculate availability from player state and derived rules.
- Avoid showing hidden puzzle clues or answers before launch.

### Likely scope
- Mission/contract data and catalog under `src/domain/mission.zig` and `src/catalog/`.
- Availability query/service in a focused domain/application module.
- `src/application/game.zig`, `src/presentation/terminal.zig`, command/gameplay docs, focused tests.

### Acceptance criteria
- [ ] Player can inspect all relevant contract states: available, locked, completed, exclusive/offer-gated, and unavailable.
- [ ] Every locked/unavailable entry gives a clear, accurate reason without leaking secret mission intel.
- [ ] Board ordering and availability are deterministic and covered by tests.
- [ ] Existing `missions`, `prepare`, `accept`, and Contact offer behavior remains compatible unless a deliberate command change is approved.
- [ ] No new persistence is required merely to display derived availability.

### Dependencies
Existing mission catalog, progression, Reputation, Contact offers. This is the first new feature.

### Out of scope
Online job boards, real clients, player-to-player contracts, story branches.

## HT-007 — Mission Modifiers

### Goal
Make repeat runs of an existing contract mechanically different through a small set of understandable, player-selected conditions.

### Owner-approved design
- Manual player selection during Preparation; no random/seeded selection.
- New separate command: `modifier [id|none]`. Preserve all existing command behavior, especially `missions` and `board`.
- Zero or one modifier per run; no stacking. No selection means normal mission rules.
- Exact effects and bonus are disclosed before `accept`; the selected modifier is copied into an immutable runtime session snapshot.
- Owner-confirmed on 2026-11-05: all three modifiers are available for all four current built-in contracts. Eligibility remains static catalog metadata.
- Modifier state and Security Sweep cadence are runtime-only. No Save V3 or legacy format changes.

| ID | Exact effect | Successful completion bonus |
|---|---|---|
| `heightened-monitoring` | +2 Detection per successful topology traversal, after Silent Boots adjustment | +$50 and +25 XP |
| `security-sweep` | +8 Detection after every third successful traversal (3, 6, 9, ...); revisits count; rejected moves do not | +$50 and +25 XP |
| `hardened-encryption` | Incorrect decryption-key attempt costs +15 Detection instead of +10; successful decryption remains +10 | +$50 and +25 XP |

The completion bonus is granted exactly once only when a modified contract completes successfully. It stacks with existing base rewards and earned optional-objective cash bonuses. It is not granted for compromise, cancellation, or incomplete runs. All modifier Detection events use the existing central Detection/failure path.

### Command contract
- `modifier`: show allowed choices, exact effects, bonus, and current selection during Preparation.
- `modifier <id>`: select an allowed ID for the prepared contract.
- `modifier none`: clear the selection.
- Reject selection outside Preparation, unknown IDs, and IDs not allowed by that contract without mutating state.
- Preparation starts with no selection. Accept snapshots the selection. Retry starts without the previous modifier.
- The existing command-plus-first-argument parser is sufficient; do not broaden it.

### Likely ownership
- New `src/domain/mission_modifier.zig`: typed IDs/definitions and pure effect metadata.
- `src/domain/mission.zig` / `src/catalog/mission_data.zig`: authored eligibility.
- `src/domain/mission_state.zig`: Preparation selection, Session snapshot, and successful traversal count for Security Sweep.
- `src/application/game.zig`: command, lifecycle, event calculations, and reward coordination.
- `src/application/detection.zig`: single central Detection application and compromise path.
- `src/domain/progression.zig`: one-time +25 XP bonus through existing progression flow.
- `src/presentation/terminal.zig`: pre-accept choice disclosure and active modifier display.
- `tests/`: focused domain and integration coverage, registered in `tests/test_all.zig`.

### Acceptance criteria
See the complete implementation contract in [HT-007 task brief](../tasks/HT-007-mission-modifiers.md). The implementation must cover typed definitions, eligibility, manual selection, pre-accept disclosure, immutable session snapshot, equipment/Detection interactions, sweep cadence, hardened decryption behavior, immediate compromise at 100, one-time payout, retry reset, and unchanged save compatibility. Zig 0.13.0 checks, docs, review, and actual CI are required before marking Implemented.

### Dependencies and scope boundaries
Depends on HT-006 Contract Board, current Mission Preparation, MissionSession, equipment loadout snapshots, Detection, and progression. Do not add other modifier types, random selection, stacking, real-time timers, new missions, baseline rebalance, or persistence. Design approval is recorded in [ADR 0009](../decisions/0009-mission-modifiers.md); implementation is complete and merged to `main`; follow the completed milestone record in the task brief.

## HT-008 — Hidden Objectives

### Goal
Reward careful exploration and analysis with optional objectives that are not fully disclosed in the initial briefing. Players discover them through fictional in-game evidence and actions, then choose whether to complete them.

### Owner-approved design (2026-11-05)
- Every objective has a stable mission-local ID independent of its event kind. Multiple objectives may share an event kind without sharing progress.
- Replace the current eight-bit kind mask as the authoritative state representation with bounded, allocation-free per-objective runtime state.
- Maximum 32 objectives per mission. Catalog data must be validated; definitions exceeding the bound are rejected safely.
- Objective states: `undiscovered`, `discovered`, `completed`, and `unavailable`.
- Support typed, deterministic discovery triggers: reaching a configured Node, inspecting a fictional File/evidence item, or performing a configured Action.
- Hidden objective descriptions and rewards remain absent from Preparation, briefing, Contract Board, and objective output until discovery. Discovery is reported once; the objective list then shows the discovered objective and its state.
- All hidden objectives are optional and never gate contract completion. A discovered objective completes only through its configured event and only once. An objective that becomes impossible is unavailable and cannot pay a reward.
- Preserve existing optional cash reward behavior. Hidden rewards are included exactly once in the normal successful completion payout.
- Preserve the existing all-optional Reputation rule: every authored optional objective, including hidden objectives, must be completed for the additional Reputation. Undiscovered or unavailable hidden objectives therefore prevent that bonus but do not block contract completion.
- Objective state is runtime-only and per-run. Fresh runs, retries, compromise resets, and restored active saves begin with authored initial states; visible objectives start discovered and hidden objectives start undiscovered.
- Save V3 writes and V2/V1/legacy reads remain unchanged. Persistent archive/discovery records are deferred to HT-022.
- No hidden mandatory goals, narrative branching, real system interaction, balance changes, or unrelated command changes.

### Implementation contract
The complete scope, likely module ownership, acceptance criteria, test requirements, implementation milestones, and progress log are in the [HT-008 task brief](../tasks/HT-008-hidden-objectives.md). The accepted design decision is recorded in [ADR 0010](../decisions/0010-hidden-objectives.md).

### Status and authorization
Design approved and implementation explicitly authorized by the owner on 2026-11-05. Implementation is in progress on `main`; follow the [HT-008 task brief](../tasks/HT-008-hidden-objectives.md) for progress and acceptance.

## HT-009 — Multi-stage Operations

### Goal
Create longer operations made of sequential contracts whose results affect later stages.

### Design direction
- Define an Operation as a static sequence of stage/contract references, not a branching story graph.
- A completed stage may unlock the next stage and pass narrowly defined mechanical facts (e.g. discovered intel, exposure flag, acquired evidence).
- Specify when cash/XP/Reputation are granted: per stage or only at operation completion. Avoid double-paying.
- Define stage failure, retry, compromised run, save/restart, and operation abandonment before coding.
- Preserve the existing rule that an active contract cannot be manually abandoned unless the owner explicitly changes it.
- Keep stage-local session data runtime-only by default. Persisting operation progress requires a separate migration decision.

### Likely scope
New operation domain/catalog types, operation progression state, mission outcome integration, application coordinator, terminal board/briefing output, tests, docs, possible save design (not pre-approved).

### Acceptance criteria
- [ ] Player can identify an operation, its stage count, current stage, and stage prerequisites.
- [ ] Stage transitions are deterministic and cannot skip required stages.
- [ ] Only explicitly defined mechanical outcomes carry forward; no narrative branch is introduced.
- [ ] Failure/retry does not duplicate rewards or corrupt stage progress.
- [ ] Restart behavior is documented and tested.
- [ ] Save compatibility is preserved unless a separate migration is approved and tested.

### Dependencies
HT-006 Contract Board; HT-008 objective model; HT-007 modifier snapshot model where applicable.

### Out of scope
Branching narrative, dialogue trees, multiplayer co-op, automatic real-time progression.

## Phase exit criteria

- [ ] Each feature has its own implementation authorization and feature-specific task brief/progress record.
- [ ] Contract availability, modifiers, objective discovery, and operation transitions have documented state lifetimes.
- [ ] No objective bit overflow or accidental Save V4 has been introduced.
- [ ] Each implemented feature has focused tests, updated docs, review, and verified CI before status changes to Implemented.
