# HT-003 — Equipment & Upgrade System

**Status:** In Progress  
**Priority:** 3  
**Approved:** 2026-11-05  
**Depends on:** HT-001 detection/risk rules and HT-002 topology interaction model.

## Goal
Expand the existing shop/decryptor flag into a coherent equipment and upgrade system where player choices create meaningful, understandable trade-offs during simulated missions.

## Design direction
- Inspect the existing `src/shop.zig`, `src/player.zig`, and save format before changing inventory.
- Define a small equipment catalog and clear effects; avoid a large generic item framework.
- Equipment effects may modify simulated risk, topology traversal, or action capabilities, but each modifier must be explicit and testable.
- Establish ownership, equipping, upgrade costs, and insufficient-funds behavior.
- Keep balance values centralized and documented.
- Preserve the current decryptor behavior and old save compatibility.

## Likely scope (verify before implementation)
- `src/player.zig` or a focused inventory/equipment data module.
- `src/shop.zig` for catalog, purchase, equip, and upgrade behavior.
- `src/game.zig` for applying equipment effects to mission actions.
- `src/save.zig` only if persistent inventory representation requires a deliberate versioned migration.
- Tests and shop/gameplay/command/architecture/save documentation as required.

## Acceptance criteria
- [ ] Equipment is represented by typed, testable data rather than unrelated ad-hoc booleans.
- [ ] The player can inspect owned/equipped equipment and available upgrades.
- [ ] Purchase/equip/upgrade validation handles insufficient funds, duplicate ownership, invalid items, and valid transitions.
- [ ] At least two equipment choices provide distinct, meaningful trade-offs tied to existing game mechanics.
- [ ] Existing decryptor purchase and decryption gating continue to work.
- [ ] Equipment effects are applied in one clear place and have focused tests.
- [ ] Persistent inventory, if selected, loads old V2, V1, and legacy saves safely through an explicit migration; otherwise transient behavior is clearly documented.
- [ ] No real system tools, external services, or host interaction are introduced.

## Non-goals
- No real cybersecurity utilities or executable payloads.
- No multiplayer trading or online marketplace.
- No story branching.

## Verification
- [ ] Tests for catalog data, purchase/equip/upgrade, effects, and save compatibility if touched.
- [ ] Zig 0.13.0 formatting, build, and full tests.
- [ ] Agent docs check and independent review/self-review.
- [ ] Inspect CI before marking Implemented.

## Agent progress notes
- Initial handoff: scope and acceptance criteria recorded; implementation has not started.


## Source audit and implementation plan (2026-11-05)

### Verified current behavior
- `Player` stores decryptor ownership as the standalone `has_decryptor` boolean.
- `shop.zig` owns only inventory/shop display and the one-time $150 decryptor purchase.
- `game.zig` checks decryptor ownership during decryption; topology movement adds a fixed 5 Detection and incorrect authentication adds 15.
- Save V2 persists balance, reputation, XP, decryptor ownership, active mission index, and mission completion flags. V1 and the original legacy layout are still accepted.
- The current test aggregate has no dedicated shop or save compatibility test module; HT-003 should add focused coverage before changing persistent equipment state.

### Milestones
1. Agree on the small typed equipment catalog, risk modifiers, upgrade levels/costs, and single utility slot before implementation.
2. Replace ad-hoc ownership with typed player equipment state while preserving the existing decryptor purchase command and semantics.
3. Add shop commands for inspecting, purchasing, equipping, and upgrading utility equipment; centralize effect calculation.
4. Introduce a new save version only if approved persistent equipment requires it; keep V2, V1, and legacy readers compatible.
5. Add focused catalog/shop/effect/save migration tests, update player-facing and agent documentation, self-review, and verify CI.

### Approved design (owner approval: 2026-11-05)
- Keep the decryptor as a required tool, separate from one mutually exclusive utility slot.
- Offer two utility choices with distinct risk profiles: Silent Boots reduce Detection per successful topology traversal; Signal Scrubber reduces Detection from incorrect authentication attempts.
- Each utility has two upgrade tiers after purchase. Only the equipped utility applies its effect; switching is allowed and does not destroy ownership.
- Persist owned utilities, equipped utility, and upgrade tiers in a new save version. Existing V2/V1/legacy saves migrate with no utility owned/equipped and retain decryptor ownership.
- Utility purchase price: $100 each; decryptor remains $150.
- Upgrade prices: $150 for level 1 and $250 for level 2.
- Silent Boots: movement Detection is 4 at level 0, 3 at level 1, and 2 at level 2 (base cost 5).
- Signal Scrubber: incorrect-password Detection is 12 at level 0, 9 at level 1, and 6 at level 2 (base cost 15).
- Both utilities may be owned; only one utility can be equipped at a time. Equipping another owned utility switches the active effect. The decryptor is separate from the utility slot.
- Save V3 persists equipment; V2/V1/legacy migrate with no utilities owned/equipped and zero upgrade levels.

### Implementation progress
- Owner approved the two-utility design, one-slot behavior, modifier values, and prices on 2026-11-05.
- Added typed Equipment and UtilityEquipment data to Player; utility ownership is a bit mask, with a typed optional equipped utility and independent 0–2 levels.
- Added utility purchase, equip, and upgrade operations. The decryptor remains a separate required tool.
- Wired equipment modifiers into topology movement and incorrect-password attempts.
- Introduced Save V3 and retained V2, V1, and legacy readers. Added a byte-based parser entry point for migration tests without filesystem coupling.
- Added focused equipment, shop, risk modifier, and save migration tests. CI verification and review remain pending.
