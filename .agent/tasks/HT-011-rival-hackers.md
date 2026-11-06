# HT-011 — Rival Hackers

- **Status:** Completed
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

- [x] Exactly five unique rival profiles exist and validate against faction, mission, and hidden optional objective catalogs.
- [x] Each rival has a stable command slug, faction, specialty, approach, and briefing hint.
- [x] Status derivation covers DORMANT, CONTESTING, RIVAL_AHEAD, and OUTPACED deterministically.
- [x] `rivals` lists all five rivals and their status.
- [x] `rival <id>` shows one dossier; unknown IDs are rejected.
- [x] Contract Board shows the relevant rival and contest state.
- [x] Preparation discloses the rival and counterplay before the affected event; active Briefing reports the live contest outcome without stale pre-decryption advice.
- [x] Successful decryption makes the linked hidden optional objective unavailable only when it remains undiscovered.
- [x] Discovering the optional evidence before decryption prevents the rival claim.
- [x] The rival event never changes required objectives or blocks primary contract completion.
- [x] No direct Detection, cash, XP, or Reputation mutation and no change to base-reward or all-optional Reputation-bonus formulas; losing the contested optional objective may forfeit the existing bonus for that run.
- [x] No real networking, external actors, shell execution, or credential collection is introduced.
- [x] Focused tests are registered in `tests/test_all.zig`.
- [x] Architecture, gameplay, commands, save, development, and agent handoff docs are synchronized.
- [x] Agent-doc structure checks pass.
- [x] Zig formatting, build, and full tests pass in CI Debug, ReleaseSafe, and ReleaseFast.
- [x] Mandatory code review is completed and all findings are resolved or explicitly recorded.

## Verification plan

- [x] `zig fmt --check test_root.zig build.zig src tests`
- [x] `zig build`
- [x] `zig build test`
- [x] `sh scripts/check-agent-docs.sh`
- [x] Inspect actual GitHub Actions result for the final main commit.
- [x] Review the complete diff against `.agent/review-checklist.md`; report self-review/independent-review availability accurately.

## Progress log

- 2026-11-06: Read project instructions, agent workflow/conventions/review standard, phase-2 and master plans, gameplay/command/architecture/save docs, current source and test ownership. Confirmed the existing five hidden optional objectives provide deterministic, zero-cash rival contest hooks.
- 2026-11-06: Added rival domain/catalog/simulation modules, game dispatch, Contract Board/Preparation/Briefing integration, five rival dossiers, and focused tests. Updated the aggregate test list and project/agent documentation. Static self-review and call-site audit found a missing `RivalId` import in `src/catalog/rival_data.zig`; fixed in commit `3dfe5c1e59279a621d90c016db8f351cf611ab09`. Also corrected the Contract Board test call and clarified that a rival claim can forfeit the pre-existing all-optional Reputation bonus without changing its formula. The container has no Zig executable, and the connected GitHub workflow/status endpoints have not exposed a run for the latest push; formatting, build, tests, and CI therefore remain unverified. Keep status In Progress until real CI evidence is available.
- 2026-11-06: Follow-up static audit found a stale `printRivalBriefing` call in the pre-launch preparation path after its signature was extended with a status argument. Passed `.contesting` for this pre-launch view (the active Briefing continues to use the live derived status) in commit `53637e2491cbcb4a5d1b1f3e458f77fa087b754b`. Re-audited all current `printRivalBriefing` / `printPreparation` call sites, confirmed `rival_test.zig` is registered in `tests/test_all.zig`, and checked the rival catalog references and CI workflow definition. The CI/status connector still returns no run/status entries for this push-triggered commit; this is not evidence of a pass or failure. Formatting, build, tests, agent-doc check, and full independent review remain unverified; keep status In Progress.

- 2026-11-06: Investigated CI run #948's Corporate Ghost regression. The test decrypted at `data-vault` before visiting `mirror-node`, while HT-011 intentionally resolves the rival contest immediately after successful decryption; therefore the hidden objective correctly became unavailable and the test's later `discovered` expectation was invalid. Reordered the test route to visit `mirror-node` from `auth-core` before `data-vault`, asserted the objective is discovered before decryption and that the decryption output does not report `[RIVAL AHEAD]`, then continued the normal analysis/extraction route. Updated the Corporate Ghost smoke-test route in `docs/development.md` to make the counterplay order explicit. Commits: test `d9e9e11a3702451d008e66b37fb3a3904ec71433`; development guide `491aec639f01b24c8ea8a472b37a2e662f1fdec8`. Local Zig execution is unavailable; CI for the resulting `main` commit is pending and must be inspected before accepting HT-011. The task remains In Progress.

