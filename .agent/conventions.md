# Module Contracts and Conventions

Production implementations live in responsibility-based folders. The original `src/*.zig` paths remain thin compatibility facades; use the grouped implementation paths for new imports.

Derived from the current source tree; re-check source before relying on this map.

| Module | Owns | Should not own |
| --- | --- | --- |
| src/main.zig | Version-gated process entry point, allocator/I/O composition, save loading, welcome, shared input loop | Mission rules or command-specific logic |
| src/application/terminal_input.zig | Shared input capacity, 511-byte accepted command limit, and overlength predicate | Stream ownership, output, or command dispatch |
| src/application/terminal_io.zig | Zig 0.16+ `std.Io` process reader and immediate stdout adapter; delimiter drain and I/O error propagation | Gameplay state, command parsing, or persistence |
| src/application/game.zig | Shared command dispatch, validation, and mission state transitions | Low-level parsing, Detection rules, or progression calculations |
| src/application/detection.zig | Detection costs, warnings, compromise failure, and penalty | Command parsing or mission catalog data |
| src/domain/progression.zig | XP thresholds, player levels, Reputation tiers, and mission reward application | Command dispatch or terminal I/O policy |
| src/domain/player.zig | Player profile, typed equipment ownership, equipped utility, upgrade levels, and the single source of truth for pure utility Detection-cost profiles | Persistence and terminal I/O |
| src/domain/contacts.zig | Fictional Contact identities, Reputation unlock thresholds, and Fixer service pricing | Game command dispatch, terminal output, or persistence |
| src/domain/faction_id.zig | Stable typed faction identities and command-facing slugs | Authored faction profiles, player state, or terminal I/O |
| src/domain/faction.zig | Faction standing and relationship types; pure standing derivation from Reputation and completed mission affiliations | Catalog data, command dispatch, persistence, or terminal I/O |
| src/catalog/faction_data.zig | Seven authored faction profiles and symmetric static inter-faction relationships | Player standing mutation or command dispatch |
| src/domain/rival.zig | Stable rival identities, profile shape, and status labels | Catalog data, command dispatch, persistence, or terminal I/O |
| src/catalog/rival_data.zig | Five authored rival profiles and their hidden optional-objective contest links | Runtime state mutation or command dispatch |
| src/domain/rival_simulation.zig | Pure rival status derivation and deterministic post-decryption optional-objective contest resolution | Terminal I/O, persistence, or external/network simulation |
| src/domain/contract_board.zig | Pure derived contract availability, faction access, and checked reward-range query; overflow propagates as RewardOverflow; no I/O or persistence |
| src/domain/mission.zig | Mission, category, static faction affiliations, optional topology reference, level/Reputation requirements, difficulty, stable-ID objective definitions, and static allowed-modifier metadata | Built-in catalog or runtime mutation |
| src/domain/mission_objectives.zig | Fixed-capacity objective tracker, typed discovery triggers, objective lifecycle transitions, and checked optional-cash reward accumulation | Terminal I/O, command dispatch, or persistence |
| src/domain/operation.zig | Static linear Operation/Stage definitions, typed carry-over facts, and catalog validation | Runtime mutation, command dispatch, terminal I/O, or persistence |
| src/domain/operation_state.zig | Bounded runtime-only operation stage/fact lifecycle, retry/reset, and reward-eligibility snapshot | Serialization, mission catalog mutation, or terminal I/O |
| src/catalog/operation_data.zig | Authored static operation sequences and stage fact/objective links | Dispatch, runtime state, or terminal output |
| src/domain/topology.zig | Static fictional graph nodes, links, lookup, adjacency, graph validation | Game dispatch, terminal I/O, or real networking |
| src/catalog/mission_data.zig | Ordered built-in mission definitions | Dispatch and terminal output |
| src/domain/mission_state.zig | Runtime preparation selection (utility, optional modifier, and OperationState), session progress, connection, per-objective tracker, detection, current node, traversal count, and per-run utility/modifier snapshots, and one-time completion payout guard | Serialization or user-facing output |
| src/application/commands.zig | Allocation-free command/first-argument parsing | Gameplay validation and dispatch |
| src/presentation/terminal.zig | Reusable terminal presentation, including faction-aware Operation availability and preauthorization status | Mutating game state or deciding rewards |
| src/persistence/save.zig | Save/load serialization and legacy compatibility | Gameplay command handling |
| src/application/shop.zig | Equipment catalog, inventory, purchases, equipping, and upgrades | Mission progression |
| tests/ | Automated tests grouped by behavior/domain | Production implementation |
| docs/ | User, architecture, save, and developer documentation | Substitute for executable tests |

## Dependency direction
- player.zig, faction_id.zig, and mission.zig are foundational and independent of high-level orchestration.
- faction.zig may depend on the mission data contract to derive standing; mission.zig depends only on faction_id.zig, never on faction Catalog or orchestration. faction_data.zig owns authored profiles and static relationships.
- topology.zig is foundational and independent; mission.zig references its topology type.
- mission_data.zig depends on mission and topology types.
- mission_state.zig models transient state and should not depend on terminal output or persistence.
- game.zig coordinates lower-level modules; avoid reverse imports into game.zig. Detection and progression modules must remain independent of command dispatch.
- UtilityEquipment owns the pure cost profile for each utility and upgrade level. Equipment reads the currently equipped utility; MissionLoadout reads the launch-time snapshot. Neither caller duplicates the numeric cost tables.
- main.zig is the composition root. Avoid circular imports.

