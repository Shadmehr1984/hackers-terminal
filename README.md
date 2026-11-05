# Hacker's Terminal

**Hacker's Terminal** is a small, text-only hacking simulator written in **Zig 0.13.0**. It is a command-driven, single-player game in which you accept fictional contracts, investigate simulated hosts, solve authentication and decryption puzzles, earn rewards, and unlock harder missions.

> [!IMPORTANT]
> This is a self-contained fictional game. It does not connect to real networks, scan real hosts, execute operating-system commands, or interact with external systems. Hostnames such as `vault-01.local` are game data only.

## Features

- Interactive terminal command loop and command parser
- Three fictional contracts with target-specific clues and puzzle answers
- Mission progression gated by operator level
- Simulated scan, connection, authentication, decryption, and extraction stages
- Player balance, reputation, XP, and level progression
- A small shop and persistent tool inventory
- Local save/load, including migration from older save formats
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
3. Enter `missions` and accept the first contract: `accept job-01`.
4. Read the mission clues with `briefing`.
5. Scan and connect to the target shown in the briefing.
6. Solve the password challenge with `brute <password>`.
7. Buy the decryptor if you do not own it, then solve the decryption challenge.
8. Extract the exact filename shown in the briefing.
9. Use `save` to persist your progress.

For a complete walkthrough, see [Gameplay](docs/gameplay.md). For exact command syntax and prerequisites, see [Command Reference](docs/commands.md).

## Documentation

| Document | Contents |
| --- | --- |
| [Gameplay](docs/gameplay.md) | Mission loop, progression, contracts, clues, and walkthrough |
| [Command Reference](docs/commands.md) | Commands, arguments, prerequisites, and responses |
| [Architecture](docs/architecture.md) | Source layout, runtime state, data model, and command flow |
| [Save Format](docs/save-format.md) | Save location, V2 layout, loading, and legacy migration |
| [Development](docs/development.md) | Build, format, test, CI, and contribution notes |

## Project layout

```text
hackers-terminal/
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
│   └── main.zig
├── .gitignore
├── build.zig
└── README.md
```

The `saves/` directory is created at runtime when the player saves. It is ignored by Git.

## Current scope and limitations

The current implementation is intentionally compact:

- All game content and mission definitions are compiled into `src/main.zig`.
- There is one player profile and one local save file.
- The command parser accepts a command and at most one whitespace-delimited argument.
- The simulated scan and connection are state flags; there is no networking layer.
- Session progress (scan, connection, authentication, and decryption) is not persisted. If a saved active contract is restored after restarting, its session stages must be performed again.
- The terminal UI is plain text and uses an ANSI escape sequence for `clear`.

See [Architecture](docs/architecture.md) for implementation details and [Development](docs/development.md) for the current verification workflow.
