# Development Guide

## Toolchain

The project is written for **Zig 0.13.0**. Install that version before building or running the checks. The CI workflow also installs Zig 0.13.0, so local development should use the same version to avoid version-related differences.

## Build

From the repository root:

```sh
zig build
```

The executable is installed under `zig-out/bin/`.

## Run

```sh
zig build run
```

The build script also supports passing arguments to the executable after the run step, although the game currently uses an interactive stdin command loop.

## Formatting

Check formatting without modifying files:

```sh
zig fmt --check build.zig src
```

Apply the formatter when needed:

```sh
zig fmt build.zig src
```

Review the resulting diff before committing.

## Tests

The CI workflow runs:

```sh
zig test src/main.zig
```

This compiles and runs Zig tests declared in the source file. The current repository does not define a dedicated test suite yet. As modules are extracted, add focused tests for independently testable data and game logic. Persistence currently remains behavior-compatible with V2, V1, and the original legacy save layouts. `main.zig` imports the extracted modules, including `save.zig` and `terminal.zig`, so this command also checks that those module imports compile.

## Continuous integration

The workflow is defined in `.github/workflows/ci.yml`. It runs for pushes and pull requests targeting `main`.

The job performs these steps:

1. Checks out the repository.
2. Installs Zig 0.13.0.
3. Checks formatting with `zig fmt --check build.zig src`.
4. Compiles the project with `zig build`.
5. Runs `zig test src/main.zig`.

The workflow requests read-only repository contents permission and cancels an older run when a newer run for the same ref is queued.

## Suggested manual smoke test

After building, start the game and verify the following:

1. `help` lists the supported commands.
2. `missions` lists the three contracts and locks contracts above the player's level.
3. `accept job-01` succeeds for a new level-1 profile.
4. `connect vault-01.local` is rejected before scanning.
5. `brute orion42` is rejected before connecting and succeeds after connecting.
6. `decrypt midnight` is rejected until authentication is granted and the decryptor is owned.
7. `extract ledger.enc` completes the first contract only after decryption.
8. `status` reflects the reward, reputation, XP, and level-up.
9. `save`, followed by restarting the program, restores persistent progress.
10. A restored active contract requires its temporary session steps to be repeated.

Use a fresh working directory or back up `saves/player.sav` before testing save migration or progression from a clean profile.

## Contribution guidelines

When changing the project:

- Keep the fictional, offline-only nature of the simulator explicit in user-facing documentation.
- Update the command reference whenever command syntax or prerequisites change.
- Update the gameplay guide when missions, clues, rewards, or progression rules change.
- Update the architecture document when responsibilities or runtime state change.
- Update the save-format document whenever the serialized layout changes.
- Keep save migration compatibility in mind when changing persisted fields.
- Run formatting, build, and test commands before opening a pull request.

## Known opportunities for future work

The current code is deliberately small. Potential improvements include:

- Split command parsing, mission data, progression, and persistence into separate modules.
- Replace independent session booleans with an explicit mission-stage enum.
- Add unit tests for progression, command validation, and save migration.
- Improve input parsing to support robust argument handling and clear errors.
- Make save writes safer with temporary files and atomic replacement.
- Move mission definitions into data files once the mission model stabilizes.
