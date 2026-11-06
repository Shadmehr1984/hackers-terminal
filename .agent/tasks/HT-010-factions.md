# HT-010 — Factions

- **Status:** In Progress
- **Owner authorization:** Explicitly authorized on 2026-11-06 with the seven-faction design baseline.
- **Implementation branch:** main
- **Persistence:** Derived from existing Reputation and mission-completion flags; Save V3 remains unchanged.

## Goal

Introduce seven fictional organizations with distinct identities, security profiles, economic behavior, static inter-faction relationships, and contract affiliations. Make faction standing mechanically relevant to Contract Board availability without adding a separate persisted relationship score or branching narrative.

## Accepted faction roster

| ID | Name | Identity | Security profile | Economic profile |
|---|---|---|---|---|
| nexus-dynamics | Nexus Dynamics | Technology megacorporation | Layered controls, hardened gateways, audit trails | Premium corporate contracts |
| ghost-protocol | Ghost Protocol | Independent hacker collective | Stealth relays, decoys, low-noise authentication | Selective clean-execution work |
| black-veil | Black Veil | Underground information syndicate | Compartmentalized archives and misleading records | Information trades and variable value |
| aegis-initiative | Aegis Initiative | Civic watchdog | Evidence integrity and traceable audits | Modest public-interest budgets |
| iron-meridian | Iron Meridian | Private security contractor | Aggressive monitoring and counter-intrusion | High-fee protection contracts |
| null-syndicate | Null Syndicate | Saboteur collective | Unstable infrastructure and false trails | Risk-heavy unconventional work |
| helix-consortium | Helix Consortium | Research consortium | Experimental authentication and encrypted research stores | Research grants and specialist fees |

## Accepted relationship model

- Faction-to-faction relationships are static, symmetric Catalog data. Unspecified pairs are Neutral.
- The player has no independently stored faction score.
- Derived standing score starts at global Reputation.
- Each completed contract adds 2 to its client faction.
- Each completed contract subtracts 2 from its target-owner faction and from a distinct opposing faction.
- Score bands: Hostile (<= -2), Wary (-1), Neutral (0..2), Trusted (3..5), Allied (>= 6).
- A contract whose client faction is Hostile to the player is faction-locked on the Contract Board and cannot be prepared/launched. The same check applies to exclusive contact contract access and operation start.
- Existing global Reputation thresholds, mission rewards, Detection costs, Contact prices, and progression rules are unchanged.

## Built-in contract affiliations

| Contract | Client | Target owner |
|---|---|---|
| job-01 Cold Storage | Aegis Initiative | Nexus Dynamics |
| job-02 Paper Trail | Black Veil | Nexus Dynamics |
| job-03 Quiet Exit | Ghost Protocol | Iron Meridian |
| job-04 Ghost Signal | Helix Consortium | Null Syndicate |

These affiliations are static catalog metadata and do not alter the existing puzzle, rewards, mission order, or save indices.

## Current behavior and ownership

- src/domain/faction_id.zig: stable faction IDs and command parsing.
- src/domain/faction.zig: standing and relationship types plus pure standing derivation.
- src/catalog/faction_data.zig: seven authored profiles and static symmetric relationships.
- src/domain/mission.zig: explicit client, target-owner, and optional opposing faction metadata.
- src/domain/contract_board.zig: derived faction-locked availability.
- src/catalog/mission_data.zig: authored affiliations for existing contracts.
- src/application/game.zig: faction commands and access enforcement.
- src/presentation/terminal.zig: faction dossiers and faction-aware board output.
- tests/faction_test.zig: catalog, relationship, standing, and availability coverage.

## Acceptance criteria

- [x] Seven stable faction identities and authored profiles exist.
- [x] Static inter-faction relationships are symmetric and default to Neutral when unspecified.
- [x] Player standing is derived deterministically from Reputation and completed contract outcomes.
- [x] Existing built-in contracts have explicit client and target-owner links.
- [x] Contract Board exposes faction standing and faction-locked availability.
- [x] Faction dossier/list terminal views are available.
- [x] Contract preparation, exclusive contract access, and operation start enforce hostile-standing restrictions.
- [x] Save V3/V2/V1/legacy formats remain unchanged.
- [ ] Catalog validation and focused regression tests pass in CI.
- [ ] Formatting, build, complete tests, and agent-doc checks pass in CI.
- [ ] Comprehensive change review against .agent/review-checklist.md is complete.
- [ ] Final docs/handoff and CI result are recorded.

## Constraints and non-goals

- No new Save fields, migration, relationship-score persistence, or mission-index changes.
- No changes to existing cash/XP rewards, Reputation gain, Detection costs, Contact unlocks/prices, or puzzle content.
- No real organizations, real political groups, external network access, shell execution, or credential collection.
- No branching narrative, player alliances, or faction warfare simulation.
- Security ratings/styles are authored intelligence shown to the player; this task does not rebalance Detection or mission risk.

## Verification plan

- [ ] zig fmt --check test_root.zig build.zig src tests
- [ ] zig build
- [ ] zig build test
- [ ] sh scripts/check-agent-docs.sh
- [ ] Inspect actual GitHub Actions result for the final main commit.
- [ ] Self-review every applicable item in .agent/review-checklist.md; record independent-review availability.
