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
map / move <node-id>
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

Difficulty is currently a descriptive rating shown by `missions` and `briefing`. It does not change mission mechanics or detection risk.

### Mission objectives

Every contract defines an ordered checklist of required and optional objectives. `briefing` displays the checklist, and `objectives` shows its current completion state at any point during the active contract. The current objective types are:

1. **Survey target** — completed by a successful `scan <target>`.
2. **Authenticate** — completed by solving the password challenge with `brute <password>`.
3. **Decrypt evidence** — completed by a successful `decrypt <key>` after purchasing the decryptor.
4. **Recover evidence** — completed by extracting the exact filename with `extract <filename>`.
5. **Optional: analyze metadata** — after decryption, run `analyze <filename>` to inspect simulated metadata. This objective is not required to finish the contract and grants bonus cash: $75 for Cold Storage, $100 for Paper Trail, and $125 for Quiet Exit.

The descriptions differ between contracts even though the current core objective types are shared. A contract is awarded after every required objective is complete. Optional objectives do not block completion; completed ones add their bonus cash to the contract payout. Objective progress and detection exposure are temporary and reset when a contract starts or ends; neither is written to the save file.

### Fictional network navigation

Each contract has a purpose-built, entirely fictional network graph. Accepting a contract places the operator at its entry node. Use `map` to inspect nodes, links, current position, and the node assigned to each operation; use `move <node-id>` to traverse one adjacent link.

Every successful traversal adds **5 Detection**, including revisiting a previously used link. Unknown and non-adjacent destinations are rejected without changing location or Detection. Movement can therefore make a route choice safer or riskier, and reaching 100 still invokes the HT-001 failure and penalty rules.

| Contract | Graph layout | Operation locations |
| --- | --- | --- |
| Cold Storage | Compact perimeter; a short exposed service corridor and a longer maintenance/utility detour both lead to the vault | Scan and authentication: `service`; decrypt, analyze, extract: `vault` |
| Paper Trail | Indexing hub with separate mail-processing and records-access branches | Scan: `index`; authentication: `mail-gw`; decrypt/extract: `mail-store`; optional analysis: `records` |
| Quiet Exit | Relay chain with a decoy branch and a controlled exit route | Scan: `relay-a`; authentication: `relay-core`; decrypt/analyze: `transfer`; extract: `exit` |

The relevant commands must be issued at their assigned nodes. For example, scanning Cold Storage from `entry` is rejected; first move to `service`. All topology and position data are local static game content. Current location is session-only and is not written to any save version.

### Detection and operational risk

Detection is a fictional exposure meter for the active contract. It starts at 0 and is capped at 100. The current band is shown by `status`:

| Level | Band |
| ---: | --- |
| 0–24 | Quiet |
| 25–49 | Noticed |
| 50–74 | Traced |
| 75–99 | Critical |
| 100 | Compromised |

Risk costs are deterministic:

| Action | Detection change |
| --- | ---: |
| Successful scan (first time only) | +10 |
| Successful authentication (first time only) | +5 |
| Incorrect password attempt | +15 |
| Successful decryption (first time only) | +10 |
| Incorrect decryption key | +10 |
| Successful optional metadata analysis (first time only) | +5 |
| Successful extraction (first time only) | +5 |
| Connect, disconnect, invalid commands, or rejected prerequisites | +0 |

Repeated successful actions do not add exposure again. Crossing a band boundary prints a warning. At 100, the active contract immediately fails: no contract reward, XP, or reputation is granted, and a $50 penalty is deducted. The penalty is capped at the player's available balance, so the balance never becomes negative. The failed contract remains available to accept again. Detection resets when a contract starts, completes, or fails.

Detection is session-only and is deliberately excluded from all save versions. Restoring an active contract after restarting begins with 0 detection, just as other temporary mission progress is reset.

## Contract clues

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
3. Run `map`, move from `entry` to `service` with `move service`, then run `scan vault-01.local` and `objectives` to see the first objective completed.
4. Run `connect vault-01.local`.
5. Solve the clue with `brute orion42`.
6. Buy the file decryptor with `buy decryptor`. It costs $150.
7. Solve the decryption clue with `decrypt midnight`.
8. Optionally run `analyze ledger.enc` to complete the metadata objective and earn an extra $75.
9. Run `objectives` to review the checklist, then retrieve the file with `extract ledger.enc`.
10. Run `status` to see the updated balance, XP, reputation, level, and current detection level.
11. Run `save` to persist your progress.

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
