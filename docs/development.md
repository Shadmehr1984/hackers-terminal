# Development Guide

## Toolchain

The project targets Zig 0.13.0. Use the same version locally and in CI.

## Build, run, formatting, and tests

```sh
zig build
zig build run
zig fmt --check test_root.zig build.zig src tests
zig test test_root.zig
```

CI runs formatting, build, and tests on pushes and pull requests targeting main.

## Automated unit tests

Automated unit tests live in the top-level `tests/` directory, separate from production source files:

- `tests/commands_test.zig` covers command parsing.
- `tests/mission_state_test.zig` covers mission-session state transitions.
- `tests/mission_data_test.zig` covers built-in mission difficulty assignments, player-facing labels, and mission-specific topology definitions.
- `tests/topology_test.zig` covers graph lookup, bidirectional adjacency, and graph validation.
- `tests/mission_objectives_test.zig` covers required and optional objective definitions, completion tracking, optional rewards, and session reset behavior.
- `tests/game_detection_test.zig` covers action risk costs, safe actions, compromise failure, bounded penalties, retry behavior, extraction failure before payout, legal movement, and location-gated operations.
- `tests/test_all.zig` is the aggregate test list that imports the test modules.
- `test_root.zig` is the repository-root module used to run the aggregate suite while keeping all test files under `tests/`.

Run the complete unit-test suite with:

```sh
zig test test_root.zig
```

The CI workflow checks formatting in `test_root.zig`, `build.zig`, `src/`, and `tests/`, then builds the game and runs the root test module.

## Architecture workflow

Keep modules focused and dependencies one-way. `main.zig` owns application setup and the input loop; `game.zig` coordinates command handling; `mission_state.zig` owns temporary mission-session progress, objective completion, detection, current node, and traversal count. `topology.zig` defines the static fictional graph model; `mission_data.zig` authors a separate graph for each built-in mission. Persistence, display, shop operations, and parsing remain in dedicated modules.

Preserve existing behavior unless a task explicitly requests a gameplay change. Update `docs/architecture.md` when module responsibilities or runtime state change. Update `docs/save-format.md` whenever serialized save layout changes. Temporary mission state is not persisted, so a loaded active mission starts at the accepted stage. Mission difficulty and objective definitions are static metadata and are not serialized. Objective completion is temporary session state and is not currently persisted.

## Manual smoke test

1. Run `help` and `missions`; verify each contract shows its difficulty.
2. Accept `job-01` and run `briefing`; verify the briefing shows Easy, four required objectives, and one optional objective.
3. Run `map`; verify the mission-specific nodes, links, operation locations, and current entry node are shown. Try an invalid/non-adjacent `move` and verify neither location nor Detection changes.
4. Run `move service`; verify Detection increases by 5. Run `objectives`; verify all five objectives are initially unchecked and the optional one displays its bonus.
5. Verify scanning is rejected away from the assigned node; scan the target at `service` and confirm the survey objective is checked.
6. Connect and authenticate at the assigned authentication node using the mission briefing password; confirm the authentication objective is checked.
7. Disconnect and verify authentication remains complete. Move through `corridor` to `vault` and verify decryption is only accepted there.
8. Buy the decryptor, decrypt with the briefing key, and confirm the decryption objective is checked.
9. Optionally run `analyze ledger.enc` at `vault`; verify the optional objective is checked.
10. Extract `ledger.enc` at `vault`; verify the required objectives permit completion and the optional bonus is included only if analysis was completed.
11. Save and restart; persistent progress should be restored while temporary objective and location state starts at the contract entry node, with a traversal count of zero.

Back up `saves/player.sav` before testing save migration or clean-profile progression.


## AI agent workflow

Read the repository-root [AGENTS.md](../AGENTS.md) before making changes. The [agent workspace](../.agent/README.md) provides the required work cycle, module contracts, roadmap, known constraints, accepted architecture decisions, task brief template, and independent review checklist.

For substantial tasks, create a brief from [the task template](../.agent/tasks/TEMPLATE.md). Follow Explore → Understand → Plan → Implement → Verify → Document → Review → Commit. Reviewers should independently inspect the diff when a second agent is available; otherwise record that the review was a self-review.

Run the agent documentation structure check with:

```sh
sh scripts/check-agent-docs.sh
```

CI runs this check in addition to Zig formatting, compilation, and unit tests. It verifies required guidance files and key links/sections; it does not prove code correctness or replace the Zig checks.
