# QUALITY-007 — Faction-aware Operation status and checked optional rewards

- **Status:** In Progress
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

- [ ] Operation list and stage details show derived client-faction standing and explicitly identify faction-locked stages/operations.
- [ ] Active Operation status explains that its access was preauthorized at start, even if standing changes during the sequence.
- [ ] Optional reward accumulation uses checked arithmetic and returns error.RewardOverflow rather than wrapping.
- [ ] Contract Board maximum-reward calculation and evaluation propagate overflow; presentation does not display a wrapped amount.
- [ ] Tests cover faction-locked Operation output, active preauthorization messaging, tracker overflow, Contract Board overflow, and atomic mission payout failure.
- [ ] No Save V3 layout, mission catalog, Operation stage sequence, or gameplay reward values change.
- [ ] Relevant user/agent documentation is synchronized.
- [ ] Zig formatting, build, full tests, and agent-doc checks pass in CI for Debug and ReleaseSafe.
- [ ] Comprehensive final review against every applicable item in .agent/review-checklist.md is recorded, including coverage and limitations.

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

- [ ] zig fmt --check test_root.zig build.zig src tests
- [ ] zig build
- [ ] zig build test
- [ ] sh scripts/check-agent-docs.sh
- [ ] Inspect actual GitHub Actions result for the final main commit.
- [ ] Complete the full review checklist; state whether an independent reviewer was available.