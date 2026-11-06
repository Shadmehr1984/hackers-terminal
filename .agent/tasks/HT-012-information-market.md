# Task: HT-012 — Information Market / Information Warfare

- **Status:** Design Approved; implementation not authorized
- **Feature:** HT-012 — Information Market
- **Phase:** EXPANSION-001 / Phase 2 — World, Intelligence, and Relationships
- **Decision record:** [ADR 0015 — Information Market](../decisions/0015-information-market.md)
- **Decision owner:** Project owner
- **Baseline branch:** `main`
- **Design baseline reviewed:** 2026-11-06

> This document records the owner's accepted design decisions and the proposed implementation contract. It is not permission to implement. Do not change production code until the owner separately authorizes implementation.

## 1. Goal

Expand the existing fictional Information Broker clue offer into a deterministic, multi-source information market and an information-warfare gameplay system. The player should inspect, purchase, compare, and research uncertain reports; identify contradictions and source dependencies; and react to intelligence deception and rival activity.

The feature should reward investigation and evidence evaluation rather than simply selling answers. Preserve the terminal-first, single-player, fictional, local/offline identity.

## 2. Owner-approved decisions — authoritative

The following decisions were explicitly selected by the project owner. Implementers must not silently replace them.

| Decision area | Accepted choice | Required interpretation |
|---|---|---|
| Fake intelligence | **BOTH** | Deception has narrative effects and gameplay effects. |
| Research depth | **DEEP** | Research is a multi-stage system with evidence requirements and meaningful alternative paths/results, not a one-command report merge. |
| Market behavior | **DYNAMIC** | Stock and offers respond to deterministic game state, progression, faction/rival conditions, and authored events. |
| Persistence | **DERIVED (option C)** | Reconstruct only what can be proven from existing persisted progression/history. Do not add Save fields or infer ownership from balance/reputation alone. Unprovable details remain runtime-only. |
| Research using fake intelligence | **BOTH** | Depending on the authored deception and evidence, research may produce an incomplete result or a misleading result. |
| Exposure | **EVENT** | Exposure triggers bounded, authored Counter-Intelligence events. It does not directly modify Reputation or faction Standing. |
| Rival involvement | **ACTIVE** | Existing rivals participate in the information contest through bounded simulated actions. |
| Purchase limits | **MIXED** | Some reports are repeatable; special/unique reports are one-time. Each catalog entry declares its policy. |
| Freshness | **EVENT-DRIVEN** | Freshness changes only when relevant authored world events occur, not merely because time passes or an unrelated mission completes. |

### 2.1. Deception effects

Both layers are required:

- **Narrative:** reports may misattribute operations, conceal motives, create suspicion, or present a false account of faction/rival activity.
- **Gameplay:** reports may mislead optional investigation, consume research resources, produce an incorrect assessment, or cause an optional lead/reward opportunity to be missed.
- Fake content must be authored and deterministic. Do not generate arbitrary false claims at runtime.
- The player must receive an appropriate reliability/risk warning before purchase, but the exact hidden false claim must not be revealed by the warning.
- False intelligence must never make a required objective, primary contract, or extraction impossible.

### 2.2. Deep research outcomes

Research must support both outcomes below when the evidence warrants them:

- **Incomplete/partial result:** omission, missing evidence, low coverage, or insufficient independent sources leaves part of the assessment unresolved.
- **Misleading result:** fabricated or misattributed claims can lead to a wrong conclusion. The result must be authored/deterministic, visibly qualified by confidence/provenance, and revisable when new evidence is obtained.

A conflicted or insufficient project is not automatically a permanent failure. The player should be able to gather more evidence and re-evaluate where the authored project permits it.

### 2.3. Event-only Exposure

- Exposure is a risk/trigger input, not a direct faction score.
- Crossing an authored exposure condition may enqueue/emit a specific Counter-Intelligence event.
- Event consequences are bounded and authored (for example: warning, temporary source unavailability, suspicious offer, or a new decoy report).
- No direct Reputation, cash, XP, or faction-standing mutation is authorized by this decision.
- Reactions must use the existing event/state architecture after it is inspected; do not create a parallel generic event framework.

### 2.4. Active rival involvement

