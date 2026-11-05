# Comprehensive Code Review Standard

> **Mandatory for every coding agent and human reviewer.** This is the canonical, exhaustive review standard for Hacker's Terminal. Do not treat it as an optional checklist or select only the convenient sections. Every review must account for every applicable item below, explicitly mark non-applicable items with a reason, and record anything that could not be verified as `NEEDS-VERIFICATION`.

## 1. Purpose, authority, and review modes

This document defines the required review method for the entire repository and for focused change reviews.

- **Full repository review:** inspect the complete current codebase, tests, build configuration, CI workflows, and relevant documentation. A diff-only review is not sufficient.
- **Change review:** inspect the complete diff and trace every changed behavior through its callers, dependencies, tests, persistence effects, and relevant invariants. Inspect adjacent code where needed to establish correctness.
- Read `AGENTS.md`, `.agent/README.md`, `.agent/conventions.md`, `.agent/known-issues.md`, this checklist, relevant ADRs/task handoffs, `docs/architecture.md`, and `docs/save-format.md` before reviewing. Read gameplay/command/development documentation when relevant.
- Verify the current branch, commit, source tree, and toolchain. Do not rely on old review reports or stale summaries as evidence of current state.
- Review is read-only unless the owner separately authorizes fixes. A request to review is not permission to edit, refactor, commit, or merge.
- Never guess. If source, test output, or environment evidence is unavailable or ambiguous, state **"نمی‌دانم"** / unknown and classify the item as `[NEEDS-VERIFICATION]` where appropriate.
- Inspect all relevant files. If a file cannot be retrieved, is truncated, generated, binary, or otherwise not fully readable, name it and explain the resulting coverage limitation. Never imply that unreadable code was reviewed.
- Every finding must include the exact repository path and line range from the reviewed commit. Recheck line numbers against that commit before reporting.
- Explain why each finding matters, the triggering conditions, the concrete impact, and a practical remediation. Reference a standard, invariant, or code path where useful.
- Do not report speculative vulnerabilities as confirmed findings. Separate confirmed defects, risks requiring verification, and improvement suggestions.

## 2. Mandatory review sequence

Follow this sequence. Do not silently omit or reorder the focused review passes.

1. **Preparation:** establish repository, branch, commit SHA, toolchain, scope, and review mode; read the mandatory project documents; identify known issues and accepted design decisions.
2. **Top-down repository understanding:** inspect the repository tree, build configuration, entry point, imports/dependency direction, module boundaries, tests and test aggregator, persistence, terminal I/O, and CI. Build a source-to-test/ownership map before drawing architectural conclusions.
3. **Focused review passes, in this order and with these weights:**
   - Correctness — **40%**
   - Security (OWASP Top 10:2025) — **20%**
   - Architecture and Design — **30%**
   - Performance — **10%**
4. **Zig-specific scan**, in this exact order:
   1. `zig fmt`
   2. **ALWAYS FLAG**
   3. **Safety**
   4. **Context-dependent**
   5. **Style**
5. **Maintainability and Observability** cross-cutting pass.
6. **Tests and CI verification:** inspect test quality and actual workflow results; distinguish local execution, CI execution, and static inspection.
7. **Report and coverage accounting:** produce the required report, prioritized findings, explicit limitations, and category/file coverage statistics.

The four percentages are review-effort priorities, not a formula for diluting a critical defect. A single exploitable or state-corrupting defect can be a BLOCKER regardless of the weighted totals. Maintainability/Observability and Zig-specific checks are additional mandatory passes, not extra weighted categories.

## 3. Correctness — 40%

Inspect every applicable item:

