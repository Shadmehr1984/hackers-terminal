# Command Reference

Commands are entered at the game prompt. Command names are lowercase. Arguments are separated from the command by spaces.

## General commands

| Command | Arguments | Description |
| --- | --- | --- |
| `help` | None | Print the command list and mission flow |
| `status` | None | Show player profile, decryptor ownership, active utility, active contract, and detection level/band |
| `missions` | None | Legacy compact list of contracts, difficulty labels, and level/Reputation requirements; behavior is unchanged |
| `operations` | None | List authored multi-stage operations, stage counts, and derived availability/current status |
| `operation <id>` | Operation ID | Inspect ordered contract stages and their level/Reputation requirements |
| `operation-start <id>` | Operation ID | Start an operation and prepare its first stage |
| `operation-status` | None | Show the current operation stage and earned carry-over facts |
| `board` | None | Open the Contract Board with categories, reward ranges, faction affiliations, standing, and availability reasons |
| `factions` | None | List all seven fictional organizations and your derived standing with each |
| `faction <id>` | Faction ID | Inspect one faction dossier and its static relationships |
| `contacts` | None | Show both fictional contacts and their unlock status |
| `contact <id>` | `broker` or `fixer` | Inspect a contact, its role, and relevant offers |
| `offers` | None | List currently actionable contact offers |
| `deal <id>` | Offer ID | Purchase intelligence, use a Fixer service, or accept the exclusive contract offer |
| `briefing` | None | Show target, difficulty, clues, and objective checklist for the active contract |
| `objectives` | None | Show completion status for every objective in the active contract |
| `map` | None | Show the active mission graph, operation locations, and current node |
| `history` | None | List completed contracts |
| `inventory` | None | Show owned tools, utility levels, and equipped utility |
| `shop` | None | List purchasable equipment and upgrade prices |
| `save` | None | Save progress to `saves/player.sav` |
| `clear` | None | Clear the terminal using an ANSI escape sequence |
| `exit` | None | Leave the game |

## Contract Board

Use `board` to inspect every catalog contract without changing the existing `missions` command. Entries remain in catalog order and show category, difficulty, base-to-maximum cash reward, XP, and one derived state: `AVAILABLE`, `LOCKED`, `COMPLETED`, `EXCLUSIVE`, `UNAVAILABLE`, or `FACTION LOCKED`. Locked entries explain each unmet level/Reputation requirement. Exclusive entries must be obtained through their Contact offer. While another contract is active or being prepared, other incomplete entries remain visible as unavailable; completed entries remain completed. The Board does not reveal puzzle clues or answers and does not save any additional state.

Use `board` for the full catalog overview; `missions` remains the original compact list.

## Factions

Use factions to list all seven organizations. Use faction <id> with one of nexus-dynamics, ghost-protocol, black-veil, aegis-initiative, iron-meridian, null-syndicate, or helix-consortium to inspect a dossier. The dossier includes identity, security profile, economic behavior, specialty, player standing, and relationships with the other factions.

The Contract Board displays each contract's client faction, target owner, client security rating, and your derived standing. A Hostile standing (score <= -2) toward a contract's client faction marks it FACTION LOCKED. Preparation, exclusive contact offers, and operation start enforce the same restriction. Standing is calculated from global Reputation and completed contract affiliations; it is not stored separately. Save V3 and older formats are unchanged.

## Multi-stage Operations

The first authored operation is `blackout-protocol`, a linear sequence of Cold Storage (`job-01`), Paper Trail (`job-02`), and Quiet Exit (`job-03`). Use `operations` to list operations and derived availability, `operation blackout-protocol` to inspect the ordered stages and prerequisites, then `operation-start blackout-protocol` to open preparation for stage one.

Accept each stage with the existing `accept <mission-id>` command. After a successful stage, the next stage is prepared automatically but still requires explicit acceptance. Use `operation-status` to inspect the current stage and earned mechanical facts. `prepare` and `cancel` cannot replace or abandon an active operation. A compromised stage is prepared again for retry; facts from earlier successful stages remain available.

Completing hidden optional objective `maintenance-telemetry` in stage one grants the `maintenance_telemetry` fact, which reveals `routing-header` in stage two. Completing `routing-header` grants `routing_header`, which reveals `relay-trace` in stage three. These objectives remain optional and still require their normal completion event. If the source objective is not completed, the later objective keeps its ordinary HT-008 discovery trigger.

