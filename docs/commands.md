# Command Reference

Commands are entered at the game prompt. Command names are lowercase. Arguments are separated from the command by spaces.

## General commands

| Command | Arguments | Description |
| --- | --- | --- |
| `help` | None | Print the command list and mission flow |
| `status` | None | Show player profile, decryptor ownership, active utility, active contract, and detection level/band |
| `missions` | None | List contracts, difficulty labels, and level/Reputation requirements |
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

## Mission commands

| Command | Arguments | Prerequisites | Effect |
| --- | --- | --- | --- |
| `prepare <id>` | Contract ID | No active or already prepared contract; both required level and Reputation are met and the contract is incomplete | Opens a pre-mission intelligence briefing without launching the contract |
| `loadout <utility|none>` | Owned utility or `none` | Contract is being prepared; selected utility must be owned | Selects the utility for this run without changing persistent equipment |
| `accept <id>` | Prepared contract ID | Matching contract is prepared; no active contract | Launches the prepared contract and snapshots its selected utility and upgrade level |
| `cancel` | None | Contract is being prepared | Cancels preparation for free; cannot abandon an active contract |
| `move <node-id>` | Adjacent node ID | Active contract with topology; destination must be directly linked to current node | Moves one edge and adds 5 detection on every successful traversal |
| `scan <target>` | Exact target hostname | Active contract; at the mission scan node when topology is present | Marks the active target as scanned |
| `connect <target>` | Exact target hostname | Active contract has been scanned; at its authentication node when topology is present | Establishes the simulated session |
| `disconnect` | None | None | Closes the simulated session |
| `brute <password>` | Password answer | Active contract, connected session, and authentication node | Grants simulated authentication when the answer matches |
| `decrypt <key>` | Decryption answer | Active contract, authentication granted, decryptor owned, and decryption node | Marks the mission file as decrypted when the key matches |
| `analyze <filename>` | Exact encrypted filename | Active contract, successful decryption, and analysis node | Completes the optional metadata objective and earns its bonus at contract completion |
| `extract <filename>` | Exact encrypted filename | Active contract, successful decryption, and extraction node | Completes the extraction objective; awards the contract only when all its objectives are complete |

Preparation shows known contract intelligence, target, difficulty, rewards, objective outline, and topology overview. Puzzle clues and answers remain undiscovered until the contract is launched. Preparation is temporary and is not saved.

Mission difficulty is currently descriptive metadata. Mission objectives are defined per contract and their completion is tracked during the active session. Optional objectives do not block contract completion; their configured cash bonuses are added only when completed. The game does not perform real scanning, authentication, password attacks, decryption, or file extraction. These commands only advance the fictional mission state. Successful topology movement adds 5 Detection per traversal, including revisits, unless equipped Silent Boots reduce the cost to 4/3/2. An incorrect password adds 15 Detection unless equipped Signal Scrubber reduces the cost to 12/9/6. Successful scan/authentication/decryption/analysis/extraction actions add detection exposure once; incorrect decryption-key attempts also add exposure. Connect, disconnect, invalid commands, and rejected prerequisites add none. At 100 detection, the contract fails and a $50 penalty (up to the available balance) is applied. The contract can be accepted again.

## Contact offer commands

| Command | Arguments | Prerequisites | Effect |
| --- | --- | --- | --- |
| `deal intel-<mission-id>` | e.g. intel-job-02 | Information Broker unlocked at Reputation 1; target contract is unlocked and incomplete; at least $50 | Charges $50 and reveals that contract's password and decryption clues, not the answers |
| `deal scrub-detection` | Fixed offer ID | Fixer unlocked at Reputation 3; active contract; Detection above zero; service unused this contract; enough funds | Reduces Detection by up to 10; costs $100 at Reputation 3–4 or $75 at Reputation 5+ |
| `deal ghost-signal` | Fixed offer ID | Fixer unlocked; no active/prepared contract; level 3 and Reputation 3; job-04 incomplete. The offer is hidden while another contract is active or prepared. | Opens preparation for the exclusive Ghost Signal contract without a fee; direct prepare is rejected |

Contact unlocks are derived from Reputation and are not separately saved. The Fixer service can be used once per active contract; its usage flag is temporary and resets when the contract starts or ends. Broker intelligence purchases are repeatable transactions and deduct $50 each time.

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
