# Phase 2 — World, Intelligence, and Relationships

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** HT-010 In Progress on main; remaining Phase 2 features are Planned  
**Goal:** Make the fictional cyber-world feel populated by organizations, competitors, information brokers, and persistent discoveries.

## Shared baseline and constraints

The game currently has two Contacts (Information Broker and Fixer), Reputation tiers derived from the persisted numeric Reputation value, a small fixed contract catalog, and a local shop/economy. Re-audit `src/domain/contacts.zig`, `src/domain/progression.zig`, `src/domain/mission.zig`, `src/catalog/mission_data.zig`, `src/application/game.zig`, `src/application/shop.zig`, and Save V3 before implementation.

Use fictional organizations and deterministic local simulation only. Avoid adding persistent relationship scores or a new save version without separate owner approval.

## HT-010 — Factions

### Goal
Introduce fictional organizations with distinct identities, security styles, contract pools, and competing interests.

### Design direction
- Start with a small authored set (e.g. megacorporation, independent collective, underground information syndicate, civic watchdog); final names and lore require owner review.
- Contracts may identify a client, target owner, or opposing faction.
- Relationships should preferably be derived from completed contract outcomes and current Reputation before adding another persisted score.
- Conflicting interests may change which contracts are offered, but must not create branching narrative.

### Likely scope
Faction domain types and catalog, contract metadata, availability rules, terminal presentation, tests/docs; persistence only if separately approved.

### Acceptance criteria
- [ ] Factions have distinct authored identities and mechanically meaningful differences.
- [ ] Contract/faction relationships are explicit and validated.
- [ ] Availability/relationship calculations are deterministic and testable.
- [ ] Existing Reputation and Contact unlock thresholds are not silently rebalanced.
- [ ] No new save fields are added without a migration decision.

### Dependencies
HT-006 Contract Board; existing Reputation/Contacts.

### Out of scope
Real organizations, real political groups, player alliances, branching story.

## HT-011 — Rival Hackers

### Goal
Add a small cast of fictional competitors who can contest contracts and leave clues of their activity.

### Design direction
- Rivals are local scripted/simulated actors, not network users or autonomous external agents.
- Use bounded event schedules or deterministic state transitions (e.g. rival accepted, rival completed, rival failed, rival left a trace).
- Rival activity should create opportunities and readable consequences, not randomly steal progress or punish the player without warning.
- Rival presence may be tied to faction affiliation and selected contract availability.

### Likely scope
Rival definitions/state, local simulation rules, Contract Board integration, optional archive events, terminal presentation, tests/docs.

### Acceptance criteria
- [ ] Rivals have stable identities and distinct, testable behavior profiles.
- [ ] Every player-visible rival action has a deterministic trigger or injectable schedule.
- [ ] Rival events are disclosed in the board/briefing before materially affecting a contract.
- [ ] Rivals never mutate the player's active mission state unexpectedly.
- [ ] No multiplayer, network access, or real external account is introduced.

### Dependencies
HT-006 Contract Board and HT-010 Factions.

### Out of scope
Live multiplayer, online leaderboards, unbounded autonomous simulation.

## HT-012 — Information Market

### Goal
Expand the existing Broker intel purchase into a small market for fictional intelligence with quality, price, and reliability trade-offs.

### Design direction
- Distinguish verified facts, partial intel, stale intel, and intentionally unreliable/false reports.
- Offer categories such as topology hints, security profile summaries, faction dossiers, rival sightings, and hidden-objective leads.
- Preserve the current rule that purchased clues do not reveal actual puzzle answers.
- Prices and quality must be visible before purchase; invalid/unaffordable transactions must not charge the player.
- Use authored or seeded market inventory, not live external feeds.

### Likely scope
Information item definitions/catalog, market transaction service, Contact integration, player balance handling, terminal output, tests/docs.

### Acceptance criteria
- [ ] Every information item has a typed category, price, and reliability/knowledge level.
- [ ] Player can inspect an item before purchase and understands what is known versus uncertain.
- [ ] Successful purchases deduct exactly the displayed amount; rejected purchases do not change balance/state.
- [ ] Purchased intel is delivered to the correct game surface (briefing/archive) and does not leak protected answers.
- [ ] Market stock/refresh is deterministic or seeded and testable.

### Dependencies
HT-006 Contract Board; HT-010 Factions; HT-025 Contact Development where services are exposed through Contacts.

### Out of scope
Online marketplace, real data feeds, player trading, puzzle-answer sales.

## HT-025 — Contact Development

### Goal
Make the existing Information Broker and Fixer more useful over long play without immediately multiplying the Contact cast.

### Design direction
- Extend current Broker/Fixer service progression, offer quality, and unlock conditions.
- Tie new services to Reputation, completed contracts, Factions, and/or archive discoveries.
- Keep Contact identities stable; new Contact characters require a separate owner-approved content decision.
- Avoid making existing Broker clue purchase and Fixer Detection service unusable or changing their prices without approval.

### Likely scope
`src/domain/contacts.zig` or focused Contact service types, offer availability/transactions, game dispatch, terminal output, tests/docs.

### Acceptance criteria
- [ ] Existing Broker/Fixer offers remain available under their current requirements unless a deliberate change is approved.
- [ ] New offers have explicit unlock conditions, costs, limits, and effects.
- [ ] Offer availability is derived where practical rather than redundantly persisted.
- [ ] Transactions are atomic: failed validation does not charge or consume a service.
- [ ] Contact service use/reset and persistence lifetime are documented and tested.

### Dependencies
HT-010 Factions; HT-012 Information Market; existing Reputation/Contacts.

### Out of scope
Dialogue trees, real messaging, external contact discovery, mandatory social mechanics.

## HT-022 — Data Archive

### Goal
Give the player a place to review evidence, dossiers, discoveries, operation reports, and unlocked world information accumulated during play.

### Design direction
- Distinguish static authored lore from player-discovered facts and per-run transient data.
- Archive entries should be useful: identify source contract, discovery condition, faction/rival relationship, and whether intel is verified or uncertain.
- Avoid storing redundant copies of static catalog data.
- Decide which discoveries are derived from completed mission history and which require persistent flags.
- Persistence is not pre-approved; any archive progress not derivable from existing saves needs a separate migration plan.

### Likely scope
Archive domain/catalog types, mission result/discovery events, terminal archive commands/views, tests/docs, save migration only after approval.

### Acceptance criteria
- [ ] Player can list and inspect unlocked archive entries.
- [ ] Locked entries reveal no protected details.
- [ ] Entries retain source/provenance and knowledge reliability.
- [ ] Repeated discovery does not duplicate entries or grant duplicate rewards.
- [ ] Archive state is correctly classified as derived, runtime-only, or persistent.
- [ ] Save V3 compatibility remains intact unless an approved migration is implemented.

### Dependencies
HT-008 Hidden Objectives; HT-010 Factions; HT-012 Information Market; multi-stage operation reports from HT-009.

### Out of scope
Free-form player notes requiring complex text editing, external files, online lore feeds.

## Phase exit criteria

- [ ] Faction, rival, market, Contact, and archive rules have clear ownership and deterministic tests.
- [ ] Reputation and existing Contact rules remain backward compatible unless specifically approved.
- [ ] Every purchased/discovered information item has provenance and secrecy rules.
- [ ] Persistent world state has an explicit migration decision before code changes.