- 2026-11-06: Applied the post-review fixes on `main`. F-01: moved optional-objective finalization until after completion payout/output succeeds; added regression coverage for both `RewardOverflow` and writer failure, asserting discovered optional objectives remain unchanged and the mission is not completed. F-02: checked the GeneralPurposeAllocator deinit result and emit an explicit stderr diagnostic on `.leak`. Coverage gap: added a catalog-driven test exercising all five rivals' authored Node/File/Action discovery triggers in both player-first and rival-first outcomes. Documentation: README now lists HT-011 and its module layout; development guide and agent invariants describe the regression guarantees. Commits: `37c7f34` (transactional finalization), `ef78656` / `afcb2eb` (allocator diagnostic), `973f7ab` (payout-failure tests), `cef991a` (five-rival trigger coverage), `a71ccc3` (README), `d3e95e1` (development guide), and this handoff update. CI for the resulting main commit remains to be inspected; do not mark HT-011 complete until the final CI run and review verification are recorded.

- 2026-11-06: Tightened the all-rivals regression test to use explicit `Mission` and `MissionObjective` types and assertion-based catalog lookup rather than inferred optional types. Final code commit: `00e7e0dc63087b9c6e551d430a138be2a233d346`. Compared the remediation range against the pre-fix CI-passing baseline: 10 commits ahead, 0 behind, with the expected nine changed files. The latest commit is present in the repository's recent commit list. The available combined-status endpoint currently returns no status checks, and the connected workflow-run endpoint exposes pull-request-triggered runs only (none returned for this push commit); therefore the push-triggered CI conclusion is not yet verifiable here. Local Zig is not installed. Keep verification and final acceptance pending until the actual Actions run can be inspected.

- 2026-11-06: Continued static verification found two test-hardening opportunities before CI: the five-rival test should not assume a discovery event can reveal exactly one objective, so it now asserts that discovery occurred and checks the contested objective's state; the extraction-output failure writer now uses an explicit pointer-backed counter because command dispatch passes writer values through generic helpers. The rival test also uses the shared ObjectiveState alias consistently. These are verification-quality fixes, not gameplay changes. CI remains unobservable through the currently available status/run endpoints; do not claim a pass without the actual Actions result.

- 2026-11-06: Fixed the formatting-only failure reported by CI run #968: removed the extra blank line between test declarations in `tests/rival_test.zig`. No test logic or gameplay behavior changed. Commit `5dc6c30434a2a467093daed7d490abf23d4dc27f`. Zig is not installed in the editing environment, so the formatter has not been run locally; the new push-triggered CI run must confirm formatting, compilation, tests, and agent-doc checks. Keep HT-011 In Progress until that run is inspected.


- 2026-11-06: Inspected final GitHub Actions run #970 for the exact latest `main` SHA `68202103eed1aad50ba2ab6c2080c032a041ce3d`. All three jobs (Debug, ReleaseSafe, ReleaseFast) completed successfully; each passed formatting, compilation, Zig tests, and the agent-documentation structure check. Run: https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42249759703. This is CI verification; Zig is not installed in the editing environment, so no local Zig command is claimed as executed.

- 2026-11-06: Rechecked the post-review remediation paths and regression tests on the latest `main`: extraction now finalizes uncompleted optional objectives only after `progression.completeMission` has completed its checked reward calculations and output; the overflow and injected writer-failure tests assert the objective states, mission completion flag, balance, and payout guard remain unchanged on failure. The allocator deinit diagnostic is present. The catalog-driven rival test covers all five authored discovery triggers in both player-first and rival-first outcomes. Compared the final verification-hardening range (base `91d697f1be2d7b84225f48e47eb790bc6df83cfb` to head `68202103eed1aad50ba2ab6c2080c032a041ce3d`): 9 commits ahead, 0 behind; final range changes are confined to this task handoff and the two focused test files. The earlier code-review fixes are recorded in the preceding progress entries. Remaining limitation: the repository-wide checklist review did not fully inspect every historical agent handoff/test file, and no independent second reviewer was available. Keep the task In Progress until that review-coverage limitation is explicitly resolved or accepted by the owner.

