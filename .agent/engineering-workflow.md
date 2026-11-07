# Engineering Workflow for Coding Agents

This document adapts selected engineering practices from the Matt Pocock Skills repository to Hacker's Terminal. It is project guidance, not a mandate to install a particular agent framework or copy another repository's tooling. Project-specific rules in `AGENTS.md`, `.agent/conventions.md`, accepted ADRs, and task specifications take precedence.

## 1. Choose the workflow that matches the work

| Situation | Workflow |
| --- | --- |
| A feature request is ambiguous or changes domain behavior | Clarify the goal, constraints, terminology, acceptance criteria, and affected modules; record settled decisions in the relevant task document/ADR before implementation |
| A concrete behavior or bug fix is understood | Use the vertical-slice TDD loop in section 2 |
| A bug or performance regression is not immediately explained | Use the evidence-first diagnosis loop in section 3 |
| A module boundary or architecture is causing repeated friction | Use the deep-module review in section 4; propose candidates before changing architecture |
| A change is implemented | Run the two-axis review in section 5, in addition to the complete repository checklist when required |
| Work is being passed to another agent/session | Write a concise handoff using section 7 and point to canonical artifacts |
| Agent-facing documentation is being changed | Apply the documentation rules in section 8 |

Do not run every workflow for every task. Select the smallest workflow that covers the risk and nature of the change. Never skip a required project checklist or verification step merely because a skill-like workflow was used.

## 2. Test-driven development: vertical red-green slices

Use this loop for behavior changes and bug fixes when a reliable test seam exists:

1. **Name the behavior.** State the externally observable behavior and the invariant being protected.
2. **Choose the seam.** Prefer the narrowest public module interface or application-level behavior that exercises the real path. Tests should observe behavior through that seam rather than private implementation details.
3. **Write one failing test.** The test must fail for the intended reason before implementation. Use an independent expected value/oracle from an accepted requirement, known example, or explicit invariant; do not calculate expected output by repeating the implementation's algorithm.
4. **Implement the minimum.** Make only the smallest coherent change needed to pass the current test. Do not anticipate unrelated future cases.
5. **Run the focused test.** Confirm the intended test turns green, then proceed to the next vertical slice.
6. **Run relevant aggregate checks.** Finish with the repository's formatting, build, and test commands, including all applicable build modes through CI.
7. **Review and refactor separately.** Keep broad cleanup/refactoring out of the red-green cycle. Perform it as a separately reviewable step after behavior is protected.

For Hacker's Terminal, place tests under `tests/`, register each new module in `tests/test_all.zig`, and use Zig 0.17.1. Preserve the supported test root and documented commands. Prefer tests of game rules/state transitions that do not require interactive terminal I/O.

Test quality rules:
- A test name should describe a behavior or invariant, not an implementation detail.
- Avoid tests coupled to private helpers, internal call order, or incidental data structure choices.
- Avoid tautological assertions whose expected result is computed using the same logic as the implementation.
- Avoid broad mocks that replace the behavior under test. Inject dependencies only where a real variation or test seam requires it.
- Cover success, rejection, boundary, retry/idempotency, and relevant failure paths.
- Do not create a new abstraction solely to make one test easy. If a correct test seam does not exist, record that architectural limitation and propose a focused seam rather than writing a misleading shallow test.

## 3. Evidence-first bug diagnosis

For difficult defects and performance regressions, do not begin by guessing at a cause.

### Phase A — Establish a tight feedback loop

Create one fast, deterministic, agent-runnable command/test that exercises the actual failing path and asserts the reported symptom. Prefer, in order: a focused failing test, a CLI/fixture reproduction, a captured-input replay, a minimal harness, or a property/fuzz loop. Record the exact command and observed failure.

A loop is useful only when it:
- fails on the reported bug, not merely on a nearby error;
- produces a clear pass/fail signal;
- is repeatable (or has a measured, sufficiently high reproduction rate);
- runs quickly enough to support repeated experiments.

If no credible reproduction can be built, stop. State what was tried and what evidence/access is missing. Do not present an untested theory as a diagnosis.

### Phase B — Reproduce and minimise

