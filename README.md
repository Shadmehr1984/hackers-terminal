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
| `briefing` | Show clues for the active contract |
| `accept <id>` | Accept a contract |
| `scan <target>` | Scan the active fictional target |
| `connect <target>` | Establish a simulated session |
| `disconnect` | Close the simulated session |
| `brute <password>` | Solve the mission's password challenge |
| `decrypt <key>` | Decrypt the mission file (requires the decryptor) |
| `extract <filename>` | Complete the contract |
| `history` | Show completed contracts |\n| `inventory` | Show owned tools |
| `shop` | List tools for sale |
| `buy <item>` | Purchase a tool |
| `save` | Save player progress |
| `clear` | Clear the terminal |
| `exit` | Quit |

## First mission walkthrough

The first contract is **Cold Storage**. Its fictional target is `vault-01.local`.

1. Run `missions` and accept `job-01`.
2. Run `briefing` to read the clues, then scan and connect to the target.
3. Solve the password clue with `brute orion42`.
4. Buy the decryptor with `buy decryptor` (it costs $150).
5. Solve the decryption clue with `decrypt midnight`.
6. Extract it with `extract ledger.enc`.

The other contracts use the same gameplay loop. Contract availability is tied to operator level: `job-01` is available at level 1, `job-02` unlocks at level 2, and `job-03` unlocks at level 3. Completing contracts grants XP as well as money and reputation. The first contract grants 100 XP; the second grants 150 XP; the third grants 200 XP. The level thresholds are 100 XP for level 2 and 250 total XP for level 3.

## Save data

Progress is stored locally in `saves/player.sav`. The game loads this file automatically on startup. Use `save` to write the current balance, reputation, XP, purchased tools, completed contracts, and active contract. Save files now use the `HACKERS_TERMINAL_SAVE_V2` format. Existing V1 and original pre-versioned save files are still accepted; V1 saves start with 0 XP (level 1). If an active contract is restored after restarting, its scan and connection session must be started again.

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

The current foundation includes a command parser, operator profile, three fictional contracts, XP and level progression, level-gated contracts, a small tool shop, and local save/load. More mission variety, richer puzzles, narrative events, and a deeper economy can be added in later versions.
