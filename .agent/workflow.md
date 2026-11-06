# Agent Workflow

Use this cycle for every code change. Trivial documentation edits may use abbreviated steps, but safety and verification rules still apply.

## 1. Explore
- Fetch latest main and read AGENTS.md.
- Inspect relevant source, tests, docs, build configuration, and CI.
- Check recent commits and CI when available; do not rely on stale summaries.

## 2. Understand
- Describe current behavior and identify its owner module.
- Trace callers, data flow, state transitions, tests, and persistence effects.
- Separate source-confirmed facts from assumptions and proposals.

## 3. Plan
For non-trivial work, create a task brief from tasks/TEMPLATE.md. Define behavior, acceptance criteria, likely files, tests, docs, save impact, and non-goals. Prefer the smallest coherent change.

## 4. Implement
- Keep the diff focused and preserve unrelated behavior.
- Keep module responsibilities clear and dependencies one-way.
- Add or update focused tests with behavior changes.
- Never add real networking, shell execution, credential collection, or external-system interaction.
- Never change save serialization incidentally.

## 5. Verify
Use Zig 0.17.1:

```sh
zig fmt --check test_root.zig build.zig src tests
zig build
zig test test_root.zig
sh scripts/check-agent-docs.sh
```

If local execution is unavailable, state that clearly. Static inspection is not a passing build or test. CI is authoritative once completed.

## 6. Document
- Update relevant user/developer documentation.
- Update AGENTS.md for lasting architecture, module, gameplay, save, or development rules.
- Update roadmap.md, known-issues.md, or ADRs only when materially changed.
- Never record a proposal as an accepted decision.

## 7. Review
- For every requested code review, follow **all** sections of `review-checklist.md` in its mandatory order. Do not reduce the review to a diff scan or a generic summary.
- Complete the four weighted passes: Correctness (40%), OWASP Top 10:2025 Security (20%), Architecture/Design (30%), and Performance (10%).
- Then complete the Zig scan in exact order: `zig fmt` → ALWAYS FLAG → Safety → Context-dependent → Style; complete the Maintainability/Observability, project-specific, tests, and CI passes as well.
- For a full repository review, inspect the whole codebase and account for every source, test, build/configuration, workflow, and relevant documentation file. State partial/unreadable/unreviewed coverage explicitly.
- Every finding requires an exact file and line range, concrete evidence/scenario, impact, and a practical fix or verification step. Use only `[BLOCKER]`, `[SUGGESTION]`, `[NIT]`, and `[NEEDS-VERIFICATION]` severities as defined in the standard.
- Include the mandatory final report, blocker prioritization, verification matrix, coverage statistics, positive observations, and limitations.
- A review request is read-only authorization. Do not edit code/docs, commit, or merge as part of a review unless the owner separately authorizes those actions.
- Never guess, overstate coverage, or claim tests/CI/manual playtesting that were not actually performed. If a fact cannot be established, say so and use `[NEEDS-VERIFICATION]`.
- Prefer a second independent reviewer for substantial changes; if unavailable, identify the review as a self-review.

## 8. Commit and report
- The owner authorized direct commits to main; use focused commits.
- Confirm writes and verify the resulting commit on main.
- Inspect CI for the new commit and report its actual state.
- Report changed files, tests actually run, CI status, and limitations.
- Never claim manual gameplay testing unless it happened.
