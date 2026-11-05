# QUALITY-003 — Active Save Validation and Status Output

- Status: In Progress
- Origin: Follow-up project-wide code review on 2026-11-05
- Owner approval: Both findings approved for remediation.

## Goal
Validate restored active missions against completion flags loaded from the same save, and correct status output line endings.

## Confirmed findings
1. In `src/save.zig`, V3/V2/V1 loading currently validates the active mission index before reading persisted mission completion flags. The validation therefore observes the caller's initial mission state and can restore a mission that the save itself marks completed.
2. In `src/terminal.zig`, `printStatus` uses escaped backslash-n sequences in its active and inactive mission output. Zig interprets `\\n` as a literal backslash followed by `n`, not as a line break.

## Acceptance criteria
- [ ] Parse the active mission index as a candidate without validating it against stale mission completion state.
- [ ] Read persisted mission completion flags before validating the candidate.
- [ ] Restore an active mission only when its index is in range and its loaded completion flag is false.
- [ ] Tests cover an inconsistent save whose active index points to a mission marked completed, and a valid active incomplete mission.
- [ ] Replace literal backslash-n output in `printStatus` with actual newline escapes.
- [ ] Tests cover active status output, including location, and inactive status output; assert line breaks rather than literal `\\n`.
- [ ] Save V3 layout, V1/V2/legacy compatibility, gameplay behavior, and command semantics remain unchanged.
- [ ] Update this brief and task index; correct the stale QUALITY-002 status in the task index.
- [ ] Zig 0.13.0 formatting, build, full tests, and agent-doc check pass in GitHub Actions.
- [ ] Complete a self-review against `.agent/review-checklist.md`; do not claim an independent reviewer unless one is actually available.

## Scope
- `src/save.zig`
- `src/terminal.zig`
- `tests/equipment_test.zig`
- A focused `tests/terminal_test.zig` and `tests/test_all.zig` registration
- `.agent/tasks/README.md`
- This task brief

## Constraints and non-goals
- Do not change serialized field order, version markers, save path, or migration formats.
- Do not add unrelated save corruption recovery or gameplay rules.
- Do not change status content beyond correcting line breaks.
- No real networking, external-system interaction, or shell execution.

## Implementation plan
1. Capture the active mission index as an unvalidated candidate in V3/V2/V1 branches.
2. Load mission completion flags, then validate the candidate against the resulting mission state.
3. Add save regression tests for completed and incomplete active candidates.
4. Correct status output escapes and add focused active/inactive output tests.
5. Run formatting/build/tests/agent-doc checks in CI, inspect the final workflow run, and record the result here.

## Verification
- [ ] Focused save validation regression tests.
- [ ] Focused terminal status formatting tests.
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig test test_root.zig`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] Inspect actual GitHub Actions result for the final commit.
- [ ] Self-review recorded; independent reviewer availability stated accurately.
