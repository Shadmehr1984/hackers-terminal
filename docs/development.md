# Development Guide

## Toolchain

The project targets Zig 0.13.0. Use the same version locally and in CI.

## Build, run, formatting, and tests

```sh
zig build
zig build run
zig fmt --check build.zig src
zig test src/tests.zig
```

CI runs formatting, build, and tests on pushes and pull requests targeting main.

## Automated unit tests

Unit tests for the mission-session state model and command parser live beside their implementation modules. The test root imports those modules so Zig discovers their tests:

```sh
zig test src/tests.zig
```

The CI workflow runs this command after formatting and build checks.

## Architecture workflow

Keep modules focused and dependencies one-way. main.zig owns application setup and the input loop; game.zig coordinates command handling; mission_state.zig owns temporary mission-session progress. Persistence, display, shop operations, parsing, and mission data remain in dedicated modules.

Preserve existing behavior unless a task explicitly requests a gameplay change. Update docs/architecture.md when module responsibilities or runtime state change. Update docs/save-format.md whenever serialized save layout changes. Temporary mission state is not persisted, so a loaded active mission starts at the accepted stage.

## Manual smoke test

1. Run help and missions.
2. Accept job-01.
3. Verify connect is rejected before scanning.
4. Scan and connect to the target, then authenticate using the mission briefing password.
5. Disconnect and verify decryption remains possible after successful authentication.
6. Buy the decryptor, decrypt with the briefing key, and extract ledger.enc.
7. Save and restart; persistent progress should be restored while temporary session steps restart.

Back up saves/player.sav before testing save migration or clean-profile progression.
