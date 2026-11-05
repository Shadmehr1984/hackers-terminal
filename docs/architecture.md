# Architecture

## Overview

The application is being refactored incrementally from a single-file implementation into focused Zig modules. The core `Player` and `Mission` data types, save/load persistence, reusable terminal display functions, shop/inventory operations, command-line parsing, and game command execution are extracted into focused modules. `main.zig` now owns application setup and the interactive input loop; built-in mission definitions live in `mission_data.zig`. `build.zig` configures the executable and its run step.

There is no client/server split, networking layer, database, plugin system, or external game service. The game is local and self-contained.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `src/main.zig` | Application entry point, allocator and standard I/O setup, save loading, welcome output, and interactive input loop |
| `src/player.zig` | Public `Player` profile data type and its defaults |
| `src/mission.zig` | Public `Mission` contract data type and its completion default |
| `src/mission_data.zig` | Built-in mission definitions and their default ordering |
| `src/save.zig` | Save/load persistence for player progress and mission completion state |
| `src/terminal.zig` | Reusable terminal output for the banner, help, status, mission list, and history |
| `src/shop.zig` | Inventory display, fictional shop display, and item purchase logic |
| `src/commands.zig` | Parses an input line into a command name and its first argument |
| `src/game.zig` | Coordinates command dispatch, mission state transitions, mission completion rewards, and player progression calculations |
| `build.zig` | Executable configuration, install artifact, and `run` build step |
| `.github/workflows/ci.yml` | Formatting, build, and test checks on pushes and pull requests targeting `main` |
| `docs/` | User and developer documentation |
| `saves/` | Runtime save directory, created when the player saves; excluded from Git |

## Core data types

### `Mission`

A mission stores its static contract definition and completion state:

- `id`, `name`, and `target` identify the contract.
- `password` and `password_hint` define the authentication puzzle.
- `encrypted_file`, `decryption_hint`, and `decryption_key` define the decryption puzzle and required extraction filename.
- `reward`, `xp_reward`, and `required_level` configure progression.
- `completed` records whether the contract has been completed.

The three built-in mission instances are returned by `mission_data.defaultMissions()` as a fixed-size array, preserving their original order. The `Mission` type itself is defined in `src/mission.zig`.

### `Player`

The player profile type is defined in `src/player.zig` and imported by `main.zig`. It stores:

- `handle`: terminal identity; defaults to `ghost`.
- `balance`: in-game currency; defaults to 250.
- `reputation`: starts at 0.
- `xp`: starts at 0.
- `has_decryptor`: whether the decryptor tool has been purchased.

### Temporary mission state

The active mission index is represented as an optional `usize`. The current mission session is represented by four booleans:

| State | Meaning |
| --- | --- |
| `scanned` | The active target has been scanned |
| `connected` | A simulated session has been established |
| `access_granted` | The password challenge has been solved |
| `decrypted` | The mission file has been decrypted |

These flags are initialized in `main` and passed by pointer to `game.runCommand`. They are reset when a new contract is accepted, when a contract is completed, and at process startup.

## Runtime flow

1. `main` creates the general-purpose allocator, standard input/output writers, and a default `Player`.
2. `mission_data.defaultMissions()` supplies the built-in mission array.
3. `save.loadGame` attempts to restore persistent progress from `saves/player.sav`.
4. `terminal.printBanner` and the welcome/status text are written to standard output.
5. The application repeatedly prints the prompt and reads a line from standard input.
6. Input is trimmed and passed to `game.runCommand`.
7. `commands.parse` separates the command name and first argument without allocating memory.
8. `game.runCommand` dispatches the parsed command, validates the current game state, and performs the requested state transition.
9. The loop ends on `exit`, end-of-input, or an input/output error propagated by the relevant function.

## Mission state transitions

The intended progression is linear:

```text
No active mission
      |
   accept
      v
Mission active
      |
     scan
      v
Target scanned
      |
   connect
      v
Session connected
      |
     brute
      v
Authentication granted
      |
    decrypt
      v
File decrypted
      |
    extract
      v
Mission completed
```

The implementation uses booleans rather than a dedicated enum/state-machine type. Each command checks the flags it requires. For example, `connect` requires `scanned`; `brute` requires `connected`; `decrypt` requires `access_granted` and the decryptor; and `extract` requires `decrypted` and the exact mission filename.

## Progression calculations

`game.playerLevel` calculates the level from total XP. The first threshold is 100 XP and each subsequent threshold increases by 150 XP. `game.xpForNextLevel` returns the cumulative threshold associated with a level for display in the status output.

`game.completeMission` (an internal helper) adds the mission's cash reward, increments reputation by one, adds the XP reward, and prints a level-up message if the level increased.

## Persistence boundary

Persistent state includes balance, reputation, XP (in V2), decryptor ownership, active mission index, and each mission's completion flag. The implementation lives in `src/save.zig` and continues to read V2, V1, and the original legacy layout.

Temporary state is not persisted: scanned, connected, access granted, and decrypted. This is why a restored active contract must be played through its session stages again. See [Save Format](save-format.md).

## Error handling style

Most user input errors are handled by printing a message and returning to the prompt. File creation and writing errors during `save` are caught and reported to the player. Loading is intentionally tolerant: failure to open or read the save file returns no active mission, and individual numeric parse failures generally fall back to the current default value.

## Incremental modularization

The refactoring has extracted the foundational data types, persistence, terminal display helpers, shop operations, command parsing, and game coordination. `player.zig` and `mission.zig` remain independent leaf modules. `mission_data.zig` imports `Mission` and owns the built-in mission catalog. `save.zig` imports those types and owns save/load. `terminal.zig` imports the data types and owns reusable display functions; it receives calculated progression values from its caller rather than depending on game logic. `shop.zig` imports only `Player` and owns inventory output, shop output, and purchases. `commands.zig` owns allocation-free parsing of the command name and first argument. `game.zig` coordinates command dispatch, mission state transitions, completion rewards, and progression calculations; it delegates parsing, persistence, display, and shop operations to their respective modules. `main.zig` now initializes the application, obtains the built-in mission array from `mission_data.zig`, and owns the interactive input loop, delegating each command to `game.runCommand`. Dependencies remain one-way and avoid circular imports.

## Current design constraints

- The built-in mission catalog is currently hard-coded in `mission_data.zig` and contains three missions.
- The command parser accepts one argument token only; additional tokens are ignored to preserve existing behavior.
- There is no automated unit-test suite beyond compiling/running Zig tests in the CI command; tests can be added in the source file.
- The save parser is line-oriented and has no checksum or schema validation layer.
- Command-specific output is still written directly by command handling; reusable display sections are centralized in `terminal.zig` and shop-specific output is centralized in `shop.zig`.
