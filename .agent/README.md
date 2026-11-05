# Agent Workspace

Read the root AGENTS.md first; it is the mandatory project contract.

## Read order
1. AGENTS.md and current source files.
2. Relevant records in decisions/.
3. conventions.md and the matching gameplay, command, or save documentation.
4. roadmap.md and known-issues.md.
5. For an approved feature, read its task brief from tasks/ before implementation.
6. For substantial work, update the feature brief's progress notes and follow tasks/TEMPLATE.md.
7. Follow workflow.md and finish with review-checklist.md.

## Current source layout

The implementation is grouped by responsibility; consult `../docs/architecture.md` and `conventions.md` for the maintained module map:

- `../src/domain/`: player, mission, mission session, topology, progression, and Contacts rules.
- `../src/application/`: game orchestration, command parsing, Detection handling, and shop operations.
- `../src/catalog/`: built-in mission definitions.
- `../src/presentation/`: terminal output.
- `../src/persistence/`: save/load and compatibility.
- `../src/main.zig`: composition root and interactive loop.
- `../tests/`: unit and integration tests; the aggregate remains `../tests/test_all.zig`.

Legacy top-level `src/*.zig` files are compatibility facades. New code and current architecture notes should use the grouped implementation paths. Historical task notes may describe the paths that existed when the task was implemented; distinguish those snapshots from current module ownership.

## Contents
- workflow.md: Explore, Understand, Plan, Implement, Verify, Document, Review, Commit.
- conventions.md: current module contracts and dependency direction.
- roadmap.md: owner-approved gameplay program, implementation order, and feature status.
- known-issues.md: verified constraints separated from open questions.
- decisions/: accepted Architecture Decision Records.
- tasks/README.md: index of approved feature task briefs and dependency order.
- tasks/HT-001 through HT-005: goals, scope, constraints, dependencies, and acceptance criteria for the completed foundational gameplay systems.
- plans/GAMEPLAY-EXPANSION-OVERVIEW.md and PHASE-1 through PHASE-4: the owner-approved planning baseline and handoff specifications for 20 future gameplay features (HT-006 through HT-025). Planning approval is not implementation authorization.
- tasks/TEMPLATE.md: concise task specification.
- review-checklist.md: independent review criteria.

## Agent expectations
Task briefs are persistent handoff documents. Agents must read the relevant brief before implementation, keep its status/progress notes current, and update the roadmap when a milestone changes status. Approval of the overall program is not permission to combine all features into one oversized change. Work in order and preserve the fictional/offline-only boundary.

Keep this workspace concise and update it only when lasting decisions, constraints, or agreed plans change.