## Zig and test conventions
- The default CI baseline remains Zig 0.13.0 while TOOLCHAIN-001 stages migration to Zig 0.17.1. `terminal_io.zig` is intentionally version-gated and Zig 0.16+ only; do not remove the legacy entry point or change the default CI pin before the full migration closeout.
- Keep cross-version tests free of Zig 0.17-only syntax. The `std.Io` test suite is separate and uses the explicit module mapping documented in `docs/development.md`.
- Prefer explicit small functions and concrete structures over speculative abstractions.
- Keep parsing allocation-free where practical; current parser accepts a command and first argument only.
- Add tests under tests/ and register modules in tests/test_all.zig.
- Add Zig doc comments to exported public types, constants, and functions; describe observable behavior and compatibility constraints rather than restating names.
- For allocator-backed algorithms, cover allocation failure where the public contract defines the failure result; use testing allocators and keep ownership/leak checks explicit.
- Run the suite with `zig build test` (or directly with `zig test test_root.zig`).

## State and persistence
- Mission preparation selection (including the optional modifier), per-run loadout snapshot, mission-session progress, connection state, objective completion, detection, current topology node, and successful traversal count are transient.
- Mission modifier eligibility is static catalog metadata; preparation rejects modifiers not explicitly allowed by the selected mission. The selected modifier is not persisted.
- The active mission loadout and optional modifier are snapshotted at launch; Detection modifiers read the session snapshot, never live player equipment or preparation state. Preparation discloses exact effects and bonuses but does not reveal puzzle clues or answers.
- HT-007 modifier Detection events use the central `detection.apply` path. `heightened-monitoring` adds +2 after adjusted movement cost; `security-sweep` adds +8 after every third successful traversal only if the normal event did not compromise the run; `hardened-encryption` changes incorrect decryption-key exposure to +15. Successful modified completion adds +$50/+25 XP once; a runtime session guard prevents duplicate completion payouts, and failure does not.
- Player progression and mission completion are persisted. Reputation tiers and Contact unlocks are derived from Reputation; Fixer service usage is transient. HT-010 faction standing is derived from global Reputation and completed contract faction metadata; no per-faction score is persisted. Hostile standing toward a contract client blocks access, and faction data remains static Catalog content.
- Save format is positional and writes V3 and reads V2, V1, and original unversioned layouts. Validate all fixed fields and every supplied completion flag before committing loaded player or mission state; truncated/malformed fixed fields must preserve the previous in-memory state. Older saves may omit trailing mission flags, which default to incomplete; extra flags are invalid. Schema changes require deliberate migration, tests, and docs/save-format.md updates.
- Mission payout calculations, optional-objective reward accumulation, and Contract Board visible reward ceilings use checked arithmetic. Overflow propagates as RewardOverflow and cannot wrap a displayed estimate or payout; progression commits cash, XP, Reputation, and the runtime duplicate-payout guard only after all totals and output succeed; mission completion flags and final optional-objective unavailability are applied only after payout/output succeeds.
- Operation list/details/status presentation uses the same derived client-faction standing as operation-start. A successfully started Operation is preauthorized for its full linear sequence; later standing changes do not revoke access, and active Operation views label this explicitly.
- Objective progress uses HT-008's fixed-capacity 32-entry tracker keyed by stable mission-local IDs; never use an event-kind enum ordinal as objective identity.
- HT-009 Operation definitions are static and linear (maximum 8 stages); current stage, typed carry-over facts, and completion display state are runtime-only. Stage rewards are paid individually once, using the existing persisted mission-completed flag to suppress rewards when a completed contract is replayed inside an operation.
- When completing an Operation stage, emit the outgoing-fact transition record successfully before mutating the runtime carried-fact state; a writer failure must leave the fact uncommitted so the stage can be retried.
- Every command transition that mutates Player, MissionSession, MissionPreparation, the active mission index, mission completion, or OperationState must stage the affected values in local copies, emit all output required for that transition, and commit only after every output operation succeeds. Apply this to movement, scan, authentication, decryption, analysis, extraction/payout, contract launch, operation start/retry, contacts, and shop actions. A writer failure must not leave a partially applied gameplay transition.
- Keep failure-injection regression tests for the critical transitions above. Test both print-formatting and writeAll failure paths where each is used; assert the original state remains unchanged.
- While an operation is active, saving must preserve the existing Save V3 layout but pass no active mission index. Restart begins the operation again at stage one with no operation facts; already-completed stage contracts are replayable without rewards.

## Git workflow
- Work directly on `main` by default, as requested by the owner on 2026-11-05.
- Do not create feature/phase branches or pull requests unless the owner explicitly asks for them.
- Keep each change focused; inspect the diff and verify GitHub Actions on the resulting `main` commit before reporting completion.
