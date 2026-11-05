# Project Roadmap

This is a planning aid, not a promise. Source code and AGENTS.md define current behavior.

## Implemented foundation
- Modular Zig 0.13.0 terminal game.
- Three built-in missions with descriptive difficulty metadata.
- Required and optional objectives with live progress and optional cash bonuses.
- Local save/load with V2, V1, and legacy compatibility.
- Unit tests and GitHub Actions formatting/build/test workflow.
- Agent instructions, module contracts, ADRs, task briefs, and review workflow.

## Candidate areas — not yet approved tasks
- More expressive mission branching and consequences.
- Richer fictional/simulated network topology.
- Equipment and inventory choices with meaningful trade-offs.
- Entirely simulated detection/risk mechanics.
- Reputation, contacts, and mission-unlock systems.

## Planning rules
Discuss one candidate with the owner before implementation. Break large systems into small milestones with observable acceptance criteria. Identify interactions with progression, objectives, and save compatibility. Do not mark proposals as committed or implemented until code, tests, and docs support that status.
