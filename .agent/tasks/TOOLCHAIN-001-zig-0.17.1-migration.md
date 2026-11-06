# TOOLCHAIN-001: Upgrade the Codebase to Zig 0.17.1

- Status: **Audit complete; implementation not started**
- Priority: High (cross-cutting toolchain migration)
- Target: Zig **0.17.1**
- Baseline commit: `34e8938f12b6f7126eacf52403c5b468eee2a1a3` on `main`
- Owner authorization: Migration plan approved on 2026-11-07. Work directly on `main`; no feature branch.
- Scope: Build system, standard I/O, filesystem/persistence, language/standard-library compatibility, tests, CI, and documentation.
- Out of scope: Gameplay changes, save-format changes, module redesign unrelated to compatibility, dependencies, real networking, shell execution, or any external-system interaction.

## 1. Goal

Move the repository from its currently configured Zig 0.13.0 toolchain to Zig 0.17.1 without changing gameplay, public project behavior, or persistence compatibility.

The migration is complete only when the build, executable, test suite, CI matrix, and developer instructions all consistently target 0.17.1 and the acceptance criteria below are verified.

## 2. Accepted constraints and invariants

1. Preserve all existing gameplay rules, command syntax, terminal experience, and deterministic/offline behavior.
2. Preserve Save V3 byte layout and writer behavior. Continue reading V3, V2, V1, and legacy saves. Do not bump the save version or change positional field order.
3. Preserve atomic save replacement: write the complete temporary payload, close it, then rename it over the destination; failures must not destroy the previous save.
4. Preserve the 512-byte command input limit and oversized-line drain behavior. A too-long command is discarded as a whole; I/O errors while draining must propagate.
5. Preserve transactional state transitions and writer-failure behavior. Output failure must not leave partial game-state mutations.
6. Preserve the current test suite's failure-injection intent. Do not weaken assertions or remove tests merely to satisfy a new Writer API.
7. Keep tests under `tests/`, keep `tests/test_all.zig` as the aggregate, and retain `test_root.zig`.
8. Work directly on `main`, in small focused commits. Do not combine migration with gameplay features or unrelated cleanup.
9. The repository is fictional, local, offline, and self-contained. No real network, shell, credential, or external-host behavior may be introduced.

## 3. Current-state audit

The audit was performed against the current `main` head listed above. Earlier code-search excerpts from commit `5d2173123d4b114ae9f927d3c37fe0582b3a5fe6` are historical only; use current file contents and SHAs before editing.

### 3.1 Build system

- `build.zig:8-12`: executable uses `.root_source_file = b.path("src/main.zig")`.
- `build.zig:23-28`: test artifact uses `.root_source_file = b.path("test_root.zig")`.
- `build.zig:16-19`: run arguments are forwarded by inspecting `b.args` and calling `run_cmd.addArgs(args)`.
- Migration work: move executable and test roots to the 0.17 module-based build API; replace argument passthrough with the supported 0.17 mechanism. Confirm how `zig build run -- <args>` behaves because the new passthrough mechanism intentionally changes what build scripts can inspect.

### 3.2 Standard input/output and process entry point

- `src/main.zig:12`: entry point is `pub fn main() !void`; 0.17 process initialization/I/O context must be checked against the exact 0.17.1 API.
- `src/main.zig:13-18`: allocator setup uses `std.heap.GeneralPurposeAllocator`.
- `src/main.zig:21-22`: standard streams use `std.io.getStdOut().writer()` and `std.io.getStdIn().reader()`.
- `src/main.zig:58-72`: line input uses `readUntilDelimiterOrEof`, handles `StreamTooLong`, drains the remainder of an oversized line, and propagates drain errors.
- `src/main.zig:29-37,52,57,68,77`: output is passed through terminal/game layers and includes formatting and write failures.
- Migration work: adopt the 0.17.1 process and `std.Io` model. Design input buffering explicitly; preserve EOF, newline, CR trimming, 512-byte boundary, oversized-line draining, and error propagation. Do not silently change terminal output or input semantics.

### 3.3 Filesystem and persistence

