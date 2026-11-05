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
Use Zig 0.13.0:

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
Review the patch independently with review-checklist.md. Look for regressions, save compatibility changes, missing tests, dependency violations, scope creep, and inaccurate docs.

## 8. Commit and report
- The owner authorized direct commits to main; use focused commits.
- Confirm writes and verify the resulting commit on main.
- Inspect CI for the new commit and report its actual state.
- Report changed files, tests actually run, CI status, and limitations.
- Never claim manual gameplay testing unless it happened.