Each stage pays its existing contract rewards only if that contract was not already completed before the operation run. Replaying a previously completed stage pays no contract, optional-objective, Reputation, XP, or modifier rewards. There is no operation-completion bonus. Operation state and facts are runtime-only; saving during an operation writes no active mission index, and after restart the operation begins again at stage one with facts cleared. Save V3 is unchanged.

## Mission commands

| Command | Arguments | Prerequisites | Effect |
| --- | --- | --- | --- |
| `prepare <id>` | Contract ID | No active or already prepared contract; required level and Reputation are met, the contract is incomplete, and its client faction is not Hostile | Opens a pre-mission intelligence briefing without launching the contract |
| `loadout <utility|none>` | Owned utility or `none` | Contract is being prepared; selected utility must be owned | Selects the utility for this run without changing persistent equipment |
| `modifier` | None | Contract is being prepared | Lists allowed modifiers, exact effects, completion bonus, and current selection |
| `modifier <id>` | `heightened-monitoring`, `security-sweep`, or `hardened-encryption` | Contract is being prepared; modifier must be allowed by that contract | Selects one modifier for this run; only one may be selected |
| `modifier none` | `none` | Contract is being prepared | Clears the selected modifier |
| `accept <id>` | Prepared contract ID | Matching contract is prepared; no active contract | Launches the prepared contract and snapshots its selected utility, upgrade level, and optional modifier |
| `cancel` | None | Contract is being prepared | Cancels preparation for free; cannot abandon an active contract |
| `move <node-id>` | Adjacent node ID | Active contract with topology; destination must be directly linked to current node | Moves one edge and adds 5 detection on every successful traversal |
| `scan <target>` | Exact target hostname | Active contract; at the mission scan node when topology is present | Marks the active target as scanned |
| `connect <target>` | Exact target hostname | Active contract has been scanned; at its authentication node when topology is present | Establishes the simulated session |
| `disconnect` | None | None | Closes the simulated session |
| `brute <password>` | Password answer | Active contract, connected session, and authentication node | Grants simulated authentication when the answer matches |
| `decrypt <key>` | Decryption answer | Active contract, authentication granted, decryptor owned, and decryption node | Marks the mission file as decrypted when the key matches |
| `inspect <filename>` | Authored fictional evidence filename | Active contract | Inspects matching fictional evidence and may reveal a hidden optional objective; unrelated names reveal nothing |
| `analyze <filename>` | Exact encrypted filename | Active contract, successful decryption, and analysis node | Completes discovered metadata objectives and earns their bonuses at contract completion |
| `extract <filename>` | Exact encrypted filename | Active contract, successful decryption, and extraction node | Completes the extraction objective; awards the contract only when all its objectives are complete |

Preparation shows known contract intelligence, target, difficulty, rewards, objective outline, topology overview, and every allowed modifier with its exact effect and successful-completion bonus. Faction-locked contracts are rejected before preparation. Puzzle clues and answers remain undiscovered until the contract is launched. Preparation and its selected modifier are temporary and are not saved.

Mission difficulty is currently descriptive metadata. Mission objectives are defined per contract and their completion is tracked during the active session. Optional objectives do not block contract completion; their configured cash bonuses are added only when completed. The game does not perform real scanning, authentication, password attacks, decryption, or file extraction. These commands only advance the fictional mission state. Successful topology movement adds 5 Detection per traversal, including revisits, unless equipped Silent Boots reduce the cost to 4/3/2. `heightened-monitoring` adds another +2 after that adjusted cost; `security-sweep` adds +8 after every third successful traversal (revisits count, rejected moves do not). An incorrect password adds 15 Detection unless equipped Signal Scrubber reduces the cost to 12/9/6. Successful scan/authentication/decryption/analysis/extraction actions add detection exposure once; incorrect decryption-key attempts also add exposure; `hardened-encryption` changes an incorrect key attempt from +10 to +15, without changing the successful decryption cost. Connect, disconnect, invalid commands, and rejected prerequisites add none. At 100 detection, the contract fails and a $50 penalty (up to the available balance) is applied. The contract can be accepted again.

## Contact offer commands

