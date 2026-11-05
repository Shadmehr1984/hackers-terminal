# Phase 4 — Player Builds, Economy, and Replayability

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** Planned; implementation not authorized  
**Goal:** Give players long-term goals, distinct play styles, meaningful equipment choices, and reasons to revisit contracts.

## Shared baseline and constraints

Current XP level is derived by `src/domain/progression.zig`, with level 1 starting below 100 XP and later thresholds increasing by 150; level is capped at 99. Reputation is persisted and tiers are derived. Equipment is typed in `src/domain/player.zig`; purchase/equip/upgrade rules live in `src/application/shop.zig`. Mission loadout is snapshotted at launch. Save writer is V3 and old formats remain readable.

Do not casually replace XP thresholds, change existing prices/rewards, or add persistent fields. Re-audit source and Save V3 before every feature.

## HT-013 — Hacker Specializations

### Goal
Let the player develop a preferred hacking style through complementary specialization paths.

### Design direction
Possible paths: Ghost (stealth/risk management), Cryptographer (decryption/intelligence), Architect (topology/navigation), and Data Runner (extraction/objective efficiency).
- Specializations should provide small, explainable bonuses or unlock options, not hard class restrictions.
- Avoid permanent irreversible choices until respec rules and balance are approved.
- Specialization effects must integrate with run loadout snapshots so mid-run changes do not alter an active contract.

### Likely scope
Specialization domain types, player progression state, reward/unlock rules, mission loadout snapshot, terminal status/preparation, tests/docs; save design only if approved.

### Acceptance criteria
- [ ] Each specialization has a distinct, measurable, testable identity.
- [ ] Player can inspect effects and prerequisites before selecting/unlocking.
- [ ] No specialization makes a core contract permanently impossible.
- [ ] Active missions use a stable launch-time snapshot.
- [ ] Respec/reset and persistence behavior are explicit and tested.
- [ ] Existing XP, Reputation, and equipment behavior remains unchanged unless approved.

### Dependencies
HT-016 Security Profiles, HT-007 Modifiers, HT-014 unlock framework, HT-015 tool expansion.

### Out of scope
Rigid RPG classes, branching story, unannounced permanent penalties.

## HT-014 — Level & Unlock Expansion

### Goal
Make progression levels unlock meaningful content over a longer game without turning level into a cosmetic number.

### Design direction
- Define unlock categories: contracts, factions, security profiles, tools, challenge tiers, and Contact services.
- Prefer derived unlock conditions over duplicated persisted booleans.
- Keep existing level cap and XP thresholds until an explicit balancing proposal is approved.
- Avoid grinding-only gates; provide visible progress and alternate skill/achievement-based unlocks where suitable.

### Likely scope
Progression domain/service, contract/board availability, terminal status, tests/docs; save changes only if an unlock cannot be derived.

### Acceptance criteria
- [ ] Every unlock has an explicit requirement and player-visible progress.
- [ ] Unlock checks are centralized and deterministic.
- [ ] Existing four contracts retain their current unlock rules unless explicitly approved.
- [ ] Level/XP calculations have boundary and cap tests.
- [ ] No duplicate persistent state is stored when derivation is possible.

### Dependencies
HT-006 Contract Board; HT-010 Factions; HT-013 specialization prerequisites where relevant.

### Out of scope
Silent XP curve changes, infinite level growth, hidden grind gates.

## HT-015 — Tool Collection

### Goal
Expand the equipment catalog with tools that change available tactics rather than merely increasing numeric stats.

### Design direction
Possible tools: Packet Analyzer (extra simulated node intel), Trace Masker (specific exposure mitigation), Memory Extractor (special evidence access), Signal Jammer (temporary simulated security disruption), Crypto Scanner (pre-decryption metadata), Node Mapper (partial topology reveal).
- These names describe fictional game tools only.
- Define tool type, capability, cost, use limit/charges, slot rules, upgrade behavior, mission compatibility, and interaction with existing decryptor/utilities.
- Avoid generic inventory frameworks unless concrete tool behaviors require them.

### Likely scope
Equipment domain/catalog, shop transactions, mission loadout snapshot, game actions, terminal inventory/shop/preparation, tests/docs and possible save migration.

### Acceptance criteria
- [ ] Every tool has a unique gameplay capability and explicit limits.
- [ ] Purchase/equip/use/recharge/upgrade validation is atomic and tested.
- [ ] Existing decryptor and two utility behaviors remain compatible.
- [ ] Mid-run equipment changes cannot mutate the active mission snapshot.
- [ ] Unaffordable, unavailable, incompatible, or exhausted-tool attempts do not charge or corrupt state.
- [ ] Persistence is explicitly designed; no incidental Save V4.

### Dependencies
HT-013 Specializations and HT-016/017 security systems; existing HT-003 equipment foundation.

### Out of scope
Real packet capture, actual memory extraction, real network utilities, executable payloads.

## HT-018 — Challenge Missions

### Goal
Offer repeatable mastery challenges that test alternate strategies after the player understands the core game.

### Design direction
Examples: finish under a Detection ceiling, complete without a selected tool, discover every hidden objective, use a bounded move count, or extract via a non-primary route.
- Challenges should be explicit rule sets over existing contracts or dedicated authored challenge entries.
- Show all challenge constraints and rewards before launch.
- Challenge failures must not unfairly erase normal contract progress or create unbounded penalties.
- Distinguish a challenge clear from a first-time contract completion to avoid duplicate rewards.

