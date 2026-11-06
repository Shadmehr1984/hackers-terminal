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


> Historical note (2026-11-07): The owner approved replacing this toolchain pin with Zig 0.17.1 under [ADR 0016](0016-zig-0.17.1.md). This ADR remains the record of the original 0.13.0 decision; the repository stays on 0.13.0 until TOOLCHAIN-001 is fully migrated and verified.
