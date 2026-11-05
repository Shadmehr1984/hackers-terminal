# HT-002 — Fictional Network Topology

**Status:** Planned  
**Priority:** 2  
**Approved:** 2026-11-05  
**Depends on:** HT-001 design baseline for risk-aware traversal.

## Goal
Replace the idea of a single flat mission target with a small, fictional graph of connected nodes. Players should be able to inspect the simulated topology and navigate between nodes to reach mission resources.

## Design direction
- Represent nodes and directed/undirected links as static mission data where practical.
- Keep current mission stages and objective system understandable; define how node traversal relates to scan/connect/authenticate/decrypt/extract before coding.
- Make topology small and terminal-friendly; do not build a real network stack.
- Provide meaningful route choices, including risk-aware trade-offs that can use HT-001.
- Keep mission catalog definitions separate from traversal/session state.

## Likely scope (verify before implementation)
- Focused data definitions in `src/mission.zig` or a new topology module.
- Built-in topology definitions alongside `src/mission_data.zig`.
- Traversal state in `src/mission_state.zig` or a focused state module.
- Dispatch and validation in `src/game.zig`; display in `src/terminal.zig`.
- Tests, command docs, gameplay docs, architecture docs, and agent module contracts as needed.

## Acceptance criteria
- [ ] A typed graph model represents fictional nodes and their connections.
- [ ] At least one built-in mission uses a small topology with more than one meaningful route or node.
- [ ] The player can inspect the topology and current node from the terminal.
- [ ] Navigation is restricted to valid adjacent nodes; invalid or unreachable destinations are rejected and tested.
- [ ] Mission actions are constrained to appropriate node/resource locations and this is covered by tests.
- [ ] Risk-aware route differences are explicit and tested against the HT-001 model.
- [ ] Existing mission objectives and completion rules remain coherent.
- [ ] No real networking or external host interaction is introduced.
- [ ] Save compatibility is preserved or any necessary migration is explicitly designed, documented, and tested.

## Non-goals
- No real IP addresses, sockets, DNS, packet handling, or network discovery.
- No branching story outcomes.
- No equipment-specific route modifiers; those belong to HT-003.

## Verification
- [ ] Tests for graph validity, adjacency, traversal, resource access, and invalid routes.
- [ ] Zig 0.13.0 formatting, build, and complete test suite.
- [ ] Agent documentation check and independent review/self-review.
- [ ] Inspect CI before marking Implemented.

## Agent progress notes
- Initial handoff: scope and acceptance criteria recorded; implementation has not started.