- 2026-11-06: Follow-up review identified an Operation transition ordering risk: the outgoing fact was committed before its confirmation output, so a writer failure could leave the fact recorded while the stage remained current. Reordered the transition so the `[OPERATION INTEL]` record must write successfully before `grantFact`; added an injected-writer regression test that confirms the fact/stage remain unadvanced on failure and that retry advances the stage without paying twice. Added the invariant to `.agent/conventions.md` and documented the test in `docs/development.md`. Commits: `2953b18` (implementation), `c3e9b52` (regression test), `f048add` (convention), plus documentation commits below. Local Zig is unavailable; formatting/build/tests and CI verification remain pending.

- 2026-11-06: Final GitHub Actions run #976 for exact `main` SHA `1c5b180b6fb5c6cd969281e2ac6685bba5cba4a1` completed successfully (run ID `42251930547`). Debug, ReleaseSafe, and ReleaseFast all passed formatting, project compilation, the complete Zig test suite, and agent-documentation structure validation. The run conclusion is `success`: https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42251930547. Zig remains unavailable locally, so verification is based on CI. HT-011 remains In Progress solely because the mandatory review-coverage limitation is unresolved: the prior review was a self-review, not an independent second review, and not every historical agent handoff/test file was inspected. Request owner acceptance of this limitation or authorization for a broader review before marking the task complete.

- 2026-11-06: Owner approved the broader review remediations. F-01: topology movement now stages Player, active-contract, and MissionSession changes in local copies and commits only after movement, discovery, Detection warning, and compromise output all succeed; Fixer Detection service similarly stages balance, exposure, and one-use state until its confirmation output succeeds. Added writer-failure regression tests for both paths in `tests/game_detection_test.zig`. F-02: reconciled the HT-008 acceptance checklist, corrected the duplicate incomplete self-review checkbox in QUALITY-006, and added QUALITY-005 to the task index. F-03: corrected the traversal-counter known-issue note because current Detection rules terminate a run far before u32 overflow. Added the output-atomicity invariant to `.agent/conventions.md` and test coverage notes to `docs/development.md`. Commits: `e94e3a0` (state staging), `bb135ed` (regression tests), `e169eda` (HT-008 checklist), `4bbc614` (QUALITY-006 checklist), `2b72860` (task index), `e028fb8` (known constraints), `891c98c` (convention), and `28cbaa7` (development docs). Zig is not installed locally; run formatting, build, full tests, and agent-doc validation in CI before considering these changes verified. HT-011 remains In Progress pending CI and final review of the resulting diff.


## Final code review and acceptance record

**Review date:** 2026-11-06  
**Repository / branch:** Shadmehr1984/hackers-terminal / main  
**Reviewed implementation commit:** 64f7a77fdff5a2947abae9370355de3a26505db6  
**Review mode:** Repository-wide static self-review; read-only during review. No independent second reviewer was available.

### Executive summary

The broader review inventoried all 119 repository files and covered the application, domain, catalog, presentation, tests, build/CI configuration, user documentation, and Agent documentation, including historical handoffs. No confirmed Blocker or Major correctness/security issue remained. Three findings were recorded: one robustness suggestion and two documentation/maintenance nits. All three were addressed in the approved remediation commits listed in the progress log. The review did not claim manual gameplay, local Zig execution, SAST, dependency audit, or benchmark coverage.

### Findings and disposition

| ID | Severity | Location | Finding | Disposition |
|---|---|---|---|---|
| F-01 | [SUGGESTION] | src/application/game.zig:121-126, 440-445 | Move and Fixer state could be mutated before all corresponding output succeeded, leaving partial state after writer failure. | Resolved: stage candidate state and commit only after output succeeds; writer-failure regression tests added. |
| F-02 | [NIT] | .agent/tasks/HT-008-hidden-objectives.md, .agent/tasks/QUALITY-006-active-save-index-bounds.md, .agent/tasks/README.md | Acceptance/review checklists and task index were inconsistent with completed work. | Resolved: reconcile HT-008 criteria, QUALITY-006 review checkbox, and QUALITY-005 index entry. |
| F-03 | [NIT] | .agent/known-issues.md:12 | Traversal-counter overflow warning did not reflect the current Detection limits, which terminate a run far earlier. | Resolved: replace the misleading warning with the actual current invariant and a future-change caveat. |