| Command | Arguments | Prerequisites | Effect |
| --- | --- | --- | --- |
| `deal intel-<mission-id>` | e.g. intel-job-02 | Information Broker unlocked at Reputation 1; target contract meets level/Reputation requirements, is incomplete, has non-Hostile client standing, and at least $50 is available | Charges $50 and reveals that contract's password and decryption clues, not the answers |
| `deal scrub-detection` | Fixed offer ID | Fixer unlocked at Reputation 3; active contract; Detection above zero; service unused this contract; enough funds | Reduces Detection by up to 10; costs $100 at Reputation 3–4 or $75 at Reputation 5+ |
| `deal ghost-signal` | Fixed offer ID | Fixer unlocked; no active/prepared contract; level 3 and Reputation 3; job-04 incomplete. The offer is hidden while another contract is active or prepared. | Opens preparation for the exclusive Ghost Signal contract without a fee; direct prepare is rejected |

Contact unlocks are derived from Reputation and are not separately saved. Broker intelligence is listed and purchasable only for contracts whose level, Reputation, and client-faction access requirements are met; a hostile faction lock cannot be bypassed through `deal intel-<mission-id>`. The Fixer service can be used once per active contract; its usage flag is temporary and resets when the contract starts or ends. Broker intelligence purchases are repeatable transactions and deduct $50 each time.

A selected modifier grants an additional +$50 and +25 XP only when the contract is successfully completed. It grants nothing on failure, Detection compromise, cancellation, or incomplete objectives. All three modifiers are available for the five current built-in contracts.

## Economy commands

| Command | Arguments | Description |
| --- | --- | --- |
| `buy <item>` | Item name | Purchase an item if it exists, is not already owned, and the player can afford it |
| `equip <utility>` | Utility name | Equip an owned utility, replacing the active utility |
| `upgrade <utility>` | Utility name | Buy the next upgrade tier for an owned utility |

An active contract cannot be abandoned or manually restarted. Detection compromise still fails the contract and allows it to be prepared and launched again.

The decryptor costs $150. Optional utilities `silent-boots` and `signal-scrubber` each cost $100. Use `equip <utility>` to activate one owned utility in the single utility slot, and `upgrade <utility>` to purchase its next tier ($150 for level 1, $250 for level 2). Silent Boots reduce successful movement Detection from 5 to 4/3/2; Signal Scrubber reduces incorrect-password Detection from 15 to 12/9/6. These effects apply only while the matching utility is equipped.

## Typical command sequence

For the first contract:

```text
missions
prepare job-01
accept job-01
briefing
map
move service
scan vault-01.local
connect vault-01.local
brute orion42
move corridor
move vault
buy decryptor
decrypt midnight
analyze ledger.enc   (optional: +$75)
extract ledger.enc
status
save
```

The password and decryption key above are the first contract's puzzle answers. Other contracts have different clues and answers; consult the briefing for the active contract.

## Input behavior and limitations

For missions with a topology, each successful `move` normally adds 5 Detection, including backtracking; equipped Silent Boots reduce this to 4/3/2. Invalid or non-adjacent moves add none. Missions without topology retain the previous command behavior.

The parser tokenizes input on spaces and reads only the first argument token. Therefore:

- Commands and arguments are case-sensitive.
- Arguments cannot contain spaces.
- Quoted multi-word arguments are not supported.
- Extra tokens after the first argument are ignored.
- The command loop reads one line at a time into a 512-byte input buffer.

If a command appears not to match, check its spelling, capitalization, argument, and the active mission stage.


## Detection risk values

Detection is temporary per-contract state, ranges from 0 to 100, and is displayed by `status`. Bands are Quiet (0–24), Noticed (25–49), Traced (50–74), Critical (75–99), and Compromised (100). See the [Gameplay Guide](gameplay.md#detection-and-operational-risk) for the action-cost table and failure rules.


### Hidden optional objectives

Some optional objectives are hidden until a deterministic discovery trigger occurs. Reach the authored node with `move`, inspect the authored fictional evidence name with `inspect <filename>`, or perform the specified successful in-game action. Hidden descriptions and rewards are omitted from preparation, the initial briefing, and the Contract Board until discovery. Use `objectives` after discovery to see the objective and its current state. Hidden objectives never block extraction; completing all authored optional objectives, including hidden ones, is still required for the extra Reputation point.
