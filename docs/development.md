# Development Guide

## Toolchain

The project and primary CI target exactly Zig 0.17.1. The process entry point uses `std.process.Init`/`std.Io`, persistence uses `std.Io.Dir`, and the legacy `std.io`/`std.fs` application paths have been removed. Do not downgrade the toolchain or reintroduce pre-0.17 APIs.

## Build, run, formatting, and tests

```sh
zig build
zig build run
zig fmt --check test_root.zig build.zig src tests
zig build test
# Direct equivalent: zig test test_root.zig
```

Primary CI runs formatting, build, terminal-entry smoke test with argument passthrough, the complete aggregate test suite, and agent-doc validation on pushes and pull requests targeting `main` in Debug, ReleaseSafe, and ReleaseFast with Zig 0.17.1. The separate `Zig 0.17.1 Migration Validation` workflow retains focused save, modifier, facade, build, and aggregate-test checks.

## Transactional command output

State-changing command handlers stage affected Player, MissionSession, MissionPreparation, active-contract, mission-completion, and OperationState values in local copies. They commit those values only after all output belonging to the transition succeeds. This protects the game from half-applied transitions when an injected or future Writer returns an error.

The regression suite injects both formatted-print and raw-write failures into critical command paths. Keep these tests aligned with any new state-changing command, especially when a command combines Detection, objective progress, rewards, or Operation stage transitions.

## Automated unit tests

Automated unit tests live in the top-level `tests/` directory, separate from production source files:

- `tests/commands_test.zig` covers command parsing.
- `tests/mission_state_test.zig` covers mission-session state transitions.
- `tests/mission_data_test.zig` covers built-in mission difficulty assignments, player-facing labels, mission-specific topology definitions, and Corporate Ghost's catalog metadata.
- `tests/corporate_ghost_test.zig` covers the Nexus Hostile lock, the Quiet Exit Reputation recovery route, and a complete Corporate Ghost run including hidden-objective discovery and rewards.
- `tests/topology_test.zig` covers graph lookup, bidirectional adjacency, graph validation, and both allocation-failure points in reachability traversal.
- `tests/equipment_test.zig` covers utility ownership, purchases, equipping, upgrade tiers, shared Detection-cost profiles, V3/V2/V1/legacy save migration, truncated/malformed save input, and purchase rollback when output fails.
- `tests/mission_objectives_test.zig` covers required and optional objective definitions, completion tracking, checked optional-reward accumulation (including overflow), and session reset behavior.
- `tests/game_detection_test.zig` covers action risk costs, safe actions, compromise failure, bounded penalties, retry behavior, extraction failure before payout, legal movement, location-gated operations, modifier Detection costs, sweep cadence, and modifier failure boundaries. It also verifies that movement, Detection compromise, scan, authentication, decryption, analysis, contract launch, and Extraction/payout state are not committed when their output writer fails.
- `tests/mission_preparation_test.zig` covers intel secrecy, contract availability, loadout ownership, modifier command/eligibility, launch snapshots, cancellation, and one-time modifier rewards.
- `tests/mission_modifier_test.zig` covers typed modifier IDs, exact metadata, Detection effect definitions, and the completion bonus.
- `tests/progression_test.zig` covers cumulative XP thresholds, player levels, modifier completion bonus, duplicate-payout protection, atomic rejection when optional-reward accumulation overflows, and preservation of objective state on payout overflow or output failure.
- `tests/contacts_test.zig` covers Reputation tier thresholds, Contact unlocks, optional-objective Reputation bonuses, paid intelligence (including rollback on output failure), Fixer service pricing/usage, and the Ghost Signal offer.
- `tests/terminal_test.zig` covers faction-aware Operation list/details/status output, active-operation preauthorization messaging, and safe Contract Board reward-overflow reporting.
- `tests/operation_test.zig` covers Operation catalog/state transitions, stage progression and retry, unchanged V3 save behavior, preauthorization, and preservation of outgoing facts when the transition-output writer fails.
- `tests/rival_test.zig` covers the five-rival catalog, deterministic status transitions, rival commands/dossiers, and all five authored Node/File/Action discovery-trigger contests in both player-first and rival-first outcomes.
- `tests/contract_board_test.zig` covers visible reward ceilings and checked overflow rejection.
- `tests/terminal_input_test.zig` covers the 511/512-byte command-input boundary and is included in the aggregate suite.
- `tests/terminal_io_test.zig` covers `std.Io` line reading, oversized-line draining, next-command alignment, read/write failure propagation, and process stream adapter construction. It is registered in `tests/test_all.zig`.
- `tests/save_io_test.zig` covers exact V3 bytes, persistence round-trip, missing-save status, the 4096/4097-byte read boundary, and staging-failure preservation. It is registered in `tests/test_all.zig`; `save_io_test_root.zig` remains available for focused diagnostic runs.
- `tests/test_all.zig` is the aggregate test list and imports all unit/integration test modules, including terminal I/O, save I/O, and facade API tests.
- `test_root.zig` is the repository-root module used to run the aggregate suite while keeping all test files under `tests/`.

