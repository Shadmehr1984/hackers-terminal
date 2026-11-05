# Gameplay Expansion Program — Master Plan

**Program ID:** EXPANSION-001  
**Owner direction:** Approved for planning on 2026-11-05  
**Implementation authorization:** HT-007 specifically authorized on 2026-11-05; all other features still require explicit owner authorization  
**Status:** Planning baseline recorded; HT-007 implementation merged to `main` via PR #11 (CI passed); all other features remain subject to per-feature approval

## Purpose

Expand the length, variety, replayability, and sense of a living fictional cyber-world while preserving Hacker's Terminal's identity: a single-player, command-driven, text-terminal hacking simulation. This document is the persistent handoff contract for future agents. It replaces reliance on the originating chat: an agent must be able to understand the intended work, dependencies, constraints, and verification expectations from repository files.

This is primarily a planning artifact, not blanket implementation authorization. HT-007 is the sole feature explicitly authorized and implemented so far; it is merged to `main` via PR #11. Do not add gameplay code, commands, save fields, balance values, or user-facing behavior for any other feature until the owner explicitly authorizes it.

## Current baseline verified during planning

- Zig 0.13.0; fictional, local, offline, single-player terminal game.
- Four built-in contracts: `job-01` through `job-04`; Ghost Signal is Reputation-gated and appended to preserve existing mission indices.
- Static `Mission` definitions live in `src/domain/mission.zig`; authored contracts/topologies/objectives live in `src/catalog/mission_data.zig`.
- `MissionSession` and `MissionPreparation` are runtime-only in `src/domain/mission_state.zig`; HT-007 adds the modifier snapshot and one-time completion-payout guard. The current objective completion representation is an eight-bit mask.
- `src/domain/mission_modifier.zig` defines the three approved typed modifiers; each current mission authors a static allowlist.
- `src/application/game.zig` coordinates commands and state transitions; `src/application/commands.zig` currently parses a command plus its first argument; `src/presentation/terminal.zig` owns terminal output.
- `src/domain/player.zig` owns player/equipment state; `src/application/shop.zig` owns shop transactions; `src/domain/progression.zig` owns XP/level/mission rewards and Reputation tiers; `src/domain/contacts.zig` owns the two current Contact definitions and unlock/service pricing.
- Save writer emits V3; V2, V1, and legacy formats remain readable. Existing mission-session details are not persisted.
- Current modules and constraints are documented in `AGENTS.md`, `.agent/conventions.md`, `docs/architecture.md`, `docs/gameplay.md`, `docs/commands.md`, and `docs/save-format.md`.

These are planning-time observations, not permission to assume source remains unchanged. Every implementation agent must re-audit the current branch before coding.

## Product principles — apply to every feature

1. Preserve terminal-first presentation, command-driven interaction, the single-player/offline model, and the fictional cyberpunk hacking theme.
2. All networks, hosts, security systems, organizations, contacts, agents, markets, and operations are simulated game content. No real networking, host access, shell execution, credential collection, or external-system interaction.
3. Favor meaningful decisions and distinct mechanics over larger quantities of repetitive missions or cosmetic names.
4. Keep domain rules testable without terminal I/O; preserve one-way module dependencies and focused module ownership.
5. Keep randomness deterministic or injectable in tests. A seeded local generator is acceptable only after a specific design is approved.
6. Do not silently rebalance existing mission rewards, XP, Reputation, Detection costs, equipment prices, or unlock rules.
7. Do not change save serialization incidentally. Every feature must classify its state as static catalog data, derived state, runtime-only state, or persistent player state.
8. Any intentional persistence change requires a separate migration design, documentation, and V3/V2/V1/legacy compatibility tests. A Save V4 is not pre-approved.
9. Preserve existing mission indices and old command behavior unless a feature brief explicitly authorizes and tests a deliberate change.
10. Story branching, dialogue trees, and player-choice narrative consequences remain out of scope. Multi-stage operations may carry mechanical state/results forward, but must not silently introduce branching narrative.

## Feature register — all 20 approved ideas

Each feature has a stable ID. The matching phase document contains its goal, design boundaries, acceptance criteria, likely ownership, dependencies, and handoff notes.

