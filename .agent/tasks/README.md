# Approved Gameplay Task Index

Owner-approved on 2026-11-05. Follow this sequence; each brief is a handoff contract for future coding agents.

| Order | ID | Feature | Status | Brief |
|---:|---|---|---|---|
| 1 | HT-001 | Detection & Risk System | Implemented | [Read task](HT-001-detection-risk.md) |
| 2 | HT-002 | Fictional Network Topology | Implemented | [Read task](HT-002-network-topology.md) |
| 3 | HT-003 | Equipment & Upgrade System | Implemented | [Read task](HT-003-equipment-upgrades.md) |
| 4 | HT-004 | Mission Preparation | Implemented | [Read task](HT-004-mission-preparation.md) |
| 5 | HT-005 | Reputation & Contacts | In Progress | [Read task](HT-005-reputation-contacts.md) |

## Quality and maintenance tasks

- [QUALITY-001 — Code Review Remediation](QUALITY-001-code-review-remediation.md) — Implemented: documentation consistency, command-path unification, atomic save writes, and focused module boundaries.
- [QUALITY-002 — Save, Topology, and Persistence Test Hardening](QUALITY-002-code-review-remediation.md) — Implemented: strict save marker handling, topology reachability validation, and filesystem persistence tests.
- [QUALITY-003 — Active Save Validation and Status Output](QUALITY-003-code-review-remediation.md) — Implemented: persisted active-mission consistency validation and corrected status line endings with regression tests.

## Handoff rules
- Start with HT-001. Do not implement all five systems together.
- Before coding, inspect current source, tests, docs, CI, and save behavior; then add a concrete milestone plan and progress notes to the relevant brief.
- Update the brief and `.agent/roadmap.md` as milestones move through Planned → In Progress → Blocked/Implemented.
- Implemented means code, focused tests, documentation, review, and relevant CI are complete.
- All systems are fictional and local/offline. No real network activity, external hosts, shell commands, or credential collection.
- Story branching remains deferred and is not part of these tasks.
