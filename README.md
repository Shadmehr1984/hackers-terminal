# Hacker's Terminal

A small, text-only command-line hacking simulator written in **Zig**.

The game takes place in a fictional underground world. You are an independent operator accepting contracts, scanning fictional hosts, solving authentication and decryption challenges, and collecting rewards.

> **Safety:** This is a self-contained fictional game. It does not connect to real networks, scan real hosts, execute system commands, or interact with external systems.

## Requirements

- Zig **0.13.0**
- A terminal

## Build and run

```bash
zig build
zig build run
```

Or run the installed executable:

```bash
zig build
./zig-out/bin/hackers-terminal
```

## Commands

| Command | Description |
| --- | --- |
| `help` | List commands |
| `status` | Show operator status |
| `missions` | List available contracts |
| `accept <id>` | Accept a contract |
| `scan <target>` | Scan the active fictional target |
| `connect <target>` | Establish a simulated session |
| `disconnect` | Close the simulated session |
| `brute <password>` | Solve the mission's password challenge |
| `decrypt <key>` | Decrypt the mission file (requires the decryptor) |
| `extract <filename>` | Complete the contract |
| `inventory` | Show owned tools |
| `shop` | List tools for sale |
| `buy <item>` | Purchase a tool |
| `save` | Save player progress |
| `clear` | Clear the terminal |
| `exit` | Quit |

## First mission walkthrough

The first contract is **Cold Storage**. Its fictional target is `vault-01.local`.

1. Run `missions` and accept `job-01`.
2. Scan and connect to the target.
3. Solve the password challenge with `brute orion42`.
4. Buy the decryptor with `buy decryptor` (it costs $150).
5. Decrypt the file with `decrypt midnight`.
6. Extract it with `extract ledger.enc`.

The other contracts unlock through the same gameplay loop.

## Save data

Progress is stored locally in `saves/player.sav`. The game loads this file automatically on startup. Use `save` to write the current balance, reputation, purchased tools, and completed contracts.

## Project layout

```text
hackers-terminal/
├── build.zig
├── src/
│   └── main.zig
├── saves/          # Created when the game is saved
└── README.md
```

## Current scope

This is the first playable foundation: a command parser, operator profile, three fictional contracts, a basic progression loop, a small tool shop, and local save/load. More mission variety, richer puzzles, narrative events, and a deeper economy can be added in later versions.
