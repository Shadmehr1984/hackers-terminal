# Command Reference

Commands are entered at the game prompt. Command names are lowercase. Arguments are separated from the command by spaces.

## General commands

| Command | Arguments | Description |
| --- | --- | --- |
| `help` | None | Print the command list and mission flow |
| `status` | None | Show handle, balance, reputation, level, XP, decryptor ownership, and active contract |
| `missions` | None | List contracts and their availability |
| `briefing` | None | Show clues for the active contract |
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
| `scan <target>` | Exact target hostname | An active contract | Marks the active target as scanned |
| `connect <target>` | Exact target hostname | Active contract has been scanned | Establishes the simulated session |
| `disconnect` | None | None | Closes the simulated session |
| `brute <password>` | Password answer | Active contract and connected session | Grants simulated authentication when the answer matches |
| `decrypt <key>` | Decryption answer | Active contract, authentication granted, decryptor owned | Marks the mission file as decrypted when the key matches |
| `extract <filename>` | Exact encrypted filename | Active contract and successful decryption | Completes the contract and awards rewards |

The game does not perform real scanning, authentication, password attacks, decryption, or file extraction. These commands only advance the fictional mission state.

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
scan vault-01.local
connect vault-01.local
brute orion42
buy decryptor
decrypt midnight
extract ledger.enc
status
save
```

The password and decryption key above are the first contract's puzzle answers. Other contracts have different clues and answers; consult the briefing for the active contract.

## Input behavior and limitations

The parser tokenizes input on spaces and reads only the first argument token. Therefore:

- Commands and arguments are case-sensitive.
- Arguments cannot contain spaces.
- Quoted multi-word arguments are not supported.
- Extra tokens after the first argument are ignored.
- The command loop reads one line at a time into a 512-byte input buffer.

If a command appears not to match, check its spelling, capitalization, argument, and the active mission stage.
