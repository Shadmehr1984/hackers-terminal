# ADR 0001: Pin the Zig Toolchain to 0.13.0

- Status: Accepted
- Date: 2026-11-05

## Context
The build configuration, source, and CI target Zig 0.13.0. Changing versions can introduce unrelated language/API compatibility changes.

## Decision
Keep Zig 0.13.0 as the project toolchain. Toolchain upgrades must be explicit, tested, and documented.

## Consequences
- Agents must not silently use newer Zig APIs.
- CI installs 0.13.0 before formatting, building, and testing.
- A future upgrade is a separate compatibility task.
