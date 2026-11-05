# HT-002 — Fictional Network Topology

**Status:** Implemented  
**Priority:** 2  
**Approved:** 2026-11-05  
**Owner decision:** All three built-in missions must receive distinct, mission-specific topologies.  
**Depends on:** HT-001 Detection & Risk System (implemented and CI-verified).

## Goal
Give each contract a small, navigable fictional network graph. The topology should create meaningful route choices, put mission resources at explicit locations, and make movement consume the existing detection budget.

## Accepted design direction
- All three built-in missions receive their own authored node-and-link graph; no generic shared map or clone maps.
- Keep graph definitions static alongside mission catalog data. Keep the player's current node and traversal count runtime-only in MissionSession.
- Add `map` to show the active mission's graph and current location, and `move <node-id>` to traverse one directly connected edge.
- Start each accepted contract at its own entry node. Movement is allowed only across a declared link; unknown nodes and non-adjacent destinations are rejected without changing state or detection.
- Every successful traversal adds +5 detection, including traversing an edge already used before. This prevents repeated backtracking from becoming a free action. Reaching 100 uses HT-001's existing failure and penalty behavior.
- Scan, connect/authenticate, decrypt/analyze, and extract must be performed at the appropriate mission node(s). Their exact node assignments are part of each authored topology and must be shown in map/briefing documentation.
- Existing mission objective kinds, rewards, clues, and save formats remain unchanged. Current node and traversal are transient and reset on mission start, completion, and failure.
- All names, nodes, links, and actions remain fictional and local/offline.

## Mission-specific topology concepts
These are distinct authored layouts, not a shared template:
- **job-01 — Cold Storage:** a compact facility perimeter with a short, exposed service corridor and a longer maintenance detour to the vault.
- **job-02 — Paper Trail:** an archive network organized around an indexing hub, with separate mail-processing and records-access branches.
- **job-03 — Quiet Exit:** a relay chain with a decoy branch and a controlled exit route; its layout should require more navigation than the earlier contracts.

The implementation should keep each graph small enough to understand from terminal output. Route lengths and link costs should create clear trade-offs without making a mission impossible to finish under the detection cap.

## Architecture plan
- Introduce a focused, foundational topology domain module for node/link/topology types and graph lookup/adjacency helpers; it must not depend on game or terminal modules.
- Attach an optional topology reference to Mission so missions without a graph retain current behavior.
- Store the current node and successful traversal count in MissionSession; do not add them to Player or save serialization.
- Keep traversal validation and detection application in game coordination, and keep map formatting in terminal presentation.
- Keep node IDs stable, concise, and distinct within a mission. Validate built-in graphs in tests.

## Acceptance criteria
- [x] Typed graph model represents nodes, links, and mission-specific topology.
- [x] Each of the three built-in missions has a distinct graph with meaningful route choices.
- [x] `map` displays nodes, connections, relevant locations, and current position.
- [x] `move <node-id>` permits only adjacent movement and handles invalid destinations safely.
- [x] Successful movement adds +5 detection per traversal, including revisits; reaching 100 triggers HT-001 failure behavior.
- [x] Scan/connect/authentication/decryption/analysis/extraction are location-aware and covered by integration tests.
- [x] Current node initializes on accept, resets on completion/failure, and restores at entry for loaded active contracts.
- [x] Missions without topology remain backward-compatible through optional topology checks.
- [x] Save V2, V1, and legacy formats remain unchanged; topology, current node, and traversal count are not serialized.
- [x] Focused tests, docs, AGENTS/module contracts, and CI are updated.

## Non-goals
- No real IP addresses, sockets, DNS, packet handling, network discovery, external host interaction, or shell execution.
- No equipment-specific route modifiers; those belong to HT-003.
- No branching story outcomes.
- No persistence of current node or traversal state.

## Verification
- [x] Tests for graph validity, adjacency, node lookup, traversal, resource access, and invalid routes.
- [x] Zig 0.13.0 formatting, build, and complete test suite.
- [x] Agent documentation structure check.
- [x] Self-review recorded; no independent second reviewer was available.
- [x] Inspect CI before marking Implemented.

## Agent progress notes
- Implemented the graph domain in `src/domain/topology.zig`, attached optional topology data to `Mission`, and authored distinct static graphs in `src/catalog/mission_data.zig`.
- Added `map` and `move`; location-gated scan, connection/authentication, decryption, analysis, and extraction; +5 detection per successful traversal; and transient current-node/traversal-count initialization/reset.
- Added graph/data/session/game integration tests. Formatting, build, full tests, and agent-documentation checks passed in CI run [42005306937](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42005306937).
- Repository review confirmed that mission definitions are static in `mission_data.zig`, runtime state is owned by `MissionSession`, and `src/application/game.zig` coordinates command behavior.
- HT-001 was CI-verified in run 42001487382; HT-002 is now implemented.
- Owner confirmed that all three missions need unique, purpose-built topologies.
- Initial topology concepts and the +5-per-traversal risk rule are recorded above. The graph model, three mission maps, movement, location-gated operations, tests, and documentation are now implemented; verification and review completed; this task is implemented.

## Verification and review record

- CI run: [42005306937](https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42005306937) — success on Zig 0.13.0.
- Verified steps: `zig fmt --check test_root.zig build.zig src tests`, `zig build`, `zig test test_root.zig`, and `sh scripts/check-agent-docs.sh`.
- Self-review: inspected the implementation against the accepted topology scope, one-way module boundaries, transient/persistent state boundary, movement failure paths, operation-node gates, and save compatibility. No save serialization files or versions were changed.
- No independent second reviewer or interactive manual playtest was available. The CI build and automated tests are the verification evidence; they are not represented as a manual playthrough.
- Verified final implementation branch: `main`; CI-tested commit: `0b66667b83a58c96f7abcadb69b7831603d71559`.
