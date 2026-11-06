# QUALITY-007 — Faction-aware Operation status and checked optional rewards

- **Status:** Implemented
- **Origin:** Follow-up to the HT-010 comprehensive code review.
- **Owner authorization:** Explicitly requested on 2026-11-06 to remediate the remaining review items and perform final review.
- **Implementation branch:** main
- **Persistence:** No save-format or runtime-persistence changes.

## Goal

Make Operation list/details/status output reflect the same derived faction-access rules enforced at operation start, and prevent overflow while accumulating optional-objective cash bonuses or calculating Contract Board reward ceilings.

## Current behavior

- src/presentation/terminal.zig shows Operation availability using only level and Reputation. It does not show a hostile client faction lock, even though src/application/game.zig validates every stage's faction access at operation start.
- src/domain/mission_objectives.zig accumulates completed optional-objective rewards with unchecked u32 addition. src/domain/contract_board.zig also sums visible optional rewards without overflow checks. Progression checks later additions, but cannot detect an accumulator that already wrapped.

## Acceptance criteria

- [x] Operation list and stage details show derived client-faction standing and explicitly identify faction-locked stages/operations.
- [x] Active Operation status explains that its access was preauthorized at start, even if standing changes during the sequence.
- [x] Optional reward accumulation uses checked arithmetic and returns error.RewardOverflow rather than wrapping.
- [x] Contract Board maximum-reward calculation and evaluation propagate overflow; presentation does not display a wrapped amount.
- [x] Tests cover faction-locked Operation output, active preauthorization messaging, tracker overflow, Contract Board overflow, and atomic mission payout failure.
- [x] End-to-end tests cover Operation start-time validation and preserve preauthorization when an earlier stage makes a later client's standing Hostile.
- [x] No Save V3 layout, mission catalog, Operation stage sequence, or gameplay reward values change.
- [x] README, user documentation, architecture/module contracts, and task handoffs are synchronized.
- [x] Zig formatting, build, full tests, and agent-doc checks pass in CI for Debug, ReleaseSafe, and ReleaseFast.
- [x] Comprehensive final review against every applicable item in .agent/review-checklist.md is recorded, including coverage and limitations.

## Likely scope

- src/presentation/terminal.zig
- src/domain/mission_objectives.zig
- src/domain/mission_state.zig
- src/domain/contract_board.zig
- src/domain/progression.zig
- src/application/game.zig (Operation status call signature only)
- tests/terminal_test.zig
- tests/mission_objectives_test.zig
- tests/contract_board_test.zig
- tests/progression_test.zig
- docs/architecture.md, docs/gameplay.md, docs/commands.md, docs/development.md
- .agent/conventions.md, .agent/known-issues.md, .agent/tasks/HT-010-factions.md, .agent/tasks/README.md, AGENTS.md

## Constraints and non-goals

- Target Zig 0.13.0 and work directly on main.
- Keep faction standing derived from existing Reputation and completed mission metadata.
- Preserve Operation preauthorization semantics: once a sequence passes all stage checks at start, subsequent standing changes do not interrupt it.
- Preserve Save V3/V2/V1/legacy behavior and all existing mission reward values.
- Do not add a new Operation or change the existing blackout-protocol stages.
- No real networking, shell execution, external-system access, or credential collection.

## Verification

- [x] zig fmt --check test_root.zig build.zig src tests
- [x] zig build
- [x] zig build test
- [x] sh scripts/check-agent-docs.sh
- [x] Inspect actual GitHub Actions result for the final main commit.
- [x] Complete the full review checklist; state whether an independent reviewer was available.

## Completion record

- Final implementation commit: 238f358bcedd2346d8b5fd893ef0754df1467376.
- GitHub Actions run #42224233431 completed successfully for Debug, ReleaseSafe, and ReleaseFast.
- The review found no remaining BLOCKER. One low-priority [SUGGESTION] remains for the u32 traversal counter at src/application/game.zig:426.
- Review limitations: no independent reviewer, local Zig execution, manual playtest, SAST/dependency audit, or benchmark. Full repository inventory and coverage accounting are recorded in the HT-010 task completion record.