Run the complete aggregate unit-test suite with:

```sh
zig test test_root.zig
```

Primary CI checks formatting in `test_root.zig`, `build.zig`, `src/`, and `tests/`, builds the game, smoke-tests `zig build run` with argument passthrough, and runs the complete root test module through `zig build test`. The aggregate includes terminal I/O and save I/O tests.

The focused save harness remains available for diagnostics with:

```sh
zig test save_io_test_root.zig
```

The root harness keeps the actual save tests in `tests/` while allowing their imports to resolve within the repository module path.

## Terminal and save error handling

The REPL discards an overlong input line (maximum 511 bytes) and continues instead of terminating. The Zig 0.17.1 adapter uses `std.Io.Reader.takeDelimiter` and drains through the newline; output uses immediate `std.Io.File.writeStreamingAll` calls so writer failures are not delayed by buffering. Save loading receives an explicit `std.Io` `SaveContext`, distinguishes a missing first-run save from an unreadable or malformed existing save; the latter cases are reported without automatically replacing the file. Detection compromise, Extraction objective progress, Broker purchases, and shop mutations stage their relevant state until required output succeeds.

## Architecture workflow

Keep modules focused and dependencies one-way. Production code is grouped under `src/domain/`, `src/application/`, `src/catalog/`, `src/presentation/`, and `src/persistence/`; `src/main.zig` remains the composition root and old top-level paths are compatibility facades. `main.zig` owns Zig 0.17.1 application setup and the shared input loop; `terminal_input.zig` owns the stable input-size policy; `terminal_io.zig` adapts Zig 0.17.1 process streams; `save.zig` owns the `std.Io` SaveContext and shared V3 serializer; `game.zig` owns the shared command dispatcher; `detection.zig` owns exposure and compromise rules; `progression.zig` owns XP, Reputation tiers, and reward calculations; `contacts.zig` owns Contact unlock and service-price rules. `mission_state.zig` owns temporary mission-session progress, objective completion, current node, and traversal count. `topology.zig` defines the static fictional graph model; `mission_data.zig` authors a separate graph for each built-in mission. Persistence, display, shop operations, and parsing remain in dedicated modules.

Pure utility Detection-cost profiles are defined once on `UtilityEquipment` in `player.zig`. `Equipment` applies the profile for the currently equipped utility, while `MissionLoadout` applies it to the utility/level snapshot captured at mission launch. Keep those adapters free of duplicate cost tables.

Preserve existing behavior unless a task explicitly requests a gameplay change. Update `docs/architecture.md` when module responsibilities or runtime state change. Update `docs/save-format.md` whenever serialized save layout changes. Temporary mission state is not persisted, so a loaded active mission starts at the accepted stage. Mission difficulty, objective definitions, and level/Reputation requirements are static metadata and are not serialized. Objective completion is temporary session state and is not currently persisted.

## Manual smoke test

