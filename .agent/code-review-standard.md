# Mandatory Full-Codebase Code Review Standard

**Status:** Mandatory for every code review of this repository  
**Toolchain:** Zig 0.13.0  
**Scope:** Entire current repository unless the owner explicitly narrows it  
**Default mode:** Analysis-only. A review does not authorize edits, fixes, refactors, commits, merges, or PRs.

This is the canonical, exhaustive standard for every human or AI agent reviewing Hacker's Terminal. Read it completely before reviewing. Do not substitute a generic checklist, sample only selected files, or silently omit a category.

## 1. Non-negotiable rules

1. Review the entire in-scope repository: production code, compatibility facades, tests, build configuration, CI, scripts, documentation, and agent instructions. Trace imports, callers, state, and data flow across module boundaries.
2. Analysis-only unless the owner separately authorizes changes. Do not edit, reformat, fix, commit, branch, merge, or open a PR during a review.
3. Never guess. Separate source-confirmed facts, hypotheses, and unknowns. Disclose every unavailable/unread/unexecuted item as NOT VERIFIED.
4. Every confirmed finding must include exact repository-relative path and line/range, observed behavior, a concrete trigger, impact, severity, and recommendation. If a line cannot be established, classify as NEEDS-VERIFICATION, not a confirmed bug.
5. Every criterion below must be dispositioned: PASS, FINDING, NOT APPLICABLE (with reason), or NOT VERIFIED. An omitted criterion means an incomplete review.
6. Distinguish defects from known constraints, accepted decisions, stale documentation, missing tests, and open questions. Read known issues and relevant ADRs first.
7. Respect project constraints: Zig 0.13.0; fictional/local/offline-only gameplay; Save V3 writer and V2/V1/legacy readers; runtime-only mission/operation state; thin compatibility facades; tests under tests/; preserve test_root.zig and tests/test_all.zig roles.
8. Never recommend real networking, shell execution, host interaction, credential collection, or external-system behavior.
9. Never infer passing builds/tests/format/CI/playtests from source inspection or a pushed commit. Report only actual results.
10. Use current main unless another ref is explicitly requested. Record exact HEAD SHA and review date.
11. Do not hide a real issue because it is rare; explain likelihood and impact. Do not inflate severity or report preferences as defects.
12. Final report and criterion-by-criterion coverage matrix are mandatory.

## 2. Required procedure

### Phase 0 — Preparation (before source review)

Read and report each:
- AGENTS.md
- .agent/README.md
- .agent/workflow.md
- .agent/conventions.md
- .agent/review-checklist.md
- .agent/known-issues.md
- Relevant .agent/decisions/ ADRs
- Relevant .agent/tasks/ briefs and handoffs
- docs/architecture.md and docs/save-format.md
- Relevant gameplay, commands, development, and user documentation
- build.zig, test_root.zig, tests/test_all.zig, CI workflows

Establish and report:
- Current branch/ref and exact HEAD commit.
- Actual repository tree and all in-scope source/test/build/script/doc files.
- Zig version, available tools, and whether execution is possible.
- Build/test/CI state only from actual command/workflow results.
- Every file/tool/output that was unavailable or truncated.

Do not rely on stale inventories or summaries; the checked-out repository is authoritative.

### Phase 1 — Top-down repository map and trace

1. Inventory every relevant file and classify it (entry point, domain, application, catalog, presentation, persistence, facade, test, build, CI, script, docs).
2. Start at src/main.zig; trace imports, composition, allocator ownership, I/O, and interactive loop.
3. Trace every command through parsing, validation, domain transition, persistence, and terminal output.
4. Trace state creation/mutation/read/serialization across module boundaries.
5. Trace save/load from bytes through parsing, validation, migration, state mutation, and write/replace failure handling.
6. Trace cross-module/public functions to all callers and tests; inspect all tests and aggregate registration.
7. Inspect build options, target/optimization modes, CI, dependency/action pinning, and docs checks.
8. Compare implementation, tests, docs, ADRs, known issues, and task handoffs for drift.

### Phase 2 — Five-pass review and weighted dimensions

All five passes are mandatory and in order. Weights guide attention; they do not permit skipping.

| Dimension | Weight |
|---|---:|
| Correctness and behavior | 40% |
| Security, including OWASP Top 10:2025 | 20% |
| Architecture and design | 30% |
| Performance and resource behavior | 10% |