Run the loop more than once. Reduce the scenario one input, state, dependency, or step at a time while preserving the failure. Keep a minimal reproducer for the regression test.

### Phase C — Form falsifiable hypotheses

List 3–5 ranked hypotheses. Each must predict an observation that would support or disprove it. Test one variable at a time; do not silently jump from a plausible story to a fix.

### Phase D — Instrument or measure

Use the least invasive probe that distinguishes the hypotheses: debugger first where available, otherwise narrowly placed diagnostics. Give temporary diagnostics a unique marker and remove them after diagnosis.

For performance claims, measure a baseline before changing code. Use a repeatable workload, compare equivalent inputs/configurations, and distinguish measured results from complexity-based reasoning. Do not claim an optimization without evidence.

### Phase E — Fix and lock the behavior

Turn the minimal reproduction into a regression test at the correct seam before applying the fix. Verify that the test fails before the fix and passes afterward. Re-run the original, unminimized reproduction and the relevant aggregate suite.

If no seam can reproduce the bug faithfully, document that as an architecture/testability finding instead of adding a test that gives false confidence.

### Phase F — Clean up and learn

Remove temporary logs, probes, harnesses, and debug-only code. Record the confirmed root cause and regression guard in the task/commit handoff. Consider whether a small change to module design, tests, or documentation would prevent recurrence; propose that separately rather than expanding the bug fix without approval.

## 4. Module design and architectural improvement

Prefer **deep modules**: a small, understandable interface that hides a coherent amount of behavior. Evaluate a module by the leverage it gives callers and the locality it gives maintainers, not by lines-of-code ratios.

Use this vocabulary consistently:
- **Module:** a unit with an interface and implementation, from a function to a subsystem.
- **Interface:** everything a caller must know: types, invariants, ordering, errors, configuration, and relevant performance behavior.
- **Seam:** the place where behavior can be varied or tested through an interface.
- **Adapter:** a concrete implementation used at a seam.
- **Depth:** how much behavior is available behind the interface.
- **Leverage:** capability callers gain without learning implementation details.
- **Locality:** how much related change, knowledge, and verification stay in one place.

Design checks:
- Can the interface expose fewer operations or simpler parameters while retaining required behavior?
- Does the module own the policy/invariant, or do callers repeat it?
- Can callers and tests use the same interface?
- Is a proposed seam justified by real variation or multiple meaningful adapters? One hypothetical implementation is not, by itself, a reason to add indirection.
- Can dependencies be passed in explicitly where that makes ownership/testability clearer, without introducing a global allocator or hidden global state?
- Does the change improve one-way dependency direction and preserve the project's domain/application/catalog/presentation/persistence separation?

Do not interpret "deep module" as permission to create large modules or generic frameworks. Keep focused responsibilities, explicit Zig types, and simple standard-library-based designs. A deep module still needs cohesive responsibility and a small interface.

### Architecture survey

When asked to assess architecture, or when recurring friction suggests it, survey the codebase and present a short list of evidence-backed candidates. Each candidate should state:
- affected files/modules;
- concrete current friction and the caller-level cost;
- proposed responsibility/interface change;
- expected effect on locality, leverage, and testability;
- dependencies, compatibility risks, and relevant ADRs;
- confidence: strong, worth exploring, or speculative.

Do not implement a candidate as part of the survey. Do not reopen an accepted ADR for a theoretical benefit; explain the concrete friction that justifies reconsideration. Ask the owner to select a candidate before substantial architectural work.

## 5. Two-axis code review

Every change review must distinguish two independent questions:

### Axis A — Project standards

Does the change follow the project's actual rules? Read `AGENTS.md`, `.agent/conventions.md`, relevant ADRs, and the complete `.agent/review-checklist.md`. Apply the documented rules first. A generic heuristic never overrides an accepted project convention.

As a supplementary smell baseline, consider these Fowler-style heuristics where relevant: mysterious names, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, middle man, and refused bequest. These are judgement prompts, not automatic violations. Label a smell as a suggestion unless it demonstrably violates a project rule or causes a concrete defect. Skip anything already enforced by tooling.

### Axis B — Specification fidelity

