# Module Contracts and Conventions

Derived from the current source tree; re-check source before relying on this map.

| Module | Owns | Should not own |
| --- | --- | --- |
| src/main.zig | Entry point, allocator/I/O setup, save loading, welcome, input loop | Mission rules or command-specific logic |
| src/game.zig | Dispatch, validation, state transitions, rewards, progression | Low-level parsing or reusable presentation |
| src/player.zig | Player profile, typed equipment ownership, equipped utility, upgrade levels, and pure Detection modifiers | Persistence and terminal I/O |
| src/mission.zig | Mission, optional topology reference, difficulty, objective types | Built-in catalog or runtime mutation |
| src/topology.zig | Static fictional graph nodes, links, lookup, adjacency, graph validation | Game dispatch, terminal I/O, or real networking |
| src/mission_data.zig | Ordered built-in mission definitions | Dispatch and terminal output |
| src/mission_state.zig | Runtime session progress, connection, objective completion, detection, current node, traversal count | Serialization or user-facing output |
| src/commands.zig | Allocation-free command/first-argument parsing | Gameplay validation and dispatch |
| src/terminal.zig | Reusable terminal presentation | Mutating game state or deciding rewards |
| src/save.zig | Save/load serialization and legacy compatibility | Gameplay command handling |
| src/shop.zig | Equipment catalog, inventory, purchases, equipping, and upgrades | Mission progression |
| tests/ | Automated tests grouped by behavior/domain | Production implementation |
| docs/ | User, architecture, save, and developer documentation | Substitute for executable tests |

## Dependency direction
- player.zig and mission.zig are foundational and independent of high-level orchestration.
- topology.zig is foundational and independent; mission.zig references its topology type.
- mission_data.zig depends on mission and topology types.
- mission_state.zig models transient state and should not depend on terminal output or persistence.
- game.zig coordinates lower-level modules; avoid reverse imports into game.zig.
- main.zig is the composition root. Avoid circular imports.

## Zig and test conventions
- Target Zig 0.13.0; do not use newer APIs without verifying compatibility.
- Prefer explicit small functions and concrete structures over speculative abstractions.
- Keep parsing allocation-free where practical; current parser accepts a command and first argument only.
- Add tests under tests/ and register modules in tests/test_all.zig.
- Run the suite with zig test test_root.zig.

## State and persistence
- Mission preparation selection, per-run loadout snapshot, mission-session progress, connection state, objective completion, detection, current topology node, and successful traversal count are transient.\n- The active mission loadout is snapshotted at launch; Detection modifiers read the session snapshot, never live player equipment. Preparation does not reveal puzzle clues or answers.
- Player progression and mission completion are persisted.
- Save format is positional and writes V3 and reads V2, V1, and original unversioned layouts. Schema changes require deliberate migration, tests, and docs/save-format.md updates.
- Objective completion currently uses an eight-bit mask; adding a ninth kind requires redesign and tests.
