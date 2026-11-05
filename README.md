# Hacker's Terminal

**Hacker's Terminal** is a small, text-only hacking simulator written in **Zig 0.13.0**. It is a command-driven, single-player game in which you accept fictional contracts, investigate simulated hosts, solve authentication and decryption puzzles, earn rewards, and unlock harder missions.

> [!IMPORTANT]
> This is a self-contained fictional game. It does not connect to real networks, scan real hosts, execute operating-system commands, or interact with external systems. Hostnames such as `vault-01.local` are game data only.

## Features

- Interactive terminal command loop and command parser
- Four fictional contracts with target-specific clues and puzzle answers
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
- Zig formatting, build, and test checks in GitHub Actions

## Requirements

- [Zig 0.13.0](https://ziglang.org/download/)
- A terminal capable of running a command-line executable

The project currently targets Zig 0.13.0. Other Zig versions are not guaranteed to be compatible.

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
├── .agent/
│   ├── decisions/
│   ├── tasks/
│   ├── README.md
│   ├── workflow.md
│   ├── conventions.md
│   ├── roadmap.md
│   ├── known-issues.md
│   └── review-checklist.md
├── scripts/
│   └── check-agent-docs.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── docs/
│   ├── architecture.md
│   ├── commands.md
│   ├── development.md
│   ├── gameplay.md
│   └── save-format.md
├── src/
│   ├── main.zig
│   ├── game.zig
│   ├── detection.zig
│   ├── progression.zig
│   ├── contacts.zig
│   ├── player.zig
│   ├── mission.zig
│   ├── topology.zig
│   ├── mission_data.zig
│   ├── mission_state.zig
│   ├── commands.zig
│   ├── terminal.zig
│   ├── save.zig
│   └── shop.zig
├── tests/
│   ├── commands_test.zig
│   ├── mission_state_test.zig
│   ├── mission_data_test.zig
│   ├── mission_objectives_test.zig
│   ├── game_detection_test.zig
│   ├── topology_test.zig
│   ├── equipment_test.zig
│   ├── mission_preparation_test.zig
│   ├── progression_test.zig
│   ├── contacts_test.zig
│   └── test_all.zig
├── test_root.zig
├── AGENTS.md
├── build.zig
└── README.md
```

The `saves/` directory is created at runtime when the player saves. It is ignored by Git.

## Current scope and limitations

- The game currently contains four built-in missions defined in `src/mission_data.zig`; `job-04` (Ghost Signal) is appended and requires level 3 and Reputation 3.
- Mission difficulty is descriptive metadata only; it is displayed in the mission list and briefing but does not yet affect gameplay mechanics.
- There is one player profile and one local save file.
- The command parser accepts a command and at most one whitespace-delimited argument.
- The simulated scan and connection are state flags; there is no networking layer.
- Mission preparation, the run-specific loadout snapshot, session progress (scan, connection, authentication, decryption, objective completion, current topology node, traversal count), and per-mission Fixer service use are not persisted. Reputation tiers and Contact unlocks are derived from persisted Reputation; no Save V4 is required. If a saved active contract is restored after restarting, its session stages and objectives must be performed again.
- The terminal UI is plain text and uses an ANSI escape sequence for `clear`.

See [Architecture](docs/architecture.md) for implementation details and [Development](docs/development.md) for the current verification workflow.