Does the implementation faithfully meet the originating issue, approved design, acceptance criteria, or task handoff? Check:
- requirements that are missing or only partially implemented;
- behavior added outside the approved scope;
- behavior that appears implemented but violates the intended semantics;
- compatibility, migration, and documentation requirements attached to the spec.

Quote or point to the exact requirement and implementation evidence. If no specification exists, say so; do not invent one.

### Review discipline

- Keep the two axes separate in the report. A standards-compliant implementation can still implement the wrong behavior, and a spec-compliant implementation can still violate project conventions.
- Follow the project's comprehensive review checklist as the authority for full-repository coverage, security, correctness, Zig-specific checks, tests, CI, severity, and reporting.
- Reviews are read-only. Do not fix findings during the review unless the owner separately authorizes remediation.
- Findings need exact paths and line ranges from the reviewed commit, concrete triggers/impact, and a practical recommendation. Unknown evidence remains unknown / `NEEDS-VERIFICATION`.
- If independent agents/reviewers are unavailable, state that the review is a self-review. Do not pretend parallel review occurred.

## 6. Clarify and record decisions before risky work

For ambiguous, cross-module, or behavior-changing work, resolve the important branches before implementation:
- user-visible outcome and non-goals;
- domain terms and state transitions;
- affected modules and dependency direction;
- persistence/save compatibility;
- test seams and acceptance criteria;
- migration, rollout, and failure behavior;
- documentation and handoff updates.

Ask focused questions only for decisions that materially change the design. Do not turn a clear, low-risk task into an unnecessary interview.

Record durable decisions in the existing task/handoff document or an ADR under the project's established convention. Update the domain vocabulary where new or clarified terms are introduced. Keep proposals visibly distinct from accepted decisions.

## 7. Handoffs between agents and sessions

A handoff should let a fresh agent continue without reconstructing the entire conversation. Include:
- objective and current status;
- exact branch and commit SHA;
- completed work and relevant paths;
- accepted decisions and constraints;
- open questions, blockers, and unverified claims;
- exact checks run and their results;
- the next concrete action;
- links/paths to canonical specs, ADRs, review reports, and source files.

Prefer references over copying whole documents. Redact credentials and private data. Update the existing task/handoff artifact when one exists; create a new handoff only when there is no suitable canonical place. Never report an uncommitted or unverified change as complete.

## 8. Writing documentation for agents

Agent-facing documentation is executable guidance: its wording influences which files an agent reads and which steps it takes.

- Keep one authoritative home for each rule. Link to it rather than duplicating long checklists across `AGENTS.md`, conventions, and task files.
- Make context pointers explicit: name the target document and the exact condition that requires reading it (for example, read `docs/save-format.md` before any persistence or save-schema change).
- Keep `AGENTS.md` concise because it is loaded broadly; put detailed branch-specific procedures in focused documents and link to them.
- Use progressive disclosure: inline universal rules, point to focused references for workflows used only on particular task types.
- Co-locate a concept's definition, rules, and caveats under one heading.
- Give every workflow step a checkable completion criterion; avoid vague "understand" or "ensure" wording without evidence.
- Prefer positive, observable instructions ("record the exact command and result") over long lists of prohibitions. Keep hard safety constraints explicit.
- Avoid duplicating the same rule with slightly different wording. When two documents conflict, resolve the conflict and identify the authoritative source.
- Date time-sensitive implementation facts or tie them to a commit/CI run. Avoid stale claims such as "currently" without a verification point.
- After editing agent docs, inspect their rendered/raw content, check links and references, and run `sh scripts/check-agent-docs.sh`.

## 9. Project-specific guardrails

These workflows supplement, and never weaken, the established project constraints:
- Zig 0.17.1 is the required toolchain.
- All tests remain under `tests/` and new test modules are registered in `tests/test_all.zig`.
- Save V3 and V2/V1/legacy loading remain compatible unless a save migration is explicitly approved and documented.
- Mission, operation, faction, rival, objective, Detection, and reward invariants remain governed by `AGENTS.md`, the relevant domain docs, and accepted ADRs.
- The game remains fictional, local, offline, and self-contained.
- Work proceeds directly on `main` by default; no feature branch or PR unless explicitly requested.
