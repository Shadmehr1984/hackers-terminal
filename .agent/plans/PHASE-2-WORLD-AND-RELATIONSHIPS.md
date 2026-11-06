# Phase 2 — World, Intelligence, and Relationships

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** HT-010 and HT-010.1 Implemented on main (final CI #42224233431 passed Debug, ReleaseSafe, and ReleaseFast); HT-011 implementation is In Progress on main; remaining Phase 2 features are Planned  
**Goal:** Make the fictional cyber-world feel populated by organizations, competitors, information brokers, and persistent discoveries.

## Shared baseline and constraints

The game currently has two Contacts (Information Broker and Fixer), Reputation tiers derived from the persisted numeric Reputation value, a small fixed contract catalog, and a local shop/economy. Re-audit `src/domain/contacts.zig`, `src/domain/progression.zig`, `src/domain/mission.zig`, `src/catalog/mission_data.zig`, `src/application/game.zig`, `src/application/shop.zig`, and Save V3 before implementation.

Use fictional organizations and deterministic local simulation only. Avoid adding persistent relationship scores or a new save version without separate owner approval.

## HT-010 — Factions

### Goal
Introduce fictional organizations with distinct identities, security styles, contract pools, and competing interests.

### Design direction
- Accepted roster: Nexus Dynamics, Ghost Protocol, Black Veil, Aegis Initiative, Iron Meridian, Null Syndicate, and Helix Consortium. Their full authored profiles are in .agent/tasks/HT-010-factions.md and src/catalog/faction_data.zig.
- Contracts may identify a client, target owner, or opposing faction.
- Relationships should preferably be derived from completed contract outcomes and current Reputation before adding another persisted score.
- Conflicting interests may change which contracts are offered, but must not create branching narrative.

### Likely scope
Faction domain types and catalog, contract metadata, availability rules, terminal presentation, tests/docs; persistence only if separately approved.

### Accepted design baseline (ADR 0012)
- Seven stable faction identities with distinct authored security/economic profiles.
- Static symmetric faction-to-faction relationships; unspecified pairs are Neutral.
- Player standing is derived from global Reputation and completed contract outcomes; no independent score is persisted.
- Hostile standing toward a contract client blocks board availability and contract selection.
- Save V3 and all older readers remain unchanged.

### Acceptance criteria
- [x] Factions have distinct authored identities and mechanically meaningful differences.
- [x] Contract/faction relationships are explicit and validated.
- [x] Availability/relationship calculations are deterministic and testable.
- [x] Existing Reputation and Contact unlock thresholds are not silently rebalanced.
- [x] No new save fields are added without a migration decision.

### Dependencies
HT-006 Contract Board; existing Reputation/Contacts.

### Out of scope
Real organizations, real political groups, player alliances, branching story.

## HT-011 — Rival Hackers

**Status:** In Progress on `main`; approved design in [ADR 0014](../decisions/0014-rival-hackers.md), implementation handoff in [HT-011 task brief](../tasks/HT-011-rival-hackers.md).

### Goal
Add five fictional competitors who contest optional intelligence opportunities and leave readable traces.

### Accepted design
- Impact: Medium; exactly five rivals.
- Ghost Operator / Ghost Protocol / job-03 / relay-trace.
- Null Byte / Null Syndicate / job-04 / mirror-fragment.
- Glasswire / Black Veil / job-02 / routing-header.
- Patchwork / Iron Meridian / job-01 / maintenance-telemetry.
- Redshift / Helix Consortium / job-05 / mirror-fragment.
- Statuses: DORMANT, CONTESTING, RIVAL_AHEAD, OUTPACED.
- After successful decryption, a rival claims its linked hidden optional objective only if the player has not discovered it. Existing discovery triggers provide the counterplay.
- Rival identity and counterplay are disclosed on the board, in Preparation, and in active Briefing.

### Hard constraints
- The rival event affects only its linked hidden optional objective for the current runtime session.
- It never changes required objectives, blocks extraction, removes/locks the primary contract, or mutates other mission state.
- No Detection, cash, XP, Reputation, faction-standing, or base reward changes.
- Rival profiles are static; contest outcomes use the existing runtime objective tracker.
- Save V3 and all older readers remain unchanged.
- All actors/events remain fictional, local, deterministic, and offline.

### Acceptance criteria
- [ ] Five unique validated rival profiles and stable command IDs.
- [ ] Deterministic derivation of all four rival statuses.
- [ ] `rivals` and `rival <id>` terminal commands.
- [ ] Contract Board, Preparation, and Briefing disclose rival activity and counterplay.
- [ ] Rival claims an undiscovered linked optional objective after successful decryption.
- [ ] Discovering the linked objective first prevents the rival claim.
- [ ] Main contract and all required objectives remain completable.
- [ ] No economy, Detection, Reputation, faction, or Save format changes.
- [ ] Focused tests, documentation, code review, and CI pass.

### Dependencies
HT-006 Contract Board and HT-010 Factions.

### Out of scope
Live multiplayer, online leaderboards, autonomous external agents, real networking, branching narrative, and persistent rival scores.

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