Zig-specific/common-bug checks, maintainability/observability, and project invariants are additional mandatory cross-cutting scans.

**Pass A — Correctness (40%)**
- Expected behavior, contracts, invariants, state transitions, return values, side effects.
- Success, rejection, partial failure, retry, cancellation, repeated-call, and recovery paths.
- Arithmetic, indexing, bounds, parsing, serialization, migration, ordering, and consistency.
- Test quality, branch coverage, and untested integration paths.

**Pass B — Security (20%)**
- Assess every OWASP Top 10:2025 category in Section 5.
- Treat save files, command input, catalog-derived data, CI, and dependency inputs as trust boundaries where applicable.
- Respect the offline threat model; mark genuinely inapplicable categories with reasons.

**Pass C — Architecture (30%)**
- Responsibility boundaries, dependency direction, cohesion/coupling, public APIs, compatibility facades, state ownership.
- Domain independence from terminal I/O, persistence, and high-level dispatch.
- Whether types/error boundaries make invalid states difficult to represent.

**Pass D — Performance (10%)**
- Allocation frequency/ownership, copies, container growth, repeated scans, complexity, I/O, worst-case behavior.
- Fixed-capacity structures and maximum valid inputs.
- No speculative micro-optimization; request profiling when static evidence is insufficient.

**Pass E — Maintainability and observability**
- Naming, readability, comments/doc comments, duplication, module size, diagnostics, output, testability, documentation, diagnosability.
- Errors should be distinguishable and surfaced without leaking secrets or corrupting state.
- Comments/docs must describe current behavior.

### Phase 3 — Zig scan order (exact and mandatory)

For every Zig file, follow exactly:
1. zig fmt / formatting
2. ALWAYS FLAG scan
3. Safety
4. Context-dependent patterns
5. Style

Do not reorder or collapse these passes. Record each in the final matrix.

#### 3.1 Formatting
- Check Zig 0.13.0 formatting using `zig fmt --check test_root.zig build.zig src tests`, or state why not run.
- Inspect malformed formatting, indentation, whitespace, malformed container literals, and formatting that obscures control flow.
- Do not reformat files during analysis-only review.

#### 3.2 ALWAYS FLAG — inspect and disposition every occurrence

“ALWAYS FLAG” means every occurrence must be explicitly examined and dispositioned; it does not mean every occurrence is automatically a defect. Explain safe/intentional uses.

- `@intCast`, `@truncate`, `@enumFromInt`, `@floatFromInt`, `@intFromFloat`, and narrowing/conversion casts.
- Optional unwraps: `.?`, `orelse unreachable`, optional pointer/value assumptions.
- `catch unreachable`, `unreachable`, `@panic`, `std.debug.panic`, runtime assertions on user-controlled data.
- Returning/storing pointers or slices to locals, temporaries, invalidated buffers, or expired lifetimes.
- Taking addresses of packed struct fields; alignment/layout assumptions.
- Flush/write/close operations and ignored I/O errors; output flush ordering and persistence durability assumptions.
- `root_source_file` and build API usage. **For Zig 0.13.0, `root_source_file` is valid; do not flag it merely because newer Zig versions changed the build API.**
- Container literals, inferred array/slice types, sentinel termination, alignment, compile-time/runtime type assumptions.
- `getOrPut`, map insertion, hash-map mutation, reference use after insertion, pointer invalidation after growth.
- `std.heap.DebugAllocator` / testing allocator setup, allocator lifetime, deinit, and leak-check assumptions.
- Build target, CPU, ABI, optimize-mode, and standard build-option selection; verify what CI actually builds.
- `@memcpy`, `@memset`, slicing, pointer casts, alignment casts, length/byte-count assumptions.
- `ArrayList`, unmanaged containers, hash maps, allocators, allocating operations, and reference invalidation.
- `defer`, `errdefer`, `try`, `catch`, and cleanup/error-path interactions.
- Fixed-size arrays, capacity constants, counters, and conversions between capacity/index/count types.
- Integer arithmetic on bounded or externally influenced values: increment, decrement, multiply, add, subtract, reward accumulation.

For every occurrence, prove range/lifetime/error safety from code. A nearby comment is not proof.

