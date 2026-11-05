# Task: Phase 4 — Tests and documentation

Status: Implementation complete; CI verification pending.

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
- [ ] Zig 0.13.0 formatting, build, and full test suite pass in CI.
- [ ] Self-review and final diff inspection recorded.

## Known limitation retained intentionally
`Topology.isValid(allocator)` returns `false` for both invalid topology and traversal allocation failure. The tests now exercise both allocation failures. Converting the API to an error union would be a public API change and is outside this phase.

## Verification
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig build test`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] Inspect GitHub Actions run and final branch diff.
- [ ] Independent review if available; otherwise record self-review explicitly.

## Review notes
- No production control flow, command dispatch, game rules, or save serialization was modified.
- Test changes are additive; aggregate test registration and test root remain unchanged.