- The five existing HT-011 rivals are the initial rival roster.
- They may gather intelligence, contest leads, publish decoys, claim eligible optional opportunities, or withdraw, but only through bounded deterministic simulation.
- Rival actions execute at explicit game transition points and in a stable order.
- Rival activity may affect optional intelligence opportunities only. It must not claim required objectives, block a primary contract, prevent extraction, or directly alter base rewards/Detection/standing.
- Do not implement autonomous agents, live multiplayer, network traffic, or an independent full economy for every rival.

### 2.5. Mixed purchase policy

Each report declares one policy:

- `REPEATABLE`: may be purchased more than once if otherwise available.
- `ONE_TIME`: can be purchased once; subsequent purchase attempts are rejected.

Repeatable purchases must not create unbounded duplicate copies of the same owned report. The implementation must distinguish transaction history from report ownership/delivery.

### 2.6. Event-driven freshness

- Each report declares which event types can invalidate or age its claims.
- Only relevant events affect that report's freshness.
- Unrelated faction changes, unrelated mission completions, or wall-clock time must not reduce freshness.
- Freshness derivation must be deterministic and testable from the existing world/progression evidence.
- Do not add a global world-revision counter unless source inspection proves it is needed and the owner approves that expansion.

## 3. Current behavior confirmed during design

The current code has a small Contact model with Information Broker and Fixer. The Broker unlocks at Reputation 1; the existing clue offer is a fixed $50 purchase associated with a mission. It is gated by current mission requirements and faction access and reveals password/decryption clues without revealing the actual answers. Fixer unlocks at Reputation 3 and provides the existing Detection service and Ghost Signal offer.

Relevant current ownership observed on `main`:

- `src/domain/contacts.zig`: Contact identities, Reputation unlock thresholds, $50 Broker clue price, Fixer service pricing.
- `src/application/game.zig`: command orchestration and current Contact offer validation/transactions.
- `src/application/shop.zig`: equipment/economy purchase behavior; do not assume it is the correct owner for intelligence-market transactions.
- `src/presentation/terminal.zig`: reusable terminal presentation.
- `src/domain/rival.zig`, `src/domain/rival_simulation.zig`, `src/catalog/rival_data.zig`: five authored rivals and deterministic optional-objective contest behavior.
- `src/persistence/save.zig`: positional Save V3 writer and V2/V1/legacy readers.
- `tests/contacts_test.zig`, `tests/terminal_test.zig`, `tests/rival_test.zig`, and `tests/test_all.zig`: existing regression/test integration points.

This is a planning-time snapshot, not a substitute for a fresh source audit immediately before implementation.

## 4. Scope and content

### 4.1. Report categories

The initial market supports five typed categories:

1. `TOPOLOGY`: fictional network layout, routes, nodes, and structural hints.
2. `SECURITY`: defensive posture, security-system summaries, and possible weaknesses.
3. `FACTION`: authored faction dossiers, relationships, motives, and activity.
4. `RIVAL`: sightings, activity traces, contest status, and rival methods.
5. `HIDDEN_OBJECTIVE`: leads that help the player discover optional objectives without directly revealing the objective's answer or bypassing its trigger.

### 4.2. Initial source concepts

The design proposes four source channels. Their final identities, unlocks, and catalog ownership must be checked against current Contacts/Lore before implementation:

- **Broker:** general-purpose commercial intelligence and established mission clues.
- **Ghost Channels:** restricted or sensitive intelligence.
- **Dead Drops:** anonymous, provenance-risky reports and unique leads.
- **Rival Intelligence:** reports/traces connected to rival activity.

These are source/catalog concepts, not approval to add four new Contact characters. Preserve the existing Broker and Fixer identities; additional Contact characters require separate approval.

### 4.3. Report model

Each authored report should have, at minimum:

- stable unique ID and player-facing title/summary;
- source ID and origin-group ID;
- typed category and tags;
- base price and declared purchase policy;
- exposure/risk classification;
- qualitative reliability label;
- numeric design dimensions for reliability, completeness, freshness, and source credibility where useful;
- one or more typed claims;
- unlock and expiry/supersession conditions;
- event types that affect freshness;
- delivery surface and secrecy constraints.

A report is a container of claims, not a single unstructured paragraph.

### 4.4. Claim model and truth separation

Each claim should have a stable ID and typed subject/predicate/object or an equivalently explicit structured representation. It must also distinguish:

- authored world truth/reference (internal only);
- what the report asserts;
- provenance/source and origin group;
- temporal/event validity;
- deception kind, if any (internal only).

World truth must never be inferred from the player's report collection. Player evidence and research conclusions are separate data. Hidden truth/deception metadata must not leak through terminal output, inspect commands, error messages, or debug-like player-facing reports.

### 4.5. Deception kinds

The design baseline includes:

- `OMISSION`: relevant facts are withheld;
- `FABRICATION`: a false claim is inserted;
- `MISATTRIBUTION`: a real or false claim is attached to the wrong source/actor/subject.

All deception must be authored and deterministic. The player-facing report can signal uncertainty without exposing the exact hidden manipulation.

## 5. Information quality and analysis

### 5.1. Independent dimensions

The design uses four separate dimensions:

- **Reliability:** trustworthiness of the report's claims.
- **Completeness:** coverage of the topic.
- **Freshness:** validity relative to relevant world events.
- **Source credibility:** historical/structural trust in the source.

Do not collapse these into a single label in the domain model. A report may be complete but unreliable, or reliable but incomplete.

### 5.2. Trust score

A weighted Trust Score was suggested during design:

`Trust = 0.40 * Reliability + 0.20 * Completeness + 0.20 * Freshness + 0.20 * SourceCredibility`

**Important:** these weights and numeric thresholds are provisional balance parameters, not a separately approved immutable owner decision. Validate them against the game's economy/content scale and expose them as centralized constants/configuration. Tests must cover boundaries and rounding. Do not present the score as a statistically calibrated probability.

### 5.3. Qualitative reliability labels

Initial labels:

- `VERIFIED`
- `PARTIAL`
- `STALE`
- `UNRELIABLE`

The label and numeric dimensions are related but not interchangeable. The catalog author must define how a report's label is derived/displayed. Do not imply that an authored score is a real-world probability.

### 5.4. Cross-reference relations

The analysis engine should identify:

- `SUPPORTS`: one claim supports another;
- `CONTRADICTS`: claims cannot both hold for the same context/time;
- `EXTENDS`: one claim adds detail without contradiction;
- `UNRELATED`: no meaningful relation.

Comparison must use typed claim identity/semantics and temporal context, not fuzzy natural-language text matching.

### 5.5. Source independence

Reports with the same `origin_group_id` are not independent confirmations, even if sold by different channels. The analysis output should show report count and independent-origin count separately. Shared-origin reports must not inflate confidence as independent corroboration.

### 5.6. Freshness rules

Freshness is event-driven. Reports declare relevant event types. The system may derive freshness from the count/order of relevant events after the report's authored baseline, or another deterministic representation compatible with existing state. The precise representation must be chosen after auditing event/history availability.

Do not:
- age reports by real elapsed time;
- age every report on every mission completion;
- age reports on unrelated faction/rival events;
- introduce unbounded event history or save fields without a separate decision.

## 6. Dynamic Market

### 6.1. Stock composition

The market should derive its visible stock from three authored pools:

- **Base stock:** stable repeatable reports.
- **Conditional stock:** reports unlocked by Reputation, faction access, contract completion, rival state, or other explicit conditions.
- **Event stock:** reports made available by specific authored world events.

Superseded/expired/one-time-purchased reports are filtered according to their catalog policy.

### 6.2. Determinism

Dynamic does not mean uncontrolled randomness. Identical relevant game state and event history must produce identical market stock, report availability, and prices. Do not use wall-clock time, network data, or unseeded random selection. A seeded local generator is not required by this design; if proposed later, document its seed lifecycle and reproducibility before implementation.

Market derivation must be pure where practical and must not mutate world/player state.

### 6.3. Pricing

The proposed price model is:

`FinalPrice = BasePrice + ScarcityAdjustment + RiskPremium + SourcePremium`

The formula is a design proposal; exact coefficients, caps, and rounding are not owner-approved fixed balance values. Centralize them and test overflow/underflow and deterministic results.

The exact final price displayed during inspection must be the amount charged by the corresponding purchase. If relevant state changes between inspection and purchase, reject a stale quote or display the newly calculated price before confirmation; never silently charge a different amount.

### 6.4. Existing Broker compatibility

