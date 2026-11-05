# QUALITY-004 — Idempotent Completed Authentication and Decryption

**Status:** In Progress  
**Priority:** P2  
**Type:** Code review remediation

## Goal
Prevent incorrect retries against already-completed authentication or decryption stages from increasing Detection or compromising an otherwise valid active contract.

## Current behavior
- `src/game.zig` handles a correct repeated `brute` or `decrypt` command without charging Detection again.
- An incorrect repeated password/key was still treated as a fresh failed attempt and increased Detection.
- Existing coverage in `tests/game_detection_test.zig` checked repeated successful attempts but omitted incorrect retries after success.

## Acceptance criteria
- [x] After authentication succeeds, any further `brute` attempt is acknowledged as already completed and does not evaluate the supplied password or change Detection.
- [x] After decryption succeeds, any further `decrypt` attempt is acknowledged as already completed and does not evaluate the supplied key or change Detection.
- [x] Regression coverage verifies Detection remains unchanged and the active contract remains active for both paths.
- [x] Gameplay and agent guidance document the invariant.
- [ ] Zig formatting, build, full tests, and agent-doc checks pass in CI.
- [ ] Final review and commit/CI verification completed.

## Likely scope
- `src/game.zig`
- `tests/game_detection_test.zig`
- `docs/gameplay.md`
- `AGENTS.md`

## Constraints and non-goals
- Save-format impact: none; no persisted fields or serialization behavior change.
- Preserve command syntax, progression, Detection costs for genuine failed attempts, and all unrelated mission behavior.
- No new dependencies or architectural abstractions.
- Fictional, local, offline gameplay only.

## Verification
- [ ] Focused regression tests
- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig test test_root.zig`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] Review diff against `.agent/review-checklist.md`
