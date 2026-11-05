# HT-003 — Equipment & Upgrade System

**Status:** Planned  
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
