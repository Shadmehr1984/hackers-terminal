# AGENTS.md — Hacker's Terminal Project Instructions

This file is the persistent source of project-specific instructions for AI coding agents and contributors. Read it before planning or changing code. If a new task or a newer source file conflicts with this document, inspect the repository and resolve the discrepancy rather than blindly following stale notes.

## Project identity and boundaries

- Project: **Hacker's Terminal**, a single-player, command-driven terminal game.
- Language/toolchain: **Zig 0.13.0**. Do not silently upgrade the Zig version or use APIs from newer Zig releases.
- The game is fictional, local, offline, and self-contained.
- Never add real network scanning, real host connections, shell-command execution, credential collection, or interaction with external systems. Hostnames and hacking actions are simulated game content only.
- Preserve the text-terminal experience unless a task explicitly changes the product direction.

## Non-negotiable engineering principles

1. **Incremental modularization:** keep modules focused and split code only when it creates a clear responsibility boundary. Avoid both a monolithic file and unnecessary fragmentation.
2. **Single responsibility:** each module should own one coherent area of behavior.
3. **One-way dependencies:** avoid circular imports. Keep foundational data types independent of higher-level game coordination and terminal I/O.
4. **Behavior preservation:** refactors should preserve existing gameplay, command syntax, progression, and save behavior unless the task explicitly requests a change.
5. **Testability:** keep game rules and state transitions testable without requiring interactive terminal input/output wherever practical.
6. **Small, reviewable changes:** implement one coherent step at a time. Avoid unrelated cleanup mixed into feature work.
7. **Documentation:** update the relevant documentation whenever architecture, commands, gameplay, development workflow, or persistence behavior changes.
8. **No speculative complexity:** prefer simple Zig code and the standard library. Do not introduce frameworks, dependencies, generic abstractions, or design patterns without a concrete need.

## Current architecture (verify against source before editing)

Production modules are grouped by responsibility under `src/domain/`, `src/application/`, `src/catalog/`, `src/presentation/`, and `src/persistence/`. `src/main.zig` remains the composition root. The original top-level `src/*.zig` module paths are compatibility facades; new production code should import the grouped implementation paths directly.

- `src/main.zig`: application entry point, allocator and standard I/O setup, save loading, welcome output, and interactive input loop.
- `src/application/game.zig`: shared command dispatch and game-state validation/transitions.
- `src/application/detection.zig`: Detection exposure costs, warnings, compromise failure, and bounded penalty.
- `src/domain/progression.zig`: XP thresholds, player levels, Reputation tiers, and mission reward progression.
- `src/domain/contacts.zig`: fictional Contact identities, unlock thresholds, and Fixer service pricing.
- `src/domain/faction_id.zig` and `src/domain/faction.zig`: stable faction identities, relationship/standing types, and pure standing derivation from Reputation plus completed contract affiliations.
- `src/catalog/faction_data.zig`: seven authored fictional faction profiles and static symmetric inter-faction relationships.
- `src/domain/rival.zig`, `src/domain/rival_simulation.zig`, and `src/catalog/rival_data.zig`: stable fictional rival identities, five authored profiles, deterministic contest status, and runtime optional-intelligence outcomes.
- `src/domain/player.zig`: player profile, typed equipment ownership, utility slot, upgrade levels, and pure risk modifier calculations.
- `src/domain/mission.zig`: mission/contract data types, static faction affiliations, categories, optional topology reference, level/Reputation requirements, difficulty classification, and typed objective definitions.
- `src/domain/mission_objectives.zig`: fixed-capacity per-objective state tracker, typed discovery triggers, and allocation-free objective lifecycle rules.
- `src/domain/contract_board.zig`: pure derived Contract Board availability, faction access, and reward-range calculations; no persistence or terminal I/O.
- `src/domain/operation.zig` and `src/domain/operation_state.zig`: static linear operation contracts, typed facts, and bounded runtime-only lifecycle.
- `src/catalog/operation_data.zig`: authored multi-stage operation sequences.
- `src/domain/topology.zig`: foundational fictional graph nodes, links, adjacency lookup, and validation that required operation nodes are reachable from the entry node.
- `src/catalog/mission_data.zig`: built-in mission catalog.
- `src/domain/mission_state.zig`: runtime-only mission preparation choice (including bounded OperationState), active-mission progress, connection state, objective completion tracking, detection exposure (0–100), topology position, traversal count, per-run loadout snapshot, and one-use Fixer service state.
- `src/application/commands.zig`: allocation-free parsing of command name and first argument; extra tokens are intentionally ignored for compatibility.
- The `board` command is a separate full Contract Board; preserve the existing `missions` command behavior.
- `src/presentation/terminal.zig`: terminal presentation, including mission list, operation list/details/status, briefing-related output, and topology maps.
- `src/persistence/save.zig`: V3 persistence and compatibility with V2, V1, and legacy save formats.
- `src/application/shop.zig`: equipment catalog, inventory, purchases, equipping, and utility upgrades.
- `tests/`: unit tests, separate from production source.
- `docs/`: user and developer documentation.