**Detailed F-01 evidence:** if a Writer failed while printing the movement/Detection or Fixer confirmation output, the old flow could leave topology, Detection, balance, or one-use service state changed despite the command failing. The implementation now stages Player, active-contract, and MissionSession values locally and commits only after all relevant output succeeds. Tests inject output failures and assert the original state is preserved.

**Blockers:** None.  
**Unresolved NEEDS-VERIFICATION findings:** None from this review. This does not mean every optional assurance activity was performed.

### Positive observations

- Save V3 writer and V2/V1/legacy readers remain unchanged.
- Rival behavior remains deterministic and runtime-only; no real networking, shell execution, host scanning, or credential collection was introduced.
- Regression tests cover writer-failure atomicity for extraction, Operation transitions, movement, and Fixer service.
- A catalog-driven test exercises all five rival discovery triggers in player-first and rival-first outcomes.
- CI exercises Debug, ReleaseSafe, and ReleaseFast and includes formatting, compilation, tests, and Agent-documentation structure validation.

### Coverage and category matrix

The review inventoried 119 unique repository files: 39 source files, 20 test/root files, 49 Agent files, 5 main documentation files, and the remaining top-level/build/CI/script files. These area counts are an inventory description and may overlap where root/Agent documentation belongs to more than one review area. Historical Agent handoffs were included in the expanded pass. The review used the project's full checklist; no independent reviewer was available.

| Category | Coverage | Notes |
|---|---|---|
| Correctness | Reviewed | State transitions, failure paths, mission/objective progression, and regressions. |
| OWASP Security | Partially reviewed | Static review of the offline boundary and relevant input/state handling; no external SAST/security scanner. |
| Architecture / Design | Reviewed | Module boundaries, dependency direction, persistence invariants, and task/ADR consistency. |
| Performance | Partially reviewed | Static reasoning only; no benchmark or profiling run. |
| Zig-specific scan | Reviewed | Formatting/build/test evidence plus static safety, ownership, error, and integer review; no local Zig executable. |
| Maintainability / Observability | Reviewed | Diagnostics, contracts, test quality, known issues, and documentation consistency. |
| Tests | Reviewed | Test modules, aggregate registration, regression coverage, and CI test results. No manual playthrough. |
| CI | Reviewed | Workflow definition and exact GitHub Actions run #988 for the reviewed implementation SHA. |

### Verification matrix

| Check | Execution | Result / evidence |
|---|---|---|
| zig fmt --check test_root.zig build.zig src tests | GitHub Actions | Passed in Debug, ReleaseSafe, ReleaseFast; run #988. |
| zig build | GitHub Actions | Passed in Debug, ReleaseSafe, ReleaseFast; run #988. |
| zig build test | GitHub Actions | Passed in Debug, ReleaseSafe, ReleaseFast; run #988. |
| sh scripts/check-agent-docs.sh | GitHub Actions | Passed in Debug, ReleaseSafe, ReleaseFast; run #988. |
| Exact reviewed SHA | GitHub Actions | 64f7a77fdff5a2947abae9370355de3a26505db6; run ID 42254566536, conclusion success. |

Run: https://github.com/Shadmehr1984/hackers-terminal/actions/runs/42254566536

### Limitations and next actions

- This was a self-review, not an independent second review.
- Zig was unavailable in the editing environment; no local Zig command is claimed.
- Manual gameplay/playtesting, SAST, dependency auditing, and performance benchmarking were not performed.
- No unresolved required code-review remediation remains. Optional assurance activities may be scheduled separately; they are not blockers for this task's accepted scope.

### Final acceptance

HT-011's implementation, regression coverage, documentation, repository-wide review, and CI verification are complete for the reviewed implementation SHA. The final handoff update is documentation-only; its own push-triggered CI run must still be inspected after this commit.
