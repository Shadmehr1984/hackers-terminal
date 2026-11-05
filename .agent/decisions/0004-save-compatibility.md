# ADR 0004: Preserve Existing Save Format Compatibility

- Status: Accepted
- Date: 2026-11-05

## Context
The loader supports V2, V1 (without XP), and an original unversioned layout. The format is positional and save files are local.

## Decision
Preserve V2, V1, and legacy loading. Any intentional schema change is a migration task, updates docs/save-format.md, and includes compatibility tests.

## Consequences
- Save serialization is out of scope for incidental refactors.
- Field order, version markers, defaults, and save path are compatibility-sensitive.
- Inspect save code and docs before modifying player or mission persistence.