- [ ] Requirements and acceptance criteria: behavior matches the accepted specification; no unapproved scope or behavior change.
- [ ] Control flow: all success, rejection, cancellation, retry, timeout/end-of-input, and failure paths behave consistently.
- [ ] State transitions: valid transitions are enforced; invalid transitions cannot skip prerequisites or partially mutate state.
- [ ] Invariants: identify and test preconditions, postconditions, class/module invariants, ordering constraints, idempotency, and cross-module assumptions.
- [ ] Boundary conditions: zero, one, maximum, maximum-plus-one, empty, missing, duplicate, malformed, and out-of-range values.
- [ ] Integer arithmetic: overflow, underflow, truncation, signedness, widening/narrowing, sentinel values, and cumulative counters.
- [ ] Parsing and serialization: malformed, truncated, extra, missing, reordered, and unsupported input; validate before mutating live state.
- [ ] Error propagation: errors are neither silently swallowed nor converted into success; cleanup and rollback behavior are correct.
- [ ] Atomicity: multi-step operations do not leave partial state when a later calculation, allocation, write, or validation fails.
- [ ] Resource lifecycle: files, readers/writers, allocations, and other acquired resources are released on every path.
- [ ] Determinism: repeated calls and retries do not unexpectedly duplicate rewards, effects, events, or mutations.
- [ ] Compatibility: public APIs, command syntax, gameplay, persisted data, and documented behavior remain compatible unless a change was explicitly approved.
- [ ] Tests: meaningful assertions cover normal behavior, rejection paths, failure injection, boundaries, regressions, and state invariants.
- [ ] Trace important functions from callers through callees and back to observable output/state; do not inspect isolated functions only.

For each suspected defect, establish a concrete input/state sequence that triggers it. If that sequence cannot be established from available evidence, use `[NEEDS-VERIFICATION]`, not a definitive bug claim.

## 4. Security — 20% — OWASP Top 10:2025

Use the **final OWASP Top 10:2025** categories below as a threat-review lens. Assess applicability to this local/offline Zig game; do not invent web-server, authentication, or network attack surfaces that do not exist. Mark a category not applicable only after checking the actual code and explain why.

- [ ] **A01:2025 — Broken Access Control:** authorization boundaries, ownership checks, privilege/state bypasses, access to hidden or restricted game data, and validation of operations against current state.
- [ ] **A02:2025 — Security Misconfiguration:** unsafe defaults, debug/release configuration, permissive file paths/permissions, CI permissions, workflow triggers, and insecure build/runtime settings.
- [ ] **A03:2025 — Software Supply Chain Failures:** pinned versus mutable third-party Actions/tool installers, dependency provenance, version drift, untrusted build inputs, compromised tools, and integrity of build/test/release workflows.
- [ ] **A04:2025 — Cryptographic Failures:** use of cryptography, random-number generation, secret handling, sensitive-data storage, and whether security claims exceed the actual guarantees. If cryptography is absent, state that.
- [ ] **A05:2025 — Injection:** command, shell, path, format-string, terminal/ANSI escape, and parser injection. Confirm that player-provided text cannot become a host command or unintended control sequence.
- [ ] **A06:2025 — Insecure Design:** missing threat boundaries, unsafe trust assumptions, abuse cases, resource-exhaustion paths, unsafe state design, and failure to enforce project constraints by construction.
- [ ] **A07:2025 — Authentication Failures:** inspect only if an authentication/identity mechanism exists; otherwise explicitly mark not applicable. Do not mistake fictional in-game authentication for real user authentication.
- [ ] **A08:2025 — Software or Data Integrity Failures:** trust boundaries for save files and other data, validation before state mutation, tampering, unsafe deserialization, artifact integrity, and update/build integrity.
- [ ] **A09:2025 — Security Logging and Alerting Failures:** whether security-relevant failures are observable and actionable without leaking sensitive data. For this terminal game, assess appropriate user/developer diagnostics rather than requiring a server alerting platform.
- [ ] **A10:2025 — Mishandling of Exceptional Conditions:** error paths, allocation failures, I/O failures, malformed saves, integer overflow, partial updates, panic/abort paths, fail-open behavior, and cleanup under failure.

### Project-specific security invariants

- [ ] The game remains fictional, local, offline, and self-contained.
- [ ] No real network scanning, host connection, external-system interaction, shell-command execution, credential collection, or real hacking behavior is introduced.
- [ ] Treat save files and all externally supplied bytes/text as untrusted input.
- [ ] Validate lengths, numeric ranges, enum/tag values, indices, identifiers, and cross-field relationships before using or committing parsed data.
- [ ] Reject unknown non-numeric save markers before mutating player or mission state.
- [ ] Hidden objective descriptions, clues, rewards, and other undiscovered content do not leak through output, status, save data, or indirect error messages.
- [ ] User-controlled text cannot forge terminal control sequences or escape the intended presentation layer.
- [ ] No secret, credential, personal data, or sensitive runtime state is added to logs, diagnostics, fixtures, or committed test data.
- [ ] Check denial-of-service-like local failure modes: unbounded input, unbounded loops, excessive allocation, oversized files, pathological parsing, and unbounded recursion.

