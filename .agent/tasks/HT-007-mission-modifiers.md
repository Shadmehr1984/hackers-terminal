# HT-007 — Mission Modifiers

**Feature:** Mission Modifiers  
**Program:** EXPANSION-001 / Phase 1  
**Status:** Design approved; implementation not yet authorized  
**Design approval:** 2026-11-05

## Goal

Make repeat runs of existing contracts mechanically different through transparent, player-selected conditions. Preserve the fictional offline game, existing contracts, central Detection pipeline, existing reward rules, and Save V3 compatibility.

This file is the implementation handoff contract. Before coding, an agent must re-audit current source, tests, docs, and CI; this document is a design baseline, not permission to implement.

## Owner-approved decisions

1. The player manually selects zero or one modifier during Mission Preparation. No random or seeded selection.
2. Add the separate command `modifier [id|none]`. Do not change existing missions, board, prepare, loadout, or accept command contracts.
3. At most one modifier per run; no stacking. No selection means normal mission rules.
4. Selection is disclosed with exact effects and reward before accept; after launch it is immutable.
5. Preparation defaults to no selection. Cancel, failed launch, mission completion/failure, and a new preparation must not leak a prior selection.
6. Accept copies the selection into a runtime-only MissionSession snapshot. Never mutate static Mission definitions.
7. Proposed eligibility default (confirm before implementation): author all three modifiers as available for all four current built-in contracts (job-01 through job-04). Eligibility remains static catalog metadata; future contracts may declare a subset.
8. Any successful contract completed with a modifier grants a separate +$50 and +25 XP exactly once. It stacks with existing base rewards and earned optional-objective cash bonuses. No bonus on failure, compromise, cancellation, or incomplete runs.
9. Every modifier Detection event must use the existing central Detection application/failure path. Do not duplicate compromise logic or bypass the existing $50 failure penalty.
10. Modifier selection, session snapshot, and Security Sweep cadence are runtime-only. Do not change Save V3 serialization or V2/V1/legacy readers.

## Approved modifiers

| ID | Exact effect |
|---|---|
| `heightened-monitoring` | Add +2 Detection to every successful topology traversal, after the normal traversal cost has been adjusted by the run's Silent Boots loadout snapshot. |
| `security-sweep` | After every third successful topology traversal (3, 6, 9, ...), add an additional +8 Detection. Revisits count; invalid/rejected moves do not. Counter starts at zero each run. |
| `hardened-encryption` | An incorrect decryption-key attempt costs +15 Detection instead of +10. Correct decryption retains the existing +10 cost. Repeated attempts after completed decryption remain idempotent and cost nothing. |

All three grant the same +$50 and +25 XP completion bonus.

## Command contract

- `modifier`: during Preparation, display all allowed choices, exact effects, completion bonus, and current selection. Outside Preparation, explain that a contract must first be prepared.
- `modifier <id>`: select the ID only when it is allowed for the prepared contract.
- `modifier none`: clear the current selection.
- Unknown IDs, unavailable modifiers, or use outside Preparation are rejected without mutating state.
- A new prepare starts with no selection. Accept transfers the selection to the session snapshot.
- The existing parser accepts a command plus its first argument; this command fits that limitation. Do not expand parser semantics.
- Preparation output must disclose the exact effects and bonus before accept. Active briefing/status should identify the selected modifier.

## Calculation and edge rules

### Heightened Monitoring

1. Obtain the normal successful traversal cost from the run's MissionLoadout snapshot (base 5; Silent Boots can reduce it to 4/3/2).
2. Add +2 and apply the final cost through the existing Detection path.
3. Invalid/non-adjacent moves remain free and do not trigger the modifier.
Expected totals: no boots 7; Silent Boots levels 0/1/2: 6/5/4.

### Security Sweep

1. Count only successful traversals, including revisits; increment only after adjacency/destination validation succeeds.
2. Apply the normal movement cost from the run's loadout snapshot.
3. On traversal numbers 3, 6, 9, etc., apply an additional +8 Detection event through the same central Detection path.
4. Invalid moves do not count. The counter is session-only and resets on retry.
5. If the normal movement cost compromises the run, do not apply a later sweep event for that traversal. If the sweep itself reaches 100, use the existing immediate compromise path.

### Hardened Encryption

1. Preserve successful decryption cost at +10.
2. For an incorrect key before decryption is complete, apply +15 instead of +10.
3. Once decryption is complete, preserve current idempotency: later attempts do not add Detection.
4. Do not alter password/authentication costs.

### Completion bonus

