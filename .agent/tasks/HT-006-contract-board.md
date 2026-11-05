# Task: HT-006 — Contract Board

**Status:** Implemented and Merged  
**Program:** EXPANSION-001 / Phase 1  
**Owner decisions:** Keep `missions` unchanged; add a separate `board` command. Add static contract categories. Keep Faction data out until HT-010. While any contract is active or prepared, all non-completed catalog entries remain visible as unavailable.

## Goal
Add a terminal-first Contract Board that presents every catalog contract with a deterministic, derived availability state, category, reward range, XP, difficulty, and actionable lock/unavailability reason.

## Current behavior
- `missions` prints a compact list and is used by the existing preparation flow.
- Contract definitions live in `src/domain/mission.zig` and `src/catalog/mission_data.zig`.
- Level and Reputation requirements are checked by the application coordinator.
- Ghost Signal is exclusive to the Fixer offer and direct `prepare` is rejected.
- Runtime active/preparation state is transient; Save V3 stores neither Board state nor mission session details.

## Accepted design
- Preserve `missions` output and semantics; introduce `board` with no argument.
- Add a typed static `MissionCategory` to `Mission`; current categories: Data Recovery, Intelligence, Extraction, and Infiltration.
- Add a pure domain query in `src/domain/contract_board.zig`.
- Availability precedence: Completed → Unavailable (another contract active/prepared) → Locked (level/Reputation requirements) → Exclusive (contact-offer-only) → Available.
- For Locked, report each unmet requirement. For Unavailable, explain that the player must finish/fail the active contract or cancel preparation.
- Reward range is base reward through base reward plus all authored optional-objective cash bonuses. XP remains separately displayed.
- Board ordering follows catalog order. All entries remain visible. Do not reveal puzzle clues, passwords, keys, or hidden mission intel.

## Acceptance criteria
- [x] `board` lists all contracts without changing `missions`.
- [x] Every entry shows ID, name, category, difficulty, cash reward range, XP, status, and reason where applicable.
- [x] Completed entries remain Completed even while another contract is active/prepared.
- [x] Level and Reputation lock reasons are accurate and may both be shown.
- [x] Contact-exclusive contracts show Exclusive only after ordinary requirements are met.
- [x] Active/prepared state marks other incomplete contracts Unavailable.
- [x] Categories and maximum reward calculation are deterministic and unit-tested.
- [x] Board output does not disclose puzzle clues or answers.
- [x] Existing `prepare`, `accept`, Contact offers, and `missions` behavior remain unchanged.
- [x] Save V3 and all legacy readers/writers remain untouched.

## Likely scope
- `src/domain/mission.zig`
- `src/domain/contract_board.zig` (new)
- `src/catalog/mission_data.zig`
- `src/application/game.zig`
- `src/presentation/terminal.zig`
- `tests/contract_board_test.zig` (new), `tests/test_all.zig`
- `docs/commands.md`, `docs/gameplay.md`
- `AGENTS.md`, `.agent/conventions.md`, `.agent/tasks/README.md`, `.agent/roadmap.md`

## Constraints and non-goals
- Zig 0.13.0 only.
- No save-format change; Board state is entirely derived.
- No Faction model, client identity system, modifiers, recurring contracts, or new mission content.
- No real networking, external systems, shell execution, or credential collection.
- Do not alter existing contract IDs/order, requirements, rewards, objectives, puzzle content, or progression balance.

## Verification
- [x] Focused domain and terminal/command tests.
- [x] `zig fmt --check test_root.zig build.zig src tests` (GitHub Actions)
- [x] `zig build` (GitHub Actions)
- [x] `zig build test` (GitHub Actions)
- [x] `sh scripts/check-agent-docs.sh` (GitHub Actions)
- [x] Self-review completed against `.agent/review-checklist.md`; independent reviewer unavailable.
- [x] GitHub Actions run 42088374052 completed successfully.

## Progress

- Implementation is complete and merged into `main`.
- Pull request: https://github.com/Shadmehr1984/hackers-terminal/pull/8 (merged into `main`).
- GitHub Actions run 42088374052: formatting, project compile, Zig tests, and agent documentation structure all succeeded.
- No save files or serialization code changed. No manual interactive playtest was performed.
