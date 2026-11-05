# ADR 0006: Runtime Mission Preparation and Per-Run Loadout

- Status: Accepted
- Date: 2026-11-05

## Context

HT-004 adds a pre-contract phase for reviewing known intelligence and choosing owned utility equipment. The active mission must not change its risk modifiers if the player later changes persistent equipment.

## Decision

- `MissionPreparation` is runtime-only and stores the prepared mission index and selected owned utility.
- `prepare <id>` is allowed only when no mission is active or already prepared and the contract is available and unlocked.
- Preparation displays contract summary, target, difficulty, rewards, objective outline, topology overview, decryptor ownership, and known risk indicators. Password/decryption clues and puzzle answers remain hidden until launch.
- `loadout <utility|none>` selects a run-specific utility. The player's persistent equipped utility is the initial default when owned.
- `accept <id>` launches only the matching prepared contract. The selected utility and its current upgrade level are copied into `MissionSession`.
- Detection modifiers use the session loadout snapshot, not live player equipment.
- `cancel` clears preparation without cost. Active contracts cannot be abandoned or manually restarted; compromise uses the existing failure and retry path.
- Preparation and session loadout are not serialized. Save V3 remains unchanged.

## Consequences

- `mission_state.zig` owns preparation and loadout runtime data.
- `game.zig` coordinates preparation, validation, and launch transitions.
- `terminal.zig` presents known intel without revealing puzzle answers.
- `main.zig` owns the lifetime of the preparation state.
- Tests cover intel secrecy, availability, ownership, launch matching, cancellation, and loadout snapshot behavior.