# HT-004 — Mission Preparation

**Status:** Implemented  
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
- Mission briefing/catalog data in `src/domain/mission.zig` and `src/catalog/mission_data.zig`.
- Preparation/loadout state in player or mission state modules.
- Coordination in `src/application/game.zig`; display in `src/presentation/terminal.zig`.
- Tests and updates to command, gameplay, architecture, and save docs.

## Acceptance criteria
- [x] The player can inspect a preparation briefing before committing to a mission.
- [x] The briefing distinguishes known intelligence from undiscovered information.
- [x] The player can select a valid loadout using owned equipment from HT-003.
- [x] Preparation validates unavailable equipment and invalid mission choices.
- [x] Starting the mission transfers the selected preparation state into runtime mission state predictably.
- [x] Preparation does not bypass existing objective, authentication, decryption, or extraction requirements.
- [x] Reset/abandon/restart behavior is explicit and tested.
- [x] Save compatibility is preserved or a deliberate migration is documented and tested.
- [x] The feature remains fictional, local, and offline.

## Non-goals
- No branching story or dialogue trees.
- No online intel feeds or external data sources.
- No real network reconnaissance.

## Verification
- [x] Tests for preparation state, intel visibility, loadout validation, and transition into mission play.
- [x] Zig 0.13.0 formatting, build, and full tests (GitHub Actions run 42016491969 passed).
- [x] Agent docs check and documented self-review; no independent second reviewer was available.
- [x] Inspect CI before marking Implemented.

## Source audit and proposed milestone plan (historical pre-implementation snapshot)

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

### Accepted owner decisions
- The proposed `prepare` → `loadout` → `accept` interaction is approved.
- `cancel` is free and applies only before launch.
- An active mission cannot be manually abandoned or restarted. Detection compromise invokes the existing failure/penalty path; the failed contract can then be prepared and launched again.
- The selected utility is temporary per run. Its upgrade level is snapshotted at launch; persistent player equipment is not changed.
- Preparation and the loadout snapshot remain runtime-only. Save V3 is unchanged.

### Implementation progress
- [x] Added runtime-only `MissionPreparation` and `MissionLoadout` state.
- [x] Added preparation intel presentation that withholds password/decryption clues and answers.
- [x] Added `prepare`, `loadout`, and `cancel`; changed interactive `accept` to launch only the matching prepared contract.
- [x] Snapshot selected utility and level at launch; Detection costs use the session snapshot.
- [x] Wired preparation state into the interactive main loop.
- [x] Added focused mission-preparation tests and registered them in the aggregate suite.
- [x] Updated command, gameplay, architecture, and agent documentation.
- [x] Run formatter/build/full tests and inspect CI.
- [x] Complete review checklist and final self-review.

### Verification and review result
- GitHub Actions run [42016491969](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42016491969) passed on commit `cdd7ecb9187f7e49e723fcbbf0dab45e2d1f5b8a`: Zig 0.13.0 format check, `zig build`, all 44 tests, and agent-doc structure check.
- No independent second reviewer was available; completed a self-review against `.agent/review-checklist.md`.
- Save V3 code and serialized field layout were not changed. No real networking, shell execution, or external-system interaction was introduced.
