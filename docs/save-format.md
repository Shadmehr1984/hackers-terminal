# Save Format

## Location and lifecycle

The game uses one local save file:

```text
saves/player.sav
```

The directory is created automatically by `saveGame` when the player runs the `save` command. At startup, `loadGame` attempts to open this file. If it is missing or cannot be read, the game starts with the default player and mission state.

The `saves/` directory is listed in `.gitignore`; player save data should remain local and should not be committed to the repository.

## V3 format (current)

The current format begins with the version marker `HACKERS_TERMINAL_SAVE_V3`. Each value is stored on its own line.

```text
HACKERS_TERMINAL_SAVE_V2
<balance>
<reputation>
<xp>
<has_decryptor: 0|1>
<active_mission_index: -1 or zero-based index>
<mission_0_completed: 0|1>
<mission_1_completed: 0|1>
<mission_2_completed: 0|1>
```

For the current three missions, indices map as follows:

| Index | Contract |
| ---: | --- |
| 0 | `job-01` — Cold Storage |
| 1 | `job-02` — Paper Trail |
| 2 | `job-03` — Quiet Exit |

An active mission index of `-1` means there is no active contract. A non-negative index is accepted only if it is within the mission array and the referenced mission is not already completed.

## Persisted and transient data

| Data | Persisted? |
| --- | --- |
| Balance | Yes |
| Reputation | Yes |
| XP | Yes, in V2 |
| Decryptor ownership | Yes |\n| Utility ownership | Yes (V3) |\n| Equipped utility | Yes (V3) |\n| Utility upgrade levels | Yes (V3) |
| Active mission index | Yes |
| Mission completion flags | Yes |
| Scan state | No |
| Connection state | No |
| Authentication state | No |
| Decryption state | No |
| Objective completion | No |
| Detection exposure | No |
| Current topology node | No |
| Successful traversal count | No |

When the application restarts, the active contract may be restored but its temporary session state starts over at that mission topology's entry node. The player must traverse the graph again, scan and connect, and repeat authentication, decryption, and any optional analysis. The current node and successful traversal count are not persisted.

## Backward compatibility

The loader recognizes four layouts:

### V2

Reads balance, reputation, XP, decryptor ownership, active mission index, and mission completion flags in that order.

### V1

The marker is `HACKERS_TERMINAL_SAVE_V1`. V1 did not store XP. During migration, the loader reconstructs XP by adding the configured XP reward for each mission marked completed.

The V1 layout stores balance, reputation, decryptor ownership, active mission index, and then completion flags. Utility state migrates to no utilities owned/equipped and level 0.

### Original unversioned format

If the first line is not either version marker, it is interpreted as the balance. The next lines are read as reputation and decryptor ownership. Any subsequent lines are consumed as mission completion flags. This preserves compatibility with the original early save layout. Utility state migrates to no utilities owned/equipped and level 0.

## Failure behavior and caveats

- If the file cannot be opened or read, loading returns no active mission and the game continues with defaults.
- Invalid numeric values generally leave the corresponding default/current value unchanged.
- The loader reads at most 4096 bytes.
- The format is positional: line order matters.
- The format does not currently include a checksum, backup rotation, atomic write, or explicit corruption recovery.
- Save files should be treated as local game data, not trusted input from an external source.

When changing the player or mission schema, update both `saveGame` and `loadGame`, preserve the older-format migration path where practical, and revise this document.
