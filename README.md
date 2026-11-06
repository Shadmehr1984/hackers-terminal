# Hacker's Terminal

**Hacker's Terminal** is a small, text-only hacking simulator written in **Zig 0.17.1**. It is a command-driven, single-player game in which you accept fictional contracts, investigate simulated hosts, solve authentication and decryption puzzles, earn rewards, and unlock harder missions.

> [!IMPORTANT]
> This is a self-contained fictional game. It does not connect to real networks, scan real hosts, execute operating-system commands, or interact with external systems. Hostnames such as `vault-01.local` are game data only.

## Features

- Interactive terminal command loop and command parser
- Five fictional contracts with target-specific clues and puzzle answers
- Five deterministic fictional rival hackers with contestable optional intelligence and dossier commands (`rivals`, `rival <id>`)
- Seven fictional factions with derived standing, symmetric relationships, and faction-locked contract access
- A Contract Board with derived availability and reward ranges
- Multi-stage Operations with ordered stages, carry-over facts, retry behavior, and start-time faction preauthorization
- Mission difficulty labels: Easy, Medium, and Hard
- Required and optional mission objectives with live completion tracking and bonus rewards
- Mission progression gated by operator level and reputation
- Four reputation tiers with two unlockable fictional contacts, paid intelligence, temporary Detection services, and an exclusive contract
- Pre-mission intelligence briefing and run-specific utility loadout selection
- Mission-specific fictional network maps with adjacent-node navigation and location-based operations
- Detection exposure increases with risky actions and every successful network traversal
- Simulated scan, connection, authentication, decryption, metadata analysis, and extraction stages
- Player balance, reputation tiers, XP, and level progression
- A shop with a required decryptor plus two optional utility tools, a single active utility slot, and two upgrade tiers per utility
- Local save/load, including V3 equipment persistence and migration from V2, V1, and legacy saves
- Zig formatting, build, and test checks in GitHub Actions for Debug, ReleaseSafe, and ReleaseFast

## Requirements

- [Zig 0.17.1](https://ziglang.org/download/)
- A terminal capable of running a command-line executable

The project currently targets Zig 0.17.1. Other Zig versions are not guaranteed to be compatible.

## Build and run

From the repository root:

```sh
zig build
zig build run
```

The executable is installed at:

```text
zig-out/bin/hackers-terminal
```

You can also run that executable directly after building:

```sh
./zig-out/bin/hackers-terminal
```

On Windows, run the generated `hackers-terminal.exe` from the corresponding `zig-out/bin` directory.

## Quick start

1. Start the game with `zig build run`.
2. Enter `help` to see the available commands.
3. Enter `missions`, inspect the first contract with `prepare job-01`, then launch it with `accept job-01`.
4. Read the mission clues and difficulty with `briefing`, then inspect the map with `map`.
5. Move to the node labelled `SCAN` on the map, scan the target, then move to the `AUTH` node to connect and authenticate.
6. Solve the password challenge with `brute <password>`. Each successful move adds 5 detection.
7. Move to the node labelled `DECRYPT`, buy the decryptor if needed, and solve the decryption challenge.
8. Move to the `ANALYZE` node and optionally run `analyze <filename>` to earn a bonus reward.
9. Move to the `EXTRACT` node and extract the exact filename shown in the briefing.
10. Use `save` to persist your progress.

For a complete walkthrough, see [Gameplay](docs/gameplay.md). For exact command syntax and prerequisites, see [Command Reference](docs/commands.md).

## Documentation

| Document | Contents |
| --- | --- |
| [Gameplay](docs/gameplay.md) | Mission loop, difficulty labels, progression, contracts, clues, and walkthrough |
| [Command Reference](docs/commands.md) | Commands, arguments, prerequisites, and responses |
| [Architecture](docs/architecture.md) | Source layout, runtime state, data model, and command flow |
| [Save Format](docs/save-format.md) | Save location, V3 equipment layout, loading, and legacy migration |
| [Development](docs/development.md) | Build, format, test, CI, and contribution notes |
| [Agent Instructions](AGENTS.md) | Mandatory project rules and coding-agent entry point |
| [Agent Workspace](.agent/README.md) | Agent workflow, module contracts, roadmap, ADRs, task template, and review checklist |

## Project layout

```text
hackers-terminal/
├── .agent/                 # ADRs, task handoffs, plans, review checklist, workflow
├── .github/workflows/ci.yml
├── docs/                   # Architecture, gameplay, commands, development, save format
├── scripts/check-agent-docs.sh
├── src/
│   ├── application/        # commands, detection, game, shop
│   ├── catalog/            # faction_data, mission_data, operation_data, rival_data
│   ├── domain/             # contacts, contract_board, factions, missions,
│   │                       # objectives, operations, player, progression, rivals, topology
│   ├── persistence/        # save/load and legacy compatibility
│   ├── presentation/       # terminal output
│   ├── main.zig            # composition root
│   └── *.zig               # thin compatibility facades for legacy imports
├── tests/                  # 22 focused test modules plus test_all.zig aggregate
├── test_root.zig
├── AGENTS.md
├── build.zig
└── README.md
```

The `saves/` directory is created at runtime when the player saves. It is ignored by Git.

## Current scope and limitations

- The game currently contains five built-in missions defined in `src/catalog/mission_data.zig`; `job-04` (Ghost Signal) remains the exclusive Fixer offer, and `job-05` (Corporate Ghost) is appended at index 4 with level 2 and Reputation 2 requirements plus Nexus Dynamics faction access.
- Faction standing is derived from Reputation and completed contract affiliations; no per-faction score is saved. Hostile client standing blocks contract access, while an Operation that passed all stage checks at start remains preauthorized.
- The authored `blackout-protocol` Operation sequences Cold Storage, Paper Trail, and Quiet Exit. Operation state and carry-over facts are runtime-only.
- Five authored rivals contest one hidden optional objective each. Their outcomes are deterministic and runtime-only; losing an optional objective can forfeit the existing all-optional +1 Reputation bonus for that run, while required objectives and extraction remain available.
- Optional-objective cash rewards and Contract Board reward ceilings use checked arithmetic; overflow is rejected rather than wrapped.
- Mission difficulty is descriptive metadata only; it is displayed in the mission list and briefing but does not yet affect gameplay mechanics.
- There is one player profile and one local save file.
- The command parser accepts a command and at most one space-delimited argument.
- The simulated scan and connection are state flags; there is no networking layer.
- Mission preparation, the run-specific loadout snapshot, session progress (scan, connection, authentication, decryption, objective completion, current topology node, traversal count), and per-mission Fixer service use are not persisted. Reputation tiers and Contact unlocks are derived from persisted Reputation; no Save V4 is required. If a saved active contract is restored after restarting, its session stages and objectives must be performed again.
- The terminal UI is plain text and uses an ANSI escape sequence for `clear`.

See [Architecture](docs/architecture.md) for implementation details and [Development](docs/development.md) for the current verification workflow.