| ID | Feature | Phase document | Key dependencies |
|---|---|---|---|
| HT-006 | Contract Board | Phase 1 | Existing mission catalog, unlock rules, Contacts offers |
| HT-007 | Mission Modifiers | Phase 1 | Contract metadata, Detection model |
| HT-008 | Hidden Objectives | Phase 1 | Objective model; resolve eight-bit capacity before adding kinds |
| HT-009 | Multi-stage Operations | Phase 1 | Contract lifecycle, objectives, runtime session state |
| HT-010 | Factions | Phase 2 | Reputation, Contracts, Contacts |
| HT-011 | Rival Hackers | Phase 2 | Factions, contract availability/results |
| HT-012 | Information Market | Phase 2 | Contacts, mission intelligence, economy |
| HT-013 | Hacker Specializations | Phase 4 | Progression, Detection, topology, equipment |
| HT-014 | Level & Unlock Expansion | Phase 4 | XP/level progression, Contract Board |
| HT-015 | Tool Collection | Phase 4 | Equipment ownership/catalog/shop, mission actions |
| HT-016 | Security Profiles | Phase 3 | Mission definitions, Detection |
| HT-017 | Security Countermeasures | Phase 3 | Security Profiles, topology, Detection |
| HT-018 | Challenge Missions | Phase 4 | Contract Board, objectives, modifiers |
| HT-019 | Operational Costs | Phase 4 | Economy, equipment, Contacts, contract results |
| HT-020 | Recurring Contract Cycles | Phase 4 | Contract Board, deterministic offline cycle |
| HT-021 | Achievements | Phase 4 | Mission results, progression, objective outcomes |
| HT-022 | Data Archive | Phase 2 | Contract evidence, hidden discoveries, Factions/Market |
| HT-023 | Security Agent Behaviors | Phase 3 | Security Profiles, Countermeasures |
| HT-024 | Security Agent Memory | Phase 3 | Agent Behaviors, MissionSession |
| HT-025 | Contact Development | Phase 2 | Existing Broker/Fixer, Reputation, Factions, Market |

## Recommended execution order

Implement one feature/milestone at a time. This order is dependency-aware, not a promise that all listed features will be implemented without further design approval.

### Phase 1 — Contract and mission-content foundation
1. **HT-006 Contract Board:** establish a unified source of available contracts and offer metadata.
2. **HT-007 Mission Modifiers:** add bounded, authored, readable variations to contract runs.
3. **HT-008 Hidden Objectives:** add discoverable optional goals; first resolve objective storage capacity.
4. **HT-009 Multi-stage Operations:** chain authored contracts with explicit mechanical carry-over and recovery rules.

### Phase 2 — World, intelligence, and relationships
5. **HT-010 Factions:** add fictional organizations with distinct identities and contract relationships.
6. **HT-011 Rival Hackers:** add bounded, deterministic competitors that influence selected contract availability/results.
7. **HT-012 Information Market:** allow purchase/sale of fictional intelligence with clear reliability and price rules.
8. **HT-025 Contact Development:** deepen Broker/Fixer services and unlocks before considering additional Contacts.
9. **HT-022 Data Archive:** retain discovered fictional evidence, dossiers, and operation records.

### Phase 3 — Security depth and simulated agents
10. **HT-016 Security Profiles:** define distinct authored security styles per target.
11. **HT-017 Security Countermeasures:** add readable tactical responses tied to profile and node state.
12. **HT-023 Security Agent Behaviors:** introduce distinct deterministic simulated security-agent roles.
13. **HT-024 Security Agent Memory:** allow bounded within-operation adaptation; clarify reset/persistence rules.

### Phase 4 — Player build, economy, and replayability
14. **HT-013 Hacker Specializations:** provide complementary play styles without locking out core content.
15. **HT-014 Level & Unlock Expansion:** add meaningful unlock pacing without casually changing existing XP thresholds.
16. **HT-015 Tool Collection:** expand tools with distinct capabilities, constraints, and equipment interactions.
17. **HT-019 Operational Costs:** add transparent costs and risk/reward decisions without soft-locking progression.
18. **HT-020 Recurring Contract Cycles:** simulate daily/weekly-style refreshes without requiring real time or internet.
19. **HT-021 Achievements:** track durable milestones with testable unlock conditions.
20. **HT-018 Challenge Missions:** add repeatable mastery challenges after the supporting systems exist.

## Dependency and sequencing rules

- Contract Board must be designed before recurring contracts, challenge listings, and rival-driven contract availability.
- Mission Modifiers must not become arbitrary random penalties. HT-007 is designed for manual player selection of zero or one modifier during Preparation; exact effects, eligibility, reward, lifecycle, and no-save-change rules are in its task brief. Implementation is complete and merged to `main` via PR #11; CI run #575 passed. Follow the HT-007 task brief.
- Hidden Objectives must not exceed the current eight-bit objective-kind mask. Prefer redesigning objective progress around objective identity/counts before introducing a ninth kind; do not overload existing bits.
- Multi-stage Operations must define failure, retry, stage reward, and partial-completion behavior. They are mechanical sequences, not branching stories.
- Factions should use derived relationship state where possible. Do not add persisted faction scores before a separate save decision.
- Rival Hackers must not simulate actual network traffic or external users. Their actions are local deterministic game events.
- The Information Market must distinguish known facts, uncertain intelligence, and deliberately false intel; it must never reveal puzzle answers where the current design intends discovery.
- Security Profiles, Countermeasures, Agent Behaviors, and Agent Memory form a dependency chain. Do not implement all four as one large system.
- Agent Memory means in-game simulated security agents remembering events within the fictional game, not external AI agents, real processes, or cross-session model memory.
- Specializations, level unlocks, tool collection, and operational costs must be balanced together. Avoid permanent build choices that make a save unwinnable.
- Recurring cycles must use an explicit offline deterministic cycle/seed or player-advanced cycle. Do not require system clock, online feeds, or a live service unless the owner separately approves a product-direction change.
- Achievements and Data Archive must explicitly define whether progress is derived, runtime-only, or persistent. No save change is implied by this plan.

