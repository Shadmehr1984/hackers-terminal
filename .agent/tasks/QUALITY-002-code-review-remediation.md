# QUALITY-002 — Save Format, Topology Reachability, and Persistence Tests

- Status: In Progress
- Origin: Follow-up project-wide code review on 2026-11-05
- Owner approval: All three remediation items approved.

## Goal
Harden save-format detection, reject mission topologies whose required locations cannot be reached from the entry node, and exercise the real atomic-save filesystem path in tests.

## Confirmed current behavior
- `src/save.zig` recognizes V3, V2, and V1 markers, but treats every other first line as a legacy numeric balance. An unknown future marker can therefore be misread as legacy data.
- `src/topology.zig` validates required node existence, duplicate node IDs, and link endpoints/self-links, but does not validate reachability between the entry and mission operation nodes.
- Existing save tests cover in-memory V3/V2/V1/legacy loading, but do not exercise `saveGame` writing and replacing a file on disk.

## Acceptance criteria
- [x] Unknown non-numeric save markers are rejected without mutating the supplied player or mission state.
- [x] Numeric legacy saves and V1/V2/V3 saves continue to load with existing migration behavior.
- [x] A topology is invalid if any required operation node (scan, auth, decrypt, analyze, extract) is unreachable from entry; valid connected graphs remain valid.
- [x] Tests cover disconnected required nodes and connected topology.
- [x] Tests exercise real save write/read round-trip using an isolated temporary directory, including replacement of an existing save.
- [x] A staging failure leaves the previous save file intact and readable.
- [x] Save V3 marker, field order, save path, and V1/V2/legacy compatibility remain unchanged.
- [x] Focused tests are included in the existing aggregate suite; no real networking or external-system behavior is introduced.
- [x] Relevant docs, this brief, task index, and review records are updated.
- [ ] Zig 0.13.0 formatting, build, all tests, and agent-doc check pass in GitHub Actions.
- [ ] Final self-review against `.agent/review-checklist.md` is recorded; no second reviewer is claimed unless one is actually available.

## Likely scope
- `src/save.zig`
- `src/topology.zig`
- `tests/equipment_test.zig` or a focused new save test module
- `tests/mission_data_test.zig`
- `tests/topology_test.zig`
- `tests/test_all.zig` if a new test module is introduced
- `.agent/tasks/README.md`
- `.agent/known-issues.md`
- This task brief

## Constraints and non-goals
- Save-format impact: none. Continue writing V3 and loading V2, V1, and numeric legacy saves.
- Compatibility: unknown format markers must fail closed; do not reinterpret them as legacy.
- Topology validation should concern the required operation nodes; optional decorative nodes need not all be connected.
- Filesystem tests must be isolated and must not touch the user's real `saves/player.sav`.
- Do not add checksum/corruption recovery, save version V4, new gameplay rules, or unrelated refactors.

## Implementation notes

- `loadGameFromBytes` now classifies V3/V2/V1 markers and validates an unversioned legacy header as an unsigned integer before resetting equipment or mutating mission/player data.
- `Topology.isValid(allocator)` now uses breadth-first traversal from the entry node and requires each operation location to be reachable. Non-empty unique node IDs are enforced; disconnected decorative nodes remain allowed. The allocator is explicit, and the test suite uses `std.testing.allocator`.
- `saveGameToDirectory` is the shared filesystem implementation used by production `saveGame` and tests. Tests use `std.testing.tmpDir` to avoid touching the real save directory and verify replacement, V3 round-trip, and temporary-file cleanup.
- Documentation now records the strict marker policy and topology reachability invariant.

## Verification
- [x] Focused save-format and filesystem test cases added (execution pending CI).
- [x] Focused topology reachability tests added (execution pending CI).
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig test test_root.zig`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] GitHub Actions result inspected for final commit
- [x] Independent review checklist completed as self-review; no second reviewer was available.


### Self-review record

Reviewed the final source/test changes against `.agent/review-checklist.md`. Save V3 serialization and old-format migration branches remain unchanged; unknown markers are rejected before state mutation. The topology BFS enqueues each node at most once and checks only required operation locations, leaving disconnected decorative nodes valid. Filesystem tests use an isolated temporary directory and cover successful replacement plus a staging failure that leaves the old save readable. No unrelated gameplay or external-system behavior was introduced. No independent second reviewer was available; this is a self-review only.
