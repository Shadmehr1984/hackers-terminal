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
- `tests/mission_data_test.zig` covers the built-in mission difficulty assignments and player-facing labels.
- `tests/mission_objectives_test.zig` covers required and optional objective definitions, completion tracking, optional rewards, and session reset behavior.
- `tests/test_all.zig` is the aggregate test list that imports the test modules.
- `test_root.zig` is the repository-root module used to run the aggregate suite while keeping all test files under `tests/`.

Run the complete unit-test suite with:

```sh
zig test test_root.zig
```

The CI workflow checks formatting in `test_root.zig`, `build.zig`, `src/`, and `tests/`, then builds the game and runs the root test module.

## Architecture workflow

Keep modules focused and dependencies one-way. `main.zig` owns application setup and the input loop; `game.zig` coordinates command handling; `mission_state.zig` owns temporary mission-session progress and objective completion. Mission definitions, difficulty, and objective metadata live in `mission_data.zig` and `mission.zig`. Persistence, display, shop operations, and parsing remain in dedicated modules.

Preserve existing behavior unless a task explicitly requests a gameplay change. Update `docs/architecture.md` when module responsibilities or runtime state change. Update `docs/save-format.md` whenever serialized save layout changes. Temporary mission state is not persisted, so a loaded active mission starts at the accepted stage. Mission difficulty and objective definitions are static metadata and are not serialized. Objective completion is temporary session state and is not currently persisted.

## Manual smoke test

1. Run `help` and `missions`; verify each contract shows its difficulty.
2. Accept `job-01` and run `briefing`; verify the briefing shows Easy, four required objectives, and one optional objective.
3. Run `objectives`; verify all five objectives are initially unchecked and the optional one displays its bonus.
4. Verify connect is rejected before scanning; scan the target and confirm the survey objective is checked.
5. Connect and authenticate using the mission briefing password; confirm the authentication objective is checked.
6. Disconnect and verify decryption remains possible after successful authentication.
7. Buy the decryptor, decrypt with the briefing key, and confirm the decryption objective is checked.
8. Optionally run `analyze ledger.enc`; verify the optional objective is checked.
9. Extract `ledger.enc`; verify the required objectives permit completion and the optional bonus is included only if analysis was completed.
10. Save and restart; persistent progress should be restored while temporary objective state starts unchecked.

Back up `saves/player.sav` before testing save migration or clean-profile progression.
