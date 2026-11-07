# QUALITY-008 — Full Review Follow-up

- **Status:** Implemented
- **Origin:** Repository-wide static review on 2026-11-07
- **Owner authorization:** The owner approved completing review coverage and remediating the confirmed findings.
- **Implementation branch:** `main`
- **Persistence:** Save V3 layout and all V2/V1/legacy readers remain unchanged.

## Goal

Close confirmed correctness, consistency, and documentation issues found during the full review without changing mission content, game balance, or persistence format.

## Review clarification

The initial terminal-injection suggestion concerning the invalid-modifier response was a false positive. The argument is printed only after exact resolution through the fixed `ModifierId.fromCommandId` allowlist; arbitrary ANSI/OSC control sequences cannot pass that branch. The suggestion was withdrawn and the inaccurate note in `.agent/known-issues.md` was replaced with this clarification.

## Confirmed findings and resolutions

1. **Equipment upgrade invariant:** `Equipment.setLevel` accepted the representable `u2` value 3 even though the game and Save V3 format support only levels 0..2. The setter now ignores unsupported values, the Equipment model exposes an invariant check, and the save writer rejects invalid in-memory levels before staging a replacement. A regression test verifies the prior save remains intact.
2. **Fixer offer visibility:** the Ghost Signal offer list did not apply the same hostile-client faction restriction as the transaction path. Contact and offer views now hide Ghost Signal when the client faction is Hostile or an Operation owns the flow; the transaction independently enforces the Operation guard and existing faction check. Regression tests cover visibility and transaction rejection.
3. **Detection and progression boundaries:** `MissionSession.addDetection` could underflow if called with a pre-existing level above 100, and `xpForNextLevel` could underflow/overflow for values outside the supported 1..99 player-level range. Both APIs now clamp invalid inputs to their documented domain boundaries, with regression tests.
4. **Duplicated cost presentation:** preparation output repeated utility cost tables and hard-coded no-utility defaults instead of using the captured `MissionLoadout` profile. Preparation now delegates all utility and no-utility values to the canonical loadout methods. Base one-time action costs are also centralized in `MissionState.DetectionEventCost`, consumed by both the command coordinator and the preparation risk display.
5. **Duplicated modifier event values:** traversal and incorrect-key dispatch repeated values already authored by `ModifierId.detectionEffect`. The application now consumes the typed event descriptor.
6. **Presentation boundary:** the `clear` command emitted ANSI control bytes directly from the application coordinator. A presentation helper now owns the sequence and the compatibility facade exports it.
7. **Test placement:** seven objective-tracker tests were embedded in `src/domain/mission_objectives.zig` despite the project rule that tests live under `tests/`. They were moved into the existing `tests/mission_objectives_test.zig` module, which is already registered in the aggregate.
8. **Documentation drift:** Architecture documentation described malformed numeric save fields as falling back to defaults, contrary to the strict preflight validator. Architecture, Save Format, Commands, Gameplay, Development, agent conventions, the roadmap, and the persistence safety rules now match the implementation.
9. **Dead code:** repository-wide symbol tracing found `hasOptionalObjective` in `src/domain/operation.zig` had no callers after the hidden-optional objective validation was consolidated. The unused helper was removed; `hasHiddenOptionalObjective` remains the single validator used by Operation stage checks.

## Acceptance criteria

- [x] Unsupported equipment levels cannot be set through `Equipment.setLevel`.
- [x] Save V3 writer refuses invalid in-memory equipment levels before replacing an existing save.
- [x] Fixer contact/offer views hide Ghost Signal when its client faction is Hostile.
- [x] Ghost Signal cannot be accepted through the Fixer while an Operation owns the contract flow.
- [x] Detection and XP-threshold public APIs preserve their supported numeric domains.
- [x] Preparation display delegates utility and no-utility Detection costs to canonical MissionLoadout profile methods.
- [x] Base one-time action Detection costs and preparation risk indicators share `MissionState.DetectionEventCost`.
- [x] Modifier Detection dispatch reads the typed `detectionEffect` metadata.
- [x] ANSI clear output is centralized in presentation and exported through the legacy facade.
- [x] Objective tracker tests live under `tests/`, not in production source modules.
- [x] Unused pre-refactor Operation helper removed after confirming it had no callers.
- [x] The withdrawn terminal-injection false positive is no longer listed as an active security issue.
- [x] Relevant tests, documentation, conventions, task index, and this handoff are updated.
- [x] Save V3 bytes, V2/V1/legacy compatibility, mission rewards, Detection balance, and fictional/offline boundaries are unchanged.

## Verification and limitations

- **TDD red stage:** primary CI run #1105 (`42387555349`) on the pre-fix test commit passed formatting, compilation, and terminal smoke testing, then reported the expected regression failures: 179 passed, 3 failed, and 3 boundary tests crashed (185 total). The failures reproduced invalid equipment level acceptance, invalid save emission, hostile Fixer offer visibility, Detection ceiling underflow, and XP-threshold underflow/overflow.
- **Final primary CI:** run #1108 (`42388292983`) passed formatting, build, terminal smoke test, the full aggregate test suite, and agent-document checks in Debug, ReleaseSafe, and ReleaseFast on implementation commit `93d46aa2b56b3a1d0b710dcaaa9dcda71da1b234`.
- **Compatibility CI:** run #43 (`42388292969`) passed Zig 0.17.1 formatting, filesystem/save compatibility checks, type-reflection compatibility, facade exports, application compilation, and the full test suite on the same implementation commit.
- Local Zig execution and manual gameplay remain unverified because the owner cannot currently run the project locally.
- This was a static self-review; no independent second reviewer, SAST/dependency audit, or benchmark was available.