Read `docs/architecture.md` for the detailed module map and runtime flow, `docs/gameplay.md` and `docs/commands.md` before changing gameplay or command behavior, and `docs/save-format.md` before touching persistence.

## Gameplay and state invariants

- Mission progression is ordered: `inactive -> accepted -> scanned -> authenticated -> decrypted`.
- Connection status is independent from mission progress. Disconnecting must not erase authentication or decryption already achieved.
- A mission cannot skip required stages. Preserve the validation rules around scan, connect, authentication, decryption, and extraction.
- Current progression rules: level 1 begins below 100 XP; the first level-up threshold is 100 XP and each subsequent threshold increases by 150 XP. Reputation tiers are Unknown (0), Recognized (1–2), Trusted (3–4), and Elite (5+). A successful mission grants +1 Reputation; completing every optional objective grants +1 additional. Failed/compromised missions do not change Reputation. Preserve these rules unless a balancing change is requested.
- The built-in mission catalog currently contains `job-01` through `job-05`; Ghost Signal (`job-04`) remains at index 3 and requires level 3 and Reputation 3, while Corporate Ghost (`job-05`) is appended at index 4 and requires level 2 and Reputation 2. The first four mission indices must remain stable for save compatibility. Corporate Ghost is a standard Nexus Dynamics contract against a Null Syndicate-owned target and is faction-locked while Nexus standing is Hostile. Difficulty values remain descriptive metadata only.
- HT-010 defines seven fictional factions. Contract client, target-owner, and optional opposing-faction links are static catalog metadata. Player standing is derived from global Reputation plus completed-contract outcomes (client +2; target owner/opposing -2). Standing bands are Hostile (<= -2), Wary (-1), Neutral (0–2), Trusted (3–5), and Allied (>= 6). Hostile standing toward a client faction blocks Contract Board availability, contract selection, and Broker intelligence listing/purchases; no faction score is serialized. Static faction profiles/relationships must not alter existing rewards, Reputation thresholds, Detection costs, Contact prices, or Save V3 layout.
- Keep mission definitions, rewards, clues, puzzle answers, and their ordering consistent with the existing catalog unless explicitly changed.
- Temporary mission-session state (including the one-time completion payout guard), mission preparation (including selected modifier), and per-run utility/modifier snapshots are runtime-only and are not persisted. A restored active mission starts again at the accepted stage.
- Mission difficulty, category, and objective definitions are static catalog data and are not serialized. Do not change the save format merely to persist them.
- Each mission defines objectives with stable mission-local IDs and a `MissionObjectiveKind` completion event. Visible objectives start discovered; hidden optional objectives use typed Node/File/Action triggers and remain hidden until discovered. Objective state is tracked per objective in a fixed-capacity 32-entry runtime tracker; duplicate/empty IDs, invalid hidden definitions, and over-capacity catalogs are rejected safely.
- `MissionObjective.optional` marks work that does not block contract completion. Completed optional objectives grant their configured `bonus_reward` when the contract is completed.
- Objective discovery/completion/unavailability and Detection exposure are runtime-only session state. HT-011 rivals may mark only their linked hidden optional objective unavailable after successful decryption when it remains undiscovered; this never affects required objectives, primary contract completion, Detection, rewards, or Save V3. `extract` may complete a contract only when every required objective is complete. Hidden objectives are always optional and never gate contract completion; all authored optional objectives, including hidden ones, must be completed for the extra Reputation bonus. Hidden descriptions/rewards must not leak before discovery.
- Detection starts at 0 for each mission, is capped at 100, and is not serialized. At 100 the active contract fails, a $50 penalty (capped at the current balance) is applied, and the contract remains retryable. Keep action costs, threshold bands, and reset behavior covered by tests and documented in `docs/gameplay.md`. Base movement/authentication costs remain 5 and 15; HT-003 equipment and the approved HT-007 modifiers apply only their explicitly defined run-snapshot effects.
- Authentication and decryption are completed stages: once either succeeds, repeated attempts at that same stage must be acknowledged without re-evaluating an incorrect supplied secret or increasing Detection. Keep this idempotency covered by regression tests.
- HT-009 operations are static linear sequences of at most eight existing contracts. Operation stage/fact state is runtime-only, facts are granted only after successful stages, completed stage contracts can be replayed without rewards, and saves during an operation must write no active mission index. Operation list/details/status output must show derived client-faction standing and faction locks consistently with operation-start validation. Once started, an operation remains preauthorized despite later standing changes; active views must say so explicitly. Save V3 and legacy readers remain unchanged.
- Mission preparation is runtime-only: `prepare <id>` opens a contract only when both level and Reputation requirements are met, `loadout <utility|none>` selects an owned utility for that run, `modifier [id|none]` lists/selects/clears at most one modifier restricted to the mission's static allowlist, `accept <id>` launches only the matching prepared contract and snapshots utility plus modifier, and `cancel` clears preparation. Preparation must disclose exact modifier effects and bonuses but must not reveal puzzle clues or answers.
- Contact unlocks are derived from Reputation: Information Broker at 1 and Fixer at 3. Broker clue purchases cost $50 and never reveal puzzle answers. Fixer Detection service costs $100 at Trusted and $75 at Elite, reduces Detection by up to 10, and is usable once per mission; its usage flag is runtime-only.
- An active mission snapshots its selected utility, upgrade level, and optional mission modifier; all run effects must use the session snapshot, not live preparation or player equipment. Buying/equipping/upgrading mid-run must not alter that run. `heightened-monitoring` adds +2 after each successful traversal's equipment-adjusted cost; `security-sweep` adds +8 after every third successful traversal, after the normal cost and only if it did not already compromise the run; `hardened-encryption` changes incorrect decryption-key exposure to +15. Every Detection event uses the central failure path. A successful modified contract grants +$50/+25 XP once; the session guards the entire completion payout against re-entry, and failed/incomplete runs grant no modifier bonus. Active contracts cannot be abandoned or manually restarted; a compromised contract remains retryable through the existing failure path.
- For missions with a topology, `map` displays the graph and `move <node-id>` permits only adjacent movement. Each successful traversal adds 5 base Detection, including revisits; Silent Boots adjust that cost, then HT-007 traversal modifiers apply in their documented order. Invalid movement changes neither location nor detection. Scan, authentication, decryption, optional analysis, and extraction are restricted to their authored mission nodes. Current node and traversal count are runtime-only and must never be serialized.