Preserve `deal intel-<mission-id>` and its current $50 clue behavior unless a deliberate command migration is separately approved. New market commands must not shadow or silently reinterpret the old offer. The old offer continues to reveal clues, never puzzle answers.

## 7. Deep Research

### 7.1. Research project model

A research project is authored data with:

- stable ID/title/category;
- prerequisites and unlock conditions;
- ordered stages;
- required evidence/claim references;
- minimum evidence/independence/quality conditions;
- cost and transaction policy;
- alternative research paths;
- authored result definitions and completion/revision rules.

Each stage declares its own input evidence, cost, allowed paths, and possible result states.

### 7.2. Lifecycle

The proposed lifecycle includes:

- `LOCKED`
- `AVAILABLE`
- `COLLECTING_EVIDENCE`
- `READY_TO_ANALYZE`
- `ANALYZING`
- `COMPLETED`
- `INSUFFICIENT_EVIDENCE`
- `CONFLICTED`

The last two are recoverable assessment states where the authored project permits more evidence or a new analysis. Avoid state transitions that trap the player permanently because of a single false report.

### 7.3. Alternative paths

A project may offer paths such as Security, Political/Faction, or Operational/Rival analysis. Paths must produce meaningfully different authored conclusions or unlocks. They must not simply be cosmetic labels. Scope the initial catalog to a small number of authored paths; do not create a generic narrative branching framework.

### 7.4. Fake evidence outcomes

- Omission or missing evidence can yield a partial/inconclusive result.
- Fabricated or misattributed evidence can yield a misleading result.
- The outcome must be deterministic from the authored evidence and selected path.
- The result must communicate uncertainty/provenance to the player.
- New evidence may permit a re-analysis when the project defines that behavior.
- Research must not invent facts that are absent from authored world truth/evidence.
- Research must not expose puzzle passwords, decryption keys, or direct puzzle answers.

### 7.5. Atomic research transactions

Validate prerequisites, evidence, costs, and result availability before committing. If output or validation fails, do not deduct money, consume a one-time input, mark the stage complete, or emit a duplicate event. Use the project's established stage-then-output-then-commit pattern where applicable.

## 8. Exposure and Counter-Intelligence

### 8.1. Exposure classification

Reports may declare a bounded exposure level (for example LOW/MEDIUM/HIGH). Exact thresholds and consequences remain authored balance data, not a global direct penalty.

### 8.2. Event-only consequences

Exposure may trigger an authored event such as:
- a warning that a source has noticed the purchase;
- a temporary source becoming unavailable;
- a suspicious/decoy report appearing;
- a bounded rival/faction intelligence reaction.

No direct Reputation/Standing mutation is part of HT-012. Any future request to alter those systems requires a separate owner decision.

### 8.3. Event integration

Use the existing game event/state transition architecture if one exists and is suitable. Audit it first. Do not add a parallel event bus/framework merely to satisfy this feature. Event triggering must be deterministic, idempotent where needed, and protected against repeated purchase/retry output failures.

## 9. Active Rival Intelligence

The initial active roster is the five HT-011 rivals:

- Ghost Operator — Ghost Protocol — job-03;
- Null Byte — Null Syndicate — job-04;
- Glasswire — Black Veil — job-02;
- Patchwork — Iron Meridian — job-01;
- Redshift — Helix Consortium — job-05.

Potential bounded actions:

- `GATHER_INTEL`
- `CONTEST_LEAD`
- `PUBLISH_DECOY`
- `CLAIM_OPPORTUNITY`
- `WITHDRAW`

These are design-level action categories, not a mandate to build a full autonomous agent system. The implementation must define explicit trigger points, stable action ordering, eligibility, and idempotency. Rival actions are fictional local simulation only.

Rivals may contest optional leads and optional objectives only. Required objectives, primary contract access, extraction, base rewards, Detection, and faction standing remain protected. Preserve HT-011 behavior and tests.

## 10. Persistence — DERIVED

No Save V3 layout changes are authorized.

Classify each data class explicitly:

