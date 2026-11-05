# HT-009 — Multi-stage Operations

- **Status:** Implemented (2026-11-06); committed directly to `main`; GitHub Actions run #733 passed.
- **Decision:** Runtime-only operation progress, approved by the owner on 2026-11-06.
- **ADR:** [0011 — Multi-stage Operations](../decisions/0011-multi-stage-operations.md)
- **Phase:** 1 — Contract and Mission Content
- **Implementation branch:** `main` only, per repository workflow. Do not create a feature branch or PR unless the owner explicitly asks.
- **Implementation authorization:** Owner explicitly authorized implementation with “شروع کن” on 2026-11-06. Work only within the approved scope; no later feature is authorized by this instruction.

## Goal

Add deterministic, linear Operations composed of existing contracts. Completing a stage unlocks the next stage and may transfer a narrowly defined mechanical fact that reveals an optional objective in a later stage. This is a runtime orchestration layer over the current contract loop, not a new narrative or mission engine.

## Approved decisions

1. Operation definitions are static catalog data: a stable ID, display name/description, and an ordered list of stage references. An operation is linear; there are no branches, choices, or graph traversal between stages.
2. Each stage references one existing contract by stable mission ID. Stage references in one operation must be unique. The first authored operation is `blackout-protocol`, with three stages: `job-01` (Cold Storage), `job-02` (Paper Trail), and `job-03` (Quiet Exit).
3. The player must meet the level/Reputation requirements of every referenced contract before starting the operation. A previously completed contract may still be replayed as an operation stage; normal standalone `prepare` continues to reject completed contracts.
4. The current stage is prepared and accepted through the existing contract preparation/accept flow. Starting an operation opens preparation for stage one. Successful extraction completes exactly the current stage and automatically prepares the next. The final successful stage completes the operation.
5. Only successful completion advances the stage index. A failed/compromised stage remains the current stage and can be retried from a fresh MissionSession. Facts from earlier successful stages remain available during retries; partial state from the failed stage is discarded.
6. No manual abandonment or cancellation of an active operation is added. Existing `cancel` remains for ordinary preparation only; it must not abandon an operation stage. A new operation cannot start while a contract, preparation, or another operation is active.
7. Stage rewards are paid per stage, using the existing contract reward rules. There is no additional Operation completion bonus. A stage's existing cash, XP, optional-objective, Reputation, and selected-modifier rewards are paid only if its contract had not already been completed before that stage run. Persisted `Mission.completed` is the durable exactly-once guard across restarts. Replaying a previously completed stage pays no stage rewards.
8. Existing objective rules remain intact: hidden objectives are optional, never block stage completion, and only completed optional objectives contribute their existing rewards/Reputation. No new reward amounts or balance changes are introduced.
9. Operation facts are typed, bounded, and runtime-only. For the first operation:
   - Completing hidden objective `maintenance-telemetry` in stage one grants `maintenance_telemetry`.
   - If that fact is present when stage two starts, hidden objective `routing-header` is revealed immediately; it still must be completed through the existing objective event.
   - Completing `routing-header` in stage two grants `routing_header`.
   - If that fact is present when stage three starts, hidden objective `relay-trace` is revealed immediately; it still must be completed through the existing objective event.
   - If a source objective is not completed, its fact is not granted and the later objective retains its ordinary HT-008 discovery trigger.
10. Facts are granted only after successful stage completion, never on discovery alone, failed runs, or partial progress. Incoming facts reveal only the authored optional hidden objective ID; they do not mutate static Mission or objective catalog data.
11. Runtime state is bounded and allocation-free. Use a maximum of 8 stages per operation and a typed `OperationFact` set (not arbitrary string-keyed maps or a generic event bus). Catalog validation rejects empty IDs, duplicate stage mission references, unknown mission IDs, invalid stage counts, and invalid fact/objective references safely.
12. **Runtime-only persistence decision:** active operation ID, stage index, facts, stage reward eligibility snapshot, and operation completion display state are not serialized. Save V3 writer and V2/V1/legacy readers remain byte/layout compatible. When `save` is invoked during an operation, persist player and existing mission completion flags but write no active mission index; the operation is not restored as a standalone contract.
13. After restart, the operation is available from stage one and all operation facts are cleared. Stages whose contracts were already completed remain replayable only through the operation and pay no rewards; incomplete stages can pay their normal rewards on their first successful completion. The player may replay the whole operation to reconstruct its facts and reach its final stage.
14. The operation completion marker is runtime-only and disappears on restart. No operation-specific reward or durable operation history is introduced. Existing contract history continues to show its constituent contracts.
15. Existing `missions`, `board`, `history`, `prepare`, and ordinary standalone contract behavior remain unchanged except that an operation temporarily owns the preparation/active-stage flow.