## Persistence safety

- Save compatibility is important. Existing V2, V1, and legacy saves must continue to load unless a deliberate migration is designed and documented. Current V3 persists typed utility ownership, equipped utility, utility upgrade levels, Reputation, and mission completion flags; older formats migrate with no utilities owned/equipped. The appended fifth mission defaults to incomplete when an older save has only three or four completion flags; a three-flag save also leaves job-04 incomplete.
- Do not change serialized field order, save version markers, defaults, or the save path as incidental parts of unrelated refactors.
- Save writes must stage the complete unchanged-format payload in a temporary file and rename it into place only after a successful write; do not truncate the previous save before the replacement is ready. Loaders must validate every required field and completion flag for V3/V2/V1/legacy before mutating caller-owned state; truncated or malformed saves leave player and mission state unchanged. Preserve compatibility with older saves that omit trailing mission-completion flags; omitted missions default to incomplete, while extra flags are rejected.
- Mission completion payouts must use checked arithmetic for cash, Reputation, and XP. Optional-objective cash accumulation and Contract Board maximum-reward estimation must also use checked u32 arithmetic and propagate RewardOverflow rather than wrapping. Preflight all totals, write completion output, then commit player progression and the runtime payout guard; arithmetic overflow must leave all payout fields and the guard unchanged. The game must not mark a mission completed until payout succeeds.
- Any intentional save-format change must update `docs/save-format.md`, include migration/compatibility handling where needed, and add or update tests.

