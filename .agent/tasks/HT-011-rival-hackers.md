# HT-011 — Rival Hackers

- **Status:** In Progress
- **Owner authorization:** Explicitly authorized on 2026-11-06 after reading the project and agent documentation.
- **Implementation branch:** `main`
- **Approved impact:** Medium
- **Roster:** Exactly five rivals
- **Persistence:** Derived/static definitions plus active-run objective state; Save V3 remains unchanged.

## Goal

Introduce five fictional hacker competitors who contest one optional intelligence opportunity per authored contract. Their presence adds readable pressure and side-content consequences without blocking primary contract completion or changing the existing economy, Detection, Reputation formula, or save format. If a rival wins an optional opportunity, the existing all-optional Reputation bonus may be forfeited because that objective remains unavailable.

## Accepted roster and authored contests

| Rival ID | Name | Faction | Contract | Optional objective |
|---|---|---|---|---|
| ghost-operator | Ghost Operator | Ghost Protocol | job-03 | relay-trace |
| null-byte | Null Byte | Null Syndicate | job-04 | mirror-fragment |
| glasswire | Glasswire | Black Veil | job-02 | routing-header |
| patchwork | Patchwork | Iron Meridian | job-01 | maintenance-telemetry |
| redshift | Redshift | Helix Consortium | job-05 | mirror-fragment |

Each profile has an authored specialty, approach, and non-spoiler briefing hint. All referenced objectives are already hidden, optional, zero-cash objectives in the existing mission catalog.

## Behavior and state model

Statuses:
- `DORMANT`: contract progression or faction access requirements are not met.
- `CONTESTING`: the contract is eligible and its optional evidence has not yet been resolved.
- `RIVAL_AHEAD`: the player decrypts before discovering the contested hidden objective; the rival marks only that objective unavailable for the current run.
- `OUTPACED`: the player discovers the contested objective first, or has completed the associated contract.

The event is deterministic and happens only after successful decryption. Existing discovery triggers allow the player to prepare:
- job-01: visit `maintenance` before decryption.
- job-02: inspect `routing-header.log` before decryption.
- job-03: the successful initial scan reveals `relay-trace`.
- job-04: visit `mirror` before decryption.
- job-05: visit `mirror-node` before decryption.

A rival can only make its linked hidden optional objective unavailable. It cannot modify the active mission's required objectives, remove a contract, change Detection, alter rewards, or prevent extraction. The pre-launch Preparation, Contract Board, and active Briefing disclose the rival and the counterplay hint before the event can occur.

## Architecture and ownership

- `src/domain/rival.zig`: stable rival IDs, profiles' domain shape, and status enum.
- `src/catalog/rival_data.zig`: five static rival profiles and contract/objective links.
- `src/domain/rival_simulation.zig`: pure status derivation and deterministic post-decryption resolution.
- `src/application/game.zig`: `rivals` / `rival <id>` dispatch and post-decryption event invocation.
- `src/presentation/terminal.zig`: rival dossiers, board labels, and pre-launch/active briefing intel.
- `tests/rival_test.zig`: catalog validation, status transitions, command output, and event integration.

Domain rules do not import application or terminal modules. The command parser remains unchanged and consumes one argument.

## Persistence and compatibility

- No Save V4 and no changes to Save V3 writer or V2/V1/legacy readers.
- Static rival profiles are catalog data.
- Contest outcome is represented by the existing runtime objective tracker state.
- Mission objective progress and rival-ahead status reset with the active mission session, consistent with current objective persistence rules.
- No player/faction/rival scores or timestamps are stored.

## Acceptance criteria

- [ ] Exactly five unique rival profiles exist and validate against faction, mission, and hidden optional objective catalogs.
- [ ] Each rival has a stable command slug, faction, specialty, approach, and briefing hint.
- [ ] Status derivation covers DORMANT, CONTESTING, RIVAL_AHEAD, and OUTPACED deterministically.
- [ ] `rivals` lists all five rivals and their status.
- [ ] `rival <id>` shows one dossier; unknown IDs are rejected.
- [ ] Contract Board shows the relevant rival and contest state.
- [ ] Preparation discloses the rival and counterplay before the affected event; active Briefing reports the live contest outcome without stale pre-decryption advice.
- [ ] Successful decryption makes the linked hidden optional objective unavailable only when it remains undiscovered.
- [ ] Discovering the optional evidence before decryption prevents the rival claim.
- [ ] The rival event never changes required objectives or blocks primary contract completion.
- [ ] No direct Detection, cash, XP, or Reputation mutation and no change to base-reward or all-optional Reputation-bonus formulas; losing the contested optional objective may forfeit the existing bonus for that run.
- [ ] No real networking, external actors, shell execution, or credential collection is introduced.
- [ ] Focused tests are registered in `tests/test_all.zig`.
- [ ] Architecture, gameplay, commands, save, development, and agent handoff docs are synchronized.
- [ ] Agent-doc structure checks pass.
- [ ] Zig formatting, build, and full tests pass in CI Debug, ReleaseSafe, and ReleaseFast.
- [ ] Mandatory code review is completed and all findings are resolved or explicitly recorded.

## Verification plan

- [ ] `zig fmt --check test_root.zig build.zig src tests`
- [ ] `zig build`
- [ ] `zig build test`
- [ ] `sh scripts/check-agent-docs.sh`
- [ ] Inspect actual GitHub Actions result for the final main commit.
- [ ] Review the complete diff against `.agent/review-checklist.md`; report self-review/independent-review availability accurately.

## Progress log

- 2026-11-06: Read project instructions, agent workflow/conventions/review standard, phase-2 and master plans, gameplay/command/architecture/save docs, current source and test ownership. Confirmed the existing five hidden optional objectives provide deterministic, zero-cash rival contest hooks.
- 2026-11-06: Added rival domain/catalog/simulation modules, game dispatch, Contract Board/Preparation/Briefing integration, five rival dossiers, and focused tests. Updated the aggregate test list and project/agent documentation. Static self-review and call-site audit found a missing `RivalId` import in `src/catalog/rival_data.zig`; fixed in commit `3dfe5c1e59279a621d90c016db8f351cf611ab09`. Also corrected the Contract Board test call and clarified that a rival claim can forfeit the pre-existing all-optional Reputation bonus without changing its formula. The container has no Zig executable, and the connected GitHub workflow/status endpoints have not exposed a run for the latest push; formatting, build, tests, and CI therefore remain unverified. Keep status In Progress until real CI evidence is available.
