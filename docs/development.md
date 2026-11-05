# Development Guide

## Toolchain

The project targets Zig 0.13.0. Use the same version locally and in CI.

## Build, run, formatting, and tests

```sh
zig build
zig build run
zig fmt --check test_root.zig build.zig src tests
zig build test
# Direct equivalent: zig test test_root.zig
```

CI runs formatting, build, and tests on pushes and pull requests targeting main.

## Automated unit tests

Automated unit tests live in the top-level `tests/` directory, separate from production source files:

- `tests/commands_test.zig` covers command parsing.
- `tests/mission_state_test.zig` covers mission-session state transitions.
- `tests/mission_data_test.zig` covers built-in mission difficulty assignments, player-facing labels, and mission-specific topology definitions.
- `tests/topology_test.zig` covers graph lookup, bidirectional adjacency, graph validation, and both allocation-failure points in reachability traversal.
- `tests/equipment_test.zig` covers utility ownership, purchases, equipping, upgrade tiers, shared Detection-cost profiles, V3/V2/V1/legacy save migration, and truncated/malformed save input.
- `tests/mission_objectives_test.zig` covers required and optional objective definitions, completion tracking, optional rewards, and session reset behavior.
- `tests/game_detection_test.zig` covers action risk costs, safe actions, compromise failure, bounded penalties, retry behavior, extraction failure before payout, legal movement, location-gated operations, modifier Detection costs, sweep cadence, and modifier failure boundaries.
- `tests/mission_preparation_test.zig` covers intel secrecy, contract availability, loadout ownership, modifier command/eligibility, launch snapshots, cancellation, and one-time modifier rewards.
- `tests/mission_modifier_test.zig` covers typed modifier IDs, exact metadata, Detection effect definitions, and the completion bonus.
- `tests/progression_test.zig` covers cumulative XP thresholds, player levels, modifier completion bonus, and duplicate-payout protection.
- `tests/contacts_test.zig` covers Reputation tier thresholds, Contact unlocks, optional-objective Reputation bonuses, paid intelligence, Fixer service pricing/usage, and the Ghost Signal offer.
- `tests/test_all.zig` is the aggregate test list that imports the test modules.
- `test_root.zig` is the repository-root module used to run the aggregate suite while keeping all test files under `tests/`.

Run the complete unit-test suite with:

```sh
zig test test_root.zig
```

The CI workflow checks formatting in `test_root.zig`, `build.zig`, `src/`, and `tests/`, then builds the game and runs the root test module through `zig build test`.

## Architecture workflow

Keep modules focused and dependencies one-way. Production code is grouped under `src/domain/`, `src/application/`, `src/catalog/`, `src/presentation/`, and `src/persistence/`; `src/main.zig` remains the composition root and old top-level paths are compatibility facades. `main.zig` owns application setup and the input loop; `game.zig` owns the shared command dispatcher; `detection.zig` owns exposure and compromise rules; `progression.zig` owns XP, Reputation tiers, and reward calculations; `contacts.zig` owns Contact unlock and service-price rules. `mission_state.zig` owns temporary mission-session progress, objective completion, current node, and traversal count. `topology.zig` defines the static fictional graph model; `mission_data.zig` authors a separate graph for each built-in mission. Persistence, display, shop operations, and parsing remain in dedicated modules.

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
13. After earning Reputation 3 and reaching level 3, inspect `contact fixer`, use `deal ghost-signal` to prepare job-04, and verify the appended contract starts at its entry node. In an active contract with Detection above zero, verify `deal scrub-detection` reduces exposure once and cannot be repeated in that contract.

Back up `saves/player.sav` before testing save migration or clean-profile progression.


## AI agent workflow

Read the repository-root [AGENTS.md](../AGENTS.md) before making changes. The [agent workspace](../.agent/README.md) provides the required work cycle, module contracts, roadmap, known constraints, accepted architecture decisions, task brief template, and independent review checklist.

For substantial tasks, create a brief from [the task template](../.agent/tasks/TEMPLATE.md). Follow Explore → Understand → Plan → Implement → Verify → Document → Review → Commit. Reviewers should independently inspect the diff when a second agent is available; otherwise record that the review was a self-review.

Run the agent documentation structure check with:

```sh
sh scripts/check-agent-docs.sh
```

CI runs this check in addition to Zig formatting, compilation, and unit tests. It verifies required guidance files and key links/sections; it does not prove code correctness or replace the Zig checks.