## Architecture and data ownership guidance

Use this as a starting map only; confirm current source before implementation.

| Concern | Likely owner | Avoid |
|---|---|---|
| Static contract/modifier/faction/profile definitions | `src/domain/mission.zig` and focused catalog modules under `src/catalog/` | Runtime mutation of static catalog data |
| Runtime operation, modifier rolls, agent state, hidden discoveries | Focused types under `src/domain/` | Persistence or terminal I/O in domain modules |
| Command workflows and transactions | `src/application/game.zig` or focused application services | Domain types importing the command coordinator |
| Player unlocks, specializations, tool ownership, achievements | Focused domain modules; `player.zig` only for core player-owned state | Growing Player into a monolith |
| Contact/faction/market rules | Focused domain modules and application services | Contact output logic in domain types |
| Terminal display and command help | `src/presentation/terminal.zig` | State mutation/reward decisions |
| Save migration | `src/persistence/save.zig` only after explicit schema approval | Incidental format edits |
| Tests | New focused files under `tests/`, registered in `tests/test_all.zig` | Test modules inside `src/` |

Create a new module only when it represents a stable responsibility with a clear contract. Do not create a generic framework for hypothetical future content.

## Required per-feature handoff checklist

Before implementation:
- Read `AGENTS.md`, `.agent/README.md`, `.agent/workflow.md`, `.agent/conventions.md`, this master plan, and the matching phase document.
- Re-fetch current `main`/authorized branch source, docs, tests, save code, and CI status. Do not rely on this planning snapshot alone.
- Record the source audit, proposed module ownership, data model, command syntax, state lifetime, save impact, edge cases, test plan, and user-visible behavior in a feature-specific task brief.
- Identify dependency completion and any unresolved owner decisions. Ask before changing approved scope, balancing, commands, or persistence.
- Implement only the explicitly authorized feature and its necessary foundations.

During/after implementation:
- Follow Explore → Understand → Plan → Implement → Verify → Document → Review → Commit.
- Add focused tests, aggregate registration, Zig 0.13.0 formatting/build/full tests, and CI inspection.
- Update `AGENTS.md`, module contracts, gameplay/command/architecture/save docs, roadmap, and task status when their contracts actually change.
- Perform independent review when available; otherwise record self-review honestly.
- Do not merge or start the next phase without explicit owner approval.

## Global acceptance criteria for the program

- The terminal-first fictional hacking identity remains intact.
- New content creates distinct player decisions, not only renamed/repeated contracts.
- All new rules are deterministic or testable with injected randomness.
- No real networking, external host interaction, shell execution, credential collection, or external services are added.
- Existing contracts and save compatibility remain intact unless separately approved.
- Each feature has tests for success, rejection, boundary, retry, and state-reset behavior as applicable.
- Player-facing help, command docs, gameplay docs, architecture docs, and agent handoff docs remain synchronized.
- No feature is marked Implemented until code, tests, docs, review, and actual CI checks are complete.

## Open design decisions — deliberately not pre-decided

The following require a feature-specific design and owner approval before implementation:
- Contract Board command surface and whether the existing `missions` command is extended or a new command is added.
- Future modifier additions, eligibility changes, stacking, or automatic selection beyond the accepted HT-007 design.
- Objective storage redesign beyond eight objective kinds.
- Multi-stage operation reward timing, retry model, and persistence.
- Faction relationship representation and any save impact.
- Rival simulation cadence and how rivals affect availability/results without frustrating the player.
- Information quality/reliability model and market pricing.
- Specialization respec rules and balance.
- Whether level cap/XP thresholds remain as-is or are deliberately redesigned.
- Tool slots, stacking, charges, and consumable behavior.
- Security profile and countermeasure effect tables.
- Security-agent activation/turn model and adaptation limits.
- Operational cost categories, failure debt/soft-lock protection, and economy sinks.
- Recurring-cycle advancement model and offline refresh behavior.
- Achievement/Data Archive persistence and save migration.
- Contact offer cadence, exclusivity, and whether more than two Contacts are justified.

Do not resolve these by assumption. Record accepted decisions in a new ADR only after the owner approves them.