## 5. Architecture and Design — 30%

- [ ] **Responsibility boundaries:** each module has one coherent responsibility; no monoliths or unnecessary fragmentation.
- [ ] **Dependency direction:** imports remain one-way; no circular dependencies; domain/foundation modules do not depend on application orchestration or terminal I/O.
- [ ] **Composition root:** `src/main.zig` remains a thin composition root and interactive loop owner.
- [ ] **Layering:** domain, application, catalog, presentation, and persistence responsibilities remain separate.
- [ ] **Data/state/logic separation:** static mission/operation catalog data is not confused with runtime state or application behavior.
- [ ] **Persistence boundary:** runtime-only state is not serialized accidentally; persisted state has a clear owner and stable contract.
- [ ] **API design:** public types/functions are cohesive, minimal, documented, and compatible; avoid leaking implementation details.
- [ ] **Abstraction quality:** abstractions solve an actual repeated or architectural need; avoid speculative frameworks, generic machinery, and unnecessary indirection.
- [ ] **State representation:** use explicit types and tagged unions where states are mutually exclusive; avoid contradictory boolean combinations.
- [ ] **Ownership and lifecycle:** allocator ownership, resource ownership, and mutation responsibility are explicit.
- [ ] **Testability:** rules and state transitions can be tested without interactive terminal I/O where practical.
- [ ] **Compatibility facades:** legacy top-level `src/*.zig` facades remain thin and preserve intended import compatibility.
- [ ] **Documentation alignment:** architecture diagrams, module maps, task handoffs, ADRs, and known-issue notes reflect the actual source.
- [ ] **Scope discipline:** no unrelated cleanup, speculative complexity, or roadmap feature is introduced without authorization.

## 6. Performance — 10%

- [ ] Identify hot paths and assess algorithmic complexity, repeated scans, nested loops, and avoidable work.
- [ ] Check allocation frequency, allocation inside loops, temporary copies, unnecessary formatting, and avoidable heap usage.
- [ ] Check fixed-capacity structures for safe bounds and appropriate capacity; ensure no hidden unbounded growth.
- [ ] Check I/O frequency, buffering, file reads/writes, and terminal redraw/output volume.
- [ ] Check parsing and lookup strategies for avoidable repeated work.
- [ ] Check stack usage, large local arrays/struct copies, recursion depth, and potential stack exhaustion.
- [ ] Check integer counters and long-running accumulation for overflow.
- [ ] Do not claim a performance regression or improvement without a benchmark, reproducible measurement, or a clear complexity proof. Label unmeasured hypotheses as suggestions.
- [ ] Do not optimize at the expense of correctness, safety, readability, or compatibility.

## 7. Zig-specific scan — mandatory order

Target toolchain: **Zig 0.13.0**. Verify APIs and language semantics against this version. Do not flag valid 0.13.0 code merely because a newer Zig version uses a different API. In particular, `root_source_file` in the project's Zig 0.13 build API is valid; do not report it as obsolete based on newer versions.

### 7.1 `zig fmt`

- [ ] Check formatting using the repository command: `zig fmt --check test_root.zig build.zig src tests`.
- [ ] Formatting differences are reported separately from correctness/security defects.
- [ ] Do not silently reformat files during a read-only review.

### 7.2 ALWAYS FLAG

These patterns must always be investigated and flagged when present unless the exact use is demonstrably safe and the justification is documented in the finding:

- [ ] `@intCast` without a proven range/bounds guarantee at the cast site.
- [ ] Optional unwrap `.?` without a dominating proof/guard that the value is non-null.
- [ ] `catch unreachable` on allocation or any operation that can fail under valid runtime conditions.
- [ ] `@panic("OOM")` or equivalent panic-based allocation failure handling.
- [ ] Use of `undefined` before every field/element is definitely initialized on every path.
- [ ] Discarding a fallible result (for example, `_ = fallibleFunction()`) without a deliberate, documented reason and safe recovery policy.
- [ ] Unjustified `@ptrCast`, `@alignCast`, pointer reinterpretation, or assumptions about layout/alignment.
- [ ] Memory/resource leaks or ownership transfer that is unclear or incomplete.
- [ ] Mutex/lock acquisition without guaranteed release (normally `defer unlock()`) on every exit path.
- [ ] Any other construct that turns a recoverable runtime condition into an unchecked assumption, silent success, or process crash.

