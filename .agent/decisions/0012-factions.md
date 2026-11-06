# ADR 0012 — Factions and derived standing

- **Status:** Accepted; implementation in progress
- **Date:** 2026-11-06
- **Feature:** HT-010 — Factions
- **Decision owner:** Project owner

## Context

Hacker's Terminal needs a more populated fictional world and contract availability consequences tied to competing organizations. The current game persists global Reputation and per-contract completion flags, but has no per-faction score. Save V3 compatibility and the established no-branching-narrative boundary must be preserved.

## Decisions

1. Introduce seven fictional factions: Nexus Dynamics, Ghost Protocol, Black Veil, Aegis Initiative, Iron Meridian, Null Syndicate, and Helix Consortium.
2. Keep stable faction IDs separate from authored profile data.
3. Store static faction-to-faction relationships in the faction Catalog. Relationships are symmetric; unspecified pairs are Neutral.
4. Derive player standing from global Reputation and completed contract outcomes:
   - Start with global Reputation.
   - Add 2 for each completed contract commissioned by the faction.
   - Subtract 2 for each completed contract whose target owner or distinct opposing faction is the faction.
   - Map score to Hostile (<= -2), Wary (-1), Neutral (0..2), Trusted (3..5), or Allied (>= 6).
5. A Hostile standing toward a contract's client faction blocks that contract from selection. Contract Board, preparation, exclusive contact access, acceptance revalidation, and operation start must use the same deterministic rule.
6. Existing contracts receive explicit client and target-owner affiliations. Existing puzzle content, catalog order, rewards, XP, Reputation progression, Detection, and Contact rules remain unchanged.
7. Faction profiles expose security rating/style, economic behavior, and specialty. These are intelligence for player decision-making; this ADR does not rebalance Detection or rewards.
8. Faction standing is derived from data already persisted by Save V3. No faction score or additional faction field is serialized; Save V3, V2, V1, and legacy layouts remain unchanged.

## Consequences

- Completing or replaying a contract deterministically changes derived faction standing based on the existing completion flag. Replaying a previously completed contract cannot add another standing effect.
- The Contract Board can present a new FACTION LOCKED availability reason.
- The player can inspect the faction network and individual faction dossiers from the terminal.
- Future contracts must author valid faction links and should add focused tests for their intended client/owner relationship.
- Future features may extend faction mechanics only with explicit owner approval; this ADR does not authorize HT-011, HT-012, or other roadmap features.

## Validation

- Catalog validation checks seven unique profiles, non-empty identity/profile fields, bounded security ratings, and unique non-self relationship pairs.
- Mission definitions expose a faction-link validation method.
- Unit tests cover catalog validity, stable IDs, symmetric relationships, standing thresholds/outcomes, faction-based availability, and terminal presentation.
- CI must verify Zig 0.13.0 formatting, build, full tests, and agent documentation checks.
