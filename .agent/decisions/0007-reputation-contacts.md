# ADR 0007: Reputation Tiers, Derived Contact Unlocks, and Offers

- Status: Accepted
- Date: 2026-11-05

## Context

HT-005 turns the existing persisted Reputation counter into a meaningful progression system and adds two fictional contacts. The feature must preserve Save V3 and keep all game interactions local and offline.

## Decision

- Reputation tiers are derived from the numeric Reputation value: 0 Unknown, 1–2 Recognized, 3–4 Trusted, and 5+ Elite.
- A successfully completed contract grants +1 Reputation. Completing every optional objective in that contract grants +1 additional Reputation. Partial optional completion grants its existing cash bonus but no Reputation bonus. Failed/compromised contracts grant no Reputation and never reduce it.
- Information Broker unlocks at Reputation 1 and sells clues for an eligible, incomplete contract for $50. It reveals the authored password and decryption clues, never puzzle answers.
- Fixer unlocks at Reputation 3. Its Detection service reduces current Detection by up to 10, is usable once per active contract, costs $100 at Trusted and $75 at Elite, and cannot be used when Detection is zero or no contract is active.
- Fixer offers the exclusive Ghost Signal contract at Reputation 3 and player level 3. Ghost Signal is job-04, requires both thresholds, is marked contact-offer-only (direct prepare is rejected), and is appended after job-01 through job-03 to preserve existing mission indices.
- Contact unlocks and offer availability are derived from Reputation, level, and mission completion state. They are not separately persisted. The Fixer service-use flag is runtime-only and resets with the mission session.
- Save V3 remains unchanged. The current writer emits four mission completion flags; older saves with three flags leave the appended mission incomplete by default.

## Consequences

- progression.zig owns tier calculation and mission Reputation rewards.
- contacts.zig owns fictional Contact identities, unlock thresholds, and Fixer pricing.
- mission.zig adds static required_reputation and requires_contact_offer metadata; mission_data.zig appends Ghost Signal at index 3.
- mission_state.zig tracks the one-use Fixer service flag for the current contract.
- game.zig validates and executes contact offers; terminal.zig presents contact and offer information.
- save.zig and the Save V3 serialized field order remain unchanged.
- Tests cover tier boundaries, reward rules, unlocks, clue secrecy, offer costs, per-contract service limits, and old-save migration behavior.
