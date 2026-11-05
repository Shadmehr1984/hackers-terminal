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
- [ ] Unknown non-numeric save markers are rejected without mutating the supplied player or mission state.
- [ ] Numeric legacy saves and V1/V2/V3 saves continue to load with existing migration behavior.
- [ ] A topology is invalid if any required operation node (scan, auth, decrypt, analyze, extract) is unreachable from entry; valid connected graphs remain valid.
- [ ] Tests cover disconnected required nodes and connected topology.
- [ ] Tests exercise real save write/read round-trip using an isolated temporary directory, including replacement of an existing save.
- [ ] Save V3 marker, field order, save path, and V1/V2/legacy compatibility remain unchanged.
- [ ] Focused tests and aggregate test suite are included; no real networking or external-system behavior is introduced.
- [ ] Relevant docs, this brief, task index, and review records are updated.
- [ ] Zig 0.13.0 formatting, build, all tests, and agent-doc check pass in GitHub Actions.
- [ ] Final self-review against `.agent/review-checklist.md` is recorded; no second reviewer is claimed unless one is actually available.

## Likely scope
- `src/save.zig`
- `src/topology.zig`
- `tests/equipment_test.zig` or a focused new save test module
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

## Verification
- [ ] Focused save-format and filesystem tests
- [ ] Focused topology reachability tests
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig test test_root.zig`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] GitHub Actions result inspected for final commit
- [ ] Independent review checklist completed as self-review if no second reviewer is available
