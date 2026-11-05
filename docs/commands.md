# Command Reference

Commands are entered at the game prompt. Command names are lowercase. Arguments are separated from the command by spaces.

## General commands

| Command | Arguments | Description |
| --- | --- | --- |
| `help` | None | Print the command list and mission flow |
| `status` | None | Show handle, balance, reputation, level, XP, decryptor ownership, active contract, and detection level/band |
| `missions` | None | List contracts, difficulty labels, and availability |
| `briefing` | None | Show target, difficulty, clues, and objective checklist for the active contract |
| `objectives` | None | Show completion status for every objective in the active contract |
| `map` | None | Show the active mission graph, operation locations, and current node |
| `history` | None | List completed contracts |
| `inventory` | None | Show owned tools |
| `shop` | None | List purchasable tools |
| `save` | None | Save progress to `saves/player.sav` |
| `clear` | None | Clear the terminal using an ANSI escape sequence |
| `exit` | None | Leave the game |

## Mission commands

| Command | Arguments | Prerequisites | Effect |
| --- | --- | --- | --- |
| `accept <id>` | Contract ID | No other active contract; contract is not completed; required level reached | Makes the selected contract active and resets temporary mission-stage flags |
| `move <node-id>` | Adjacent node ID | Active contract with topology; destination must be directly linked to current node | Moves one edge and adds 5 detection on every successful traversal |
| `scan <target>` | Exact target hostname | Active contract; at the mission scan node when topology is present | Marks the active target as scanned |
| `connect <target>` | Exact target hostname | Active contract has been scanned; at its authentication node when topology is present | Establishes the simulated session |
| `disconnect` | None | None | Closes the simulated session |
| `brute <password>` | Password answer | Active contract, connected session, and authentication node | Grants simulated authentication when the answer matches |
| `decrypt <key>` | Decryption answer | Active contract, authentication granted, decryptor owned, and decryption node | Marks the mission file as decrypted when the key matches |
| `analyze <filename>` | Exact encrypted filename | Active contract, successful decryption, and analysis node | Completes the optional metadata objective and earns its bonus at contract completion |
| `extract <filename>` | Exact encrypted filename | Active contract, successful decryption, and extraction node | Completes the extraction objective; awards the contract only when all its objectives are complete |

Mission difficulty is currently descriptive metadata. Mission objectives are defined per contract and their completion is tracked during the active session. Optional objectives do not block contract completion; their configured cash bonuses are added only when completed. The game does not perform real scanning, authentication, password attacks, decryption, or file extraction. These commands only advance the fictional mission state. Successful scan/authentication/decryption/analysis/extraction actions add detection exposure once; incorrect password and decryption-key attempts also add exposure. Connect, disconnect, invalid commands, and rejected prerequisites add none. At 100 detection, the contract fails and a $50 penalty (up to the available balance) is applied. The contract can be accepted again.

## Economy commands

| Command | Arguments | Description |
| --- | --- | --- |
| `buy <item>` | Item name | Purchase an item if it exists, is not already owned, and the player can afford it |

Currently, the only item is `decryptor`, priced at $150.

## Typical command sequence

For the first contract:

```text
missions
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

For missions with a topology, each successful `move` adds 5 detection, including backtracking. Invalid or non-adjacent moves add none. Missions without topology retain the previous command behavior.\n\nThe parser tokenizes input on spaces and reads only the first argument token. Therefore:

- Commands and arguments are case-sensitive.
- Arguments cannot contain spaces.
- Quoted multi-word arguments are not supported.
- Extra tokens after the first argument are ignored.
- The command loop reads one line at a time into a 512-byte input buffer.

If a command appears not to match, check its spelling, capitalization, argument, and the active mission stage.


## Detection risk values

Detection is temporary per-contract state, ranges from 0 to 100, and is displayed by `status`. Bands are Quiet (0–24), Noticed (25–49), Traced (50–74), Critical (75–99), and Compromised (100). See the [Gameplay Guide](gameplay.md#detection-and-operational-risk) for the action-cost table and failure rules.
