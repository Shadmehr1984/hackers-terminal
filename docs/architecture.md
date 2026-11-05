# Architecture

## Overview

Hacker's Terminal is being developed incrementally as a modular, single-player terminal game. Core player and mission data, persistence, terminal presentation, shop operations, command parsing, and game coordination live in focused Zig modules. The application targets Zig 0.13.0 and runs locally without external services.

There is no client/server split, real networking layer, database, plugin system, or external game service. All targets and hacking actions are fictional game content.

## Source layout

```text
src/
├── main.zig                 # Composition root and interactive loop
├── domain/                  # Player, mission/session, topology, progression, and Contact rules
├── application/              # Command coordination and gameplay services
├── catalog/                  # Built-in mission definitions
├── presentation/             # Terminal output
└── persistence/              # Save/load and legacy compatibility
```

The former top-level module paths remain as thin compatibility facades so existing imports continue to work. New production imports should target the grouped implementation modules directly.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `src/main.zig` | Application entry point, allocator and standard I/O setup, save loading, welcome output, and interactive input loop |
| `src/domain/player.zig` | Player profile plus typed equipment ownership, utility-slot selection, upgrade levels, and pure Detection-cost profiles |
| `src/domain/mission.zig` | Public `Mission` contract data type, optional topology reference, level/Reputation requirements and contact-offer gating, `MissionDifficulty`, and typed `MissionObjective` definitions |
| `src/domain/topology.zig` | Static fictional graph nodes/links, node lookup, adjacency checks, and required-operation reachability validation |
| `src/domain/mission_state.zig` | Runtime-only preparation choice, active mission progress, connection state, objective completion bitset, detection exposure, topology position, traversal count, per-run loadout snapshot, and Fixer service-use flag |
| `src/catalog/mission_data.zig` | Four built-in mission definitions and their default ordering; Ghost Signal is appended at index 3 |
| `src/persistence/save.zig` | Save/load persistence for player progress and mission completion state |
| `src/presentation/terminal.zig` | Reusable terminal output for the banner, help, status, mission list, Contacts, offers, history, and topology map |
| `src/application/shop.zig` | Equipment catalog display, purchase/equip/upgrade validation, and inventory presentation |
| `src/application/commands.zig` | Parses an input line into a command name and its first argument |
| `src/application/game.zig` | Coordinates the shared preparation-aware command dispatcher, Contact commands, offer transactions, and game-state transitions |
| `src/application/detection.zig` | Detection exposure changes, warnings, compromise failure, and bounded penalty |
| `src/domain/progression.zig` | Player level thresholds, reputation tiers, XP display thresholds, and mission reward progression |
| `src/domain/contacts.zig` | Fictional Contact identities, Reputation unlock thresholds, and Fixer service pricing |
| `tests/` | Unit tests for command parsing, mission state, mission data, Reputation, Contacts, and offers |
| `test_root.zig` | Repository-root test module that imports the aggregate test suite |
| `docs/` | User and developer documentation |
| `.github/workflows/ci.yml` | Formatting, build, and test checks on pushes and pull requests targeting `main` |

## Core data types

### `Mission`

A mission stores its static contract definition and completion state:

- `id`, `name`, and `target` identify the contract.
- `difficulty` classifies the contract as `easy`, `medium`, or `hard`. Its `label()` method provides the player-facing title-case label.
- `objectives` contains the static, ordered list of `MissionObjective` records. Each record has a `MissionObjectiveKind` and player-facing description.
- `password` and `password_hint` define the authentication puzzle.
- `encrypted_file`, `decryption_hint`, and `decryption_key` define the decryption puzzle and required extraction filename.
- `reward` and `xp_reward` configure contract payouts.
- `required_level` and `required_reputation` define the minimum progression requirements; `requires_contact_offer` marks contracts that must be prepared through a contact offer.
- `completed` records whether the contract has been completed.

Difficulty is currently descriptive metadata only. It is displayed in the contract list and active briefing; it does not yet modify detection, rewards, puzzle rules, or mission requirements. Objectives may be required or optional. Required objectives gate contract completion; optional objectives never block it and can grant configured bonus cash. Successful scan, authentication, decryption, extraction, and metadata-analysis commands complete their matching objective.

The four built-in mission instances are returned by `mission_data.defaultMissions()` as a fixed-size array. Ghost Signal is appended at index 3 so the original mission indices remain stable. Each contract has its own static graph from `src/domain/topology.zig`: Cold Storage has an exposed short corridor and a maintenance detour; Paper Trail branches from an indexing hub into mail and records systems; Quiet Exit uses a relay chain with a decoy branch and controlled exit; Ghost Signal uses an abandoned relay with a mirrored-traffic branch.

### `Player`

