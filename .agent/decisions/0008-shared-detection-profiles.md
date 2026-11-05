# ADR 0008: Centralize Utility Detection-Cost Profiles

- Status: Accepted
- Date: 2026-11-05

## Context
The equipped player inventory and the per-mission loadout snapshot both calculate Detection costs. The movement and incorrect-authentication cost tables were duplicated in `Equipment` and `MissionLoadout`. Duplicate policy risks allowing live equipment and a mission snapshot to drift apart.

## Decision
`UtilityEquipment` owns the pure Detection-cost profile for a utility at a given upgrade level:
- Silent Boots modify movement Detection only.
- Signal Scrubber modifies incorrect-authentication Detection only.
- A non-matching utility returns the unchanged base cost for that action.

`Equipment` delegates using the currently equipped utility and its current level. `MissionLoadout` delegates using the utility and level snapshotted when the mission starts. The adapters retain their existing public methods and fallback costs.

Mission progress and connection remain separate state dimensions. A tagged union would incorrectly couple independently changing state: disconnecting must not revoke authenticated or decrypted progress.

## Consequences
- Each utility's numeric cost profile is defined once.
- Both live equipment and mission snapshots use identical calculations.
- Existing public method signatures, gameplay values, and save data remain unchanged.
- New utility types must define their action-specific cost profile in `UtilityEquipment` and receive tests for matching and non-matching actions.
