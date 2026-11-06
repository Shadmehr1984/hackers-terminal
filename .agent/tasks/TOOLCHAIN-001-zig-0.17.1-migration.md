# TOOLCHAIN-001: Upgrade the Codebase to Zig 0.17.1

- Status: **Phases 0–5 implementation complete. The project and primary CI now target Zig 0.17.1; formatting, build, run smoke test, and the full aggregate suite pass in Debug/ReleaseSafe/ReleaseFast. Phase 6 documentation synchronization and full mandatory code review are in progress.**
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
- Phase 1 implementation uses a compile-time `builtin.zig_version.minor >= 17` compatibility bridge: Zig 0.17+ receives `root_module` and `addPassthruArgs`; the existing 0.13.0 CI baseline retains the legacy root fields and `b.args`/`addArgs` branch until the final toolchain pin switch. This avoids knowingly breaking the default branch during the multi-phase migration. Remove the legacy branch only when CI is switched to 0.17.1.

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

- `src/domain/mission_modifier.zig` previously reconstructed enum values from reflected field metadata. Phase 4 replaced that with explicit matching of the three stable command IDs; the test now iterates a fixed enum list. Keep `@intFromEnum` where it encodes existing bit flags or stable numeric values, and preserve those values.
- `@intFromEnum` appears in objective tracking, operation facts, equipment bit flags, save serialization, and tests. Audit each conversion and preserve stable numeric values where persisted or bit-packed.
- `std.mem`, `std.fmt`, allocator usage, and the GPA setup appear throughout the codebase. Compile-driven migration must check changed signatures and semantics, not perform blind global replacements.
- The 13 compatibility facades now expose explicit public exports and are covered by `facade_api_test_root.zig`; the focused facade test and full application compile pass under Zig 0.17.1. Array repetition syntax (`**`) was removed from `src/domain/mission_objectives.zig` using an allocation-free initializer loop. `@intFromEnum` remains supported by both toolchains in the current persisted/bit-packed conversions; do not change numeric encodings without explicit compatibility tests.
- No `std.ArrayList` usage was found in the production/test scan.
- No direct `std.process` or `std.Io` usage existed at the initial audit baseline. Phase 2 now adds a version-gated `std.process.Init` entry point and a 0.16+ `std.Io` adapter in `src/application/terminal_io.zig`.
- Compatibility facades under `src/*.zig` must continue to compile and preserve their exports. Phase 4 replaced legacy facade declarations with explicit exports; `facade_api_test_root.zig` checks their public API and the complete application now compiles with Zig 0.17.1.

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
- [x] Change executable/test root modules to the 0.17.1 module API (compile-time version-gated while 0.13 CI remains active).
- [x] Replace the 0.17+ run-argument forwarding path with `addPassthruArgs`; preserve the 0.13 compatibility path until CI is switched.
- [ ] Verify `zig build`, `zig build run`, `zig build run -- <args>`, and `zig build test` with Zig 0.17.1.
- [x] Verify the legacy compatibility branch with the still-pinned 0.13.0 CI run (CI run #1040 passed all three optimization modes).
- [x] Verify the targeted Zig 0.17.1 build-graph workflow; run #1 (`42300207973`) passed on commit `6f73764a28c916881aee4886532012c226fba0e6`.

### Phase 2 — Terminal/process I/O
- [x] Migrate the entry point and stdin/stdout to a version-gated `std.process.Init` / `std.Io` path; retain the Zig 0.13 legacy entry point while CI remains pinned. The application has no direct stderr writer in the new path; process-level error reporting remains owned by the runtime.
- [x] Preserve prompt/output call sites, EOF and newline handling, the 511-byte accepted command limit (512-byte buffer), oversized-line drain, and read/write error propagation.
- [x] Preserve generic output/failure-injection seams with `ProcessWriter.writeAll` and `.print` adapting to immediate `std.Io.File.writeStreamingAll` calls.
- [x] Add focused Zig 0.17.1 tests for 511/512-byte boundaries, newline and unterminated EOF, oversized-line draining, next-command alignment, drain read failure, and warning-output failure.
- [x] Keep cross-version input-boundary tests in `tests/test_all.zig`; keep the `std.Io`-only tests in `tests/terminal_io_test.zig` and run them only with Zig 0.17.1.
- [x] Implementation committed in focused commits, latest integration head at this phase: `7e0ed496dd02a9aadf72de9151f1daf344c0aadd`.
- [x] Verify legacy application path with Zig 0.13.0 CI run #1051 (`42301770858`): Debug, ReleaseSafe, and ReleaseFast all passed formatting, compile, tests, and agent-doc structure checks.
- [x] Verify isolated new I/O layer with Zig 0.17.1 workflow run #9 (`42301770875`): exact version check, migrated-file formatting, all seven `terminal_io_test.zig` tests, and build-graph re-evaluation passed.
- Full application compilation on 0.17.1 remains deferred until the `std.fs` persistence work in Phase 3 and language/facade compatibility work in Phase 4 are complete.

### Phase 3 — Filesystem and persistence
- [x] Introduce a version-gated `SaveContext`: Zig 0.13 carries `std.fs.Dir`; Zig 0.17.1 carries `std.Io` plus `std.Io.Dir`. Pass it explicitly from the process boundary through `main` and `game`.
- [x] Factor the V3 serializer into one generic writer function so legacy and `std.Io.Writer` backends produce identical bytes.
- [x] Migrate create-path, create/open/read/delete/rename operations to `std.Io.Dir`/`std.Io.File`; use `std.testing.io` in Zig 0.17.1 tests.
- [x] Preserve the exact `saves/player.sav.tmp` staging path, truncate behavior, flush → close → rename ordering, and error cleanup. Do not replace the explicit staging seam with `File.Atomic`, because failure-injection tests intentionally target the stable temp path.
- [x] Preserve the 4096-byte load limit, including acceptance of exactly 4096 bytes; use a 4097-byte bounded read and reject content beyond 4096.
- [x] Preserve `LoadStatus` distinctions (`missing`, `invalid`, `io_error`) and ensure parsing remains transactional.
- [x] Cross-version CI continues to test V3 replacement, staging failure, and V3/V2/V1/legacy parser compatibility. The Zig 0.17.1 save adapter suite additionally tests exact V3 bytes, round-trip, missing file, the 4096/4097-byte boundary, and staging-failure preservation.
- [x] Implementation committed on `main`; final Phase 3 source commit: `49547d4734028acb01efaf78563b106043000e31`.
- [x] Verify Zig 0.13.0 CI run #1059 (`42303650922`): Debug, ReleaseSafe, and ReleaseFast all passed format, compile, tests, and agent-doc structure checks.
- [x] Verify Zig 0.17.1 migration workflow run #15 (`42303650865`): exact version assertion, migrated-file format checks, terminal I/O tests, save I/O tests, and build-graph evaluation all passed.
- Full application compilation with Zig 0.17.1 is now verified. Running the complete aggregate test suite under 0.17.1 remains Phase 5 work.

### Phase 4 — Language and standard-library compatibility
- [x] Remove version-specific enum reflection conversion from modifier command lookup; use explicit stable command-ID matching and a fixed enum list in tests.
- [x] Resolve language/stdlib and compatibility-facade compile blockers; the complete application compiles with Zig 0.17.1.
- [x] Preserve numeric enum meanings used by flags/save encoding and verify facade exports through focused API tests.
- [x] Verify the legacy Zig 0.13.0 build and aggregate test suite in Debug, ReleaseSafe, and ReleaseFast.
- [x] Verify Zig 0.17.1 targeted formatting, terminal/save/modifier/facade tests, build graph, and full application build.
- Implementation was delivered in focused commits, including `b0c06a5a91170aaa060b20cab2f6c57d42cd3703` and `538079fa718e3fa486f11d2778365a672543f35c`.
- Zig 0.13.0 CI run `42305995360` on current main commit `538079fa718e3fa486f11d2778365a672543f35c` passed all three optimization modes, formatting, compile, aggregate tests, and agent-doc checks.
- Zig 0.17.1 migration validation run `42305965641` passed on commit `8c4ec5cd15c7bef2860923d9407f837b97ba3f49`; its Git tree (`384805b2b48a14cb47ce9fff8a3b41a9715eb702`) is identical to current main commit `538079fa718e3fa486f11d2778365a672543f35c`. It passed exact-version assertion, migrated-file formatting, terminal/save/modifier/facade tests, build-graph evaluation, and full application compilation.
- Full aggregate test-suite execution under Zig 0.17.1 remains Phase 5 work.

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
- [ ] Inspect CI for the final `main` commit after the documentation-guard correction; report manual playtest separately.
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

### 2026-11-07 — Phase 1 implementation and verification
- Changed `build.zig` to create explicit root modules for the executable and aggregate test artifact when running Zig 0.17+.
- Changed 0.17+ run argument forwarding to `addPassthruArgs()`; retained the 0.13 path conditionally so the current default-branch CI remains usable during the staged migration.
- Kept target/optimization options, install behavior, `run` step, aggregate test root, and test step dependencies unchanged.
- Official API references consulted: [Zig 0.17.1 language reference](https://ziglang.org/documentation/0.17.1/) and [official Build System guide](https://ziglang.org/intro/build-system/). The 0.17.1 build-system module shape is `root_module = b.createModule(...)`; `addPassthruArgs()` is the 0.17+ replacement for inspecting `b.args` in the build script.
- Local Zig executable is unavailable in this environment; no local compile, run, formatting, or test result is claimed.
- GitHub Actions run #1040 (`42299861705`) on commit `948c30844a6a6785254b618ff7ca8c1f69141aad` completed successfully: Debug, ReleaseSafe, and ReleaseFast each passed formatting, compile, tests, and agent-doc structure checks using Zig 0.13.0. This verifies only the legacy compatibility branch.
- Added `.github/workflows/zig-017-build-graph.yml`, a narrow workflow pinned to Zig 0.17.1. It verifies the exact toolchain version and evaluates `build.zig` with `zig build --help`; it deliberately does not claim to compile application sources before later migration phases.
- Targeted GitHub Actions run #1 (`42300207973`) completed successfully on commit `6f73764a28c916881aee4886532012c226fba0e6`: Zig 0.17.1 installed, exact version assertion passed, and `zig build --help` evaluated the build graph successfully.
- Main CI run #1041 (`42300208078`) also completed successfully on the same commit: Debug, ReleaseSafe, and ReleaseFast each passed format, compile, tests, and agent-doc structure checks using Zig 0.13.0.
- Phase 1 is closed for build-graph API validation only. Full 0.17.1 `zig build`, `zig build run`, `zig build test`, and argument-passthrough behavior remain acceptance checks for later phases/final validation. Local Zig executable remains unavailable.


### 2026-11-07 — Phase 2 terminal/process I/O
- Added `src/application/terminal_input.zig` with the shared 512-byte input-buffer capacity, 511-byte accepted line limit, and a pure overlength predicate. Added cross-version boundary tests to `tests/terminal_input_test.zig` and registered them in `tests/test_all.zig`.
- Added `src/application/terminal_io.zig` for the Zig 0.16+ `std.Io` path. `ProcessWriter` implements the existing generic `writeAll`/`print` surface and uses immediate file writes so output failures remain synchronous with transactional command handlers.
- `readLine` uses `std.Io.Reader.takeDelimiter`, rejects a 512-byte unterminated final line, drains an oversized line through its delimiter, and propagates read/write errors. It returns a dedicated `CommandDiscarded` signal only after the warning output succeeds.
- Updated `src/main.zig` with a compile-time version-gated entry point: Zig 0.13 retains the legacy stream setup; Zig 0.16+ uses `std.process.Init`, `std.Io.File.stdin().readerStreaming`, and the new output adapter. The shared game loop and command dispatch remain unchanged.
- Added seven isolated tests in `tests/terminal_io_test.zig`: 511-byte accepted line, oversized-line drain and next-command alignment, read failure during drain, output failure while reporting a discarded line, 511-byte unterminated EOF, 512-byte unterminated EOF rejection, and process stream adapter construction.
- Zig 0.17.1 workflow command: `zig test --dep terminal_io -Mroot=tests/terminal_io_test.zig -Mterminal_io=src/application/terminal_io.zig`. Direct relative imports outside the root module path are rejected by Zig 0.17; the test uses an explicit module dependency.
- CI run #1051 (`42301770858`) on commit `7e0ed496dd02a9aadf72de9151f1daf344c0aadd` passed all three Zig 0.13.0 optimization modes, including the new aggregate input-boundary tests.
- Zig 0.17.1 run #9 (`42301770875`) completed successfully: exact version assertion, migrated-file formatting, all 7 terminal I/O tests, and build-graph re-evaluation passed.
- The full Zig 0.17.1 application build has not yet been claimed. It depends on the remaining filesystem and language/facade migrations.


### 2026-11-07 — Phase 3 filesystem/persistence plan
- The filesystem API migration uses `SaveContext` rather than hidden global I/O. This keeps `std.Io` explicit in production and preserves the existing caller-supplied directory test seam.
- Serialization stays in one generic writer path. The Zig 0.13 adapter uses its existing file writer; the Zig 0.17.1 adapter uses `file.writer(io, &buffer).interface`, explicitly flushes, then closes before rename.
- The save file remains V3 with the same field order and numeric encodings. V3/V2/V1/Legacy parsing code is not redesigned.
- The existing temp filename is deliberately retained. `std.Io.File.Atomic` was considered but rejected for this phase because the tests inject staging failures by creating `saves/player.sav.tmp`; switching to an opaque atomic-file temporary would weaken that test seam and alter cleanup observability.
- The current read cap is 4096 bytes. The 0.17.1 bounded read uses `.limited(4097)` so a 4096-byte file remains valid while a 4097-byte file is rejected as `error.StreamTooLong`.
- Verified 0.17 filesystem references: Zig 0.16.0 official release notes map `std.fs.Dir` to `std.Io.Dir` and document the `rename` API; the Zig 0.17 API probe guide records `createDirPath`, `readFileAlloc`, `createFile`, `deleteFile`, and the 4,097-byte bounded-read behavior. The CI workflow will be the final authority for the exact 0.17.1 compiler.


### 2026-11-07 — Phase 3 filesystem/persistence implementation and verification
- Added version-gated `save.SaveContext`: the Zig 0.13 branch carries `std.fs.Dir`; the Zig 0.17.1 branch carries both `std.Io` and `std.Io.Dir`. `main` supplies the context and `game` passes it to persistence rather than creating hidden global I/O dependencies.
- Extracted the V3 payload writer into one generic `writeSavePayload` function shared by both toolchains. The serialized marker, positional field order, numeric values, and completion-flag order are unchanged.
- The 0.17.1 path uses `Dir.createDirPath`, `createFile`, `File.writer`, `Writer.flush`, `File.close`, `Dir.rename`, `Dir.deleteFile`, and bounded file reading. The temporary filename remains exactly `saves/player.sav.tmp`.
- The 0.17.1 reader uses `.limited(4097)` and rejects any returned data longer than 4096 bytes. This accepts a 4096-byte file for validation (status `invalid` when malformed) and reports a 4097-byte file as `io_error`.
- Updated operation/equipment save tests to construct a `SaveContext` from the caller-supplied temporary directory. Added `tests/save_test_support.zig` for cross-version filesystem test helpers.
- Added `tests/save_io_test.zig` and root-scoped harness `save_io_test_root.zig` because Zig 0.17 module path restrictions reject a named module rooted at `src/persistence` importing its sibling `../domain` files. The harness keeps the actual tests under `tests/` while giving the module root the repository root.
- The Zig 0.17.1 save adapter tests verify exact V3 bytes, write/read round-trip, missing-save status, 4096/4097-byte read boundaries, and that a staging failure leaves the previous save intact.
- A minimal Phase 4 syntax prerequisite was pulled forward: `mission_objectives.zig` no longer uses array repetition `**`; it initializes its fixed array with a small loop, preserving allocation-free behavior and Zig 0.13 compatibility.
- Cross-version enum serialization still uses `@intFromEnum`, which compiles under both toolchains. The targeted 0.17 formatter check intentionally excludes shared files that Zig 0.17 would rewrite to `@backingInt`; final formatting migration belongs in Phase 4/5 after the default toolchain switch.
- CI run #1059 (`42303650922`) on the Phase 3 head passed all Zig 0.13.0 modes. Zig 0.17.1 run #15 (`42303650865`) passed all targeted terminal/save tests, formatting checks for migrated files, and build-graph evaluation.
- Full application build under 0.17.1 remains pending until the compatibility facades and remaining language/stdlib blockers are resolved.


### 2026-11-07 — Phase 4 language/facade compatibility
- Replaced modifier lookup's reflected enum-to-integer conversion with explicit matching of the three stable command IDs. The modifier test now uses a fixed enum list for bonus/description assertions.
- Confirmed the compatibility facade exports through the isolated facade API test; the complete application now compiles under Zig 0.17.1.
- Kept `@intFromEnum` in existing equipment bit flags, objective kinds, operation facts, and save serialization. Both Zig 0.13.0 and 0.17.1 compile these uses; preserve their numeric meanings.
- The earlier Zig 0.17.1 formatting/test failure was traced to an accidentally duplicated `builtin` import and stale reflected-enum test block. The test was corrected and the targeted 0.17.1 workflow passed on a Git tree identical to current `main`.
- Current main: `538079fa718e3fa486f11d2778365a672543f35c`; tree: `384805b2b48a14cb47ce9fff8a3b41a9715eb702`.
- Zig 0.13.0 CI run `42305995360`: all three optimization modes passed formatting, compile, aggregate tests, and agent-doc validation.
- Zig 0.17.1 validation run `42305965641`: exact version, targeted formatting, terminal/save/modifier/facade tests, build graph, and full application compilation passed.
- Phase 4 is complete. Next is Phase 5: run the complete aggregate suite under Zig 0.17.1, migrate test infrastructure as needed, and switch primary CI to 0.17.1 only after all acceptance checks pass.
