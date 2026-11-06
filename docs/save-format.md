# Save Format

## Location and lifecycle

The game uses one local save file: `saves/player.sav`. The directory is created by `saveGame` when the player runs `save`. New data is written to `saves/player.sav.tmp`; only after the complete payload is written and the file is closed is it renamed to `saves/player.sav`. This prevents a failed write from truncating the previous save. The loader starts with defaults when the file is missing or unreadable. The `saves/` directory is ignored by Git.

## V3 format (current)

The current marker is `HACKERS_TERMINAL_SAVE_V3`. Each value occupies one line:

```text
HACKERS_TERMINAL_SAVE_V3
<balance>
<reputation>
<xp>
<has_decryptor: 0|1>
<owned_utilities: bit mask>
<equipped_utility: 0 none, 1 silent-boots, 2 signal-scrubber>
<silent_boots_level: 0..2>
<signal_scrubber_level: 0..2>
<active_mission_index: -1 or zero-based index>
<mission_0_completed: 0|1>
<mission_1_completed: 0|1>
<mission_2_completed: 0|1>
<mission_3_completed: 0|1>
<mission_4_completed: 0|1>
```

Utility ownership bit 0 represents Silent Boots; bit 1 represents Signal Scrubber. Equipped code 0 means none, 1 means Silent Boots, and 2 means Signal Scrubber. The loader clears an equipped selection and upgrade levels when the corresponding ownership bit is absent.

For the current five missions, indices map as follows:

| Index | Contract |
| ---: | --- |
| 0 | `job-01` — Cold Storage |
| 1 | `job-02` — Paper Trail |
| 2 | `job-03` — Quiet Exit |
| 3 | `job-04` — Ghost Signal |
| 4 | `job-05` — Corporate Ghost |

The fifth mission is appended at index 4; the original indices 0–3 are unchanged. Older V3/V2/V1/legacy saves with only three completion flags leave both job-04 and job-05 incomplete; saves with four flags leave job-05 incomplete. The V3 marker and player-field order are unchanged; the current writer emits five mission completion flags.

An active mission index of `-1` means there is no active contract. A non-negative index must be within the current mission catalog; an out-of-range index rejects the save before any in-memory state is changed. An in-range index that points to a mission marked completed in the same save is not restored as active.

## Persisted and transient data

| Data | Persisted? |
| --- | --- |
| Balance, reputation, XP | Yes |
| Decryptor ownership | Yes |
| Utility ownership, equipped utility, and upgrade levels | Yes (V3) |
| Active mission index and mission completion flags | Yes |
| Scan, connection, authentication, and decryption state | No |
| Objective discovery/completion state, Detection exposure, and Fixer service-use flag | No |
| Active operation ID, stage index, typed carry-over facts, reward eligibility, and completion display marker | No (runtime-only) |
| Reputation tiers, Contact unlocks, and Contact catalog | Derived from persisted Reputation/static catalog |
| Faction profiles, inter-faction relationships, and player standing | Static Catalog / derived from Reputation and existing mission completion flags; not serialized |
| Current topology node and traversal count | No |

When the application restarts, an active contract may be restored, but temporary session state starts over at the mission topology's entry node. The player must repeat mission stages as needed. An active multi-stage operation is not restored: saving during an operation writes `-1` for the active mission index, while preserving player state and existing mission completion flags. After restart the operation begins again at stage one with its facts cleared; contracts completed before the restart may be replayed as operation stages without rewards. This behavior adds no fields and does not change the V3 layout.

## Backward compatibility

The loader recognizes four layouts:

### V3

Reads the fields listed above in order.

### V2

Reads balance, reputation, XP, decryptor ownership, active mission index, and mission completion flags. V2 saves migrate with no utilities owned or equipped and both upgrade levels at 0.

### V1

The marker is `HACKERS_TERMINAL_SAVE_V1`. V1 did not store XP. The loader reconstructs XP by summing the configured XP rewards for completed missions. The layout stores balance, reputation, decryptor ownership, active mission index, and completion flags. Utility state migrates to no utilities owned/equipped and level 0.

### Original unversioned format

The first line must be a valid unsigned numeric balance, followed by reputation and decryptor ownership. Subsequent lines are mission completion flags. Utility state migrates to no utilities owned/equipped and level 0. Unknown non-numeric version markers are rejected; the loader returns no active mission and leaves the supplied player and mission state unchanged.

## Failure behavior and caveats

- If the file cannot be opened or read, loading returns no active mission and the game continues with defaults.
- Unknown non-numeric format markers, truncated payloads, blank positional fields, malformed or out-of-range numeric fields (including active mission indices outside the current catalog), invalid boolean flags, and unsupported completion-flag counts are rejected before mutating player or mission state.
- A recognized save is parsed and validated in full before the loaded player and mission-completion state are committed. A rejected save leaves every caller-owned field unchanged.
- Current mission catalogs accept any completion-flag count up to the catalog size for backward compatibility; omitted trailing mission flags default to incomplete. Extra flags are rejected.
- The loader reads at most 4096 bytes.
- The format is positional: line order matters. Every required field must be present and parse successfully; extra or missing completion flags are rejected while omitted trailing flags are treated as incomplete for older catalogs.
- The format has no checksum, backup rotation, or explicit corruption recovery. Writes use a temporary file and rename to avoid truncating the previous save on a write failure.
- Save files are local game data and should not be treated as trusted external input.

When changing the player or mission schema, update both `saveGame` and `loadGame`, preserve older-format migration paths, and add compatibility tests.
