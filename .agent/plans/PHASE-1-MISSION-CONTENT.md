# Phase 1 — Contract and Mission Content

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** Planned; implementation not authorized  
**Goal:** Increase contract variety and replayability before expanding the wider world.

## Shared baseline and constraints

Current contract data is defined by `Mission` in `src/domain/mission.zig` and authored in `src/catalog/mission_data.zig`. Runtime progress lives in `src/domain/mission_state.zig`; command coordination is in `src/application/game.zig`; terminal output is in `src/presentation/terminal.zig`. Current objective progress uses an eight-bit mask. Current command parsing accepts only a command and first argument. Re-audit before implementation.

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
Make repeat runs of a contract mechanically different through a small set of understandable conditions.

### Design direction
Potential modifier categories include heightened monitoring, encrypted storage, limited access, security sweeps, time pressure, decoy data, and unstable nodes. Each modifier must define exact effects, visibility, eligibility, stacking/exclusion rules, and reset behavior. Do not choose numeric costs in this plan.

Prefer authored or seeded deterministic selection. The same run seed and contract definition must reproduce the same modifier set. Display modifiers during preparation before the player commits.

### Likely scope
Mission modifier definitions/catalog, a run-specific modifier snapshot in mission runtime state, focused pure rule functions, application coordination, terminal presentation, tests/docs.

### Acceptance criteria
- [ ] A modifier is typed, documented, and has a bounded observable effect.
- [ ] The player sees all active modifiers before accepting the contract.
- [ ] Modifier combinations are validated; incompatible modifiers cannot coexist.
- [ ] A run's selected modifiers remain stable for that run and do not mutate static mission definitions.
- [ ] Detection, objective, reward, and retry interactions have boundary tests.
- [ ] Random selection, if used, is injectable/seeded and reproducible in tests.

### Dependencies
HT-006 Contract Board; existing Detection, topology, and preparation systems.

### Out of scope
Unexplained random punishment, unseeded nondeterminism, real-time timers, changing existing balance without approval.

## HT-008 — Hidden Objectives

### Goal
Reward careful exploration and analysis by allowing a player to discover optional objectives that are not fully disclosed in the initial briefing.

### Design direction
- Distinguish undiscovered, discovered, completed, and failed/unavailable states.
- Hidden goals must be hinted through fictional files, node descriptions, Contact intel, or operation events.
- Do not expose hidden objective details in the preparation screen.
- Existing objective tracking is an eight-bit mask. Before adding objective kinds or per-objective identities, design a scalable representation (for example, indexed objective state) and migrate all existing tests safely. Do not simply allocate a ninth bit.
- Define whether discovered/completed hidden goals reset per run or persist as collection/archive facts.

### Likely scope
Mission objective definitions, objective state representation in `src/domain/mission_state.zig` or a focused module, catalog data, game transitions, terminal output, tests, docs.

### Acceptance criteria
- [ ] Hidden objectives are not disclosed before their discovery condition is met.
- [ ] Discovery and completion are distinct, testable states.
- [ ] Hidden objectives do not block required contract completion unless explicitly authored as required and shown to the player.
- [ ] Existing five objective kinds and all current mission outcomes remain correct after any storage redesign.
- [ ] Objective counts beyond eight are supported safely before new kinds are introduced.
- [ ] Reward/XP/Reputation interactions are explicit and tested; no duplicate reward on repeated completion.

### Dependencies
HT-006 board for discoverable contract descriptions; HT-007 modifiers may add optional variation. Objective-storage design is a prerequisite.

### Out of scope
Branching narrative, hidden mandatory requirements, unbounded objective kinds without validation.

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
