# ADR 0005: Typed Utility Equipment and Save V3

- Status: Accepted
- Date: 2026-11-05

## Context

HT-003 introduces two optional utility tools whose effects modify existing fictional Detection costs. Equipment must support ownership, a single active utility slot, two upgrade tiers, and persistence without changing the decryptor's required-tool role.

## Decision

- Represent utilities with the typed `UtilityEquipment` enum and player equipment state, not unrelated booleans.
- Keep decryptor ownership separate from the mutually exclusive utility slot.
- Allow ownership of both utilities but only one equipped utility at a time. Switching equipment does not discard ownership or upgrades.
- Price each utility at $100. Price upgrade tier 1 at $150 and tier 2 at $250.
- Silent Boots reduce each successful traversal from 5 Detection to 4/3/2 at levels 0/1/2.
- Signal Scrubber reduces each incorrect-password attempt from 15 Detection to 12/9/6 at levels 0/1/2.
- Only the currently equipped matching utility applies its modifier.
- Persist equipment in Save V3. Continue loading V2, V1, and legacy saves with no utilities owned/equipped and zero upgrade levels.

## Consequences

- `player.zig` owns typed equipment state and pure modifier calculations.
- `shop.zig` owns purchase, equip, and upgrade validation.
- `game.zig` applies the equipment modifiers at the relevant Detection actions.
- Save V3 is positional and documented in `docs/save-format.md`; compatibility paths require tests.
