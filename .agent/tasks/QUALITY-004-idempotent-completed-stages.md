# QUALITY-004 — Idempotent Completed Authentication and Decryption

**Status:** Implemented  
**Priority:** P2  
**Type:** Code review remediation

## Goal
Prevent incorrect retries against already-completed authentication or decryption stages from increasing Detection or compromising an otherwise valid active contract.

## Resolution
- `src/game.zig` now checks completed authentication/decryption state before evaluating another supplied password or key.
- Repeated `brute` attempts after authentication return an acknowledgement without changing Detection.
- Repeated `decrypt` attempts after decryption return an acknowledgement without changing Detection.
- Regression coverage in `tests/game_detection_test.zig` verifies Detection remains unchanged and the active contract remains active for both incorrect retry paths.
- `docs/gameplay.md` and `AGENTS.md` record the completed-stage idempotency invariant.
- No save-format or persistence changes were required.

## Acceptance criteria
- [x] After authentication succeeds, any further `brute` attempt is acknowledged as already completed and does not evaluate the supplied password or change Detection.
- [x] After decryption succeeds, any further `decrypt` attempt is acknowledged as already completed and does not evaluate the supplied key or change Detection.
- [x] Regression coverage verifies Detection remains unchanged and the active contract remains active for both paths.
- [x] Gameplay and agent guidance document the invariant.
- [x] Zig formatting, build, full tests, and agent-doc checks pass in CI.
- [x] Final review and commit/CI verification completed.

## Verification
GitHub Actions run [42045018533](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42045018533) on `main` completed successfully. Its Zig 0.13.0 job passed:
- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig test test_root.zig`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Review against `.agent/review-checklist.md`

Final implementation commit: [ba3d409](https://github.com/Shadmehr1984/hackers-terminal/commit/ba3d409ff3785c4d40bad65ab5eea21bffb41de5)  
Final verified `main` commit: [0783550](https://github.com/Shadmehr1984/hackers-terminal/commit/0783550a8471e687e276e838d6d19a969ca16df2)

## Constraints and non-goals
- Save-format impact: none; no persisted fields or serialization behavior changed.
- Existing command syntax, progression, Detection costs for genuine failed attempts, and unrelated mission behavior are preserved.
- No new dependencies or architectural abstractions.
- Fictional, local, offline gameplay only.
