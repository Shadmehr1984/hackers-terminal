# ADR 0014 — Rival Hackers

- **Status:** Accepted; implementation in progress
- **Date:** 2026-11-06
- **Feature:** HT-011 — Rival Hackers
- **Decision owner:** Project owner

## Context

The game needs a small cast of fictional competitors to make the world feel active and to add bounded consequences around optional mission intelligence. The existing game already has five contracts, hidden optional objectives with stable IDs and typed discovery triggers, a runtime objective tracker, seven faction identities, and a deterministic offline architecture. Save V3 compatibility is a hard constraint.

## Decisions

1. Add exactly five rivals: Ghost Operator (Ghost Protocol), Null Byte (Null Syndicate), Glasswire (Black Veil), Patchwork (Iron Meridian), and Redshift (Helix Consortium).
2. Use Medium impact: rivals may claim a linked optional hidden-intelligence opportunity if the player successfully decrypts before discovering it. The player can outpace them by satisfying the existing discovery trigger first.
3. Bind one rival to each built-in contract and one existing hidden optional objective:
   - Patchwork / job-01 / maintenance-telemetry
   - Glasswire / job-02 / routing-header
   - Ghost Operator / job-03 / relay-trace
   - Null Byte / job-04 / mirror-fragment
   - Redshift / job-05 / mirror-fragment
4. Rival statuses are DORMANT, CONTESTING, RIVAL_AHEAD, and OUTPACED. They are derived from current progression, faction access, the active mission, and existing runtime objective state.
5. Resolve the contest only after successful decryption. If the linked objective is still undiscovered, mark that optional objective unavailable for the current run. If it has been discovered, the player has outpaced the rival.
6. Disclose rival identity and counterplay in the Contract Board, Preparation, and active Briefing before the event can occur.
7. Rival activity must never block or remove a primary contract, mutate required objectives, directly change Detection, cash, XP, or Reputation, or modify faction-standing/reward formulas. Because the contested item is an existing optional objective, losing it can forfeit the existing all-optional Reputation bonus; this is an intended side-opportunity consequence, not a changed reward rule.
8. Rival profiles are static catalog data. Contest state uses the existing runtime objective tracker and is not persisted. Save V3 writer and V2/V1/legacy readers remain unchanged.
9. Keep all actors and events fictional, local, deterministic, and offline. No real network activity, external actors, shell execution, or credential collection.

## Consequences

- The player can inspect the five rival dossiers with `rivals` and `rival <id>`.
- The current optional-objective tracker is the sole runtime source of contest outcomes; no parallel save or mission state is introduced.
- A rival can reduce access to an optional objective, but primary mission completion remains possible.
- Existing optional-objective Reputation eligibility remains governed by the current rule that every optional objective must be completed; a rival-claimed objective therefore forfeits that existing bonus for the run.

## Validation

- Catalog validation covers five unique rivals and all mission/objective references.
- Unit tests cover all status states, deterministic resolution, command output, and the post-decryption event.
- CI must verify Zig 0.13.0 formatting, build, full tests, and agent documentation checks in all configured optimization modes.
