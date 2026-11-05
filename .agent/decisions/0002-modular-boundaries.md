# ADR 0002: Keep Game Responsibilities in Focused Modules

- Status: Accepted
- Date: 2026-11-05

## Context
The game has distinct concerns: application setup, game rules, player/mission data, transient state, parsing, presentation, persistence, and shop operations.

## Decision
Keep these concerns in focused modules with one-way dependencies. main.zig is the composition root, game.zig coordinates rules and transitions, and lower-level modules must not import the coordinator.

## Source layout

Group production implementations by responsibility: `domain/`, `application/`, `catalog/`, `presentation/`, and `persistence/`. Keep `main.zig` at the source root as the composition root. Preserve the former `src/*.zig` paths as thin compatibility facades so existing imports do not break.

## Consequences
- New behavior belongs in the module that owns its domain.
- Refactors should be incremental, avoiding both a monolith and unnecessary fragmentation.
- State and parsing logic should be testable without interactive terminal I/O where practical.
- New production imports should use grouped implementation paths; compatibility facades exist for existing consumers only.