| Data | Intended lifetime |
|---|---|
| Report/source/claim/research catalog | Static authored catalog |
| Market stock and price | Derived from current persisted progression plus provable event/history |
| Purchased report ownership | Derived only when existing persisted evidence proves the purchase; otherwise runtime-only |
| Transaction display/history | Runtime-only unless already provable from persisted state |
| Cross-reference result | Recomputed from available reports/claims |
| Research progress/result | Derived only when existing persisted progression/events prove it; otherwise runtime-only |
| Exposure and unpersisted Counter-Intel events | Runtime-only unless derivable from existing persisted evidence |
| Rival market actions | Derived from existing progression/rival state where provable; otherwise runtime-only |

Rules:
1. Do not add Save fields, change field order/version markers, or alter V3/V2/V1/legacy readers.
2. Balance decrease alone is not proof that a report was purchased.
3. Reputation, mission completion, or faction standing alone must not be treated as proof of a specific report/research transaction unless the authored progression explicitly establishes that relation.
4. Reconstruct only state that can be proven without ambiguity from existing persisted fields/events.
5. If proof is unavailable, do not pretend the player owns the report or completed the research after restart.
6. Load/reconstruction must not replay a charge, reward, or event.
7. Any future need for durable per-report/per-research history requires a separate owner-approved save migration decision.

## 11. Command and presentation direction

Candidate commands for evaluation against the current first-argument parser:

- `market`
- `market-sources`
- `market-inspect <id>`
- `deal info-<id>`
- `intel`
- `intel-view <id>`
- `intel-compare <id> <id>`
- `intel-analyze <topic>`
- `research`
- `research-view <id>`
- `research-start <id>`
- `research-status <id>`
- `research-analyze <id>`

These are candidate UX names, not accepted exact syntax. The current parser accepts a command and first argument token only; do not implement multi-token subcommands without deliberately updating parser behavior and its compatibility tests. Preserve existing Broker/Fixer commands.

Presentation requirements:
- Show report title, source, category, price, reliability label, completeness/freshness/exposure indicators, and a concise non-spoiling summary before purchase.
- Explain source/provenance and uncertainty without revealing hidden truth or exact deception.
- Clearly distinguish owned reports, repeatable purchase availability, one-time offers, expired/superseded offers, and locked offers.
- Show Research stage, required evidence, missing evidence, independent source count, contradictions, confidence, path, and result qualification.
- Never print protected puzzle answers or hidden-objective descriptions before their existing discovery conditions.

## 12. Architecture guidance

Likely responsibilities (confirm source and existing abstractions before creating modules):

- Domain: typed report/category/reliability/claim/source/research models and pure derivation rules.
- Catalog: authored sources, reports, claims, deception cases, event sensitivities, and research projects.
- Application: market query/purchase transactions, cross-reference analysis, research workflow, exposure/event coordination, rival information actions.
- Presentation: terminal rendering and command help.
- Persistence: no change for HT-012.

Potential file names discussed during design include `intel.zig`, `intel_source.zig`, `intel_claim.zig`, `research.zig`, `information_market.zig`, `cross_reference.zig`, `research_engine.zig`, and `counter_intelligence.zig`. These are not mandatory. Reuse current module ownership where possible; do not fragment the code into many tiny modules or create speculative frameworks.

## 13. Atomicity and failure behavior

All market and research state-changing operations must follow the project's transaction discipline:

1. Validate IDs, unlocks, source access, freshness/expiry, purchase policy, prerequisites, evidence, price, and available balance.
2. Prepare the resulting state and output without mutating caller-owned state.
3. Ensure required output/transition writes succeed.
4. Commit balance, ownership, one-time purchase state, research stage/result, and event markers together.
5. On any rejection or writer/allocator failure, leave all relevant state unchanged.

Use checked arithmetic for prices, costs, and totals. No wraparound. A failed operation must not partially charge, consume a one-time offer, publish an event twice, or mark research complete.

## 14. Acceptance criteria

### A. Data and secrecy
- [ ] Stable unique typed IDs for reports, claims, sources, projects, stages, and events.
- [ ] Five categories are supported: topology, security, faction, rival, hidden objective.
- [ ] World truth, player evidence, and research conclusions are distinct.
- [ ] Hidden deception/truth metadata never leaks to player-facing output.
- [ ] Report provenance and origin-group identity are explicit.
- [ ] Puzzle answers and undiscovered hidden-objective details remain protected.

