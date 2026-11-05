# AGENTS.md — Hacker's Terminal Project Instructions

This file is the persistent source of project-specific instructions for AI coding agents and contributors. Read it before planning or changing code. If a new task or a newer source file conflicts with this document, inspect the repository and resolve the discrepancy rather than blindly following stale notes.

## Project identity and boundaries

- Project: **Hacker's Terminal**, a single-player, command-driven terminal game.
- Language/toolchain: **Zig 0.13.0**. Do not silently upgrade the Zig version or use APIs from newer Zig releases.
- The game is fictional, local, offline, and self-contained.
- Never add real network scanning, real host connections, shell-command execution, credential collection, or interaction with external systems. Hostnames and hacking actions are simulated game content only.
- Preserve the text-terminal experience unless a task explicitly changes the product direction.

## Non-negotiable engineering principles

1. **Incremental modularization:** keep modules focused and split code only when it creates a clear responsibility boundary. Avoid both a monolithic file and unnecessary fragmentation.
2. **Single responsibility:** each module should own one coherent area of behavior.
3. **One-way dependencies:** avoid circular imports. Keep foundational data types independent of higher-level game coordination and terminal I/O.
4. **Behavior preservation:** refactors should preserve existing gameplay, command syntax, progression, and save behavior unless the task explicitly requests a change.
5. **Testability:** keep game rules and state transitions testable without requiring interactive terminal input/output wherever practical.
6. **Small, reviewable changes:** implement one coherent step at a time. Avoid unrelated cleanup mixed into feature work.
7. **Documentation:** update the relevant documentation whenever architecture, commands, gameplay, development workflow, or persistence behavior changes.
8. **No speculative complexity:** prefer simple Zig code and the standard library. Do not introduce frameworks, dependencies, generic abstractions, or design patterns without a concrete need.

## Current architecture (verify against source before editing)

- `src/main.zig`: application entry point, allocator and standard I/O setup, save loading, welcome output, and interactive input loop.
- `src/game.zig`: command dispatch, game-state validation/transitions, mission completion rewards, and player progression calculations.
- `src/player.zig`: player profile data and defaults.
- `src/mission.zig`: mission/contract data types, difficulty classification, and typed objective definitions.
- `src/mission_data.zig`: built-in mission catalog.
- `src/mission_state.zig`: temporary active-mission progress, connection state, and objective completion tracking.
- `src/commands.zig`: allocation-free parsing of command name and first argument; extra tokens are intentionally ignored for compatibility.
- `src/terminal.zig`: terminal presentation, including mission list and briefing-related output.
- `src/save.zig`: persistence and compatibility with V2, V1, and legacy save formats.
- `src/shop.zig`: inventory and shop behavior.
- `tests/`: unit tests, separate from production source.
- `test_root.zig`: repository-root test module that imports the aggregate test suite, allowing test modules to import source files under `src/` without escaping their module root.
- `docs/`: user and developer documentation.

Read `docs/architecture.md` for the detailed module map and runtime flow, `docs/gameplay.md` and `docs/commands.md` before changing gameplay or command behavior, and `docs/save-format.md` before touching persistence.

## Gameplay and state invariants

- Mission progression is ordered: `inactive -> accepted -> scanned -> authenticated -> decrypted`.
- Connection status is independent from mission progress. Disconnecting must not erase authentication or decryption already achieved.
- A mission cannot skip required stages. Preserve the validation rules around scan, connect, authentication, decryption, and extraction.
- Current progression rules: level 1 begins below 100 XP; the first level-up threshold is 100 XP and each subsequent threshold increases by 150 XP. Preserve these rules unless a balancing change is requested.
- The built-in mission catalog currently classifies `job-01` as `easy`, `job-02` as `medium`, and `job-03` as `hard`. These difficulty values are descriptive metadata only; do not imply they affect mechanics until a separate feature explicitly implements and tests that behavior.
- Keep mission definitions, rewards, clues, puzzle answers, and their ordering consistent with the existing catalog unless explicitly changed.
- Temporary mission-session state is runtime-only and is not currently persisted. A restored active mission starts again at the accepted stage.
- Mission difficulty and objective definitions are static catalog data and are not serialized. Do not change the save format merely to persist them.
- Each built-in mission defines objectives using `MissionObjectiveKind`; successful scan, authentication, decryption, and extraction actions complete the corresponding objective.
- Objective completion is runtime-only session state. `extract` may complete a contract only when every objective defined for that mission is complete. Keep the objective-kind bit positions within the current eight-bit session mask; redesign the storage before adding more than eight kinds.

## Persistence safety

- Save compatibility is important. Existing V2, V1, and legacy saves must continue to load unless a deliberate migration is designed and documented.
- Do not change serialized field order, save version markers, defaults, or the save path as incidental parts of unrelated refactors.
- Any intentional save-format change must update `docs/save-format.md`, include migration/compatibility handling where needed, and add or update tests.

## Tests, formatting, and verification

Use Zig **0.13.0** and the repository's documented commands:

```sh
zig fmt --check test_root.zig build.zig src tests
zig build
zig test test_root.zig
```

- Add tests under `tests/`; do not put test modules back into `src/`.
- Keep `tests/test_all.zig` as the aggregate test list and include new test modules there.
- Use `test_root.zig` as the test command's root module. It exists so test imports such as `../src/commands.zig` remain within the repository-root module path.
- Add tests for state transitions, objective definitions and completion tracking, parsing edge cases, progression rules, and save compatibility when those areas change.
- If local build execution is unavailable, perform static inspection and say clearly that build/tests were not run. Never describe static inspection as a passing build or test.
- When CI is available, inspect the actual workflow run and report its conclusion; do not infer success from a commit being pushed.

## Repository workflow

- Work on the existing `main` branch unless the user explicitly asks for another branch.
- The user has authorized direct commits to `main` for this project. Make focused commits and report the commit link and SHA after each completed step.
- Before editing an existing file, fetch its latest contents and current blob SHA from GitHub. Do not overwrite based on stale copies.
- After changes, inspect the resulting files/diff where possible and verify the commit exists on `main`.
- Do not claim that a change has been pushed or committed until GitHub confirms it.
- Explain the purpose and architectural impact of meaningful changes in the conversation. Prefer Persian explanations for this user, while keeping source code, identifiers, and repository documentation in clear technical English.

## Working with future feature ideas

Build new systems incrementally. The current broad direction may include richer mission design, simulated network topology, equipment/inventory, detection/risk, and reputation/contacts, but these are ideas—not implemented requirements.

Before implementing a new system:
1. Inspect the current source and relevant docs; do not assume the architecture snapshot above is still exact.
2. Explain the smallest useful design and how it fits existing modules.
3. Identify gameplay and save-compatibility implications.
4. Add focused tests and update docs as part of the same coherent change.
5. Avoid implementing future roadmap items pre-emptively.
6. Whenever an agreed feature changes project architecture, gameplay rules, data contracts, or development conventions, update this `AGENTS.md` in the same implementation step. Do not edit it mechanically for a change that introduces no lasting project rule or design decision.