For every occurrence, trace the proof and all relevant control-flow paths. Do not mechanically flag a safe construct when its invariant is explicit and locally demonstrable; document why it is safe.

### 7.3 Safety

- [ ] Bounds and slice safety: index/slice operations are preceded by valid range checks; lengths and capacities are not confused.
- [ ] Integer safety: casts, arithmetic, counters, shifts, signed/unsigned conversions, and sentinel values cannot overflow or truncate unexpectedly.
- [ ] Pointer safety: no dangling pointers, use-after-free, double-free, invalid aliasing, stale pointers after reallocation, or pointer to stack/local data escaping its lifetime.
- [ ] Alignment/layout safety: alignment assumptions are valid; packed structs and pointer casts are justified; no invalid field address assumptions.
- [ ] Initialization safety: no read-before-write, partially initialized struct, invalid enum/tag, or uninitialized array element.
- [ ] Allocation safety: every allocation has a clear owner and matching release; use `defer` and `errdefer` correctly; failure paths are tested where practical.
- [ ] Allocator safety: library/domain code receives an explicit allocator when needed; do not introduce a hidden global allocator; allocator lifetime outlives all allocations made from it.
- [ ] Error safety: use explicit error sets and `!T`, propagate with `try`, and catch only where recovery/translation is intentional. Avoid `anyerror` without a strong reason.
- [ ] No recoverable path is represented by `unreachable`, panic, or unchecked assumption.
- [ ] File and stream safety: handles close on every path; short reads/writes and I/O errors are handled; temporary files and rename semantics preserve prior data.
- [ ] Concurrency safety if concurrency exists: synchronization protects shared state; lock ordering is consistent; no data races; locks are always released. If no concurrency exists, state that it is not applicable.
- [ ] FFI/extern safety if present: ABI, pointer lifetime, alignment, ownership, and error translation are verified. If absent, state not applicable.
- [ ] Runtime safety is not disabled to hide a defect; inspect `@setRuntimeSafety(false)` and equivalent unsafe optimizations.

### 7.4 Context-dependent

Investigate these in context; do not automatically label every occurrence a defect:

- [ ] Arena versus general-purpose allocator choice and arena lifetime.
- [ ] Allocation inside loops, repeated allocation, reuse, and amortized cost.
- [ ] Stack allocation versus heap allocation; large stack objects and copies.
- [ ] `comptime`, `inline`, compile-time evaluation, and code-size trade-offs.
- [ ] `catch` fallback values, swallowed errors, and error translation.
- [ ] Optional values and defaults that may hide missing/invalid data.
- [ ] Fixed arrays/capacities, sentinel-terminated data, and assumptions about maximum sizes.
- [ ] Tagged unions, enums, integer-backed flags, and packed representations.
- [ ] `@memcpy`, `@memmove`, `@memset`, and aliasing/length preconditions.
- [ ] Sorting/searching algorithms and their assumptions about ordering or uniqueness.
- [ ] Global mutable state, cached state, and initialization order.
- [ ] Atomic operations, volatile, locks, and memory ordering if used.
- [ ] Error unions and optional conversions that may erase useful failure information.
- [ ] Build-mode-dependent behavior, safety checks, and Debug/ReleaseSafe/ReleaseFast differences.

### 7.5 Style

- [ ] Names communicate domain meaning and follow Zig conventions.
- [ ] Functions and types have focused responsibilities and manageable complexity.
- [ ] Public declarations have concise doc comments.
- [ ] Comments explain invariants and non-obvious reasoning, not merely restate code.
- [ ] Error names/messages are precise and consistent.
- [ ] Avoid unnecessary wrappers, one-use abstractions, excessive nesting, and duplicated logic.
- [ ] Prefer static dispatch and compile-time specialization when they keep the design simpler; do not introduce runtime polymorphism or generic machinery without a concrete need.
- [ ] Use an Options Struct for functions with multiple related optional/configuration parameters when it materially improves call-site clarity; do not force it for trivial functions.
- [ ] Keep formatting idiomatic and avoid clever code that obscures safety.
- [ ] Keep imports organized and dependency direction obvious.

## 8. Project-specific review requirements

