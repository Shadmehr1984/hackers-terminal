# QUALITY-003 — Active Save Validation and Status Output

- Status: Implemented
- Origin: Follow-up project-wide code review on 2026-11-05
- Owner approval: Both findings approved for remediation.

## Goal
Validate restored active missions against completion flags loaded from the same save, and correct status output line endings.

## Confirmed findings
1. In `src/save.zig`, V3/V2/V1 loading currently validates the active mission index before reading persisted mission completion flags. The validation therefore observes the caller's initial mission state and can restore a mission that the save itself marks completed.
2. In `src/terminal.zig`, `printStatus` uses escaped backslash-n sequences in its active and inactive mission output. Zig interprets `\\n` as a literal backslash followed by `n`, not as a line break.

## Acceptance criteria
- [x] Parse the active mission index as a candidate without validating it against stale mission completion state.
- [x] Read persisted mission completion flags before validating the candidate.
- [x] Restore an active mission only when its index is in range and its loaded completion flag is false.
- [x] Tests cover an inconsistent save whose active index points to a mission marked completed, and a valid active incomplete mission.
- [x] Replace literal backslash-n output in `printStatus` with actual newline escapes.
- [x] Tests cover active status output, including location, and inactive status output; assert line breaks rather than literal `\\n`.
- [x] Save V3 layout, V1/V2/legacy compatibility, gameplay behavior, and command semantics remain unchanged.
- [x] Update this brief and task index; correct the stale QUALITY-002 status in the task index.
- [x] Zig 0.13.0 formatting, build, full tests, and agent-doc check pass in GitHub Actions.
- [x] Complete a self-review against `.agent/review-checklist.md`; no independent reviewer was available.

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

## Implementation notes

- `readActiveCandidate` parses the persisted index without consulting mission state. After all completion flags are loaded, `validateActiveCandidate` accepts only an in-range mission that remains incomplete. Save field order and version formats are unchanged.
- Added a regression test for a persisted active index pointing to a mission marked completed, plus a valid active/incomplete case.
- `printStatus` now uses Zig newline escapes in active, location, traversal, and inactive output.
- Added `tests/terminal_test.zig` to cover active status output (including location) and inactive status output, and registered it in `tests/test_all.zig`.
- Corrected the stale QUALITY-002 status in the task index and indexed this task.

### Self-review record

Reviewed the changed save loader, terminal output, regression tests, and task index against `.agent/review-checklist.md`. The loader still reads the same V3/V2/V1/legacy fields in the same order; only the timing of active-index validation changed. The active index is now checked against the completion flags from the same save. Status text content is otherwise unchanged. The new tests are included in the aggregate suite. No independent second reviewer was available; this is a self-review only.

## Verification
- [x] Focused save validation regression tests.
- [x] Focused terminal status formatting tests.
- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig test test_root.zig`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Inspect actual GitHub Actions result: run [42033803399](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42033803399) completed with `success` for commit `3069926975760a92b801f8070c13494eabf6a4aa`; all workflow steps passed.
- [x] Self-review recorded; independent reviewer availability stated accurately.
