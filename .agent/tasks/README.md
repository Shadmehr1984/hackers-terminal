# Approved Gameplay Task Index

Owner-approved on 2026-11-05. Follow this sequence; each brief is a handoff contract for future coding agents.

| Order | ID | Feature | Status | Brief |
|---:|---|---|---|---|
| 1 | HT-001 | Detection & Risk System | Implemented | [Read task](HT-001-detection-risk.md) |
| 2 | HT-002 | Fictional Network Topology | Implemented | [Read task](HT-002-network-topology.md) |
| 3 | HT-003 | Equipment & Upgrade System | Implemented | [Read task](HT-003-equipment-upgrades.md) |
| 4 | HT-004 | Mission Preparation | Implemented | [Read task](HT-004-mission-preparation.md) |
| 5 | HT-005 | Reputation & Contacts | Implemented | [Read task](HT-005-reputation-contacts.md) |
| 6 | HT-006 | Contract Board | Implemented & Merged | [Read task](HT-006-contract-board.md) |
| 7 | HT-007 | Mission Modifiers | Implemented and merged to main (PR #11) | [Read task](HT-007-mission-modifiers.md) |
| 8 | HT-008 | Hidden Objectives | Implemented on `main`; CI run #679 passed | [Read task](HT-008-hidden-objectives.md) |

## Gameplay Expansion Program — EXPANSION-001

Planning approved on 2026-11-05. HT-006 is implemented and merged. HT-007 implementation is merged to `main` via PR #11; latest CI run #575 passed. Squash merge commit: `c17d19b93c18af286e97d6f00d2b9892017a784c`. HT-008 design is approved in ADR 0010; implementation completed directly on `main` on 2026-11-05 and CI run #679 passed. All other later features still require their own feature-specific design approval and implementation authorization. These phase documents are persistent agent handoffs and contain the execution scope and acceptance criteria for all 20 ideas.

- [Master plan and dependency register](../plans/GAMEPLAY-EXPANSION-OVERVIEW.md)
- [Phase 1 — Contract and Mission Content](../plans/PHASE-1-MISSION-CONTENT.md): HT-006 Contract Board; HT-007 Mission Modifiers; HT-008 Hidden Objectives; HT-009 Multi-stage Operations.
- [Phase 2 — World, Intelligence, and Relationships](../plans/PHASE-2-WORLD-AND-RELATIONSHIPS.md): HT-010 Factions; HT-011 Rival Hackers; HT-012 Information Market; HT-025 Contact Development; HT-022 Data Archive.
- [Phase 3 — Security Systems](../plans/PHASE-3-SECURITY-SYSTEMS.md): HT-016 Security Profiles; HT-017 Security Countermeasures; HT-023 Security Agent Behaviors; HT-024 Security Agent Memory.
- [Phase 4 — Progression and Replayability](../plans/PHASE-4-PROGRESSION-AND-REPLAYABILITY.md): HT-013 Hacker Specializations; HT-014 Level & Unlock Expansion; HT-015 Tool Collection; HT-018 Challenge Missions; HT-019 Operational Costs; HT-020 Recurring Contract Cycles; HT-021 Achievements.

## Quality and maintenance tasks

- [QUALITY-001 — Code Review Remediation](QUALITY-001-code-review-remediation.md) — Implemented: documentation consistency, command-path unification, atomic save writes, and focused module boundaries.
- [QUALITY-002 — Save, Topology, and Persistence Test Hardening](QUALITY-002-code-review-remediation.md) — Implemented: strict save marker handling, topology reachability validation, and filesystem persistence tests.
- [QUALITY-003 — Active Save Validation and Status Output](QUALITY-003-code-review-remediation.md) — Implemented: persisted active-mission consistency validation and corrected status line endings with regression tests.
- [QUALITY-004 — Idempotent Completed Authentication and Decryption](QUALITY-004-idempotent-completed-stages.md) — Implemented: incorrect retries after completed stages no longer increase Detection.

## Handoff rules
- HT-001 through HT-006 are complete. For EXPANSION-001, follow the dependency order and require individual owner authorization for each feature. Do not combine multiple features into one oversized change.
- Before coding, inspect current source, tests, docs, CI, and save behavior; then add a concrete milestone plan and progress notes to the relevant brief.
- Update the brief and `.agent/roadmap.md` as milestones move through Planned → Design Approved → In Progress → Blocked/Implemented.
- Implemented means code, focused tests, documentation, review, and relevant CI are complete.
- All systems are fictional and local/offline. No real network activity, external hosts, shell commands, or credential collection.
- Story branching remains deferred and is not part of these tasks.
