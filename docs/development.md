# Development Guide

## Toolchain

The project targets Zig 0.13.0. Use the same version locally and in CI.

## Build, run, formatting, and tests

\`\`\`sh
zig build
zig build run
zig fmt --check build.zig src tests
zig test tests/test_all.zig
\`\`\`

CI runs formatting, build, and tests on pushes and pull requests targeting main.

## Automated unit tests

Automated unit tests live in the top-level \`tests/\` directory, separate from production source files:

- \`tests/commands_test.zig\` covers command parsing.
- \`tests/mission_state_test.zig\` covers mission-session state transitions.
- \`tests/mission_data_test.zig\` covers the built-in mission difficulty assignments and player-facing labels.
- \`tests/test_all.zig\` is the aggregate test root that imports the test modules.

Run the complete unit-test suite with:

\`\`\`sh
zig test tests/test_all.zig
\`\`\`

The CI workflow checks formatting in both \`src/\` and \`tests/\`, then builds the game and runs this test entry point.

## Architecture workflow

Keep modules focused and dependencies one-way. \`main.zig\` owns application setup and the input loop; \`game.zig\` coordinates command handling; \`mission_state.zig\` owns temporary mission-session progress. Mission definitions and their difficulty classification live in \`mission_data.zig\` and \`mission.zig\`. Persistence, display, shop operations, and parsing remain in dedicated modules.

Preserve existing behavior unless a task explicitly requests a gameplay change. Update \`docs/architecture.md\` when module responsibilities or runtime state change. Update \`docs/save-format.md\` whenever serialized save layout changes. Temporary mission state is not persisted, so a loaded active mission starts at the accepted stage. Mission difficulty is static metadata and is not currently serialized.

## Manual smoke test

1. Run \`help\` and \`missions\`; verify each contract shows its difficulty.
2. Accept \`job-01\` and run \`briefing\`; verify the briefing shows Easy.
3. Verify connect is rejected before scanning.
4. Scan and connect to the target, then authenticate using the mission briefing password.
5. Disconnect and verify decryption remains possible after successful authentication.
6. Buy the decryptor, decrypt with the briefing key, and extract \`ledger.enc\`.
7. Save and restart; persistent progress should be restored while temporary session steps restart.

Back up \`saves/player.sav\` before testing save migration or clean-profile progression.