- [ ] **Terminal presentation:** ANSI escape generation and styling are centralized in the terminal/presentation helpers; user-controlled text is handled safely; output remains readable and deterministic.
- [ ] **Input handling:** inspect input length limits, trimming, parsing, EOF, read errors, and malformed input. Where the implementation uses a non-blocking/state-machine input design, verify it does not block or corrupt state; do not introduce a blocking design contrary to the accepted architecture.
- [ ] **Main loop:** `main.zig` remains thin; application orchestration is not duplicated in the entry point.
- [ ] **Terminal cleanup:** any terminal mode/raw input/alternate screen/resource setup is restored on all exits and error paths. If the project does not use such modes, mark not applicable.
- [ ] **Mission model:** static definitions, runtime mission session, and command/application logic remain separate.
- [ ] **Mission state:** progression order, connection independence, objective tracker capacity/identity, hidden objective visibility, Detection bounds, and runtime-only fields preserve their invariants.
- [ ] **Progression/rewards:** payouts, XP, Reputation, optional-objective bonuses, modifiers, and operation rewards cannot be duplicated or partially applied.
- [ ] **Topology:** node/link IDs, adjacency, reachability, movement restrictions, and traversal counters are validated.
- [ ] **Operations:** stage limits, linear order, typed carry-over facts, retry behavior, reward eligibility, and runtime-only lifecycle are preserved.
- [ ] **Save compatibility:** Save V3 writer and V2/V1/legacy readers remain compatible unless a migration was explicitly approved. Do not casually alter version markers, field order, defaults, paths, or legacy behavior.
- [ ] **Save transactionality:** stage the full payload before replacing the previous save; failure must not truncate or corrupt the previous valid save.
- [ ] **Save validation:** treat save bytes as untrusted; validate numeric ranges, booleans, indices, flags, lengths, and cross-field consistency before committing state.
- [ ] **Tests layout:** tests stay under `tests/`; preserve `tests/test_all.zig` and `test_root.zig`; register every new test module in the aggregate.
- [ ] **Build API:** target Zig 0.13.0 and current build API; do not apply newer-version advice blindly.
- [ ] **Offline boundary:** no real networking, external host access, shell execution, or credential collection.

## 9. Maintainability and Observability

This is a mandatory cross-cutting pass.

- [ ] Code is understandable without relying on undocumented tribal knowledge.
- [ ] Module contracts, public APIs, naming, comments, and documentation agree with actual behavior.
- [ ] Known issues are not silently reintroduced or incorrectly marked fixed.
- [ ] Error messages and diagnostics identify the failing operation and useful context without exposing secrets or misleading users.
- [ ] Failure paths are observable enough to diagnose; errors are not silently discarded.
- [ ] State changes and reward/persistence outcomes can be verified through tests or deterministic output.
- [ ] Tests are focused, deterministic, isolated, and do not depend on real external services.
- [ ] Test names describe behavior; assertions verify outcomes rather than merely executing code.
- [ ] Use `std.testing.allocator` for tests that exercise owned allocations where appropriate, so leaks are detected; use `std.testing.expectError` to assert expected error paths rather than checking only that an error occurred indirectly.
- [ ] Failure injection covers allocator and I/O failure paths where relevant.
- [ ] CI output is actionable; workflow steps and documentation checks are not redundant or misleading.
- [ ] Update `.agent/known-issues.md`, module contracts, task handoffs, ADRs, or user docs only when evidence and scope justify it. Never turn an unaccepted proposal into an accepted decision.

## 10. Tests, build, and CI

Inspect the actual repository workflow and the exact commit under review.

- [ ] Confirm Zig version is exactly **0.13.0**.
- [ ] Inspect `build.zig`, test root, aggregate test list, and all relevant test modules.
- [ ] Check formatting with `zig fmt --check test_root.zig build.zig src tests`.
- [ ] Check compilation with `zig build`.
- [ ] Check tests with `zig build test` and, where useful, `zig test test_root.zig`.
- [ ] Check agent documentation with `sh scripts/check-agent-docs.sh`.
- [ ] Inspect CI workflow triggers, permissions, concurrency, action/tool versions, cache/artifact handling, and failure visibility.
- [ ] Determine which optimization modes CI actually tests. Do not imply ReleaseSafe or ReleaseFast was tested if CI only runs default Debug.
- [ ] Consider Debug, ReleaseSafe, and ReleaseFast behavior where practical, especially integer safety and runtime checks.
- [ ] Check dependency/action pinning and supply-chain exposure.
- [ ] Inspect the actual CI run for the reviewed commit and report its conclusion. A pushed commit is not evidence of a passing workflow.
- [ ] Distinguish: locally executed checks, CI-executed checks, static inspection, and checks not run.
- [ ] Do not claim manual gameplay/playtesting unless it was actually performed.
- [ ] Note missing coverage, security scanning, dependency auditing, or release-mode testing as gaps/suggestions, not as proof of a vulnerability.