- `src/persistence/save.zig:5-35`: default save path uses `std.fs.cwd()`; save helper accepts `std.fs.Dir`; temporary file uses `createFile`; output uses `file.writer()`; finalization uses `dir.rename`.
- `src/persistence/save.zig:247-267`: load path uses `openFile`, `readToEndAlloc`, and explicit missing/invalid/I/O-error status.
- `src/application/game.zig:296-318`: command dispatch is generic over a writer but receives `std.fs.Dir` for isolated save testing.
- `tests/operation_test.zig:37-47`: filesystem-isolated command tests use `std.fs.Dir`.
- Migration work: adapt file/directory handles and read/write operations to 0.17.1. Keep save serialization format and transaction boundary identical. Preserve the test seam for a caller-supplied directory or replace it with an equally testable abstraction without changing behavior.

### 3.4 Writer abstraction and tests

- Production output is generic (`writer: anytype`) in `src/application/game.zig` and presentation/shop modules; calls use `writeAll` and `print`.
- Several test modules provide lightweight fake writers implementing these methods. Examples include `tests/contacts_test.zig:11-38`, `tests/operation_test.zig:12-23`, `tests/mission_preparation_test.zig`, `tests/progression_test.zig`, `tests/rival_test.zig`, and `tests/terminal_test.zig`.
- Failure-injection writers are essential to transactional-state tests.
- Migration work: determine whether generic test writers can remain as local test adapters while production uses `std.Io.Writer`, or whether a narrow project-owned output interface is needed. Do not make all tests depend on a concrete stdlib writer if that weakens failure injection.

### 3.5 Language and standard-library API scan

- `src/domain/mission_modifier.zig:48-54`: `@enumFromInt` is used to reconstruct a modifier ID from enum metadata. The same pattern exists in `tests/mission_modifier_test.zig`. Zig 0.17.1 deprecates this builtin; replace it with the supported conversion only after verifying the enum backing type and safety semantics.
- `@intFromEnum` appears in objective tracking, operation facts, equipment bit flags, save serialization, and tests. Audit each conversion and preserve stable numeric values where persisted or bit-packed.
- `std.mem`, `std.fmt`, allocator usage, and the GPA setup appear throughout the codebase. Compile-driven migration must check changed signatures and semantics, not perform blind global replacements.
- No `std.ArrayList` usage was found in the production/test scan.
- No direct `std.process` or `std.Io` usage currently exists in the application source.
- Compatibility facades under `src/*.zig` must continue to compile and preserve their exports.

### 3.6 CI and documentation

- `.github/workflows/ci.yml` currently installs Zig 0.13.0 and runs formatting, build, tests for Debug, ReleaseSafe, and ReleaseFast, plus the agent-doc structure check.
- `AGENTS.md`, `.agent/conventions.md`, `.agent/known-issues.md`, `.agent/decisions/0001-zig-toolchain.md`, `.agent/review-checklist.md`, `docs/development.md`, and `docs/architecture.md` contain 0.13.0 assumptions.
- Migration work: update every active toolchain reference in one coordinated final phase. Keep historical ADR history clear; do not leave conflicting instructions that tell agents to use 0.13.0 after completion.

## 4. Execution phases and handoff

### Phase 0 — Audit and migration plan
- [x] Confirm current `main` commit and existing toolchain pin.
- [x] Read project/agent instructions and architecture, save-format, development, and CI documentation.
- [x] Inventory build, I/O, filesystem, enum, writer-test, and CI touchpoints.
- [x] Record migration constraints, acceptance criteria, and handoff here.
- [ ] Owner reviews audit findings if further design decisions are needed.

### Phase 1 — Build-system migration
- [ ] Change executable/test root modules to the 0.17.1 module API.
- [ ] Replace `b.args`/`addArgs` with supported passthrough-argument handling.
- [ ] Verify `zig build`, `zig build run`, `zig build run -- <args>`, and `zig build test`.
- [ ] Keep CI on the old pin until the complete migration is ready, unless a deliberate temporary CI strategy is documented.
- [ ] Commit as `build: migrate build graph to Zig 0.17.1`.

### Phase 2 — Terminal/process I/O
- [ ] Migrate entry point and stdout/stderr/stdin to the 0.17.1 process and I/O API.
- [ ] Preserve prompt, formatted output, EOF, newline handling, input-size bound, oversized-input drain, and error propagation.
- [ ] Preserve generic output/failure-injection seams.
- [ ] Add focused tests for input boundaries and I/O failure paths where testable.
- [ ] Commit as `refactor: migrate terminal I/O to Zig 0.17.1`.

