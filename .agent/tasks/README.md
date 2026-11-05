# Approved Gameplay Task Index

Owner-approved on 2026-11-05. Follow this sequence; each brief is a handoff contract for future coding agents.

| Order | ID | Feature | Status | Brief |
|---:|---|---|---|---|
| 1 | HT-001 | Detection & Risk System | In Progress | [Read task](HT-001-detection-risk.md) |
| 2 | HT-002 | Fictional Network Topology | Planned | [Read task](HT-002-network-topology.md) |
| 3 | HT-003 | Equipment & Upgrade System | Planned | [Read task](HT-003-equipment-upgrades.md) |
| 4 | HT-004 | Mission Preparation | Planned | [Read task](HT-004-mission-preparation.md) |
| 5 | HT-005 | Reputation & Contacts | Planned | [Read task](HT-005-reputation-contacts.md) |

## Handoff rules
- Start with HT-001. Do not implement all five systems together.
- Before coding, inspect current source, tests, docs, CI, and save behavior; then add a concrete milestone plan and progress notes to the relevant brief.
- Update the brief and `.agent/roadmap.md` as milestones move through Planned → In Progress → Blocked/Implemented.
- Implemented means code, focused tests, documentation, review, and relevant CI are complete.
- All systems are fictional and local/offline. No real network activity, external hosts, shell commands, or credential collection.
- Story branching remains deferred and is not part of these tasks.
