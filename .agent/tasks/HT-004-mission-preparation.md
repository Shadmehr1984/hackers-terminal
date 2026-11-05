# HT-004 — Mission Preparation

**Status:** Planned  
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

## Agent progress notes
- Initial handoff: scope and acceptance criteria recorded; implementation has not started.