#### 3.3 Safety pass
- Exception/error safety: fallible operations, partial mutation, cleanup on every exit.
- Allocation failure: ownership, leaks, double-free, use-after-free, state consistency at each failure point.
- Pointer/slice lifetime and invalidation, including container growth/reallocation and returned references.
- Integer overflow/underflow, signedness, narrowing, sentinel, and size calculations.
- User-controlled/corrupted input reaching unreachable, panic, unchecked casts, indexing, or assumptions.
- Fixed buffers: overflow, truncation, silent clipping, terminators, length tracking.
- Arena reset/deinit: no retained pointer/slice survives reset; correct nested lifetimes.
- defer/errdefer/try cleanup order; no early release or missed release.
- Runtime safety and differences among Debug, ReleaseSafe, ReleaseFast.
- FFI/extern/C ABI, raw pointers, alignment, ownership, calling convention, foreign errors, if present.
- File operations: partial writes, close/flush errors, temp files, rename semantics, prior-data preservation.
- Concurrency/thread safety if present; otherwise explicitly N/A.
- Untrusted save parsing: bounds, markers/versions, numeric conversion, malformed/truncated data, validation before live mutation.

#### 3.4 Context-dependent pass
Inspect where present and explain whether context justifies:
- inline, comptime, generic functions, compile-time evaluation, code-size effects.
- Unions/tagged unions, enum ordinals, exhaustive switches, invalid tags.
- anytype, anyopaque, type erasure, reflection-like patterns, casts.
- Global mutable state, singleton-like state, shared mutable references, hidden dependencies.
- Allocator passing/selection, arena vs page/general allocator, ownership contracts.
- Error-set design, anyerror, error translation, swallowed errors.
- Container choice, preallocation, capacity limits, iteration invalidation, complexity.
- Recursion, loops, nested scans, worst-case input size.
- Logging/terminal output and error propagation.
- Build options, target-specific code, conditional compilation, platform assumptions.
- Tests using mocks/fakes or bypassing actual integration paths.
- Compatibility facades, shims, deprecation, migration.

#### 3.5 Style pass
- Naming clarity/consistency for types, functions, variables, constants, files, tests.
- Single-purpose functions, readable control flow, no excessive nesting or clever one-liners.
- Prefer explicit, concrete Zig over speculative abstractions.
- Comments/doc comments explain intent, contracts, invariants, ownership, non-obvious decisions; remove stale/redundant comments.
- Consistent error names and meaningful error boundaries.
- Avoid duplicated policy/constants and magic numbers.
- Focused imports/module APIs; no unused code or accidental public surface.
- Tests readable, deterministic, isolated, behavior-named.

### Phase 4 — Findings and final report

Severity labels:
- **BLOCKER** — demonstrable severe correctness/security/data-loss issue; affected code must not be considered safe to ship.
- **HIGH** — significant bug, security weakness, compatibility break, or invariant violation with credible scenario.
- **MEDIUM** — meaningful defect, robustness gap, or missing protection/test likely to matter under plausible conditions.
- **LOW** — limited-impact issue, edge-case robustness, maintainability or observability weakness.
- **SUGGESTION** — non-defect improvement or defense in depth.
- **NIT** — minor clarity/style issue without material behavior impact.
- **NEEDS-VERIFICATION** — credible concern that cannot be confirmed; state exact missing evidence.

Do not inflate severity. A missing test is not automatically a runtime bug. A known issue is not new unless a new impact/status is identified.

Every finding must contain:
1. ID and severity.
2. Exact file path and line/range.
3. Relevant function/type and call path.
4. What is wrong or why verification is needed.
5. Concrete triggering input/state/scenario.
6. Consequence and affected invariant/trust boundary.
7. Why current tests/checks do not prevent it.
8. Specific remediation direction (not an unapproved patch).

Final report must contain:
1. Review identity: repository, ref/branch, exact commit SHA, date, scope.
2. Executive summary: overall risk, key conclusion, blocker status.
3. Phase 0 evidence: each document read and every unavailable file/tool.
4. Coverage inventory: counts of source, test, build, script, workflow, docs actually inspected; exclusions.
5. Findings table: ID, severity, file/line, title, status.
6. Detailed findings with all required fields.
7. BLOCKER priority and rationale; “None found” only when supported by full scan.
8. NEEDS-VERIFICATION and exact evidence required.
9. Criterion coverage matrix: every section/pass/category/item marked PASS, FINDING, NOT APPLICABLE, or NOT VERIFIED. No broad row hiding unchecked sub-items.
10. Positive observations with evidence where useful.
11. Verification results: exact commands, toolchain, results, CI URL/commit, manual-playtest status; separate local and CI.
12. Statistics: findings by severity; inspected/in-scope files; passed/N/A/not-verified checks.
13. Limitations: inaccessible files, truncated output, missing tools, unavailable runtime, unrun tests, no independent reviewer.
14. Ordered recommendations. Do not implement without explicit authorization.