### B. Market
- [ ] Broker, Ghost Channels, Dead Drops, and Rival Intelligence source concepts are represented without adding unapproved Contact characters.
- [ ] Base, conditional, and event-driven stock are supported.
- [ ] Identical relevant game state/history produces identical stock and prices.
- [ ] Market derivation does not mutate game state.
- [ ] Each report declares repeatable or one-time policy.
- [ ] Inspect displays the exact price and risk/reliability information before purchase.
- [ ] Purchase charges exactly the confirmed displayed price.
- [ ] Unaffordable, locked, expired, stale-quote, duplicate one-time, and invalid-ID purchases do not mutate state.
- [ ] Repeatable purchases do not create uncontrolled duplicate ownership records.
- [ ] Existing `deal intel-<mission-id>` behavior remains compatible and continues not to reveal answers.

### C. Quality, provenance, and freshness
- [ ] Reliability, completeness, freshness, and source credibility remain separate dimensions.
- [ ] Qualitative reliability labels are supported.
- [ ] Any Trust Score formula is centralized, bounded, deterministic, and documented as a design score rather than statistical probability.
- [ ] Cross-reference supports SUPPORTS, CONTRADICTS, EXTENDS, and UNRELATED.
- [ ] Reports from the same origin group do not count as independent corroboration.
- [ ] Freshness changes only on relevant authored events.
- [ ] Unrelated events and wall-clock time do not age reports.

### D. Deception and safety
- [ ] Omission, fabrication, and misattribution can be authored.
- [ ] Deception has both narrative and gameplay consequences.
- [ ] Player-facing warnings reveal risk without exposing the hidden false claim.
- [ ] Fake information can produce partial/incomplete Research.
- [ ] Fake information can produce misleading Research.
- [ ] Results remain deterministic and traceable to authored evidence.
- [ ] Required objectives, primary contracts, and extraction remain completable.
- [ ] Fake information cannot disclose puzzle answers.

### E. Deep Research
- [ ] Projects have prerequisites, stages, evidence requirements, costs, paths, and authored results.
- [ ] Multiple stages and meaningful alternative paths are supported.
- [ ] Different paths can produce different conclusions/unlocks.
- [ ] Insufficient and conflicted evidence are visible and recoverable where authored.
- [ ] Additional evidence can permit re-analysis where authored.
- [ ] Research cannot invent facts or answer mission puzzles.
- [ ] Research transactions are atomic and duplicate execution is controlled.

### F. Exposure and Counter-Intelligence
- [ ] Exposure is event-driven and bounded.
- [ ] Event reactions are authored and deterministic.
- [ ] No direct Reputation or faction Standing mutation occurs.
- [ ] Existing event architecture is reused where suitable.
- [ ] Repeated commands/retries cannot duplicate an event or partially apply its effect.

### G. Rival participation
- [ ] All five HT-011 rivals can participate in bounded information actions.
- [ ] Rival action trigger points and ordering are deterministic.
- [ ] Gather/contest/decoy/claim/withdraw behaviors are testable.
- [ ] Rival effects are limited to eligible optional intelligence opportunities.
- [ ] Required objectives, primary contract completion, extraction, Detection, base rewards, and faction standing remain unaffected.
- [ ] Existing HT-011 behavior remains regression-tested.

### H. Persistence and compatibility
- [ ] Save V3 writer is byte/layout compatible and unchanged.
- [ ] V2, V1, and legacy readers remain unchanged.
- [ ] Derived reconstruction uses only provable existing persisted evidence.
- [ ] Balance/XP/Reputation alone are not treated as proof of report ownership.
- [ ] Unprovable state remains runtime-only and is not falsely restored.
- [ ] Load never repeats a purchase charge, reward, or event.

### I. Integration and quality
- [ ] Existing Broker and Fixer unlocks/prices/behaviors remain compatible unless separately approved.
- [ ] Commands fit the current parser or parser changes are explicitly designed and regression-tested.
- [ ] Unit and integration tests cover success, rejection, boundaries, determinism, atomicity, secrecy, and recovery.
- [ ] New tests live under `tests/` and are registered in `tests/test_all.zig`.
- [ ] Relevant architecture, gameplay, command, save, task, ADR, and agent docs are updated.
- [ ] Full Zig 0.13.0 format/build/test checks and agent-doc check pass in CI Debug, ReleaseSafe, and ReleaseFast.
- [ ] Full code review follows every item in `.agent/review-checklist.md`; review is read-only and gaps are explicit.

