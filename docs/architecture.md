# Architecture

## Overview

Hacker's Terminal is being developed incrementally as a modular, single-player terminal game. Core player and mission data, persistence, terminal presentation, shop operations, command parsing, and game coordination live in focused Zig modules. The application targets Zig 0.13.0 and runs locally without external services.

There is no client/server split, real networking layer, database, plugin system, or external game service. All targets and hacking actions are fictional game content.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `src/main.zig` | Application entry point, allocator and standard I/O setup, save loading, welcome output, and interactive input loop |
| `src/player.zig` | Public `Player` profile data type and its defaults |
| `src/mission.zig` | Public `Mission` contract data type and `MissionDifficulty` classification |
| `src/mission_state.zig` | Runtime-only mission progress and connection state |
| `src/mission_data.zig` | Built-in mission definitions and their default ordering |
| `src/save.zig` | Save/load persistence for player progress and mission completion state |
| `src/terminal.zig` | Reusable terminal output for the banner, help, status, mission list, and history |
| `src/shop.zig` | Inventory display, fictional shop display, and item purchase logic |
| `src/commands.zig` | Parses an input line into a command name and its first argument |
| `src/game.zig` | Coordinates command dispatch, mission state transitions, mission completion rewards, and player progression calculations |
| `tests/` | Unit tests for command parsing, mission state, and built-in mission data |
| `test_root.zig` | Repository-root test module that imports the aggregate test suite |
| `docs/` | User and developer documentation |
| `.github/workflows/ci.yml` | Formatting, build, and test checks on pushes and pull requests targeting `main` |

## Core data types

### `Mission`

A mission stores its static contract definition and completion state:

- `id`, `name`, and `target` identify the contract.
- `difficulty` classifies the contract as `easy`, `medium`, or `hard`. Its `label()` method provides the player-facing title-case label.
- `password` and `password_hint` define the authentication puzzle.
- `encrypted_file`, `decryption_hint`, and `decryption_key` define the decryption puzzle and required extraction filename.
- `reward`, `xp_reward`, and `required_level` configure progression.
- `completed` records whether the contract has been completed.

Difficulty is currently descriptive metadata only. It is displayed in the contract list and active briefing; it does not yet modify detection, rewards, puzzle rules, or mission requirements.

The three built-in mission instances are returned by `mission_data.defaultMissions()` as a fixed-size array, preserving their original order.

### `Player`

The player profile type is defined in `src/player.zig` and imported by `main.zig`. It stores:

- `handle`: terminal identity; defaults to `ghost`.
- `balance`: in-game currency; defaults to 250.
- `reputation`: starts at 0.
- `xp`: starts at 0.
- `has_decryptor`: whether the decryptor tool has been purchased.

### Temporary mission session

The active mission index is an optional `usize`. Its temporary runtime state is modeled by `MissionSession` in `mission_state.zig`, rather than four independent booleans.

The session has two dimensions:
- `progress`: `inactive`, `accepted`, `scanned`, `authenticated`, or `decrypted`.
- `connected`: whether the simulated connection is currently open.

Progress is monotonic. Connection is independent because disconnecting must not revoke authentication or decryption already achieved. A newly accepted contract and a restored active contract start at `accepted`; completing a contract resets the session to `inactive`.

## Runtime flow

1. `main` creates the allocator, standard input/output writers, and a default `Player`.
2. `mission_data.defaultMissions()` supplies the built-in mission array.
3. `save.loadGame` attempts to restore persistent progress from `saves/player.sav`.
4. `terminal.printBanner` and the welcome/status text are written to standard output.
5. The application repeatedly prints the prompt and reads a line from standard input.
6. Input is trimmed and passed to `game.runCommand`.
7. `commands.parse` separates the command name and first argument without allocating memory.
8. `game.runCommand` dispatches the parsed command, validates the current game state, and performs the requested state transition.
9. The loop ends on `exit`, end-of-input, or an input/output error propagated by the relevant function.

## Mission state transitions

```text
inactive -> accepted -> scanned -> authenticated -> decrypted
                         |
                         +---- connected (independent, temporary)
```

- `scan` advances progress to `scanned`.
- `connect` requires a scanned target and opens the connection.
- `brute` requires an open connection and advances progress on a correct password.
- `disconnect` closes only the connection; it does not revoke authentication or decryption.
- `decrypt` requires authentication and an owned decryptor.
- `extract` requires decrypted progress and the exact mission filename, then resets the session.

## Progression calculations

`game.playerLevel` calculates the level from total XP. The first threshold is 100 XP and each subsequent threshold increases by 150 XP. `game.xpForNextLevel` returns the cumulative threshold associated with a level for display in the status output.

`game.completeMission` (an internal helper) adds the mission's cash reward, increments reputation by one, adds the XP reward, and prints a level-up message if the level increased.

## Persistence boundary

Persistent state includes balance, reputation, XP (in V2), decryptor ownership, active mission index, and each mission's completion flag. The implementation lives in `src/save.zig` and continues to read V2, V1, and the original legacy layout.

Mission difficulty is static catalog metadata and is not serialized. Temporary `MissionSession` progress and connection state are also not persisted. A restored active contract therefore starts at the accepted stage. See [Save Format](save-format.md).

## Error handling style

Most user input errors are handled by printing a message and returning to the prompt. File creation and writing errors during `save` are caught and reported to the player. Loading is intentionally tolerant: failure to open or read the save file returns no active mission, and individual numeric parse failures generally fall back to the current default value.

## Dependency direction

`player.zig` and `mission.zig` are foundational data modules. `mission_data.zig` imports `Mission` and owns the built-in catalog. `save.zig` imports the data types and owns save/load. `terminal.zig` imports data types and owns reusable display functions; it receives calculated progression values from its caller rather than depending on game logic. `shop.zig` imports only `Player`. `commands.zig` owns allocation-free parsing. `game.zig` coordinates command dispatch and delegates parsing, persistence, display, and shop operations. `main.zig` initializes the application and owns the interactive input loop. Keep dependencies one-way and avoid circular imports.

## Current design constraints

- The built-in mission catalog is hard-coded in `mission_data.zig` and contains three missions.
- Mission difficulty is currently descriptive metadata; no mechanics are tied to it yet.
- The command parser accepts one argument token only; additional tokens are ignored to preserve existing behavior.
- The save parser is line-oriented and has no checksum or schema validation layer.
- Command-specific output is written by command handling; reusable display sections are centralized in `terminal.zig` and shop-specific output in `shop.zig`.
- Automated tests live under `tests/` and are aggregated by `tests/test_all.zig`, with `test_root.zig` providing the repository-root module path.