## 3. Correctness checklist (40%)

- [ ] Preconditions and postconditions are enforced.
- [ ] State transitions are valid, ordered, and cannot skip required stages.
- [ ] State changes occur only after all required computations/operations succeed (atomicity).
- [ ] Failure paths do not leave partial or contradictory state.
- [ ] Repeated calls are idempotent where required; rewards/side effects cannot duplicate.
- [ ] Retry, reset, cancel, disconnect, replay, recovery are coherent.
- [ ] Boundaries: zero, one, max, max+1, empty, missing, malformed, truncated.
- [ ] Indexes, lengths, capacities, counters, offsets validated before use.
- [ ] Arithmetic cannot overflow/underflow or wrap in supported modes.
- [ ] Parsing handles/rejects extra tokens, whitespace, empty fields, invalid encodings, malformed values.
- [ ] Return values/errors accurately represent outcomes; no swallowed errors.
- [ ] Ordering deterministic where gameplay, saves, or tests depend on it.
- [ ] No stale pointer/slice/reference after mutation or deallocation.
- [ ] Resource acquisition/cleanup balanced on success and every failure.
- [ ] Persistence load validates fully before mutating live state.
- [ ] Persistence write failure preserves previous valid save.
- [ ] Migration defaults/compatibility correct for every supported version.
- [ ] Tests cover normal, invalid, boundary, failure, regression, integration.
- [ ] Tests exercise actual public/application path, not only helper shortcuts.
- [ ] No nondeterminism, hidden environment dependency, or test-order coupling.

## 4. Architecture checklist (30%)

- [ ] Each module has coherent responsibility and ownership boundary.
- [ ] Dependencies one-way; no circular imports or domain-to-application/presentation dependency.
- [ ] main.zig remains a thin composition root.
- [ ] Domain rules independent of terminal I/O, persistence, and command dispatch.
- [ ] Presentation renders; it does not mutate state or decide rewards.
- [ ] Persistence serializes; it does not own gameplay policy.
- [ ] Static catalog definitions separate from mutable runtime/session state.
- [ ] Runtime-only and persistent state clearly distinguished.
- [ ] Public APIs intentional, minimal, documented, compatible.
- [ ] Compatibility facades thin and preserve expected import paths.
- [ ] Types encode valid states; tagged unions/enums used when they clarify state.
- [ ] Static dispatch preferred over runtime indirection when dynamic behavior is unnecessary.
- [ ] Options structs considered for growing related parameter sets; avoid long positional lists.
- [ ] Allocator ownership/lifetime explicit at API boundaries.
- [ ] Error sets communicate expected failures; unjustified anyerror avoided.
- [ ] Shared policy/constants/numeric rules have one source of truth.
- [ ] Abstractions justified by actual reuse/variation, not speculative future needs.
- [ ] Changes focused; unrelated refactors absent.
- [ ] Docs, ADRs, module contracts match architecture.

## 5. Security checklist — OWASP Top 10:2025 (20%)

Assess all ten categories. Local/offline design can make a category N/A, but explain why and still inspect relevant local trust boundaries.

### A01 — Broken Access Control
- [ ] Validate command permissions, progression gates, mission/operation stage gates, hidden-objective visibility.
- [ ] Lower-level mutation paths cannot bypass authoritative application validation.
- [ ] Locked content, hidden clues/rewards, Contact services cannot be accessed early.
- [ ] File/path access limited to intended save locations; reject traversal or arbitrary path influence if user-controlled.

### A02 — Security Misconfiguration
- [ ] Build flags, optimization modes, Debug/Release behavior, unsafe runtime options, production defaults.
- [ ] File permissions, save locations, temporary-file handling, accidental sensitive output.
- [ ] CI permissions, triggers, secrets exposure, least privilege.
- [ ] Debug-only assumptions and unsafe release defaults.