## 15. Proposed implementation milestones

Do not run these milestones until the owner explicitly authorizes implementation.

1. **Source/architecture audit:** inspect current Contacts, game dispatch, terminal, rival simulation, event/state model, persistence, tests, and CI. Resolve module ownership and derived-state proof limits.
2. **Core typed catalog:** report/source/claim/research types, authored catalog validation, secrecy boundaries.
3. **Market read path:** dynamic deterministic stock, inspect, pricing, availability, expiry.
4. **Atomic purchase path:** repeatable/one-time policy, balance, ownership/delivery, old Broker regression.
5. **Quality/provenance:** reliability dimensions, source independence, event-driven freshness, cross-reference.
6. **Deception and Exposure:** authored false claims, narrative/gameplay effects, event-only counter-intelligence.
7. **Deep Research:** stages, evidence, alternative paths, partial/misleading outcomes, atomic execution.
8. **Rival integration:** bounded active rival intelligence actions with HT-011 regression coverage.
9. **Terminal integration and docs:** command/help/output, gameplay/architecture docs, smoke tests.
10. **Final QA/review:** full tests, CI, full review, acceptance matrix, limitations.

The owner may change milestone granularity after the source audit, but scope expansion requires explicit approval.

## 16. Required agent handoff

### Architecture Agent
- Read all mandatory project docs and this brief/ADR.
- Audit actual current source and report current ownership, call graph, event capabilities, parser constraints, save proof limits, and tests.
- Recommend the smallest coherent module/API plan.
- Do not implement before a separate authorization.

### Market Agent
- Own report catalog/stock/pricing/inspection/purchase only after architecture contracts are approved.
- Preserve legacy Broker behavior.
- Provide deterministic and atomic tests.

### Intelligence Agent
- Own claim/provenance/quality/freshness/cross-reference/deception rules.
- Prove same-origin independence and no hidden-truth leakage.
- Test all relation and deception boundaries.

### Research Agent
- Own staged research, evidence validation, alternative paths, and partial/misleading results.
- Test insufficient evidence, contradictory evidence, re-analysis, costs, idempotency, and atomicity.

### Counter-Intelligence/Rival Agent
- Integrate event-only Exposure and active HT-011 rivals.
- Reuse current rival/event contracts; no parallel event bus or full autonomous simulation.
- Preserve required-objective and primary-contract safety.

### Integration/QA Agent
- Integrate commands and terminal rendering without breaking the first-argument parser contract.
- Add focused tests to `tests/` and `tests/test_all.zig`.
- Update user/developer documentation and manual smoke checklist.

### Review Agent
- Read the complete `.agent/review-checklist.md`.
- Perform a read-only full review of the changed code and relevant invariants.
- Record file/line evidence, verification gaps, and whether review was independent or self-review.
- Never fix findings without separate authorization.

## 17. Non-goals and hard constraints

- No online marketplace, live data feeds, player-to-player trading, or real-world intelligence.
- No real networking, host connections, shell execution, credential collection, external processes, or external actors.
- No new Contact characters without separate approval.
- No puzzle-answer sales or direct puzzle solving.
- No required-objective denial, mission soft-lock, or extraction denial.
- No direct Reputation/Standing changes from Exposure or rival actions.
- No Save V3 schema change or new persistent state without a separate migration decision.
- No uncontrolled random stock/deception/rival behavior.
- No story dialogue tree or generic branching narrative framework.
- No implementation until the owner separately authorizes it.

## 18. Open implementation questions (not owner-decision reversals)

The following are technical details to resolve during the authorized source audit, not permission to alter the accepted design:

- Which existing event/history records can prove report ownership or research completion after restart?
- Does the current event model support typed, idempotent events, or should a minimal feature-local transition contract be used?
- What exact parser-compatible command forms best fit existing command dispatch?
- What numeric Trust Score weights, price adjustments, exposure thresholds, and category stock sizes balance the current economy?
- Which existing rival state transitions can be reused without changing HT-011 semantics?
- Which freshness event identifiers already exist and which new authored identifiers are necessary?
- What is the smallest useful first catalog of reports and research projects?

If evidence is insufficient, mark the item unresolved rather than guessing. Any change to an owner-approved decision requires renewed owner approval.