## Tests, formatting, and verification

Use Zig **0.13.0** and the repository's documented commands:

```sh
zig fmt --check test_root.zig build.zig src tests
zig build
zig build test
zig test test_root.zig
```

- Add tests under `tests/`; do not put test modules back into `src/`.
- Keep `tests/test_all.zig` as the aggregate test list and include new test modules there.
- `zig build test` is the supported build-system test step; it uses `test_root.zig` and the unchanged aggregate list.
- Use `test_root.zig` as the test command's root module.
- Add tests for state transitions, objective definitions and completion tracking, parsing edge cases, progression rules, save compatibility, and allocator failure paths when those areas change.
- Document exported public types, constants, and functions with concise Zig doc comments.
- If local build execution is unavailable, perform static inspection and say clearly that build/tests were not run. Never describe static inspection as a passing build or test.
- When CI is available, inspect the actual workflow run and report its conclusion; do not infer success from a commit being pushed.

## Repository workflow

- Work directly on `main` by default. Do not create feature/phase branches or pull requests unless the owner explicitly requests a separate branch or PR. Keep changes small and reviewable; obtain explicit approval before destructive or scope-expanding actions.
- Before editing an existing file, fetch its latest contents and current blob SHA from GitHub. Do not overwrite based on stale copies.
- After changes, inspect the resulting files/diff and verify the commit exists on `main`. Report the exact commit and CI status; do not claim verification that was not performed.
- Do not claim that a change has been pushed or committed until GitHub confirms it.
- Explain the purpose and architectural impact of meaningful changes in the conversation. Prefer Persian explanations for this user, while keeping source code, identifiers, and repository documentation in clear technical English.

## Working with future feature ideas

The completed foundational gameplay program HT-001 through HT-005 is recorded in `.agent/roadmap.md` and `.agent/tasks/`. The next 20-feature expansion program (HT-006 through HT-025) is planned in `.agent/plans/GAMEPLAY-EXPANSION-OVERVIEW.md` and its four phase handoff documents. HT-006 is implemented and merged. HT-007 implementation is merged to `main` in commit `c17d19b93c18af286e97d6f00d2b9892017a784c`; its accepted design is recorded in .agent/tasks/HT-007-mission-modifiers.md and ADR 0009. Mission modifier eligibility is static catalog metadata and preparation selection is runtime-only; do not serialize it. HT-009 implementation was explicitly authorized and completed directly on `main` on 2026-11-06; its accepted Runtime-only design is recorded in ADR 0011 and CI run #733 passed. HT-010 implementation was explicitly authorized on 2026-11-06 and is implemented on `main`; HT-011's five-rival Medium-impact design is accepted under ADR 0014 and its implementation is in progress on `main`; its seven-faction/derived-standing decisions are recorded in ADR 0012 and its final handoff/review is `.agent/tasks/HT-010-factions.md` (CI #42224233431 passed Debug, ReleaseSafe, and ReleaseFast). HT-010.1 Corporate Ghost was separately approved as the fifth contract and is implemented on `main` under ADR 0013 and `.agent/tasks/HT-010.1-corporate-ghost.md` (CI #42221149753 passed). All other expansion features remain planning-only until individually designed and authorized. Before any future implementation, read the master plan and matching phase document, inspect current source/docs/tests/save behavior, create a feature-specific task brief and progress notes, and work in dependency order one small reviewable milestone at a time. Do not interpret inclusion in the plan as permission to code. Branching narrative and dialogue trees remain out of scope; multi-stage operations are mechanical sequences only.

