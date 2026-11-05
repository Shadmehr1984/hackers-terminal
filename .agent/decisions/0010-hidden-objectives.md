# ADR 0010 — Hidden Objective State and Discovery

- **Status:** Accepted
- **Date:** 2026-11-05
- **Feature:** HT-008 — Hidden Objectives
- **Decision owner:** Project owner

## Context

Mission objective progress is currently represented by an eight-bit mask keyed by MissionObjectiveKind. This cannot safely represent more than eight kinds, cannot distinguish multiple objectives that share an event kind, and has no representation for a hidden-but-not-yet-discovered objective.

HT-008 introduces hidden optional objectives with independent discovery and completion states. The model must remain bounded, testable, runtime-only, and compatible with existing saves.

## Decision

1. Every objective receives a stable mission-local ID independent of its event kind.
2. Runtime state is tracked per objective, not by enum ordinal or the legacy eight-bit mask.
3. Each objective has one of four states: undiscovered, discovered, completed, or unavailable.
4. Each mission supports at most 32 objectives. Catalog definitions exceeding this bound are rejected safely.
5. Discovery uses typed deterministic triggers: Node, File, and Action.
6. Hidden objectives are always optional and are not shown before discovery.
7. Objective state is per-run and runtime-only. Fresh runs/retries reset it; restored active missions retain the existing reset-on-load behavior.
8. Save V3 writes and V2/V1/legacy reads are unchanged. Persistent evidence/archive behavior is deferred to HT-022.
9. All optional objectives, including hidden objectives, must be completed to earn the existing all-optional Reputation bonus. Hidden objectives never gate contract completion itself.

## Consequences

- Objective definitions and runtime progress become separate concepts.
- Multiple objectives can share an event kind without sharing state.
- Objective rendering must filter undiscovered objectives before producing any player-facing text.
- Discovery triggers and transitions must be idempotent and covered by domain/integration tests.
- The fixed capacity requires explicit catalog validation and safe handling of invalid definitions.
- The existing optional reward and Reputation paths must be reviewed to account for hidden objectives without changing baseline reward values.
- No persistence migration is required.

## Scope boundary

This ADR records the approved design only. It does not authorize implementation. HT-008 implementation requires separate explicit owner authorization.