### A03 — Software Supply Chain Failures
- [ ] Inventory dependencies, Zig toolchain acquisition, GitHub Actions, scripts, downloaded tools.
- [ ] Mutable action tags vs immutable commit-SHA pinning.
- [ ] Dependency provenance, version pinning, update policy, integrity verification.
- [ ] Workflow permissions, third-party action trust, untrusted PR code exposure.
- [ ] Missing audit mechanisms reported as gaps, not fabricated vulnerabilities.

### A04 — Cryptographic Failures
- [ ] Identify secrets, tokens, credentials, sensitive save data, cryptographic operations, if any.
- [ ] Sensitive data not stored/emitted in plaintext where protection is required.
- [ ] Randomness requirements and cryptographic API selection, if crypto exists.
- [ ] If no secrets/crypto exist, state limited applicability; do not invent crypto requirements.

### A05 — Injection
- [ ] Command parsing: command/argument confusion, delimiter injection, unsafe interpretation.
- [ ] No user-controlled text reaches shell, OS commands, SQL, interpreters, format strings, external processes.
- [ ] Terminal escape/control sequences and untrusted output rendering.
- [ ] Fictional hostnames/actions remain data and cannot trigger real network/host operations.

### A06 — Insecure Design
- [ ] Threat assumptions/trust boundaries, especially untrusted saves and command input.
- [ ] Validation at authoritative layer, not only presentation.
- [ ] Fail-safe defaults, bounded resources, abuse-resistant transitions, reward/economy invariants.
- [ ] Hidden content, progression gates, replay/retry bypasses.
- [ ] Important security assumptions documented and tested.

### A07 — Authentication Failures
- [ ] Determine whether real authentication/credential handling exists.
- [ ] Fictional in-game authentication isolated from real credentials/external services.
- [ ] Secret/key comparison, retry behavior, information disclosure within game mechanics.
- [ ] If no real identity/authentication surface, mark N/A with rationale.

### A08 — Software or Data Integrity Failures
- [ ] Save files untrusted; validate markers, versions, lengths, numeric ranges, semantic invariants.
- [ ] Parsing/migration handles malformed, truncated, oversized, tampered data.
- [ ] Writes: staging, flush/close, atomic replacement assumptions, prior-save preservation.
- [ ] Build/release artifact provenance and CI integrity.
- [ ] Serialized data cannot create impossible states or bypass progression/rewards.

### A09 — Security Logging and Alerting Failures
- [ ] Security-relevant failures/integrity errors distinguishable and diagnosable.
- [ ] Diagnostics do not leak secrets/sensitive data.
- [ ] Swallowed/generic errors do not hide corrupt saves, failed writes, state violations.
- [ ] Local single-player limits of applicability explicitly stated.

### A10 — Mishandling of Exceptional Conditions
- [ ] Allocation/I/O failures, malformed input, invalid states, overflow, unexpected enum/tag values.
- [ ] Panic/unreachable paths reachable from user/save data.
- [ ] Cleanup, rollback, atomicity, valid-state preservation after errors.
- [ ] Debug, ReleaseSafe, ReleaseFast behavior.
- [ ] Errors surfaced accurately; no silent degradation into success.

## 6. Performance/resource checklist (10%)

- [ ] Complexity of loops, graph traversal, lookup, parsing, repeated catalog scans.
- [ ] Repeated allocations and bounded/preallocated storage opportunities.
- [ ] Copies of large structs, arrays, slices, strings.
- [ ] Container growth and rehash costs.
- [ ] Allocation lifetime and allocator choice match data lifetime.
- [ ] I/O frequency, buffering, flush frequency, redundant serialization.
- [ ] Fixed-capacity structures safe and efficient.
- [ ] Worst-case maximum valid input/catalog/save sizes.
- [ ] Accidental quadratic behavior/repeated work inside loops.
- [ ] Profiling/benchmarking requested where static evidence cannot establish impact; no invented measurements.

## 7. Zig language and design checklist

