# ADR 0002: Keep Game Responsibilities in Focused Modules

- Status: Accepted
- Date: 2026-11-05

## Context
The game has distinct concerns: application setup, game rules, player/mission data, transient state, parsing, presentation, persistence, and shop operations.

## Decision
Keep these concerns in focused modules with one-way dependencies. main.zig is the composition root, game.zig coordinates rules and transitions, and lower-level modules must not import the coordinator.

## Consequences
- New behavior belongs in the module that owns its domain.
- Refactors should be incremental, avoiding both a monolith and unnecessary fragmentation.
- State and parsing logic should be testable without interactive terminal I/O where practical.
