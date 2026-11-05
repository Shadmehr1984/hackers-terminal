# Module Contracts and Conventions

Derived from the current source tree; re-check source before relying on this map.

| Module | Owns | Should not own |
| --- | --- | --- |
| src/main.zig | Entry point, allocator/I/O setup, save loading, welcome, input loop | Mission rules or command-specific logic |
| src/game.zig | Dispatch, validation, state transitions, rewards, progression | Low-level parsing or reusable presentation |
| src/player.zig | Player profile data/defaults | Persistence and terminal I/O |
| src/mission.zig | Mission, difficulty, objective types | Built-in catalog or runtime mutation |
| src/mission_data.zig | Ordered built-in mission definitions | Dispatch and terminal output |
| src/mission_state.zig | Runtime session progress, connection, objective completion | Serialization or user-facing output |
| src/commands.zig | Allocation-free command/first-argument parsing | Gameplay validation and dispatch |
| src/terminal.zig | Reusable terminal presentation | Mutating game state or deciding rewards |
| src/save.zig | Save/load serialization and legacy compatibility | Gameplay command handling |
| src/shop.zig | Inventory/shop display and purchases | Mission progression |
| tests/ | Automated tests grouped by behavior/domain | Production implementation |
| docs/ | User, architecture, save, and developer documentation | Substitute for executable tests |

## Dependency direction
- player.zig and mission.zig are foundational and independent of high-level orchestration.
- mission_data.zig depends on mission types.
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
- Mission-session progress, connection state, and objective completion are transient.
- Player progression and mission completion are persisted.
- Save format is positional and supports V2, V1, and original unversioned layouts. Schema changes require deliberate migration, tests, and docs/save-format.md updates.
- Objective completion currently uses an eight-bit mask; adding a ninth kind requires redesign and tests.
