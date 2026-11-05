# Module Contracts and Conventions

Production implementations live in responsibility-based folders. The original `src/*.zig` paths remain thin compatibility facades; use the grouped implementation paths for new imports.

Derived from the current source tree; re-check source before relying on this map.

| Module | Owns | Should not own |
| --- | --- | --- |
| src/main.zig | Entry point, allocator/I/O setup, save loading, welcome, input loop | Mission rules or command-specific logic |
| src/application/game.zig | Shared command dispatch, validation, and mission state transitions | Low-level parsing, Detection rules, or progression calculations |
| src/application/detection.zig | Detection costs, warnings, compromise failure, and penalty | Command parsing or mission catalog data |
| src/domain/progression.zig | XP thresholds, player levels, Reputation tiers, and mission reward application | Command dispatch or terminal I/O policy |
| src/domain/player.zig | Player profile, typed equipment ownership, equipped utility, upgrade levels, and the single source of truth for pure utility Detection-cost profiles | Persistence and terminal I/O |
| src/domain/contacts.zig | Fictional Contact identities, Reputation unlock thresholds, and Fixer service pricing | Game command dispatch, terminal output, or persistence |
| src/domain/contract_board.zig | Pure derived contract availability and reward-range query; no I/O or persistence |
| src/domain/mission.zig | Mission, category, optional topology reference, level/Reputation requirements, difficulty, objective types | Built-in catalog or runtime mutation |
| src/domain/topology.zig | Static fictional graph nodes, links, lookup, adjacency, graph validation | Game dispatch, terminal I/O, or real networking |
| src/catalog/mission_data.zig | Ordered built-in mission definitions | Dispatch and terminal output |
| src/domain/mission_state.zig | Runtime session progress, connection, objective completion, detection, current node, traversal count, and the per-run loadout snapshot that delegates Detection costs to UtilityEquipment | Serialization or user-facing output |
| src/application/commands.zig | Allocation-free command/first-argument parsing | Gameplay validation and dispatch |
| src/presentation/terminal.zig | Reusable terminal presentation | Mutating game state or deciding rewards |
| src/persistence/save.zig | Save/load serialization and legacy compatibility | Gameplay command handling |
| src/application/shop.zig | Equipment catalog, inventory, purchases, equipping, and upgrades | Mission progression |
| tests/ | Automated tests grouped by behavior/domain | Production implementation |
| docs/ | User, architecture, save, and developer documentation | Substitute for executable tests |

## Dependency direction
- player.zig and mission.zig are foundational and independent of high-level orchestration.
- topology.zig is foundational and independent; mission.zig references its topology type.
- mission_data.zig depends on mission and topology types.
- mission_state.zig models transient state and should not depend on terminal output or persistence.
- game.zig coordinates lower-level modules; avoid reverse imports into game.zig. Detection and progression modules must remain independent of command dispatch.
- UtilityEquipment owns the pure cost profile for each utility and upgrade level. Equipment reads the currently equipped utility; MissionLoadout reads the launch-time snapshot. Neither caller duplicates the numeric cost tables.
- main.zig is the composition root. Avoid circular imports.

## Zig and test conventions
- Target Zig 0.13.0; do not use newer APIs without verifying compatibility.
- Prefer explicit small functions and concrete structures over speculative abstractions.
- Keep parsing allocation-free where practical; current parser accepts a command and first argument only.
- Add tests under tests/ and register modules in tests/test_all.zig.
- Add Zig doc comments to exported public types, constants, and functions; describe observable behavior and compatibility constraints rather than restating names.
- For allocator-backed algorithms, cover allocation failure where the public contract defines the failure result; use testing allocators and keep ownership/leak checks explicit.
- Run the suite with `zig build test` (or directly with `zig test test_root.zig`).

## State and persistence
- Mission preparation selection, per-run loadout snapshot, mission-session progress, connection state, objective completion, detection, current topology node, and successful traversal count are transient.
- The active mission loadout is snapshotted at launch; Detection modifiers read the session snapshot, never live player equipment. Preparation does not reveal puzzle clues or answers.
- Player progression and mission completion are persisted. Reputation tiers and Contact unlocks are derived from Reputation; Fixer service usage is transient.
- Save format is positional and writes V3 and reads V2, V1, and original unversioned layouts. Schema changes require deliberate migration, tests, and docs/save-format.md updates.
- Objective completion currently uses an eight-bit mask; adding a ninth kind requires redesign and tests.