- Pay +$50 and +25 XP once only when the contract completes successfully and its session snapshot contains a modifier.
- Do not mutate static mission reward fields; route the extra XP through existing progression logic.
- No payout on Detection compromise, failure, cancellation, or incomplete objectives.
- Guard against duplicate payout if completion handling is re-entered or a completion command is repeated.
- Preserve base cash, base XP, Reputation, optional-objective rewards, and the existing failure penalty.
- Show the bonus during Preparation and in completion output.

## Expected architecture ownership

Re-audit current source before implementation; these paths are the expected ownership based on the current architecture:

- New src/domain/mission_modifier.zig: typed IDs/definitions and pure effect/reward metadata; no terminal I/O.
- src/domain/mission.zig and src/catalog/mission_data.zig: static allowed-modifier metadata.
- src/domain/mission_state.zig: Preparation selection; Session snapshot and successful traversal count.
- src/application/game.zig: command validation, lifecycle, event calculations, and one-time completion bonus coordination.
- src/application/detection.zig: remain the single Detection/failure path.
- src/domain/progression.zig: grant +25 XP through the existing progression flow.
- src/presentation/terminal.zig: option/effect/reward disclosure and active-run presentation.
- tests/: focused domain and integration tests; register new modules in tests/test_all.zig.

Keep dependencies one-way. Domain rules must be testable without terminal I/O. Three typed modifiers do not justify a generic framework.

## Lifecycle invariants

- Preparation starts with no modifier.
- Selection is allowed only while preparing and before accept.
- Cancel, failed launch validation, and a new preparation cannot leak a previous selection.
- Accept snapshots the selection; later equipment or preparation changes cannot affect the active run.
- Session reset after completion/failure clears modifier and sweep count.
- Retry requires a fresh selection.
- No preparation/session field is serialized.

## Acceptance criteria

- [ ] Typed definitions exist for exactly the three approved modifiers, with stable IDs and clear descriptions.
- [ ] All four current contracts author all three as allowed.
- [ ] modifier, modifier <id>, and modifier none follow the command contract and preserve parser behavior.
- [ ] Preparation shows exact effects and +$50/+25 XP before acceptance.
- [ ] Invalid/out-of-phase/unavailable selections are rejected without state mutation.
- [ ] Accept snapshots the selection; active behavior does not read mutable preparation or live equipment.
- [ ] Heightened Monitoring adds +2 after Silent Boots adjustment; invalid moves remain free.
- [ ] Security Sweep adds +8 at successful traversal counts 3, 6, 9, etc.; revisits count and rejected moves do not.
- [ ] Hardened Encryption changes only incorrect decryption attempts to +15; successful and repeated-completed behavior remains correct.
- [ ] All modifier Detection events use the central path and compromise immediately at 100.
- [ ] Successful completion grants +$50/+25 XP exactly once; failure/incomplete paths grant none.
- [ ] Retry starts without the previous modifier or sweep count.
- [ ] Save V3 writer and V2/V1/legacy readers remain unchanged.
- [ ] Tests cover selection, eligibility, snapshot, equipment interaction, Detection boundaries, sweep cadence, idempotency, payout uniqueness, and reset.
- [ ] User docs, architecture, ADR, and agent handoffs are synchronized.
- [ ] Zig 0.13.0 formatting, build, tests, agent-doc check, review, and actual CI are verified before marking Implemented.

## Explicit non-goals

- Automatic/random/rotating/seeded selection; multiple or stacking modifiers.
- Time pressure, real-time timers, decoy data, limited access, unstable nodes, or other future modifiers.
- New missions, changed puzzle answers, base rewards, XP thresholds, Reputation, equipment prices, or baseline Detection costs.
- Save V4 or persistence of preparation/session state.
- Real network activity, external hosts, shell execution, or credential collection.
- Changes to existing missions or board command behavior.

## Implementation milestone plan

1. Re-audit current main, source, ADRs, tests, and CI; record baseline SHA.
2. Implement typed modifier definitions and pure domain tests.
3. Add authored eligibility and preparation selection/reset tests.
4. Add modifier command and preparation/active-run presentation tests.
5. Add session snapshot and each Detection effect with focused integration tests.
6. Add one-time cash/XP bonus and failure/retry tests.
7. Update user and agent documentation; inspect Save V3 diff for zero serialization changes.
8. Run Zig 0.13.0 fmt/build/full tests and agent-doc check; inspect actual CI.
9. Complete independent review when available (otherwise label self-review honestly) and record commit/PR/CI evidence.

**Progress note:** On 2026-11-05 the owner approved manual selection, one modifier maximum, the three exact effects, and the common +$50/+25 XP successful-completion bonus. This is design approval only. Do not create gameplay code until the owner separately authorizes HT-007 implementation.