# Architecture

## Overview

The application is being refactored incrementally from a single-file implementation into focused Zig modules. The core `Player` and `Mission` data types and save/load persistence are now extracted; command handling and the rest of the game flow remain in `main.zig` for now. `build.zig` configures the executable and its run step.

There is no client/server split, networking layer, database, plugin system, or external game service. The game is local and self-contained.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `src/main.zig` | Mission definitions, terminal output, save/load, command handling, and application entry point (remaining responsibilities during the incremental refactor) |
| `src/player.zig` | Public `Player` profile data type and its defaults |
| `src/mission.zig` | Public `Mission` contract data type and its completion default |
| `src/save.zig` | Save/load persistence for player progress and mission completion state |
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

The three mission instances are still initialized in `main` as a fixed-size array. The `Mission` type itself is defined in `src/mission.zig` and imported by `main.zig`.

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

These flags live in `main` and are passed by pointer to `runCommand`. They are reset when a new contract is accepted, when a contract is completed, and at process startup.

## Runtime flow

1. `main` creates the general-purpose allocator, standard input/output writers, a default `Player`, and the mission array.
2. `save.loadGame` attempts to restore persistent progress from `saves/player.sav`.
3. `printBanner` and the welcome/status text are written to standard output.
4. The application repeatedly prints the prompt and reads a line from standard input.
5. Input is trimmed and passed to `runCommand`.
6. `runCommand` tokenizes the line, checks the command name, validates the current game state, and performs the requested state transition.
7. The loop ends on `exit`, end-of-input, or an input/output error propagated by the relevant function.

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

`playerLevel` calculates the level from total XP. The first threshold is 100 XP and each subsequent threshold increases by 150 XP. `xpForNextLevel` returns the threshold associated with the next level for display in the status output.

`completeMission` adds the mission's cash reward, increments reputation by one, adds the XP reward, and prints a level-up message if the level increased.

## Persistence boundary

Persistent state includes balance, reputation, XP (in V2), decryptor ownership, active mission index, and each mission's completion flag. The implementation lives in `src/save.zig` and continues to read V2, V1, and the original legacy layout.

Temporary state is not persisted: scanned, connected, access granted, and decrypted. This is why a restored active contract must be played through its session stages again. See [Save Format](save-format.md).

## Error handling style

Most user input errors are handled by printing a message and returning to the prompt. File creation and writing errors during `save` are caught and reported to the player. Loading is intentionally tolerant: failure to open or read the save file returns no active mission, and individual numeric parse failures generally fall back to the current default value.

## Incremental modularization

The refactoring has extracted the foundational data types and persistence. `player.zig` and `mission.zig` remain independent leaf modules. `save.zig` imports those types and owns the save/load functions; `main.zig` calls the persistence API without owning its implementation. This keeps dependencies one-way and avoids circular imports while preserving the existing save formats. Further responsibilities (terminal I/O, command handling, and game coordination) will be extracted in later steps.

## Current design constraints

- Mission content is hard-coded in `main.zig`.
- The command parser accepts one argument token only.
- There is no automated unit-test suite beyond compiling/running Zig tests in the CI command; tests can be added in the source file.
- The save parser is line-oriented and has no checksum or schema validation layer.
- Game output is directly coupled to the writer passed into command functions.
