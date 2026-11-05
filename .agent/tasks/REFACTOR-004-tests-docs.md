# Task: Phase 4 — Tests and documentation

Status: Completed; verified by GitHub Actions run 42057308382.

## Goal
Close high-value regression gaps and make the public module contracts easier to use without changing gameplay, public behavior, or persistence formats.

## Scope
- Add allocator-failure regression coverage for both reachability allocations in `Topology.isValid`.
- Add malformed and truncated V3 save-input coverage while preserving current loader behavior.
- Add Zig doc comments for exported public types, constants, and functions across domain, application, catalog, persistence, and presentation modules.
- Update architecture/development documentation and agent conventions.
- Record verified limitations separately from open questions.

## Accepted constraints
- Zig 0.13.0 only.
- No gameplay or command behavior changes.
- No public signature changes.
- Save V3 writing and V2/V1/legacy reads remain unchanged.
- Keep tests in `tests/`; do not change `tests/test_all.zig` or `test_root.zig`.
- Preserve the separate phase branch workflow; do not merge without explicit approval.
- Fictional/offline safety boundary remains unchanged.

## Acceptance criteria
- [x] Topology tests cover both allocation failure points using `std.testing.FailingAllocator`.
- [x] Save tests cover truncated and malformed versioned input.
- [x] Existing save migration, V3 round-trip, invalid-marker, active-index, and staged-write tests remain intact.
- [x] Exported public APIs have concise Zig doc comments describing observable behavior.
- [x] `AGENTS.md` and `.agent/conventions.md` document public API comment and allocator-test expectations.
- [x] `.agent/known-issues.md` records the boolean OOM/invalid conflation without changing the source-compatible API.
- [x] Architecture and development docs reflect the expanded coverage.
- [x] Zig 0.13.0 formatting, build, and full test suite pass in CI.
- [x] Self-review and final diff inspection recorded.

## Known limitation retained intentionally
`Topology.isValid(allocator)` returns `false` for both invalid topology and traversal allocation failure. The tests now exercise both allocation failures. Converting the API to an error union would be a public API change and is outside this phase.

## Verification
- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig build test`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Inspect GitHub Actions run and final branch diff.
- [x] Independent reviewer unavailable; self-review performed and recorded.

## Review notes
- No production control flow, command dispatch, game rules, or save serialization was modified.
- Test changes are additive; aggregate test registration and test root remain unchanged.

## Final self-review
- Public declaration audit across domain, catalog, application, persistence, and presentation found doc comments on every exported public type, constant, and function.
- The two Equipment Detection-cost adapters received explicit method documentation after the audit found they were not yet covered.
- The new topology test uses the Zig 0.13.0 `FailingAllocator.init(allocator, config)` API and exercises fail indices 0 and 1. The standard testing allocator detects leaks from the first allocation when the second allocation fails.
- Save input tests assert the existing loader behavior for truncated V3 data, malformed numeric fields, normalized equipment levels, and invalid equipped utility values.
- Diff against Phase 3 is limited to tests, API comments, agent guidance, architecture/development docs, the task brief, and known-issue documentation. No save implementation, gameplay control flow, command dispatch, test aggregator, or test root changed.
- CI run 42057308382 completed successfully: Zig 0.13.0 install, formatting, `zig build`, `zig build test`, and agent-doc structure check all passed.
- Independent review was not available. This review is a self-review, not a second-agent review.
