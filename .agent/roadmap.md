# Project Roadmap

This roadmap records owner-approved feature direction and implementation order. Task briefs are the execution contracts for coding agents. A feature is not implemented merely because it is approved or has a task brief.

## Implemented foundation
- Modular Zig 0.13.0 terminal game.
- Five built-in missions with descriptive difficulty metadata, including Reputation-gated Ghost Signal and faction-gated Corporate Ghost.
- Required and optional objectives with live progress and optional cash bonuses.
- Local save/load with V2, V1, and legacy compatibility.
- Unit tests and GitHub Actions formatting/build/test workflow.
- Agent instructions, module contracts, ADRs, task briefs, and review workflow.

## Approved gameplay program

The project owner approved these five feature areas on 2026-11-05. Implement them in the following order, one coherent milestone at a time. Do not start all systems simultaneously; later systems depend on foundations established by earlier work.

| Order | Feature | Task brief | Status | Dependency |
|---:|---|---|---|---|
| 1 | Detection & Risk System | [HT-001](tasks/HT-001-detection-risk.md) | Implemented | None |
| 2 | Fictional Network Topology | [HT-002](tasks/HT-002-network-topology.md) | Implemented | Detection/risk model should be defined first so topology can expose risk-aware choices |
| 3 | Equipment & Upgrade System | [HT-003](tasks/HT-003-equipment-upgrades.md) | Implemented | Detection/risk and topology provide meaningful equipment trade-offs |
| 4 | Mission Preparation | [HT-004](tasks/HT-004-mission-preparation.md) | Implemented | Reuses mission topology, equipment, and risk concepts |
| 5 | Reputation & Contacts | [HT-005](tasks/HT-005-reputation-contacts.md) | Implemented | Builds on mission outcomes and preparation/progression; Save V3 remains unchanged |

### Program-wide design constraints
- All hacking, hosts, networks, detection, and operations remain fictional, deterministic or game-randomized simulations running locally/offline.
- Never add real network scanning, external host connections, shell execution, credential collection, or interaction with external systems.
- Preserve the existing terminal-first, single-player experience.
- Prefer testable domain state and game rules over terminal I/O. Keep module dependencies one-way.
- Do not change save serialization incidentally. Each task must explicitly decide whether its feature state is transient or persistent; any intentional format change requires a documented migration and compatibility tests for V2, V1, and legacy saves.
- Maintain backwards-compatible command behavior unless a task explicitly defines and tests a deliberate change.
- Update AGENTS.md, module contracts, architecture docs, gameplay docs, and ADRs only when the implementation establishes lasting rules or decisions.
- Do not implement story branching as part of this program. Branching objectives and branching narrative remain deferred.

## Gameplay Expansion Program — EXPANSION-001

The owner approved planning for the next 20 gameplay ideas on 2026-11-05. HT-006 is implemented and merged. HT-007 is implemented and merged to `main` via PR #11; CI has passed. HT-008 was implemented directly on `main` on 2026-11-05 after explicit owner authorization; final implementation CI run #679 passed. HT-009 design and Runtime-only persistence were approved in ADR 0011; implementation was explicitly authorized and completed directly on `main` on 2026-11-06; GitHub Actions run #733 passed. HT-010 seven-faction design and derived standing were explicitly approved on 2026-11-06 and are in progress on `main` under ADR 0012 and task brief HT-010. HT-010.1 Corporate Ghost was approved as the fifth contract to make Nexus faction access recoverable; implementation is complete under ADR 0013 and its task brief (CI run #42221149753 passed).

| Phase | Scope | Plan | Status |
|---|---|---|---|
| 1 | Contract Board, Mission Modifiers, Hidden Objectives, Multi-stage Operations (HT-006–HT-009) | [Phase 1](plans/PHASE-1-MISSION-CONTENT.md) | HT-006 Implemented; HT-007 Implemented and Merged (PR #11); HT-008 Implemented on `main` (CI #679 passed); HT-009 Implemented on `main` (Runtime-only; CI #733 passed) |
| 2 | Factions, Rival Hackers, Information Market, Contact Development, Data Archive (HT-010–HT-012, HT-022, HT-025) | [Phase 2](plans/PHASE-2-WORLD-AND-RELATIONSHIPS.md) | HT-010 In Progress on `main`; HT-010.1 Implemented (CI #42221149753); remaining Phase 2 features Planned |
| 3 | Security Profiles, Countermeasures, Security Agent Behaviors and Memory (HT-016–HT-017, HT-023–HT-024) | [Phase 3](plans/PHASE-3-SECURITY-SYSTEMS.md) | Planned |
| 4 | Specializations, Level/Unlocks, Tool Collection, Operational Costs, Recurring Contracts, Achievements, Challenges (HT-013–HT-015, HT-018–HT-021) | [Phase 4](plans/PHASE-4-PROGRESSION-AND-REPLAYABILITY.md) | Planned |

The complete feature register, dependency order, architectural guidance, open design decisions, and mandatory agent handoff checklist are in [the master plan](plans/GAMEPLAY-EXPANSION-OVERVIEW.md). All 20 feature IDs HT-006 through HT-025 are individually specified in the phase plans.

The existing HT-001 through HT-005 program remains implemented. EXPANSION-001 is a separate future program and must not be conflated with those completed features.

## Deferred candidate
- More expressive mission branching and consequences — intentionally deferred; not part of the approved five-feature sequence.

## Planning and status rules
- The task brief is the source of scope and acceptance criteria for each feature. Agents must read it before implementation and update its status/progress notes as work advances.
- Status values: Planned, Design Approved, In Progress, Blocked, Implemented. Use Implemented only after code, tests, documentation, review, and the relevant CI checks are complete.
- Discuss substantial scope changes with the project owner before proceeding.
- Do not begin a later feature while an earlier feature has unresolved foundational decisions, unless the owner explicitly changes the order.