## Commands and terminal contract

The existing parser accepts a command plus only its first argument. Do not introduce a multi-token subcommand grammar. Use these commands:

| Command | Behavior |
| --- | --- |
| `operations` | List authored operations, stage counts, and derived availability/current runtime status. |
| `operation <id>` | Show operation overview, ordered stage contract names, and level/Reputation prerequisites without leaking undiscovered objective details. |
| `operation-start <id>` | Validate all stage prerequisites and availability, initialize runtime state, and open preparation for stage one. |
| `operation-status` | Show current operation, stage number/name, and already-earned mechanical facts. |
| Existing `accept <mission-id>` | Accept only the currently prepared operation stage when an operation owns preparation. |
| Existing `modifier` / `loadout` | Remain available during stage preparation and snapshot into that stage's MissionSession as today. |

While an operation is active, ordinary `prepare` and `cancel` cannot replace or abandon its stage. After a successful stage, the next stage is prepared automatically and must still be accepted explicitly. A failed stage is re-prepared for retry. The final stage completion clears the active operation and records a runtime-only completion marker.

## State and lifecycle model

- **Static catalog:** Operation definitions, ordered stage-to-mission references, typed incoming/outgoing fact rules.
- **Runtime OperationState:** active operation ID, current stage index, bounded facts, whether the current stage is reward-eligible, and last-completed operation ID for current-process presentation.
- **Runtime MissionSession:** remains stage-local and is reset between stages/retries exactly as existing mission sessions are.
- **Persistent existing state:** player balance/XP/Reputation/equipment and each existing contract's `completed` flag remain governed by Save V3.
- **Restart:** discard OperationState and MissionSession. Existing completed contract flags remain. Starting the operation again begins at stage one, replays completed stages without rewards, and reconstructs facts only by completing their source optional objectives again.
- **Save during operation:** pass `null` for the active mission index to the existing V3 writer. Do not add operation fields or change the save marker/layout.
- **Failure:** do not advance stage or discard facts earned by prior stages. Reset only the failed stage's MissionSession and reopen preparation for the same stage.
- **Success:** mark the stage contract completed; pay its existing reward once if it was incomplete before this stage run; derive outgoing facts from completed authored optional objective IDs; advance by exactly one stage.

## Implemented architecture ownership (verified against current source)

- `src/domain/operation.zig`: static Operation, OperationStage, typed OperationFact, and catalog validation contracts.
- `src/domain/operation_state.zig`: bounded allocation-free runtime lifecycle, stage transition, fact storage, retry/reset, and reward-eligibility snapshot.
- `src/catalog/operation_data.zig`: `blackout-protocol` and its three stage definitions.
- `src/domain/mission_objectives.zig`: add a narrow safe operation-facing reveal-by-stable-objective-ID transition; it may reveal only an authored hidden optional objective and must remain idempotent.
- `src/application/game.zig`: coordinate operation commands, current stage preparation/acceptance, success/failure transitions, and save behavior. Keep domain modules free of terminal I/O and persistence imports.
- `src/presentation/terminal.zig`: operation list, details, status, help, and reusable stage presentation. Hidden objectives remain undisclosed until their normal trigger or an approved incoming operation fact.
- `src/persistence/save.zig`: no schema changes; existing writer receives a null active index while an operation is active.
- `tests/`: domain, catalog validation, command, transition, retry, carry-over, reward idempotency, restart, and save-compatibility tests.
- Updated `docs/architecture.md`, `docs/gameplay.md`, `docs/commands.md`, `docs/save-format.md`, `AGENTS.md`, and agent handoff records as part of implementation.

## Explicitly out of scope

