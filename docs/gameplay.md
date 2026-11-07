# Gameplay Guide

## Core loop

Hacker's Terminal is built around a repeatable contract loop:

```text
missions
   |
prepare <id>
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

## Mission preparation

Use `prepare <id>` to inspect an available, unlocked contract before committing to it. Preparation displays the target, difficulty, base rewards, objective outline, known topology nodes and links, decryptor ownership, and a concise Detection risk overview. Password clues, decryption clues, puzzle answers, and other undiscovered mission details remain hidden until launch.

The selected utility defaults to the currently equipped utility if it is owned. Use `loadout silent-boots`, `loadout signal-scrubber`, or `loadout none` to choose a run-specific utility. A utility must already be owned. This selection does not change the player's persistent equipment slot; its current upgrade level is snapshotted when the contract launches.

Use `modifier` to list the modifiers allowed by this contract, including their exact effects and completion bonuses. Choose at most one with `modifier <id>`, or clear it with `modifier none`. All three current modifiers are allowed on all five built-in contracts. A selection is displayed again in the preparation summary and copied into the active session when you accept.

Use `accept <id>` to launch only the contract currently being prepared. The ID must match. Use `cancel` to leave preparation without cost and then prepare another contract. Only one preparation or active contract can exist at a time.

After launch, the run's utility, upgrade level, and selected mission modifier are fixed for that contract. Buying, equipping, or upgrading items later does not change its Detection effects. Active contracts cannot be abandoned or manually restarted. If Detection reaches 100, the existing failure penalty applies and the failed contract can be prepared and launched again.

Preparation and its selected loadout are runtime-only and are not written to Save V3. Restoring a saved active contract starts a fresh accepted session and snapshots the player's currently equipped utility.

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

The decryptor costs $150. It is a persistent tool: once purchased, it remains owned in subsequent sessions when the save is loaded. Utility equipment is separate from the decryptor and uses one mutually exclusive active slot.

## Contract Board

Use `board` to open the full catalog overview. It displays each contract's category, difficulty, base-to-maximum cash reward (including all authored optional-objective bonuses), XP, and derived availability. States are `AVAILABLE`, `LOCKED`, `COMPLETED`, `EXCLUSIVE`, `UNAVAILABLE`, and `FACTION LOCKED`. Lock reasons show the exact unmet level and/or Reputation requirement. Exclusive contracts must be accepted through their Contact offer. If a contract is active or being prepared, other incomplete entries are shown as unavailable; completed entries retain their completed status. The original `missions` command remains unchanged as a compact list. Board availability is calculated from current game state and is not persisted. The Board never reveals puzzle clues or answers.

## Factions

The world contains seven fictional organizations: Nexus Dynamics, Ghost Protocol, Black Veil, Aegis Initiative, Iron Meridian, Null Syndicate, and Helix Consortium. Use factions to list them and faction <id> to inspect a dossier, security profile, economic behavior, specialty, and relationships with other groups.

Every built-in contract has a client faction and a target-owner faction. The Contract Board shows these affiliations, the client's security rating, and your current standing. Faction-to-faction relationships are static Catalog data; pairs not explicitly listed are Neutral.

Your standing with a faction is derived, not separately saved. Start with global Reputation, add 2 for each completed contract commissioned by that faction, and subtract 2 for each completed contract whose target owner or opposing faction is that faction. The resulting score maps to Hostile (at or below -2), Wary (-1), Neutral (0–2), Trusted (3–5), or Allied (6+). Replaying a completed contract does not add another outcome because the existing completion flag is used.

A contract is faction-locked when its client faction is Hostile toward you. The Contract Board displays FACTION LOCKED, and preparation, Broker intelligence listing/purchases, exclusive Contact access, and operation start reject access. Completing contracts for that client faction can improve standing again. Existing Reputation gains, Contact unlock thresholds, rewards, Detection costs, and prices are unchanged. Faction standing uses existing persisted Reputation and contract-completion flags; Save V3 and older formats are unchanged.

Faction security ratings/styles are authored intelligence to help compare contract profiles. They do not independently change Detection costs or rewards in this feature.

## Contracts

The game currently defines five contracts in `src/catalog/mission_data.zig`. The fourth contract, Ghost Signal, is an exclusive Fixer offer; the fifth, Corporate Ghost, is a standard contract commissioned by Nexus Dynamics against a Null Syndicate-owned target.

| ID | Contract | Category | Difficulty | Fictional target | Required level | Required Reputation | Cash reward | XP reward |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `job-01` | Cold Storage | Data Recovery | Easy | `vault-01.local` | 1 | 0 | $300 | 100 |
| `job-02` | Paper Trail | Intelligence | Medium | `archive-02.local` | 2 | 0 | $500 | 150 |
| `job-03` | Quiet Exit | Extraction | Hard | `relay-03.local` | 3 | 0 | $800 | 200 |
| `job-04` | Ghost Signal | Infiltration | Hard | `signal-04.local` | 3 | 3 | $1,100 | 250 |
| `job-05` | Corporate Ghost | Infiltration | Hard | `relay-05.local` | 2 | 2 | $1,200 | 275 |

A contract is available only when the player's level and Reputation meet its requirements, its client faction is not Hostile, and it has not already been completed. The first four contracts retain their existing progression rules. Ghost Signal additionally requires Reputation 3 and its Fixer offer; Corporate Ghost requires level 2 and Reputation 2 and is faction-locked while Nexus Dynamics is Hostile. Only one active contract is allowed at a time.

Difficulty is currently a descriptive rating shown by `missions` and `briefing`. It does not change mission mechanics or detection risk.

### Mission objectives

Every contract defines an ordered checklist of required and optional objectives. `briefing` displays the checklist, and `objectives` shows its current completion state at any point during the active contract. The current objective types are:

1. **Survey target** — completed by a successful `scan <target>`.
2. **Authenticate** — completed by solving the password challenge with `brute <password>`.
3. **Decrypt evidence** — completed by a successful `decrypt <key>` after purchasing the decryptor.
4. **Recover evidence** — completed by extracting the exact filename with `extract <filename>`.
5. **Optional: analyze metadata** — after decryption, run `analyze <filename>` to inspect simulated metadata. This objective is not required to finish the contract and grants bonus cash: $75 for Cold Storage, $100 for Paper Trail, $125 for Quiet Exit, $175 for Ghost Signal, and $200 for Corporate Ghost. Corporate Ghost also has a required metadata-verification objective and a hidden, zero-cash mirror-fragment objective discovered at `mirror-node`.

The descriptions differ between contracts even though the current core objective types are shared. A contract is awarded after every required objective is complete. Optional objectives do not block completion; completed ones add their bonus cash to the contract payout. Completing every optional objective in a contract also grants one additional Reputation point. Completing only some optional objectives grants their cash bonuses but no Reputation bonus. Objective progress and detection exposure are temporary and reset when a contract starts or ends; neither is written to the save file.

### Fictional network navigation

Each contract has a purpose-built, entirely fictional network graph. Accepting a contract places the operator at its entry node. Use `map` to inspect nodes, links, current position, and the node assigned to each operation; use `move <node-id>` to traverse one adjacent link.

Every successful traversal normally adds **5 Detection**, including revisiting a previously used link. Equipped Silent Boots reduce this cost to 4 at level 0, 3 at level 1, or 2 at level 2. If `heightened-monitoring` is selected, add another 2 after that adjustment. If `security-sweep` is selected, add 8 after traversal numbers 3, 6, 9, and so on; invalid or non-adjacent movement does not increment the counter. Unknown and non-adjacent destinations are rejected without changing location or Detection. Movement can therefore make a route choice safer or riskier, and reaching 100 still invokes the HT-001 failure and penalty rules.

| Contract | Graph layout | Operation locations |
| --- | --- | --- |
| Cold Storage | Compact perimeter; a short exposed service corridor and a longer maintenance/utility detour both lead to the vault | Scan and authentication: `service`; decrypt, analyze, extract: `vault` |
| Paper Trail | Indexing hub with separate mail-processing and records-access branches | Scan: `index`; authentication: `mail-gw`; decrypt/extract: `mail-store`; optional analysis: `records` |
| Quiet Exit | Relay chain with a decoy branch and a controlled exit route | Scan: `relay-a`; authentication: `relay-core`; decrypt/analyze: `transfer`; extract: `exit` |
| Ghost Signal | Abandoned relay with an optional mirrored-traffic branch | Scan: `uplink`; authentication: `handshake`; decrypt/analyze: `cache`; extract: `beacon` |
| Corporate Ghost | Hardened gateway leading to an audit archive and encrypted vault, with a hidden traffic-mirror branch that rejoins before extraction | Scan: `gateway`; authentication: `auth-core`; analyze: `audit-hub`; decrypt: `data-vault`; extract: `exit-relay` |

The relevant commands must be issued at their assigned nodes. For example, scanning Cold Storage from `entry` is rejected; first move to `service`. All topology and position data are local static game content. Current location and successful traversal count are session-only and are not written to any save version.

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
| Every successful topology traversal (including revisits) | +5 normally; equipped Silent Boots: +4/+3/+2 |
| Successful authentication (first time only) | +5 |
| Incorrect password attempt | +15 normally; equipped Signal Scrubber: +12/+9/+6 |
| Successful decryption (first time only) | +10 |
| Incorrect decryption key | +10 normally; +15 with `hardened-encryption` |
| Successful optional metadata analysis (first time only) | +5 |
| Successful extraction (first time only) | +5 |
| Connect, disconnect, invalid commands, or rejected prerequisites | +0 |

Repeated successful actions do not add exposure again. A modifier is applied only to its named event: `heightened-monitoring` and `security-sweep` affect successful topology traversals, while `hardened-encryption` affects only incorrect decryption keys. Once authentication or decryption succeeds, further attempts at that completed stage are acknowledged without evaluating the supplied password/key or adding Detection. Crossing a band boundary prints a warning. At 100, the active contract immediately fails: no contract reward, XP, or reputation is granted, and a $50 penalty is deducted. The penalty is capped at the player's available balance, so the balance never becomes negative. The failed contract remains available to accept again. Detection resets when a contract starts, completes, or fails.

Detection is session-only and is deliberately excluded from all save versions. Restoring an active contract after restarting begins with 0 detection, just as other temporary mission progress is reset.

## Contract clues

Use `briefing` after accepting a contract. The briefing displays the target, difficulty, password clue, encrypted filename, and decryption clue.

| Contract | Password clue | Decryption clue | File to extract |
| --- | --- | --- | --- |
| Cold Storage | A hunter constellation, followed by 42 | The middle of the night | `ledger.enc` |
| Paper Trail | A reddish metal, followed by 17 | A small songbird often associated with a clear blue color | `mailbox.enc` |
| Quiet Exit | A fixed point used for navigation in the northern sky | The time after normal business hours | `manifest.enc` |
| Ghost Signal | A transparent shelter used to grow delicate plants | A sudden, brief fall of rain | `ghost-signal.enc` |
| Corporate Ghost | A secure room where valuable records are kept | A record that tracks who entered and when | `access-ledger.enc` |

<details>
<summary>Puzzle solutions (spoilers)</summary>

| Contract | Password | Decryption key |
| --- | --- | --- |
| Cold Storage | `orion42` | `midnight` |
| Paper Trail | `copper17` | `bluebird` |
| Quiet Exit | `northstar` | `afterhours` |
| Ghost Signal | `glasshouse` | `cloudburst` |
| Corporate Ghost | `vaultkeeper` | `auditlog` |

</details>

## Completing the first contract

The first contract is a guided introduction to the complete game loop.

1. Run `missions`, then `prepare job-01` and `accept job-01`.
2. Run `briefing` to read the clues and objective checklist.
3. Run `map`, move from `entry` to `service` with `move service`, then run `scan vault-01.local` and `objectives` to see the first objective completed.
4. Run `connect vault-01.local`.
5. Solve the clue with `brute orion42`.
6. Buy the file decryptor with `buy decryptor`. It costs $150.
7. Move through `corridor` to `vault` (or take the longer maintenance route), then buy the decryptor and solve the clue with `decrypt midnight`.
8. Optionally run `analyze ledger.enc` at `vault` to complete the metadata objective and earn an extra $75.
9. Run `objectives` to review the checklist, then retrieve the file with `extract ledger.enc` at `vault`.
10. Run `status` to see the updated balance, XP, reputation, level, and current detection level.
11. Run `save` to persist your progress.

The initial $250 is enough to buy the decryptor. Completing the first contract grants $300 and 100 XP.

## Progression and leveling

A successful modified contract also grants its separate +25 XP bonus, in addition to the modifier's +$50 cash bonus.

The player begins at level 1. The XP threshold for level 2 is 100 XP; the threshold for level 3 is 250 total XP. Each level after level 2 requires another 150 XP.

The threshold for reaching level `L` (where `L >= 2`) is:

```text
100 + (L - 2) * 150
```

Completing a contract adds its configured XP reward. The game announces a level-up when the player's level increases. Since the second contract requires level 2 and awards 150 XP, completing the first contract unlocks it. Completing the second contract brings the player to 250 XP and level 3, unlocking Quiet Exit. Completing Quiet Exit without its optional-objective Reputation bonus raises Reputation from 2 to 3 while leaving both Nexus-owned completion flags unchanged; Nexus standing moves from Hostile to Wary, unlocking Corporate Ghost if its level and Reputation requirements are met. Ghost Signal remains an additional exclusive contract and requires Reputation 3.

Each completed contract grants 1 Reputation. If every optional objective in that contract was also completed, the player gains 1 additional Reputation (2 total). Optional-objective cash bonuses are accumulated with checked u32 arithmetic; if the total overflows, completion is rejected before player progression or the payout guard is committed. The Contract Board uses the same checked arithmetic for its visible maximum-reward estimate and propagates an overflow instead of displaying a wrapped value.

### Reputation tiers

Reputation is a persistent numeric progression value. Its player-facing tier is calculated from that value:

| Reputation | Tier | Meaning |
| ---: | --- | --- |
| 0 | Unknown | No established reputation |
| 1–2 | Recognized | Known within the fictional network |
| 3–4 | Trusted | Considered a reliable operator |
| 5+ | Elite | A highly regarded operator |

Failed or compromised contracts do not reduce Reputation and grant no Reputation.

### Contacts and offers

Use `contacts` to see both characters and their unlock status, `contact broker` or `contact fixer` for details, and `offers` to list actionable offers. Unlocks are derived from the current Reputation; they are not separately stored.

- **Information Broker** unlocks at Reputation 1. The Broker sells contract-specific password and decryption clues for $50 using `deal intel-<mission-id>`. Offers appear only for unlocked, incomplete contracts. The purchase reveals clues, never the actual password or decryption key. Each purchase is a separate transaction.
- **Fixer** unlocks at Reputation 3. The Fixer offers `deal scrub-detection` during an active contract. It reduces Detection by up to 10, can be used once per contract, and costs $100 at Trusted (Reputation 3–4) or $75 at Elite (Reputation 5+). It cannot raise Detection or be used when Detection is already zero.
- The Fixer also offers `deal ghost-signal`, which opens preparation for `job-04` when the player meets both level 3 and Reputation 3 requirements, has no active/prepared contract or active Operation, and has non-Hostile standing with the contract's client faction. The offer is hidden while any of these conditions are unmet. Direct `prepare job-04` is rejected; the contract must be opened through the Fixer offer. The offer has no fee. Corporate Ghost (`job-05`) is a separate standard contract and can be prepared directly when Nexus standing is not Hostile.

The Fixer service-use flag is runtime-only and resets when a contract starts or ends. Reputation, tiers, and Contact unlocks use the existing persisted Reputation value, so Save V3 remains unchanged.

## Economy and inventory

The shop contains the required decryptor and two optional utilities:

| Item | Purchase | Upgrade 1 | Upgrade 2 | Effect |
| --- | ---: | ---: | ---: | --- |
| `decryptor` | $150 | — | — | Required to decrypt mission files |
| `silent-boots` | $100 | $150 | $250 | Movement Detection: 4 / 3 / 2 |
| `signal-scrubber` | $100 | $150 | $250 | Incorrect-password Detection: 12 / 9 / 6 |

Each utility starts at level 0. Both can be owned, but only one can occupy the active utility slot. Equipping another owned utility switches the effect without losing ownership or upgrades. The decryptor is separate and does not occupy this slot. Only the equipped matching utility modifies Detection; otherwise the base costs remain 5 per traversal and 15 per incorrect password.

Use `shop` to inspect equipment and upgrade prices, `buy <item>` to purchase, `equip <utility>` to activate an owned utility, `upgrade <utility>` to purchase its next tier, and `inventory` to inspect ownership and levels. Duplicate purchases, unowned equip/upgrade attempts, maximum-level upgrades, and unaffordable transactions are rejected without charging the player.

## Multi-stage operations

Operations combine existing contracts into a deterministic linear sequence without changing their underlying puzzles or objective rules. The first operation, `blackout-protocol`, contains:

1. `job-01` — Cold Storage
2. `job-02` — Paper Trail
3. `job-03` — Quiet Exit

Use `operations` to list the catalog, `operation blackout-protocol` to inspect its stages and requirements, and `operation-start blackout-protocol` to prepare the first stage. Accept each prepared stage with the existing `accept <mission-id>` command. Successful extraction prepares the next stage automatically, but the player must explicitly accept it. `operation-status` shows the current stage and facts already earned.

An operation validates the level, Reputation, and non-Hostile client-faction standing requirements of every stage before it starts. The Operation list and stage details show faction standing and FACTION LOCKED status using the same derived rule. Once started, the operation is preauthorized: later standing changes do not interrupt it, and the active Operation views explicitly label that preauthorization. A completed contract can be replayed inside an operation, while standalone `prepare` still rejects completed contracts. While an operation is active, `prepare` and `cancel` cannot replace or abandon its current stage. Detection compromise resets the current stage and prepares it for retry; successful earlier-stage facts are retained, while partial progress from the failed stage is discarded.

### Carry-over facts

Completing the hidden optional objective `maintenance-telemetry` in Cold Storage grants the typed `maintenance_telemetry` fact. When Paper Trail is accepted, that fact reveals its hidden optional `routing-header` objective. Completing `routing-header` grants `routing_header`, which reveals the hidden optional `relay-trace` objective when Quiet Exit is accepted. The normal in-game completion event is still required for each revealed objective. If a source objective is not completed, no fact is granted and the later objective retains its normal HT-008 discovery trigger. Facts are granted only after successful stage completion.

### Rewards and persistence

Each stage uses its existing contract reward rules. There is no operation-specific completion bonus. A stage whose contract was already completed before the operation run can be replayed, but pays no contract cash, XP, optional-objective cash, Reputation, or modifier bonus. Incomplete contracts pay their normal rewards on their first successful completion in the operation.

Operation ID, stage index, facts, reward eligibility, and the completion display marker are runtime-only. Saving during an operation preserves player progress and existing contract completion flags but writes `-1` for the active mission index. After restart, the operation begins again at stage one and facts are cleared; previously completed stage contracts remain replayable without rewards. Save V3 and all older readers are unchanged.

## Saving and resuming

The game automatically attempts to load `saves/player.sav` at startup. Use `save` to write the current player and contract progress.

The active contract can be restored, but preparation, the run-specific loadout, and temporary session stages are not saved. After restarting, repeat the scan and connection stages and solve the challenges again as needed. See [Save Format](save-format.md) for the exact fields and compatibility behavior.


## Hidden optional objectives

Some contracts contain optional objectives that are not listed during preparation or in the initial briefing. They are revealed only by their authored fictional discovery condition: reaching a particular topology node, inspecting a named evidence file with `inspect <filename>`, or completing a specified in-game action. Discovery is deterministic and idempotent. The `objectives` command shows only objectives already discovered in the current run.

Hidden objectives never block contract completion. Once discovered, they are completed by the same authored gameplay event kind as other objectives. Any authored hidden cash reward is paid only on successful contract completion and only when the objective was completed. The current built-in hidden objectives carry a zero cash reward, preserving existing contract payout values until reward amounts are explicitly approved; completing all optional objectives can still earn the existing Reputation bonus. An optional objective whose discovery trigger or completion event has irreversibly passed becomes unavailable; this includes hidden objectives that were never discovered and discovered optional objectives that were not completed before the contract ends. Unavailable objectives grant no cash and prevent the all-optional Reputation bonus. As before, the additional Reputation is granted only when every authored optional objective, visible or hidden, is completed.

Objective identity is a stable mission-local ID, separate from its event kind. This allows multiple objectives to react independently to the same event. A run tracks at most 32 objectives using fixed-capacity runtime state. Objective discovery and progress reset on a fresh run, retry, compromise, or session reset and are not saved. Save V3 and older save readers are unchanged.


## Rival hackers (HT-011)

Five fictional competitors contest optional intelligence in the existing contract catalog:

| Rival | Faction | Contract | Contested optional evidence |
|---|---|---|---|
| Ghost Operator | Ghost Protocol | job-03 | `relay-trace` |
| Null Byte | Null Syndicate | job-04 | `mirror-fragment` |
| Glasswire | Black Veil | job-02 | `routing-header` |
| Patchwork | Iron Meridian | job-01 | `maintenance-telemetry` |
| Redshift | Helix Consortium | job-05 | `mirror-fragment` |

The rival is disclosed on the Contract Board and in Preparation/Briefing, including the relevant counterplay hint. The contest resolves deterministically after successful decryption: if the linked hidden objective is still undiscovered, it becomes unavailable for that run and the rival is marked RIVAL_AHEAD. If the player discovered it first, the rival is OUTPACED. DORMANT means the associated contract is still progression/faction locked; CONTESTING means the opportunity remains unresolved.

Counterplay uses the existing discovery trigger: reach the maintenance or mirror node, inspect the routing-header file, or perform the scan that reveals the relay trace before decrypting. The rival can affect only that hidden optional objective. Required objectives, extraction, primary contract availability, Detection, cash, XP, direct Reputation mutation, faction standing, and base rewards are unchanged. The existing rule requiring every optional objective for the +1 Reputation bonus remains unchanged; if the rival claims its optional objective, the player may forfeit that bonus for the run. Rival profiles are static and rival contest state is runtime-only; no Save V3 change is made.