### Likely scope
Challenge definitions/catalog, validation and result state, Contract Board integration, terminal display, tests/docs, achievement integration.

### Acceptance criteria
- [ ] Each challenge has explicit constraints, eligibility, reward, and repeatability rules.
- [ ] Player can inspect all constraints before accepting.
- [ ] Challenge completion checks are deterministic and boundary-tested.
- [ ] Replays do not duplicate first-clear cash/XP/Reputation unless a repeat reward is deliberately defined.
- [ ] Challenge failure does not corrupt normal contract completion or save state.

### Dependencies
HT-006 Contract Board; HT-007 Modifiers; HT-008 Hidden Objectives; HT-013/015 progression and tools.

### Out of scope
Timed real-world leaderboards, multiplayer competition, opaque scoring.

## HT-019 — Operational Costs

### Goal
Make preparation and operations involve transparent resource-management choices beyond buying equipment.

### Design direction
Potential costs: optional pre-mission intelligence, repairs, limited Contact services, temporary access support, and post-operation cleanup.
- Each cost must have a clear benefit and price displayed before confirmation.
- Avoid mandatory recurring costs that can drain a new player into a soft-lock.
- Define what happens on failure/compromise and whether a purchased service is refunded.
- Preserve existing $50 compromise penalty and current prices unless explicitly rebalanced.

### Likely scope
Economy rules/service transactions, player balance operations, shop/Contact integration, mission preparation, tests/docs.

### Acceptance criteria
- [ ] Every operational cost is optional or has a safe guaranteed funding path.
- [ ] Cost and benefit are shown before purchase/commit.
- [ ] Failed transactions never partially deduct funds or consume a service.
- [ ] Failure/retry refund and consumption rules are explicit and tested.
- [ ] New costs cannot make progression permanently unwinnable.
- [ ] Existing balance, decryptor price, utility prices, and compromise penalty remain unchanged absent approval.

### Dependencies
HT-012 Information Market; HT-015 Tool Collection; HT-025 Contact Development.

### Out of scope
Real-money purchases, microtransactions, online economies, punitive upkeep.

## HT-020 — Recurring Contract Cycles

### Goal
Make the contract board feel refreshed over repeated play sessions without requiring online services or real-time availability.

### Design direction
- Simulate daily/weekly-style cycles through a deterministic local cycle index, explicit player-advanced cycle, or seeded schedule.
- Do not require system clock, internet, server time, or background process.
- Define whether refresh can be triggered by player action, operation completion, or a local calendar snapshot.
- Ensure fixed story contracts never disappear or become permanently inaccessible.
- Keep recurring contract generation bounded and testable.

### Likely scope
Cycle state/generator, contract board integration, deterministic seed rules, terminal output, tests/docs; persistence only if cycle continuity is approved.

### Acceptance criteria
- [ ] Player understands current cycle and refresh trigger.
- [ ] Same cycle seed produces the same contract set.
- [ ] Fixed core contracts remain available under their original rules.
- [ ] Refresh cannot duplicate unique rewards or erase active/prepared contracts.
- [ ] Offline/restart behavior is explicit and tested.
- [ ] No real-time or online dependency is introduced.

### Dependencies
HT-006 Contract Board; HT-007 Modifiers; HT-010 Factions and HT-011 Rivals for richer contract pools.

### Out of scope
Real daily login rewards, live events, online feeds, background monitoring.

## HT-021 — Achievements

### Goal
Give players long-term optional goals for exploring mechanics and mastering different approaches.

### Design direction
Examples: Ghost Protocol (clean operations), Data Hunter (hidden discoveries), Clean Operator (no failures), Network Architect (exploration), Trusted Name (Reputation), Risk Taker (high-exposure completion).
- Achievement definitions are static; completion should be derived from authoritative events/history where practical.
- Separate one-time unlock rewards from cosmetic recognition to prevent duplicate economy rewards.
- Decide whether completion is derivable from existing saves or requires persistent flags before implementation.

### Likely scope
Achievement domain/catalog, event/result integration, terminal list/detail output, tests/docs, possible save migration.

### Acceptance criteria
- [ ] Every achievement has a stable ID, description, exact unlock condition, and reward policy.
- [ ] Unlock checks are deterministic and do not rely on parsing terminal output.
- [ ] Repeated events cannot duplicate one-time rewards.
- [ ] Existing save files load correctly; new persistence is separately approved.
- [ ] Player can inspect locked/unlocked achievements and progress where measurable.

### Dependencies
Mission outcomes, HT-008 Hidden Objectives, HT-013 Specializations, HT-014 progression, HT-018 challenges.

### Out of scope
Online trophies, account linking, cloud synchronization, leaderboard service.

## Phase exit criteria

- [ ] Specialization, unlock, tool, economy, cycle, challenge, and achievement rules have compatible balance and clear ownership.
- [ ] Existing player progression remains completable and backward compatible.
- [ ] No mandatory cost or specialization choice can soft-lock a save.
- [ ] All persistent progress has an explicit save migration decision before implementation.
