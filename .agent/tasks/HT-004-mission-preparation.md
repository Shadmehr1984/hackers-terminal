# HT-004 — Mission Preparation

**Status:** In Progress  
**Priority:** 4  
**Approved:** 2026-11-05  
**Depends on:** HT-001 risk model, HT-002 topology, and HT-003 equipment/inventory.

## Goal
Add a pre-mission planning phase where the player reviews available intelligence, chooses equipment, and prepares for a contract before entering its simulated environment.

## Design direction
- Make preparation a clear phase in the existing terminal workflow, not a separate game mode.
- Show concise mission intel: target summary, known nodes/resources, objective outline, and known risk indicators.
- Allow loadout selection from already-owned equipment.
- Keep information gathering and purchasing decisions coherent with the existing shop and progression.
- Avoid revealing puzzle answers that are currently intended to be discovered during mission play.
- Define what happens when a player accepts, abandons, or restarts a prepared mission.

## Likely scope (verify before implementation)
- Mission briefing/catalog data in `src/mission.zig` and `src/mission_data.zig`.
- Preparation/loadout state in player or mission state modules.
- Coordination in `src/game.zig`; display in `src/terminal.zig`.
- Tests and updates to command, gameplay, architecture, and save docs.

## Acceptance criteria
- [ ] The player can inspect a preparation briefing before committing to a mission.
- [ ] The briefing distinguishes known intelligence from undiscovered information.
- [ ] The player can select a valid loadout using owned equipment from HT-003.
- [ ] Preparation validates unavailable equipment and invalid mission choices.
- [ ] Starting the mission transfers the selected preparation state into runtime mission state predictably.
- [ ] Preparation does not bypass existing objective, authentication, decryption, or extraction requirements.
- [ ] Reset/abandon/restart behavior is explicit and tested.
- [ ] Save compatibility is preserved or a deliberate migration is documented and tested.
- [ ] The feature remains fictional, local, and offline.

## Non-goals
- No branching story or dialogue trees.
- No online intel feeds or external data sources.
- No real network reconnaissance.

## Verification
- [ ] Tests for preparation state, intel visibility, loadout validation, and transition into mission play.
- [ ] Zig 0.13.0 formatting, build, and full tests.
- [ ] Agent docs check and independent review/self-review.
- [ ] Inspect CI before marking Implemented.

## Source audit and proposed milestone plan

### Confirmed current behavior
- `accept <id>` immediately activates a mission and resets `MissionSession`.
- The active briefing reveals password and decryption clues; these must remain hidden during preparation.
- The mission catalog already contains target, difficulty, reward, objectives, and static topology node data.
- HT-003 stores a persistent default equipped utility and its upgrade level. Detection modifiers currently read the player's live equipment directly.
- The save format is V3. Preparation choices should remain runtime-only so HT-004 does not require another save migration.

### Proposed interaction
1. `prepare <id>` opens a preparation phase for an available, unlocked mission without activating it.
2. The preparation briefing shows known intel (contract summary, target, difficulty, reward, objective outline, topology overview, required decryptor status, and a risk overview) while explicitly marking puzzle answers and undiscovered details as unknown.
3. `loadout <utility|none>` selects one already-owned utility for this run. The default is the currently equipped utility when owned. This selection is a temporary snapshot and does not alter the player's persistent default equipment.
4. `accept <id>` launches only the matching prepared contract, snapshots the selected utility and upgrade level into the new mission session, then clears preparation state.
5. `cancel` clears preparation without cost. A different mission can then be prepared.
6. Once launched, preparation cannot be changed mid-contract. The existing failure/retry behavior remains the way to restart a compromised mission; active-contract abandonment is not introduced in this proposal.

### Proposed implementation milestones
- M1: Add testable runtime preparation state and intel presentation; no save changes.
- M2: Add prepare/loadout/cancel/accept transition rules and snapshot the chosen utility for the active session.
- M3: Add focused tests for intel secrecy, locked/completed/unknown missions, ownership validation, launch matching, cancel/reprepare, and modifier snapshot behavior.
- M4: Update command/gameplay/architecture/agent docs, perform self-review, and verify with CI.

### Open owner decision
Confirm the proposed interaction and especially the rule that an active mission cannot be abandoned/restarted manually; a compromised mission remains retryable through the existing failure path. No gameplay code has been changed for HT-004 yet.
