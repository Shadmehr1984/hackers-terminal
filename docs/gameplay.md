# Gameplay Guide

## Core loop

Hacker's Terminal is built around a repeatable contract loop:

```text
missions
   |
accept <id>
   |
briefing
   |
scan <target>
   |
connect <target>
   |
brute <password>
   |
buy decryptor (if needed)
   |
decrypt <key>
   |
extract <filename>
   |
reward, XP, and reputation
```

Each stage unlocks the next. Commands that are issued out of order are rejected with an explanatory message.

## Starting profile

A new player starts with:

| Attribute | Initial value |
| --- | ---: |
| Handle | `ghost` |
| Balance | $250 |
| Reputation | 0 |
| XP | 0 |
| Level | 1 |
| Decryptor | Not owned |

The decryptor costs $150. It is a persistent tool: once purchased, it remains owned in subsequent sessions when the save is loaded.

## Contracts

The game currently defines three contracts in `src/mission_data.zig`.

| ID | Contract | Difficulty | Fictional target | Required level | Cash reward | XP reward |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `job-01` | Cold Storage | Easy | `vault-01.local` | 1 | $300 | 100 |
| `job-02` | Paper Trail | Medium | `archive-02.local` | 2 | $500 | 150 |
| `job-03` | Quiet Exit | Hard | `relay-03.local` | 3 | $800 | 200 |

A contract is available only when the player's level meets its required level and it has not already been completed. Only one active contract is allowed at a time.

Difficulty is currently a descriptive rating shown by `missions` and `briefing`. It does not yet change mission mechanics, rewards, or detection risk. Future mission-system work may give these ratings mechanical meaning, but that should be introduced as a separately designed and tested change.

### Mission objectives

Every contract defines an ordered checklist of objectives. `briefing` displays the checklist, and `objectives` shows its current completion state at any point during the active contract. The current objective types are:

1. **Survey target** — completed by a successful `scan <target>`.
2. **Authenticate** — completed by solving the password challenge with `brute <password>`.
3. **Decrypt evidence** — completed by a successful `decrypt <key>` after purchasing the decryptor.
4. **Recover evidence** — completed by extracting the exact filename with `extract <filename>`.

The descriptions differ between contracts even though the current core objective types are shared. A contract is awarded only after every objective in its definition is complete. Objective progress is temporary and is reset when a contract starts or ends; it is not written to the save file.

### Contract clues

Use `briefing` after accepting a contract. The briefing displays the target, difficulty, password clue, encrypted filename, and decryption clue.

| Contract | Password clue | Decryption clue | File to extract |
| --- | --- | --- | --- |
| Cold Storage | A hunter constellation, followed by 42 | The middle of the night | `ledger.enc` |
| Paper Trail | A reddish metal, followed by 17 | A small songbird often associated with a clear blue color | `mailbox.enc` |
| Quiet Exit | A fixed point used for navigation in the northern sky | The time after normal business hours | `manifest.enc` |

<details>
<summary>Puzzle solutions (spoilers)</summary>

| Contract | Password | Decryption key |
| --- | --- | --- |
| Cold Storage | `orion42` | `midnight` |
| Paper Trail | `copper17` | `bluebird` |
| Quiet Exit | `northstar` | `afterhours` |

</details>

## Completing the first contract

The first contract is a guided introduction to the complete game loop.

1. Run `missions` and accept `job-01`.
2. Run `briefing` to read the clues and objective checklist.
3. Run `scan vault-01.local`, then `objectives` to see the first objective completed.
4. Run `connect vault-01.local`.
5. Solve the clue with `brute orion42`.
6. Buy the file decryptor with `buy decryptor`. It costs $150.
7. Solve the decryption clue with `decrypt midnight`.
8. Run `objectives` to review the checklist, then retrieve the file with `extract ledger.enc`.
9. Run `status` to see the updated balance, XP, reputation, and level.
10. Run `save` to persist your progress.

The initial $250 is enough to buy the decryptor. Completing the first contract grants $300 and 100 XP.

## Progression and leveling

The player begins at level 1. The XP threshold for level 2 is 100 XP; the threshold for level 3 is 250 total XP. Each level after level 2 requires another 150 XP.

The threshold for reaching level `L` (where `L >= 2`) is:

```text
100 + (L - 2) * 150
```

Completing a contract adds its configured XP reward. The game announces a level-up when the player's level increases. Since the second contract requires level 2 and awards 150 XP, completing the first contract unlocks it. Completing the second contract brings the player to 250 XP and level 3, unlocking the final contract.

Each completed contract also increases reputation by 1.

## Economy and inventory

The current shop has one item:

| Item | Price | Purpose |
| --- | ---: | --- |
| `decryptor` | $150 | Required to decrypt mission files |

Use `shop` to list items, `buy decryptor` to purchase it, and `inventory` to inspect owned tools. The game prevents duplicate purchases and purchases when the player cannot afford the item.

## Saving and resuming

The game automatically attempts to load `saves/player.sav` at startup. Use `save` to write the current player and contract progress.

The active contract can be restored, but the temporary session stages are not saved. After restarting, repeat the scan and connection stages and solve the challenges again as needed. See [Save Format](save-format.md) for the exact fields and compatibility behavior.