## 11. Finding severity and evidence rules

Use exactly these labels:

- **[BLOCKER]** — confirmed critical correctness/security/data-integrity issue, exploitable path, likely data loss/corruption, or state failure that must be fixed before the reviewed change/release is accepted. Must include a concrete trigger and a specific remediation. A blocker must never be a vague concern.
- **[SUGGESTION]** — meaningful quality, robustness, security-hardening, performance, architecture, test, documentation, or CI improvement that is not a confirmed release-blocking defect.
- **[NIT]** — minor style/readability/documentation issue with low impact.
- **[NEEDS-VERIFICATION]** — plausible issue or important property that cannot be confirmed from available code/evidence; state exactly what evidence or test is needed.

Every finding must contain:

1. Severity label and concise title.
2. Exact file path and line range from the reviewed commit.
3. Relevant code path and preconditions.
4. Concrete failure/abuse scenario or reason for improvement.
5. Impact and affected invariant/category.
6. Specific recommended fix or verification procedure.
7. Confidence/evidence status where useful.

Do not duplicate the same root cause as multiple findings merely because it appears in multiple call sites. Group related locations and explain the shared cause. Do not inflate severity. Do not hide a blocker among suggestions.

## 12. Mandatory final report format

Every full review must report all sections below, even when a section has no findings:

1. **Review identity and scope:** repository, branch, exact commit SHA, review mode, date, toolchain, and files/areas inspected.
2. **Executive summary:** overall risk, review coverage, and whether any BLOCKER exists.
3. **Findings table:** severity, ID, title, file/line, category, and concise impact.
4. **Detailed findings:** evidence, trigger, impact, and concrete remediation for every finding.
5. **Prioritized BLOCKERS:** explicit list and fix order; write "None" when none exist.
6. **NEEDS-VERIFICATION:** explicit list of unresolved questions and exact evidence/tests required; write "None" when none exist.
7. **Positive observations:** sound design, defensive code, useful tests, and good architecture found during review.
8. **Coverage statistics:** total source/test/config/doc files considered; files fully inspected, partially inspected, and not inspected; counts by review category and severity; tests and CI runs inspected.
9. **Verification matrix:** command/check, execution location (local/CI/static), exact result, and commit/run reference.
10. **Limitations:** unavailable files, truncated outputs, missing runtime/manual tests, untested build modes, unavailable independent reviewer, and other evidence gaps.
11. **Recommended next actions:** ordered by risk and value; distinguish required fixes from optional improvements.

For a full review, include a category coverage matrix for Correctness, OWASP Security, Architecture/Design, Performance, Zig-specific scan, Maintainability/Observability, Tests, and CI. For each, state **reviewed**, **partially reviewed**, or **not reviewed**, with a short reason. A blank section is not evidence of coverage.

## 13. Reviewer conduct and completion gate

- [ ] Review the code that exists at the recorded commit, not a remembered or assumed version.
- [ ] Complete every applicable checklist section; record N/A with rationale.
- [ ] Do not modify source, tests, docs, workflow, or repository state during a read-only review.
- [ ] Do not approve a change based only on the author's explanation or test names.
- [ ] Prefer an independent second reviewer for substantial changes. If unavailable, state that this was a self-review.
- [ ] Do not claim complete coverage when any relevant file or pass was skipped.
- [ ] Do not claim build/test/CI success without actual successful execution evidence.
- [ ] The review is complete only when the report, severity prioritization, coverage statistics, verification matrix, and limitations are all present.

## 14. Reference

The OWASP category names in this standard follow the final [OWASP Top 10:2025](https://top10.owasp.org/2025/). Recheck the official project when the standard is revised; do not silently substitute an older edition.
