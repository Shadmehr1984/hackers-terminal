# HT-005 — Reputation & Contacts

**Status:** Complete  
**Priority:** 5  
**Approved:** 2026-11-05  
**ADR:** 0007 — Reputation Tiers, Derived Contact Unlocks, and Offers  
**Depends on:** Existing mission outcomes, progression, topology, and HT-004 preparation.

## Goal

Turn the existing persisted Reputation value into a meaningful progression system and introduce two fictional contacts with role-specific offers. All interactions remain local, offline, and entirely simulated.

## Accepted design

### Reputation tiers

| Reputation | Tier |
|---:|---|
| 0 | Unknown |
| 1–2 | Recognized |
| 3–4 | Trusted |
| 5+ | Elite |

- Successful contract completion: +1 Reputation.
- Completing every optional objective in that contract: +1 additional Reputation.
- Partial optional completion: existing cash bonus only; no Reputation bonus.
- Failed/compromised contract: no Reputation gain and no Reputation loss.

### Contacts and offers

**Information Broker** — unlock at Reputation 1.
- deal intel-<mission-id> buys authored password and decryption clues for an unlocked, incomplete contract.
- Price: $50 per purchase.
- Clues are revealed; actual password and decryption answers remain hidden.

**Fixer** — unlock at Reputation 3.
- deal scrub-detection requires an active contract and Detection above zero.
- Reduces Detection by up to 10, once per contract.
- Price: $100 at Trusted (Reputation 3–4), $75 at Elite (Reputation 5+).
- deal ghost-signal prepares the exclusive contract when player level and Reputation are both at least 3.

**Ghost Signal**
- ID: job-04; append after the original three contracts to preserve indices.
- Requires level 3 and Reputation 3.
- Can only be prepared through the Fixer offer; direct prepare is rejected. The offer is not displayed while another contract is active or prepared.
- Has its own fictional topology, required objectives, optional metadata objective, clues, reward, and XP.
- No Save V4 is needed.

### Persistence

- Reputation remains the existing persisted numeric value.
- Tiers, Contact unlocks, and available offers are derived from Reputation, level, and mission completion state.
- Fixer service usage is stored only in MissionSession and resets at the start/end of a contract.
- Save V3 serialization and field order remain unchanged. The current writer emits four mission flags; old saves with three flags leave job-04 incomplete.

## Architecture

- src/progression.zig: Reputation tier mapping and outcome-based Reputation rewards.
- src/contacts.zig: Contact identity, unlock thresholds, and service pricing.
- src/mission.zig: optional static required_reputation and requires_contact_offer.
- src/mission_data.zig: appended job-04 catalog entry and topology.
- src/mission_state.zig: runtime-only fixer_service_used.
- src/game.zig: contacts, contact, offers, and deal dispatch and transaction validation.
- src/terminal.zig: Contact, offer, and tier presentation.
- src/save.zig: unchanged.

## Acceptance criteria

- [ ] Reputation tiers map correctly at 0, 1, 2, 3, 4, and 5+.
- [ ] Every successful contract grants +1 Reputation.
- [ ] Completing every optional objective grants +1 additional Reputation; partial completion does not.
- [ ] Failed/compromised contracts do not change Reputation.
- [ ] Broker unlocks at Reputation 1; Fixer unlocks at Reputation 3.
- [ ] Locked contacts and unavailable offers cannot be used.
- [ ] Broker purchases cost $50 and reveal clues but not puzzle answers.
- [ ] Unaffordable or invalid Broker purchases do not change balance.
- [ ] Fixer service requires an active contract and positive Detection, reduces up to 10, and costs $100/$75 at the defined tiers.
- [ ] Fixer service can be used only once per active contract and resets for the next contract.
- [ ] Ghost Signal requires level 3 and Reputation 3, is prepared only through the Fixer offer, is hidden while another contract is active/prepared, and is appended at index 3.
- [ ] Existing mission indices and original mission progression remain unchanged.
- [ ] Existing V3/V2/V1/legacy saves load; older three-mission completion lists leave Ghost Signal incomplete.
- [ ] All new behavior and important invalid/failure paths have automated tests.
- [ ] README, gameplay, command, architecture, save-format, development, AGENTS, module conventions, roadmap, ADR, and task index are accurate.
- [x] Zig 0.13.0 formatting, build, full tests, agent-doc check, and CI pass.
- [x] Independent review or documented self-review is complete.

## Non-goals

- No dialogue trees or branching narrative.
- No multiplayer/social networking or real-world contact discovery.
- No external messaging, online services, real networking, shell execution, or credential collection.
- No Save V4 or persistence for contact unlocks/service usage.

## Verification plan

- Run zig fmt --check test_root.zig build.zig src tests.
- Run zig build.
- Run zig test test_root.zig.
- Run sh scripts/check-agent-docs.sh.
- Inspect the actual GitHub Actions run for the final implementation commit.
- Local build/gameplay testing is not claimed unless actually performed.

## Agent progress notes

- [x] Owner approved the tier, two-contact, mixed-offer, and derived-persistence design.
- [x] ADR 0007 recorded.
- [x] Reputation tiers, Contact rules, mission requirement metadata, and appended Ghost Signal added.
- [x] Contact commands, offer transactions, and focused automated tests added.
- [x] Documentation and agent handoff updates complete.
- [x] Full CI verification and final review complete.


## Review record

- Self-review performed against .agent/review-checklist.md after inspecting the changed source, tests, persistence behavior, and documentation. A follow-up review also checked contact-offer visibility against active/prepared state; the corresponding display logic and regression test were added.
- No independent second reviewer was available; this is recorded as a self-review, not a second-agent review.
- Zig is not installed in the execution environment and network access to obtain it is unavailable, so formatting/build/tests were not run locally.
- GitHub Actions run [42042129713](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42042129713) for commit `ef43396a6fbdbdd9ce463de345b1edf704b468b4` completed successfully. Formatting, project compilation, full Zig test suite, and agent documentation structure check all passed. The initial CI failure was a missing enum declaration terminator in `src/progression.zig`; it was fixed in the follow-up commit and the full workflow passed.