### Naming and API
- [ ] Types/functions/variables/constants/files use clear consistent Zig naming.
- [ ] Names communicate domain meaning and units (count/index/bytes/time).
- [ ] Public declarations have doc comments describing behavior/contracts.
- [ ] Functions focused; parameter count reasonable.
- [ ] Options structs considered for multiple related configuration parameters.
- [ ] Tagged unions/enums model mutually exclusive states; avoid parallel booleans where appropriate.
- [ ] Static dispatch used when dynamic dispatch is unnecessary.
- [ ] Public API surface minimal and compatibility preserved.

### Memory and ownership
- [ ] Allocator explicit for allocation-capable operations.
- [ ] Ownership/deallocation responsibility clear.
- [ ] No leaks, double frees, use-after-free, dangling pointers, invalid slices.
- [ ] No retained references across container reallocation or arena reset.
- [ ] defer/errdefer correctly paired and ordered.
- [ ] Allocation failures handled according to API contract.
- [ ] No hidden allocation in code expected to be allocation-free.
- [ ] Fixed buffers/capacities checked before writes/appends.

### Errors and control flow
- [ ] Explicit error unions (!T) and try for fallible operations.
- [ ] Specific error sets where practical; no unjustified anyerror.
- [ ] No swallowed errors or failures converted into success.
- [ ] No unreachable/panic/assert for malformed/user/save-controlled input.
- [ ] Error handling preserves state and releases resources.
- [ ] Diagnostics useful and do not disclose sensitive data.
- [ ] catch unreachable only where impossibility is structurally proven.

### Idioms and patterns
- [ ] Prefer standard library containers/idioms over custom structures without concrete reason.
- [ ] Tagged unions for variants; exhaustive switches for closed sets.
- [ ] Avoid anytype/generic abstraction unless materially useful.
- [ ] Avoid unnecessary heap allocation and runtime polymorphism.
- [ ] Avoid magic numbers and duplicated domain policy.
- [ ] Compile-time features improve correctness/performance/clarity.
- [ ] Enum conversions and integer casts have explicit bounds/validation.

### Structure/build
- [ ] Build API matches Zig 0.13.0; no newer-version assumptions.
- [ ] root_source_file is valid for Zig 0.13.0 and is not itself a defect.
- [ ] Target/optimize options explicit enough; report modes CI actually tests.
- [ ] build.zig and test_root.zig retain required roles.
- [ ] Production implementation stays in responsibility-based src/ groups; facades stay thin.
- [ ] Tests remain under tests/; aggregate registration remains tests/test_all.zig.
- [ ] Imports follow one-way dependency direction.
- [ ] No accidental dependencies, generated artifacts, machine-specific paths.

### Testing
- [ ] std.testing.allocator used for leak detection where appropriate.
- [ ] Failing allocators/test allocators cover allocation failure paths where relevant.
- [ ] std.testing.expectError used for expected errors; exact observable state asserted.
- [ ] Boundary, invalid, retry, idempotency, and failure cases tested.
- [ ] Tests deterministic, isolated, independent of external systems.
- [ ] Integration tests exercise real dispatch/serialization boundaries, not only helpers.
- [ ] New test modules registered in tests/test_all.zig.
- [ ] Test names explain behavior and regression intent.

### Anti-patterns
- [ ] No unnecessary anyerror, catch {}, ignored errors, broad catches hiding defects.
- [ ] No unreachable/panic on untrusted/external data.
- [ ] No unchecked casts or arithmetic outside proven bounds.
- [ ] No stale pointers/slices after append, realloc, deinit, arena reset.
- [ ] No incorrect defer/errdefer lifetime or cleanup ordering.
- [ ] No fixed-buffer write without capacity/length validation.
- [ ] No unnecessary allocation/copy/global mutable state/hidden allocator.
- [ ] No cyclic imports, god modules, speculative abstraction layers.
- [ ] No tests merely duplicating implementation or bypassing important public paths.

## 8. Hacker's Terminal project-specific checklist

### Product/threat boundary
- [ ] All hacking, hosts, credentials, scans, network effects are fictional/simulated.
- [ ] No real network, sockets, host probing, shell/subprocess execution, external-system interaction.
- [ ] No real credential collection/storage/transmission.
- [ ] Command input and save contents treated as untrusted.
- [ ] Untrusted terminal output cannot execute/expose host control sequences.

