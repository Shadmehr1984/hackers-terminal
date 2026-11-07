# Known Constraints and Open Questions

This file separates verified constraints from items that need investigation.

## Verified constraints
- The repository and primary CI now target Zig 0.17.1. The Debug, ReleaseSafe, and ReleaseFast matrix, full aggregate tests (including terminal/save I/O and facade coverage), formatting, and terminal entry-point smoke test are the migration acceptance checks; consult the latest main-branch CI run for the current result.
- The command parser accepts a command and at most one argument; later tokens are ignored.
- Mission-session state and objective completion are not persisted.
- Save data is positional and has no checksum or full corruption recovery. Writes are staged through a temporary file and renamed after a successful write. Loaders accept V3, V2, V1, and numeric legacy headers; unknown non-numeric markers are rejected before mutating player or mission state.
- Mission topology validation requires every operation node to be reachable from the entry node; decorative nodes may remain disconnected.
- Objective progress uses a fixed-capacity 32-entry tracker keyed by stable objective IDs; catalogs exceeding 32 objectives are rejected.
- Runtime topology traversal count is a u32. Under current Detection rules, successful traversal exposure and the one-use Fixer reduction end a mission run long before the counter can approach u32 overflow; revisit this only if future changes materially reduce movement exposure or remove the Detection failure boundary.
- Mission difficulty is descriptive metadata, not a gameplay modifier.
- There is no real networking layer; all hacking/host behavior is fictional and simulated.
- The owner cannot reliably build locally at present; report CI separately from manual playtesting.

## TOOLCHAIN-001 migration constraints
- `src/application/terminal_io.zig` is the active Zig 0.17.1 `std.Io` adapter imported directly by `src/main.zig`; the legacy `std.io` process path has been removed.
- The full aggregate suite now includes terminal I/O boundary/failure tests, save I/O compatibility tests, and facade API tests. It runs under Zig 0.17.1 in all three CI optimization modes.
- The 13 compatibility facades use explicit public exports and are covered by the aggregate facade API test. The removed array repetition syntax in `mission_objectives.zig` was replaced by an allocation-free initializer loop.
- `save.zig` uses a single `std.Io`/`std.Io.Dir` SaveContext backend. V3 serialization and the temp-write/flush/close/rename transaction remain unchanged and are covered by aggregate save I/O tests.
- Shared enum-backed bit fields and persisted numeric values use `@backingInt` under Zig 0.17.1. Their explicit backing types and numeric values are compatibility-sensitive; preserve them and keep enum catalog/save-byte tests.

## Review clarification
- The initial 2026-11-07 terminal-injection suggestion for the invalid-modifier response was withdrawn after tracing the complete branch condition: the argument is printed only after exact resolution through the fixed ModifierId command allowlist, so arbitrary ANSI/OSC control sequences cannot reach that output. This was a false positive, not a confirmed vulnerability.

## Open questions, not confirmed bugs
- Should mission-session progress survive restart, and what migration would that require?
- Should command parsing evolve beyond one argument?
- Should future mission branches affect payout, reputation, unlocks, or narrative only?

Do not present an open question as a defect or resolve it during unrelated work.


## Verified API limitation
- `Topology.isValid(allocator)` currently returns `false` both for invalid graph data and for allocation failure during reachability traversal. Phase 4 adds regression coverage for both allocation-failure points. The boolean API is retained for source compatibility; a future error-union redesign requires an explicit API-change decision.