The player profile type is defined in `src/domain/player.zig` and imported by `main.zig`. It stores:

- `handle`: terminal identity; defaults to `ghost`.
- `balance`: in-game currency; defaults to 250.
- `reputation`: starts at 0.
- `xp`: starts at 0.
- `equipment`: typed equipment state. The decryptor remains a required tool; utility ownership is represented by a bit mask over `UtilityEquipment`, with one optional equipped utility and separate upgrade levels.

### Temporary preparation and mission session

`MissionPreparation` stores the prepared mission index and selected owned utility before launch. It is runtime-only and is cleared on launch or cancellation. The active mission index is an optional `usize`. Its temporary runtime state is modeled by `MissionSession` in `mission_state.zig`, rather than independent booleans.

The session tracks the following related pieces of temporary state:
- `progress`: `inactive`, `accepted`, `scanned`, `authenticated`, or `decrypted`.
- `connected`: whether the simulated connection is currently open.
- `completed_objectives`: an eight-bit mask keyed by `MissionObjectiveKind`.
- `detection_level`: simulated exposure from 0 to 100, with Quiet, Noticed, Traced, Critical, and Compromised bands.
- `current_node`: the current node ID in the active mission topology, or null for missions without topology.
- `traversal_count`: number of successful node-to-node movements in this session.
- `loadout`: the selected utility and upgrade level snapshotted at launch; Detection modifiers read this snapshot rather than the player inventory.
- `fixer_service_used`: whether the one-use Fixer Detection service has been consumed during this mission.

Each `MissionObjective` also carries an `optional` flag and a `bonus_reward`. `MissionSession.allObjectivesComplete` ignores optional entries, while `optionalReward` totals the rewards for optional entries completed during the current session.

Progress is monotonic. Connection is independent because disconnecting must not revoke authentication or decryption already achieved. A newly accepted contract and a restored active contract start at `accepted`; completing a contract resets the session to `inactive`. Objective completion and detection exposure are runtime-only and are cleared when a mission starts or resets. Detection reaching 100 fails the active contract and applies a $50 penalty, capped at the player's current balance.

## Runtime flow

1. `main` creates the allocator, standard input/output writers, and a default `Player`.
2. `mission_data.defaultMissions()` supplies the built-in mission array.
3. `save.loadGame` attempts to restore persistent progress from `saves/player.sav`.
4. `terminal.printBanner` and the welcome/status text are written to standard output.
5. The application repeatedly prints the prompt and reads a line from standard input.
6. Input is trimmed and passed to `game.runCommand`, together with runtime preparation state.
7. `commands.parse` separates the command name and first argument without allocating memory.
8. `game.runCommand` dispatches the parsed command, validates preparation and active game state, and performs the requested state transition.
9. The loop ends on `exit`, end-of-input, or an input/output error propagated by the relevant function.

## Mission state transitions

```text
inactive -> preparing -> accepted -> scanned -> authenticated -> decrypted
                         |
                         +---- connected (independent, temporary)
```

- `prepare <id>` selects an available contract and displays known intel without revealing puzzle clues.
- `loadout <utility|none>` selects a run-specific owned utility.
- `accept <id>` launches only the matching prepared contract and snapshots the selected utility and its current level.
- `cancel` clears preparation; an active contract cannot be abandoned or manually restarted.
- `scan` advances progress to `scanned`.
- `connect` requires a scanned target and opens the connection.
- `brute` requires an open connection and advances progress on a correct password.
- `disconnect` closes only the connection; it does not revoke authentication or decryption.
- `decrypt` requires authentication and an owned decryptor.
- `analyze <filename>` requires decrypted progress and the exact mission filename. It completes the optional metadata-analysis objective.
- `extract` requires decrypted progress and the exact mission filename. It adds 5 detection on the first successful extraction; if the meter reaches 100 the contract fails instead of paying out. Otherwise it completes the extraction objective and awards the contract when every required objective is complete; completed optional objectives add their configured cash bonus.
- Successful scan (+10), authentication (+5), decryption (+10), optional analysis (+5), and extraction (+5) actions add detection once per objective. Incorrect password attempts add 15; incorrect decryption keys add 10. Connect/disconnect, invalid commands, rejected prerequisites, and repeated successful actions add no exposure.
- Crossing a detection band prints a warning. At 100, the contract is failed, a $50 penalty (capped by available balance) is applied, and the contract remains retryable.
- `map` displays the active graph, node purposes, links, and current location. `move <node-id>` accepts only directly adjacent nodes; every successful traversal adds 5 detection, including revisits. Invalid destinations do not alter state.
- Each topology assigns scan, authentication, decryption, optional analysis, and extraction to specific nodes. The corresponding commands are rejected away from those locations.
- `briefing` displays the objective list and points players to `map`; `objectives` displays the live checklist at any time.