### Architecture/module boundaries
- [ ] src/main.zig is a thin composition root.
- [ ] src/domain/ contains foundational rules/data and does not depend on high-level application/presentation.
- [ ] src/application/ coordinates domain behavior without owning unrelated parsing/rendering.
- [ ] src/catalog/ contains static authored data, not mutable session state.
- [ ] src/presentation/ renders and does not decide/mutate gameplay rules.
- [ ] src/persistence/ owns serialization/compatibility, not gameplay policy.
- [ ] Legacy top-level src/*.zig files remain compatibility facades.
- [ ] No circular imports or reverse dependency into game.zig.

### Gameplay invariants
- [ ] Mission progression cannot skip: inactive → accepted → scanned → authenticated → decrypted.
- [ ] Connection status independent of completed stages; disconnect does not erase valid progress.
- [ ] Repeated successful authentication/decryption is idempotent and does not re-evaluate wrong secrets or add Detection.
- [ ] Mission completion requires all required objectives; hidden objectives optional and never gate completion.
- [ ] Hidden objective descriptions/rewards do not leak before discovery.
- [ ] Objective identity is stable mission-local ID, not enum ordinal/event-kind identity.
- [ ] Objective tracker fixed-capacity 32 and allocation-free; duplicate/empty IDs, invalid hidden definitions, over-capacity catalogs fail safely.
- [ ] Optional-objective rewards and all-objectives Reputation bonus applied exactly once under specified rules.
- [ ] Detection bounded 0–100, centralized, compromise/failure applies documented capped penalty/reset/retry behavior.
- [ ] Modifier/utility effects use launch-time session snapshots, not live equipment/preparation.
- [ ] Modifier rewards and mission payouts cannot duplicate through re-entry/replay.
- [ ] Operations static/linear, max eight stages; stage facts/state runtime-only.
- [ ] Operation facts granted only after successful stage completion.
- [ ] Saving during active operation writes no active mission index; restart begins stage one without transient facts.
- [ ] Topology movement only to adjacent nodes; invalid movement changes neither position nor Detection.
- [ ] Successful traversal applies base/equipment/modifier costs in documented order.
- [ ] Scan/authentication/decryption/analysis/extraction restricted to authored mission nodes.
- [ ] Topology position and traversal count runtime-only.

### Persistence/compatibility
- [ ] Save V3 writer remains current unless migration explicitly approved.
- [ ] V2, V1, legacy readers remain supported.
- [ ] Positional field order, version markers, defaults, save path, compatibility unchanged incidentally.
- [ ] Unknown non-numeric markers rejected before mutating player/session state.
- [ ] Older saves migrate with documented defaults; old three-mission completion arrays handle appended fourth mission safely.
- [ ] Static mission/objective/operation catalog data and runtime-only session/operation state are not serialized.
- [ ] Save files fully validated before live state mutation.
- [ ] Save replacement stages complete payload and preserves previous valid save on failure.
- [ ] Loaded numeric values range-checked against machine bounds and logical game constraints.

### Build/tests/docs/workflow
- [ ] Zig 0.13.0; no false positives from newer compiler assumptions.
- [ ] zig fmt --check test_root.zig build.zig src tests checked or marked not run.
- [ ] zig build and zig build test (or documented direct test command) checked or marked not run.
- [ ] CI inspected for exact reviewed commit; default Debug CI not described as ReleaseSafe/ReleaseFast coverage.
- [ ] ReleaseSafe/ReleaseFast gaps reported where relevant.
- [ ] sh scripts/check-agent-docs.sh checked or marked not run.
- [ ] README, architecture, gameplay, commands, save-format, development, ADR, task handoff, agent docs checked for drift.
- [ ] known-issues.md checked so known constraints are not mislabeled as new defects.
- [ ] Local inability to build distinguished from CI status; manual playtesting reported separately.

## 9. Completion gate

A review is INCOMPLETE if:
- Any in-scope file/category/pass silently skipped.
- Phase 0 documents not read or missing documents not disclosed.
- Exact reviewed commit not recorded.
- A confirmed finding lacks path and line reference.
- ALWAYS FLAG scan not dispositioned item by item.
- Any OWASP Top 10:2025 category omitted.
- Zig scan order not followed.
- Criterion coverage matrix missing.
- Unrun tests/CI/manual playtests represented as passing.
- Analysis-only scope violated without explicit authorization.

If the repository is too large for one pass or tool output is truncated, split into enumerated batches and continue until all are covered. Report completed and remaining batches; never label a partial scan as a full review.
