# HT-010 — Factions

- **Status:** Implemented
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
- A contract whose client faction is Hostile to the player is faction-locked on the Contract Board and cannot be prepared/launched. The same check applies to exclusive contact contract access and operation start. Operation start validates every stage once; an active operation is preauthorized so standing changes from earlier stages cannot strand the player mid-operation.
- Existing global Reputation thresholds, mission rewards, Detection costs, Contact prices, and progression rules are unchanged.

## Built-in contract affiliations

| Contract | Client | Target owner |
|---|---|---|
| job-01 Cold Storage | Aegis Initiative | Nexus Dynamics |
| job-02 Paper Trail | Black Veil | Nexus Dynamics |
| job-03 Quiet Exit | Ghost Protocol | Iron Meridian |
| job-04 Ghost Signal | Helix Consortium | Null Syndicate |
| job-05 Corporate Ghost | Nexus Dynamics | Null Syndicate |

These affiliations are static catalog metadata and do not alter existing puzzle content or save indices. HT-010.1 appends Corporate Ghost at index 4 with Nexus Dynamics as client and Null Syndicate as target owner; it does not change the first four contracts.

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
- [x] HT-010.1 Corporate Ghost is appended at index 4 with the approved Nexus Dynamics / Null Syndicate affiliation and preserves earlier contract indices.
- [x] The new contract is faction-locked at Nexus Hostile standing and becomes available after Quiet Exit raises standing to Wary.
- [x] Its seven-node topology, five required objectives, visible optional objective, and hidden mirror-node objective are validated and covered by end-to-end tests.
- [x] Catalog validation and focused regression tests pass in CI.
- [x] Formatting, build, complete tests, and agent-doc checks pass in CI.
- [x] Comprehensive change review against .agent/review-checklist.md is complete.
- [x] Final docs/handoff and CI result are recorded.

## Constraints and non-goals

- No new Save fields, migration, relationship-score persistence, or mission-index changes.
- No changes to existing cash/XP rewards, Reputation gain, Detection costs, Contact unlocks/prices, or puzzle content.
- No real organizations, real political groups, external network access, shell execution, or credential collection.
- No branching narrative, player alliances, or faction warfare simulation.
- Security ratings/styles are authored intelligence shown to the player; this task does not rebalance Detection or mission risk.

## Verification plan

- [x] zig fmt --check test_root.zig build.zig src tests
- [x] zig build
- [x] zig build test
- [x] sh scripts/check-agent-docs.sh
- [x] Inspect actual GitHub Actions result for the final main commit.
- [x] Self-review every applicable item in .agent/review-checklist.md; record independent-review availability.


## Completion record

- 2026-11-06: HT-010 and HT-010.1 are implemented on main. Final verification commit: 238f358bcedd2346d8b5fd893ef0754df1467376.
- GitHub Actions run #42224233431 passed formatting, build, the complete Zig test suite, and agent-documentation checks in Debug, ReleaseSafe, and ReleaseFast.
- Follow-up review items S-01 (faction-aware Operation views), S-02 (end-to-end faction/Contact/Operation access coverage), S-03 (checked optional reward accumulation), S-04 (README consistency), and S-05 (ReleaseFast CI coverage) were addressed.
- Final self-review used the mandatory checklist. The 113-file repository inventory included 36 production Zig files, 18 test modules, 4 build/CI/script files, 54 documentation/agent files, and .gitignore. All production files and test modules were inventoried and statically scanned; key faction, Operation, payout, save, and command flows plus directly affected tests were inspected in detail. Historical task/ADR documents outside the HT-010 dependency chain were not individually re-read.
- No independent reviewer was available. No local Zig toolchain, manual interactive playtest, SAST, dependency audit, or performance benchmark was available/performed.
- One non-blocking hardening suggestion remains: the runtime traversal counter is u32 and could theoretically wrap after more than 4.29 billion successful moves (src/application/game.zig:426). No practical reproduction was attempted; this does not affect faction access or reward correctness.
