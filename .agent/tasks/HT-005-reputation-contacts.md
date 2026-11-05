# HT-005 — Reputation & Contacts

**Status:** Planned  
**Priority:** 5  
**Approved:** 2026-11-05  
**Depends on:** Existing mission outcomes and progression; benefits from HT-004 preparation flow.

## Goal
Turn the existing reputation value into a meaningful progression system and introduce fictional contacts who can offer contracts, information, or services based on the player's history.

## Design direction
- Inspect current reputation changes in mission completion and existing mission catalog/unlock behavior.
- Define a small number of understandable reputation tiers and how mission outcomes affect them.
- Contacts should be static, fictional game characters with clear roles and unlock conditions.
- Use existing command/terminal patterns; avoid a complex dialogue engine.
- Keep contact offers and unlock state deterministic and testable.
- Decide persistence explicitly. Existing reputation is already part of player progression; new contact/unlock state may require save migration.

## Likely scope (verify before implementation)
- Player progression data in `src/player.zig` or a focused progression/contact module.
- Mission reward/outcome coordination in `src/game.zig`.
- Fictional contact catalog in a focused data module.
- Terminal presentation and command parsing/dispatch only where needed.
- Save compatibility, tests, and progression/gameplay/command/architecture docs.

## Acceptance criteria
- [ ] Reputation has documented, testable thresholds or tiers with clear player-facing meaning.
- [ ] Mission outcomes update reputation according to explicit rules.
- [ ] At least two fictional contacts have distinct roles and unlock/availability conditions.
- [ ] The player can inspect available contacts and their current offers.
- [ ] Unlock conditions and invalid/unavailable interactions are tested.
- [ ] Existing balance, XP, level, and mission completion behavior remain coherent.
- [ ] Any new persistent state has an explicit migration preserving V2, V1, and legacy saves.
- [ ] No external messaging, online services, real identities, or real-world interactions are introduced.

## Non-goals
- No branching narrative or complex dialogue framework.
- No multiplayer/social network features.
- No real-world contact discovery.

## Verification
- [ ] Tests for reputation thresholds, outcome updates, contact availability, and persistence if changed.
- [ ] Zig 0.13.0 formatting, build, and full tests.
- [ ] Agent docs check and independent review/self-review.
- [ ] Inspect CI before marking Implemented.

## Agent progress notes
- Initial handoff: scope and acceptance criteria recorded; implementation has not started.