### Phase 3 — Filesystem and persistence
- [ ] Migrate `std.fs` directory/file APIs and file read/write calls.
- [ ] Preserve temporary-file write → close → rename ordering and cleanup on failure.
- [ ] Preserve LoadStatus behavior and bounded read behavior.
- [ ] Test Save V3 output and V3/V2/V1/legacy load compatibility.
- [ ] Verify failure paths leave previous save and caller-owned state unchanged.
- [ ] Commit as `refactor: migrate filesystem and save I/O`.

### Phase 4 — Language and standard-library compatibility
- [ ] Replace deprecated enum conversion builtins with 0.17.1-supported equivalents after verifying backing-type semantics.
- [ ] Resolve compile errors and deprecations in memory, formatting, allocator, and other stdlib APIs.
- [ ] Preserve enum numeric values used by flags/save encoding and public compatibility facades.
- [ ] Commit as `refactor: update Zig language and stdlib APIs`.

### Phase 5 — Tests and CI
- [ ] Migrate test infrastructure and test doubles without losing failure injection.
- [ ] Keep aggregate test list and root test module stable.
- [ ] Update CI setup to Zig 0.17.1.
- [ ] Run formatting, build, and tests in Debug, ReleaseSafe, ReleaseFast.
- [ ] Confirm agent-doc check passes.
- [ ] Commit as `ci: target Zig 0.17.1`.

### Phase 6 — Documentation, review, and closeout
- [ ] Update toolchain version and commands in all active agent/user docs.
- [ ] Mark ADR 0001 superseded and retain the new accepted toolchain ADR.
- [ ] Update roadmap/task status only after implementation, review, and CI are complete.
- [ ] Perform the full mandatory repository review using `.agent/review-checklist.md`.
- [ ] Inspect CI for the final `main` commit; report manual playtest separately.
- [ ] Commit final documentation/closeout if not already included in Phase 5.

## 5. Acceptance criteria

- `zig version` reports exactly 0.17.1 in the documented environment and CI.
- `zig fmt --check test_root.zig build.zig src tests` succeeds.
- `zig build`, `zig build run`, and `zig build test` succeed.
- Debug, ReleaseSafe, and ReleaseFast all compile and pass the complete test suite.
- The interactive REPL preserves existing input/output behavior, including oversized-line draining and I/O error propagation.
- Save V3 writer output remains byte-compatible; V3, V2, V1, and legacy fixtures still load.
- Atomic save replacement, malformed-save handling, and caller-state transactional guarantees remain intact.
- Writer-failure regression tests remain effective.
- No gameplay, economy, progression, mission catalog, command syntax, or fictional/offline boundary changes.
- CI passes on the final commit and all active docs consistently describe Zig 0.17.1.
- Full review has no unresolved Blocker or unverified migration-critical finding.

## 6. Verification matrix

| Check | Debug | ReleaseSafe | ReleaseFast |
| --- | --- | --- | --- |
| `zig build` | Pending | Pending | Pending |
| `zig build test` | Pending | Pending | Pending |
| Format check | Shared check | Shared check | Shared check |
| REPL smoke test | Pending | Pending | Pending |
| Save compatibility | Pending | Pending | Pending |

Manual playtesting is a separate check and must never be inferred from CI.

## 7. Agent handoff instructions

The next agent must:
1. Read `AGENTS.md`, `.agent/README.md`, `.agent/workflow.md`, `.agent/conventions.md`, `.agent/review-checklist.md`, this task, `docs/architecture.md`, `docs/save-format.md`, `docs/development.md`, `build.zig`, and `.github/workflows/ci.yml`.
2. Confirm current `main` head and fetch fresh contents/blob SHAs for every file before editing.
3. Use the exact Zig 0.17.1 official language reference and release notes to verify APIs. Do not infer APIs from 0.17.0, development snapshots, old examples, or memory.
4. Implement only the next unfinished phase; do not combine phases or alter gameplay/save format.
5. Update this task's progress, changed-file inventory, test evidence, and commit references after each phase.
6. Run only checks actually available; state clearly if a local Zig 0.17.1 toolchain is unavailable. CI must be inspected after push.
7. Keep all work on `main`, use focused commits, and never claim success before the host confirms it.

## 8. Progress log

### 2026-11-07 — Phase 0 audit
- Confirmed main head: `34e8938f12b6f7126eacf52403c5b468eee2a1a3`.
- Confirmed current baseline: Zig 0.13.0 in build/CI/agent docs.
- Identified build graph, process I/O, filesystem, enum conversion, test-writer, and CI migration points listed above.
- No production code, tests, or CI files changed during the audit.
- Implementation has not started; no 0.17.1 build/test result is claimed.
