# Task: Phase 2 — Module boundaries and layered source layout

Status: Completed; verified by GitHub Actions.

## Goal
Group production Zig modules by responsibility, preserve existing import paths through compatibility facades, clarify one-way dependencies, and expose the test suite as `zig build test`.

## Current behavior
Production modules are currently flat under `src/`. The dependency graph has no import cycles. `main.zig` is the composition root; `game.zig` coordinates gameplay; domain types are shared across persistence, catalog, application, and presentation modules. Tests live in `tests/`, aggregated by `tests/test_all.zig` and rooted at `test_root.zig`.

## Acceptance criteria
- [x] Group implementations under `domain/`, `application/`, `catalog/`, `presentation/`, and `persistence/`.
- [x] Keep `src/main.zig`, all test files, `tests/test_all.zig`, and `test_root.zig` in their current locations.
- [x] Keep old top-level `src/*.zig` imports working through compatibility facades.
- [x] Keep dependency direction one-way and avoid import cycles.
- [x] Add a Zig 0.13.0 `zig build test` step using the existing root test module.
- [x] Update CI and architecture/development/agent docs to reflect the layout and test command.
- [x] Preserve public declarations, gameplay behavior, command syntax, and all save formats.

## Likely scope
- `src/**`
- `build.zig`
- `.github/workflows/ci.yml`
- `AGENTS.md`
- `.agent/conventions.md`
- `.agent/decisions/0002-modular-boundaries.md`
- `docs/architecture.md`
- `docs/development.md`

## Constraints and non-goals
- Save-format impact: none; V3 writing and V2/V1/legacy reading must remain unchanged.
- Compatibility and safety constraints: preserve old import paths; target Zig 0.13.0; tests remain in `tests/`; keep the fictional/offline boundary.
- Explicitly out of scope: gameplay changes, public API changes, test relocation, test aggregator changes, save schema changes, and broad refactoring of function behavior.

## Verification
- [x] Existing full suite executed; no new behavior tests were required for this structural-only change
- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig build test`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Documentation updated
- [x] Self-review completed; independent reviewer was unavailable