All new systems must remain entirely fictional, local, and offline. Never implement real networking, external host interaction, shell execution, or credential collection.

Before implementation:
1. Confirm current behavior from source; do not assume this architecture snapshot is exact.
2. Identify the owning module, dependencies, affected tests, docs, and persistence implications.
3. Explain the smallest useful design and acceptance criteria.
4. Add focused tests and update docs as part of the same coherent change.
5. Avoid implementing later roadmap items pre-emptively.
6. Whenever an agreed feature changes architecture, gameplay rules, data contracts, or development conventions, update this `AGENTS.md` in the same implementation step.

## Agent infrastructure and required work cycle

The `.agent/` directory is the project memory for coding agents. Read `.agent/README.md` after this file; it links the workflow, module contracts, roadmap, known constraints, ADRs, task template, and independent review checklist.

For every code change, follow `.agent/workflow.md`: Explore → Understand → Plan → Implement → Verify → Document → Review → Commit. For non-trivial work, create/update a task brief from `.agent/tasks/TEMPLATE.md`. Before implementation, confirm current behavior from source and identify the owning module, affected tests, documentation, and persistence implications.

### Definition of Done

A change is complete only when all applicable items are satisfied:
- [ ] Acceptance criteria are met and unrelated behavior is preserved.
- [ ] Focused tests cover new behavior and important rejection/edge cases.
- [ ] Zig formatting, build, and the full test suite pass, or unrun checks are explicitly reported.
- [ ] `sh scripts/check-agent-docs.sh` passes when agent infrastructure is present.
- [ ] Relevant README/docs and this file are updated for lasting architecture, gameplay, data-contract, save, or development-rule changes.
- [ ] The independent review checklist in `.agent/review-checklist.md` is completed.
- [ ] A focused commit is confirmed on the authorized `main` branch.
- [ ] The actual CI result for that commit is inspected and reported; manual gameplay testing is never implied unless performed.

### Review expectations

For substantial changes, use a second, independent reviewer/agent where available. The reviewer should inspect the diff against the task acceptance criteria and checklist, not merely approve the implementer's summary. If no independent reviewer is available, state that limitation and perform a clearly identified self-review; do not claim a second-agent review occurred.

### Documentation maintenance

Keep `.agent/roadmap.md` as the authoritative feature sequence and status tracker. Keep `.agent/known-issues.md` factual and distinguish verified constraints from open questions. Add ADRs only for decisions actually accepted by the project owner. Update module contracts when source responsibilities change. Do not mechanically edit every agent file for trivial changes.

### CI documentation check

The CI workflow also runs `sh scripts/check-agent-docs.sh` to ensure the required agent guidance and core docs remain present. This structural check does not replace code review, Zig compilation, unit tests, or manual playtesting.

## Mandatory code review standard

Every code review request must follow the complete `.agent/review-checklist.md` standard. That file is the canonical, exhaustive review contract; it is not optional and must be read in full by every agent before reviewing. It requires the weighted Correctness (40%), OWASP Top 10:2025 Security (20%), Architecture/Design (30%), and Performance (10%) passes; the exact Zig scan order (`zig fmt` → ALWAYS FLAG → Safety → Context-dependent → Style); project-specific checks; Maintainability/Observability; tests and CI verification; severity/evidence rules; and the complete final report with coverage statistics and limitations.

For a full repository review, inspect the whole current repository, not only a diff. Account for every relevant source, test, build/configuration, workflow, and documentation file. Mark every item as reviewed, not applicable (with reason), partially reviewed, or not verified. Every finding requires exact file/line evidence and a concrete scenario or rationale. If evidence is unavailable, say "نمی‌دانم" and use `[NEEDS-VERIFICATION]`; never guess or overstate coverage.

A code review is read-only by default. Do not modify source, tests, documentation, CI, or repository state unless the owner separately authorizes fixes. Never claim tests, CI, or manual gameplay checks passed unless they were actually run and their results inspected.
