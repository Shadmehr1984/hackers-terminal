# ADR 0009 — Mission Modifier Selection and Runtime Effects

- **Status:** Accepted
- **Date:** 2026-11-05
- **Feature:** HT-007 Mission Modifiers

## Context

Hacker's Terminal needs controlled replay variation without opaque random penalties, mutation of authored contract definitions, save-format changes, or bypassing established Detection and progression systems.

## Decision

- The player manually selects zero or one modifier during Mission Preparation using the separate `modifier [id|none]` command.
- The initial set is `heightened-monitoring`, `security-sweep`, and `hardened-encryption`.
- Proposed eligibility default (confirm before implementation): make all three available on the four current built-in contracts. Eligibility remains static catalog metadata.
- Exact effects and the completion bonus are disclosed before `accept`.
- `accept` snapshots the selection into runtime-only MissionSession state; static Mission definitions are never mutated.
- Modifier selection and Security Sweep cadence are runtime-only. Save V3 and V2/V1/legacy compatibility remain unchanged.
- Detection effects flow through the existing central Detection path.
- Successful completion with a modifier grants a separate +$50 and +25 XP exactly once. Failed/incomplete runs grant no modifier bonus.

## Approved effects

| Modifier | Effect |
|---|---|
| `heightened-monitoring` | +2 Detection per successful topology traversal, after the run's Silent Boots adjustment |
| `security-sweep` | +8 Detection after every third successful traversal (3, 6, 9, ...); revisits count; rejected moves do not |
| `hardened-encryption` | Incorrect decryption-key attempts cost +15 Detection instead of +10; successful decryption remains +10 |

## Consequences

- No random generator or seed is required for HT-007.
- At most one effect can be active, so stacking rules are unnecessary.
- Preparation and session state gain transient modifier data; retry starts with no selected modifier.
- The existing command parser's first-argument model is sufficient.
- Completion reward coordination must guard against duplicate payout.
- Future modifiers, eligibility changes, stacking, automatic selection, or persistence require a separate design and owner approval.

## Scope boundary

This ADR records design approval only. It does not authorize implementation. The owner must separately authorize HT-007 coding.