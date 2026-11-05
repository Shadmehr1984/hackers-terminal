# Project Roadmap

This roadmap records owner-approved feature direction and implementation order. Task briefs are the execution contracts for coding agents. A feature is not implemented merely because it is approved or has a task brief.

## Implemented foundation
- Modular Zig 0.13.0 terminal game.
- Three built-in missions with descriptive difficulty metadata.
- Required and optional objectives with live progress and optional cash bonuses.
- Local save/load with V2, V1, and legacy compatibility.
- Unit tests and GitHub Actions formatting/build/test workflow.
- Agent instructions, module contracts, ADRs, task briefs, and review workflow.

## Approved gameplay program

The project owner approved these five feature areas on 2026-11-05. Implement them in the following order, one coherent milestone at a time. Do not start all systems simultaneously; later systems depend on foundations established by earlier work.

| Order | Feature | Task brief | Status | Dependency |
|---:|---|---|---|---|
| 1 | Detection & Risk System | [HT-001](tasks/HT-001-detection-risk.md) | Planned | None |
| 2 | Fictional Network Topology | [HT-002](tasks/HT-002-network-topology.md) | Planned | Detection/risk model should be defined first so topology can expose risk-aware choices |
| 3 | Equipment & Upgrade System | [HT-003](tasks/HT-003-equipment-upgrades.md) | Planned | Detection/risk and topology provide meaningful equipment trade-offs |
| 4 | Mission Preparation | [HT-004](tasks/HT-004-mission-preparation.md) | Planned | Reuses mission topology, equipment, and risk concepts |
| 5 | Reputation & Contacts | [HT-005](tasks/HT-005-reputation-contacts.md) | Planned | Builds on mission outcomes and preparation/progression |

### Program-wide design constraints
- All hacking, hosts, networks, detection, and operations remain fictional, deterministic or game-randomized simulations running locally/offline.
- Never add real network scanning, external host connections, shell execution, credential collection, or interaction with external systems.
- Preserve the existing terminal-first, single-player experience.
- Prefer testable domain state and game rules over terminal I/O. Keep module dependencies one-way.
- Do not change save serialization incidentally. Each task must explicitly decide whether its feature state is transient or persistent; any intentional format change requires a documented migration and compatibility tests for V2, V1, and legacy saves.
- Maintain backwards-compatible command behavior unless a task explicitly defines and tests a deliberate change.
- Update AGENTS.md, module contracts, architecture docs, gameplay docs, and ADRs only when the implementation establishes lasting rules or decisions.
- Do not implement story branching as part of this program. Branching objectives and branching narrative remain deferred.

## Deferred candidate
- More expressive mission branching and consequences — intentionally deferred; not part of the approved five-feature sequence.

## Planning and status rules
- The task brief is the source of scope and acceptance criteria for each feature. Agents must read it before implementation and update its status/progress notes as work advances.
- Status values: Planned, In Progress, Blocked, Implemented. Use Implemented only after code, tests, documentation, review, and the relevant CI checks are complete.
- Discuss substantial scope changes with the project owner before proceeding.
- Do not begin a later feature while an earlier feature has unresolved foundational decisions, unless the owner explicitly changes the order.