## Progression calculations

`progression.playerLevel` calculates the level from total XP. The first threshold is 100 XP and each subsequent threshold increases by 150 XP. `progression.xpForNextLevel` returns the cumulative threshold associated with a level for display in the status output.

`progression.reputationTier` maps Reputation 0 to Unknown, 1–2 to Recognized, 3–4 to Trusted, and 5+ to Elite. `progression.completeMission` adds the mission's cash reward and optional-objective bonus, increments Reputation by one, grants one additional Reputation when every optional objective is complete, adds the XP reward, and prints the resulting tier and any level-up.

## Persistence boundary

Persistent state includes balance, reputation, XP, decryptor ownership, utility ownership, equipped utility, both utility upgrade levels, active mission index, and mission completion flags. Save V3 is current; `src/persistence/save.zig` continues to read V2, V1, and the original legacy layout. Older saves migrate with no utility equipment owned or equipped.

Mission difficulty, objective definitions, and Reputation requirements are static catalog metadata and are not serialized. Contact unlocks and tiers are derived from the persisted Reputation value. Fixer service use is runtime-only. Temporary `MissionPreparation`, the run-specific loadout snapshot, `MissionSession` progress, connection state, objective completion, detection exposure, current topology node, and traversal count are also not persisted. A loaded active contract starts at its topology entry node. A restored active contract therefore starts at the accepted stage with all objectives unchecked. See [Save Format](save-format.md).

## Error handling style

Most user input errors are handled by printing a message and returning to the prompt. File creation and writing errors during `save` are caught and reported to the player. Loading is intentionally tolerant: failure to open or read the save file returns no active mission, unknown non-numeric format markers are rejected before caller state is mutated, and individual numeric parse failures inside a recognized format generally fall back to the current default value.

## Dependency direction

`player.zig`, `mission.zig`, and `topology.zig` are foundational data modules. `mission.zig` references the topology type; `mission_data.zig` imports mission and topology types and owns the built-in catalog. `save.zig` imports the data types and owns save/load. `terminal.zig` imports data types and the pure progression/contact catalogs for reusable display functions; it does not mutate game state or depend on the game coordinator. `shop.zig` imports only `Player`. `commands.zig` owns allocation-free parsing. `game.zig` coordinates command dispatch and mission transitions; `detection.zig` owns exposure and compromise handling; `progression.zig` owns XP, levels, Reputation tiers, and mission rewards. `contacts.zig` owns the static fictional Contact catalog, unlock thresholds, and service pricing. These modules depend on foundational player/mission/session types and do not import the command coordinator. `main.zig` initializes the application and owns the interactive input loop. Keep dependencies one-way and avoid circular imports.

## Current design constraints

- The built-in mission catalog is hard-coded in `mission_data.zig` and contains four missions; `job-04` is appended after the original three.
- Mission difficulty is currently descriptive metadata; no mechanics are tied to it yet.
- The current objective kinds are scan target, authenticate, decrypt file, extract file, and metadata analysis. Objective progress is stored in a runtime-only eight-bit mask; expand or redesign it before introducing more than eight objective kinds. Optional objective rewards are calculated at contract completion and are not separately persisted.
- Detection is a runtime-only 0–100 meter. Its thresholds, action costs, failure penalty, and reset behavior are defined in the gameplay guide and implemented through `MissionSession` and `detection.zig`.
- The command parser accepts one argument token only; additional tokens are ignored to preserve existing behavior.
- The save parser is line-oriented and has no checksum or full corruption-recovery layer. It recognizes V3, V2, V1, and numeric legacy data; unknown non-numeric markers are rejected without mutating loaded state. Save writes are staged to a temporary file and renamed into place after the complete payload is written.
- `topology.Topology.isValid` verifies unique non-empty node IDs, valid links, and reachability from the entry node to every required operation node. Decorative nodes are not required to be connected.
- Command-specific output is written by command handling; reusable display sections are centralized in `terminal.zig` and shop-specific output in `shop.zig`.
- Automated tests live under `tests/` and are aggregated by `tests/test_all.zig`, with `test_root.zig` providing the repository-root module path.


## Agent knowledge and decision records

The root `AGENTS.md` is the mandatory instruction entry point for contributors and coding agents. The `.agent/` directory contains the workflow, module contracts, roadmap, known constraints, task template, review checklist, and accepted Architecture Decision Records. These documents describe development constraints; they do not replace source code as the authority for current runtime behavior.

The accepted records capture the current Zig 0.13.0 toolchain, focused one-way module boundaries, runtime-only mission sessions, preservation of older save compatibility, and the typed equipment/save V3 decision.