1. Run `help` and `missions`; verify each contract shows its difficulty.
2. Run `prepare job-01`; inspect the modifier list, select `heightened-monitoring`, verify its exact +2 movement effect and +$50/+25 XP completion bonus, then run `modifier none` and `accept job-01`. Verify the briefing shows Easy, four required objectives, and one optional objective.
3. Run `status` and verify the selected modifier is shown for the active run. Run `map`; verify the mission-specific nodes, links, operation locations, and current entry node are shown. Try an invalid/non-adjacent `move` and verify neither location nor Detection changes.
4. Run `move service`; verify Detection increases by 5. Run `objectives`; verify all five objectives are initially unchecked and the optional one displays its bonus.
5. Verify scanning is rejected away from the assigned node; scan the target at `service` and confirm the survey objective is checked.
6. Connect and authenticate at the assigned authentication node using the mission briefing password; confirm the authentication objective is checked.
7. Disconnect and verify authentication remains complete. Move through `corridor` to `vault` and verify decryption is only accepted there.
8. Buy the decryptor, decrypt with the briefing key, and confirm the decryption objective is checked.
9. Optionally run `analyze ledger.enc` at `vault`; verify the optional objective is checked.
10. Extract `ledger.enc` at `vault`; verify the required objectives permit completion and the optional bonus is included only if analysis was completed.
11. Save and restart; persistent progress should be restored while temporary objective and location state starts at the contract entry node, with a traversal count of zero.
12. After earning Reputation 1, inspect `contacts`, `contact broker`, and `offers`; purchase `deal intel-job-02` only after meeting its level requirement and verify it reveals clues but not answers.
13. After earning Reputation 3 and reaching level 3, inspect `contact fixer`, use `deal ghost-signal` to prepare job-04, and verify the exclusive contract starts at its entry node.
14. Complete job-01 and job-02 without optional-objective Reputation bonuses; verify Corporate Ghost is FACTION LOCKED at Nexus Hostile. Complete job-03, then verify Nexus becomes Wary and `prepare job-05` succeeds. Follow the gateway → identity-control → `mirror-node` → vault route to discover the contested hidden objective before decryption; then visit `audit-hub` to analyze `access-ledger.enc` and extract it at `exit-relay`.
15. In an active contract with Detection above zero, verify `deal scrub-detection` reduces exposure once and cannot be repeated in that contract.

Back up `saves/player.sav` before testing save migration or clean-profile progression.


## AI agent workflow

Read the repository-root [AGENTS.md](../AGENTS.md) before making changes. The [agent workspace](../.agent/README.md) provides the required work cycle, module contracts, roadmap, known constraints, accepted architecture decisions, task brief template, and independent review checklist.

For substantial tasks, create a brief from [the task template](../.agent/tasks/TEMPLATE.md). Follow Explore → Understand → Plan → Implement → Verify → Document → Review → Commit. Reviewers should independently inspect the diff when a second agent is available; otherwise record that the review was a self-review.

Run the agent documentation structure check with:

```sh
sh scripts/check-agent-docs.sh
```

CI runs this check in addition to Zig formatting, compilation, and unit tests. It verifies required guidance files and key links/sections; it does not prove code correctness or replace the Zig checks.


### HT-011 smoke checks

1. Run `rivals` and confirm exactly five profiles and stable IDs are shown.
2. Run `rival patchwork` and inspect its faction, specialty, contested contract, and counterplay.
3. Run `board` and `prepare job-01`; confirm the rival warning appears before launch.
4. In Cold Storage, reach `maintenance` before decrypting and confirm the hidden optional objective is discoverable; after decryption, Patchwork must be OUTPACED.
5. After decryption but before extraction, run `board` and `briefing`; confirm the active rival status and outcome-specific message are reflected. In a fresh run, decrypt before visiting `maintenance`; confirm Patchwork becomes RIVAL_AHEAD and only the hidden optional objective is unavailable.
6. Verify the required objectives and primary contract remain completable and no Detection/reward/save behavior changes.
