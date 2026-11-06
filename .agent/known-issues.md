# Known Constraints and Open Questions

This file separates verified constraints from items that need investigation.

## Verified constraints
- Zig 0.13.0 remains the default application/CI baseline during TOOLCHAIN-001; Zig 0.17.1 is the migration target. The complete application build and targeted terminal/save/facade tests now pass under Zig 0.17.1; the full aggregate test suite and CI cutover remain pending.
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
- `src/application/terminal_io.zig` is a Zig 0.16+ module. It is conditionally imported by `src/main.zig`; the Zig 0.13 path remains active until the final CI/toolchain switch.
- The Zig 0.17.1 terminal and save I/O suites pass. They cover input boundaries, oversized-line drain, next-command alignment, read/write failure propagation, exact V3 bytes, save round-trip, missing-save status, the 4096/4097-byte read boundary, and staging-failure preservation. The complete application also compiles under Zig 0.17.1; the full aggregate suite has not yet been run under that toolchain.
- A full-repository Zig 0.17.1 formatter probe identified 13 legacy compatibility facades; their explicit public exports are now covered by the focused facade API test, and the full application compile passes. The removed array repetition syntax in `mission_objectives.zig` has been replaced by a cross-version allocation-free initializer loop.
- `save.zig` now has a version-gated `SaveContext` and tested `std.Io` backend; V3 serialization and the temp-write/flush/close/rename transaction are preserved. The full application build has passed under Zig 0.17.1.
- Shared files retain `@intFromEnum` for existing numeric enum encodings; both Zig 0.13.0 and Zig 0.17.1 compile these uses. Preserve their numeric values and avoid blanket conversion changes.

## Open questions, not confirmed bugs
- Should mission-session progress survive restart, and what migration would that require?
- Should command parsing evolve beyond one argument?
- Should future mission branches affect payout, reputation, unlocks, or narrative only?

Do not present an open question as a defect or resolve it during unrelated work.


## Verified API limitation
- `Topology.isValid(allocator)` currently returns `false` both for invalid graph data and for allocation failure during reachability traversal. Phase 4 adds regression coverage for both allocation-failure points. The boolean API is retained for source compatibility; a future error-union redesign requires an explicit API-change decision.