- Branching story graphs, dialogue trees, player-selected branches, or narrative consequences.
- Operation-specific cash/XP/Reputation rewards, new economy values, or balance changes.
- Persisting active operation progress, Save V4, or changes to V3/V2/V1/legacy layouts.
- Manual operation abandonment, stage skipping, or automatic acceptance of the next stage.
- More than 8 stages per operation, unbounded/dynamic fact maps, generic event buses, or real-time/network-backed progression.
- Real network scanning, host access, shell execution, credential collection, or external-system interaction.
- Changes to existing standalone contract command semantics, mission indices, modifier effects, objective reward amounts, Detection costs, or level thresholds.

## Acceptance criteria

- [x] Operation catalog validates stable IDs, 1–8 stages, unique stage references, known mission IDs, and valid fact/objective references.
- [x] Player can list and inspect operations, including stage count, ordered stage names, and prerequisites.
- [x] Operation start validates all stage unlock requirements atomically and does not mutate state on rejection.
- [x] Only the current stage can be prepared/accepted; stage order cannot be skipped or changed.
- [x] Successful stage completion advances exactly one stage and prepares the next; final completion is reported once.
- [x] Failed/compromised stage retries the same stage from a clean MissionSession; prior facts survive and failed-stage partial facts do not.
- [x] Stage-one and stage-two objective completions grant only their authored facts; incoming facts reveal only the specified optional hidden objective, idempotently.
- [x] Undiscovered objective details remain hidden unless an authored trigger or approved incoming fact reveals them.
- [x] Existing per-contract cash, XP, optional objective, Reputation, and modifier rewards are paid once per contract across standalone play, operation play, and restart replay; no operation bonus is added.
- [x] Previously completed stage contracts can be replayed in an operation without repeating any reward.
- [x] Operation state and facts reset on restart; a save made during an operation does not restore its stage as a standalone active mission.
- [x] Save V3 bytes/layout and V2/V1/legacy readers remain unchanged; existing standalone active-mission save behavior remains unchanged.
- [x] Existing commands and standalone contract flow retain their behavior.
- [x] Focused tests, full Zig 0.13.0 formatting/build/test, docs, self/independent review (independent review if available), and main-branch CI are complete before status becomes Implemented.

## Implementation milestones

1. **[x] Audit and model:** re-audit current main, mission success/failure/reset paths, reward idempotency, save behavior, parser, tests, and catalog; finalize exact types and invariants.
2. **[x] Domain/catalog:** add bounded Operation/OperationStage/OperationFact definitions, OperationState lifecycle, validation, and the first static operation.
3. **[x] Stage orchestration:** integrate operation list/details/start/status with preparation and accept flow; preserve standalone commands and stage order.
4. **[x] Carry-over:** implement safe reveal-by-objective-ID and typed fact grant/consume rules for the three-stage operation.
5. **[x] Recovery/rewards/save:** handle stage failure/retry, previously completed stage replay, per-stage reward eligibility, and runtime-only save/restart behavior without changing Save V3.
6. **[x] Regression and handoff:** add focused and integration tests, update gameplay/command/architecture/save/agent docs, review, and verify main CI.

## Progress log

- 2026-11-06: Owner approved Runtime-only operation progress and requested final design plus agent handoff documentation.
- 2026-11-06: Design finalized and recorded in ADR 0011; owner explicitly authorized implementation with “شروع کن”.
- 2026-11-06: Implemented the bounded domain model, catalog, runtime state, command orchestration, stage transitions, fact carry-over, retry, completed-stage reward suppression, and runtime-only save behavior directly on `main`.
- 2026-11-06: Added domain/integration coverage for catalog validation, atomic start rejection, operation ownership, stage-one-to-three fact carry-over, compromise retry during movement and extraction, completed-stage replay, and unchanged V3 active-index behavior.
- 2026-11-06: Updated gameplay, command, architecture, save-format, root agent, ADR, roadmap, phase plan, and handoff documentation.
- 2026-11-06: GitHub Actions run [#733](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42120909577) passed formatting, build, full Zig tests, and agent documentation checks.
- 2026-11-06: Self-review completed. No independent second reviewer or manual interactive playtest was available; no claim of either is made.