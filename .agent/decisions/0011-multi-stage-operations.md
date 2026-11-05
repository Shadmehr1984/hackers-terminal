# ADR 0011 — Multi-stage Operations

- **Status:** Accepted — design only
- **Date:** 2026-11-06
- **Feature:** HT-009 — Multi-stage Operations
- **Decision owner:** Project owner

## Context

Hacker's Terminal currently executes one contract at a time. HT-009 introduces longer, linear operations that sequence existing contracts and transfer a small amount of mechanical state between stages. The design must coexist with mission preparation, modifiers, hidden objectives, progression rewards, and the positional Save V3 format.

The owner explicitly selected **Runtime-only** operation progress on 2026-11-06. The operation must not create a persistence migration or accidental Save V4.

## Decisions

1. An Operation is static catalog data containing a stable ID and an ordered sequence of unique existing mission IDs. It is linear; there is no branching graph or dialogue system.
2. The first operation is `blackout-protocol`: `job-01` → `job-02` → `job-03`.
3. All referenced contracts' level/Reputation requirements are checked before operation start. A completed contract is still replayable as an operation stage, but not through ordinary standalone preparation.
4. The existing prepare/accept flow is reused for each stage. Operation start prepares stage one; the player explicitly accepts each prepared stage. Successful extraction advances one stage and prepares the next. The final stage completes the operation.
5. Failure/Detection compromise retries the same stage from a clean MissionSession. Facts from earlier successful stages survive within the current process; partial state from the failed stage is discarded. No manual operation abandonment or stage skipping is added.
6. Stage rewards are paid individually using existing contract reward rules. No operation-completion bonus is added. The existing persisted `Mission.completed` flag is the durable exactly-once reward guard: a stage contract already completed before an operation stage run can be replayed but pays no contract, objective, Reputation, or modifier rewards.
7. Operation facts are typed and bounded, not arbitrary string-keyed data. A fact is granted only after its source optional objective is completed and its stage succeeds.
8. The first operation's carry-over:
   - Completed `maintenance-telemetry` in stage one grants `maintenance_telemetry`.
   - That fact reveals hidden optional objective `routing-header` when stage two begins; its normal completion event is still required.
   - Completed `routing-header` in stage two grants `routing_header`.
   - That fact reveals hidden optional objective `relay-trace` when stage three begins; its normal completion event is still required.
   - If a fact is absent, HT-008's normal discovery trigger remains in effect.
9. The operation supports at most 8 stages. Catalog validation rejects invalid IDs, duplicate stage references, unknown missions, invalid stage count, and invalid fact/objective references.
10. **Runtime-only:** operation ID, current stage, facts, stage reward eligibility snapshot, and completion display marker are not serialized. Restart begins the operation again from stage one and clears all facts.
11. Save invoked during an active operation persists the player and existing mission completion flags but writes no active mission index. It must not restore the operation's active contract as a standalone contract.
12. Save V3 writer layout and V2/V1/legacy readers remain unchanged. No Save V4, operation history, or durable operation-completion marker is introduced.
13. Existing standalone mission commands and behavior remain unchanged. During an operation, the operation owns preparation/active-stage flow; ordinary `prepare` and `cancel` cannot replace or abandon the current stage.

## Command contract

The existing parser accepts a command and one argument. Keep that grammar and use:

- `operations` — list operations.
- `operation <id>` — inspect one operation.
- `operation-start <id>` — start an operation and prepare its first stage.
- `operation-status` — inspect current stage and earned facts.

Reuse `accept <mission-id>`, `modifier`, and `loadout` for stage execution. Do not require a multi-token form such as `operation start <id>`.

## Runtime and persistence consequences

- Operation catalog data is static; operation lifecycle and facts live only in bounded runtime state.
- MissionSession remains stage-local and resets between stages and retries.
- Existing contract completion flags remain persisted and act as the no-duplicate-reward marker when completed stages are replayed after restart.
- On restart, the operation returns to stage one. Completed stages can be replayed without rewards to reconstruct carry-over facts; incomplete stages pay their existing rewards only on first successful completion.
- Operation completion is visible only during the current process. Existing contract history continues to show constituent contracts; there is no durable Operation history.
- Save V3 serialization and all legacy readers are untouched.

## Consequences

- The application coordinator must own transitions between OperationState and MissionPreparation/MissionSession.
- The objective tracker needs a narrow, idempotent reveal-by-ID operation that only reveals authored hidden optional objectives.
- Reward eligibility must be snapshotted before a stage begins so replaying completed contracts cannot pay again.
- Save must deliberately omit the active mission index while an operation is in progress, otherwise restart would incorrectly restore one stage as an independent contract.
- Tests must cover stage transitions, failure/retry, carry-over facts, replayed completed stages, reward idempotency, restart, and unchanged save compatibility.

## Scope boundary

This ADR approves the HT-009 design only. It does **not** authorize implementation. A separate explicit owner instruction is required before code changes begin.
