# ADR 0015 — Information Market and Information Warfare

- **Status:** Accepted design; implementation not authorized
- **Date:** 2026-11-06
- **Feature:** HT-012 — Information Market
- **Decision owner:** Project owner
- **Task brief:** [HT-012 Information Market](../tasks/HT-012-information-market.md)

## Context

The current game has an Information Broker that sells a fixed-price ($50) mission clue offer, plus a Fixer with existing Detection and exclusive-contract services. The game also has five deterministic rivals, seven fictional factions, hidden optional objectives, a local economy, and a positional Save V3 format with V2/V1/legacy readers.

The owner requested a deeper Information Market: a dynamic intelligence economy, authored false information, deep research, evidence comparison, active rival participation, and counter-intelligence consequences. The design must preserve the terminal-first fictional/offline game, avoid puzzle-answer disclosure, preserve primary mission solvability, and avoid unapproved save migration.

## Accepted owner decisions

1. **Fake intelligence: BOTH.** False or manipulated reports must have both narrative consequences and gameplay consequences.
2. **Research depth: DEEP.** Research is multi-stage and evidence-driven, with meaningful alternative paths/results rather than a single report-merging command.
3. **Market: DYNAMIC.** Market stock/offers respond to relevant progression, faction/rival state, and authored world events. Dynamic behavior remains deterministic and locally reproducible.
4. **Persistence: DERIVED (option C).** Reconstruct market ownership/research state only when existing persisted progression/history proves it. Do not change Save V3 or add fields. If a fact cannot be proven, it remains runtime-only and must not be fabricated on load.
5. **Fake intelligence in Research: BOTH.** Depending on authored deception/evidence, research can produce incomplete results or misleading results.
6. **Exposure: EVENT.** Exposure triggers bounded authored Counter-Intelligence events only; it does not directly modify Reputation or faction Standing.
7. **Rival involvement: ACTIVE.** The five HT-011 rivals participate through bounded deterministic simulated information actions.
8. **Purchase limits: MIXED.** Each report is explicitly repeatable or one-time; base reports may be repeatable while unique/special reports may be one-time.
9. **Freshness: EVENT-DRIVEN.** Only relevant authored world events change report freshness. Wall-clock time and unrelated progression do not age reports.

## Detailed consequences

### Market and information model

- Support five report categories: TOPOLOGY, SECURITY, FACTION, RIVAL, and HIDDEN_OBJECTIVE.
- Model reports as containers of typed claims with explicit source and provenance.
- Keep authored world truth, player-visible evidence, and derived research conclusions separate.
- Model source identity and origin groups; reports from the same origin group do not count as independent corroboration.
- Support qualitative labels VERIFIED, PARTIAL, STALE, and UNRELIABLE, with separate dimensions for reliability, completeness, freshness, and source credibility.
- Dynamic stock derives from base, conditional, and event-driven catalog pools.
- Identical relevant game state/event history must yield identical stock and price.
- Each report declares REPEATABLE or ONE_TIME purchase policy.
- Inspect must disclose price and uncertainty/risk before purchase; successful purchase charges exactly the confirmed displayed price.
- Preserve the existing `deal intel-<mission-id>` $50 clue offer and its no-answer-leak behavior unless a separate command migration is approved.

### Deception and Research

- Support authored deception kinds: OMISSION, FABRICATION, and MISATTRIBUTION.
- Deception affects both narrative interpretation and gameplay outcomes, but may only affect bounded optional information opportunities.
- Deep Research contains prerequisites, multiple stages, evidence requirements, alternative paths, costs, and authored conclusions.
- False/missing evidence may yield PARTIAL/INCONCLUSIVE results.
- Fabricated/misattributed evidence may yield MISLEADING results.
- Results are deterministic, qualified by confidence/provenance, and revisable when more evidence is allowed.
- Research must not invent facts or disclose passwords, decryption keys, or puzzle answers.

### Cross-reference and freshness

- Cross-reference relations: SUPPORTS, CONTRADICTS, EXTENDS, UNRELATED.
- Comparison uses typed claim/context semantics, not fuzzy prose matching.
- Shared origin groups do not count as independent sources.
- Freshness responds only to report-specific relevant event types.
- No wall-clock aging, blanket mission-completion aging, or unnecessary global revision counter.

### Exposure and rivals

- Exposure consequences are authored events, such as warnings, bounded source unavailability, decoy offers, or rival/faction intelligence reactions.
- No direct Reputation, cash, XP, or faction Standing mutation is part of the Exposure decision.
- The five existing HT-011 rivals participate in bounded deterministic actions such as gathering intel, contesting leads, publishing decoys, claiming optional opportunities, or withdrawing.
- Rival actions run at explicit game transition points in stable order.
- Rivals may affect optional intelligence opportunities only; required objectives, primary contract access/completion, extraction, Detection, and base reward formulas remain protected.
- No live multiplayer, network activity, autonomous external agents, or full per-rival economy.

### Persistence and compatibility

- Save V3 writer and V2/V1/legacy readers remain unchanged.
- Market stock/prices and other state are derived from existing persisted evidence where possible.
- Balance loss alone is not proof of a specific purchase.
- Reputation, mission completion, or faction standing alone must not be treated as proof of a report/research transaction unless the authored progression establishes that relation.
- Unprovable report ownership, research progress, exposure, or event state remains runtime-only.
- Loading must not replay charges, rewards, or events.
- Any future durable per-report/per-research history requires a separate owner-approved migration.

## Design parameters that are not fixed owner decisions

The following were discussed as implementation proposals, not accepted immutable values:

- Trust Score weights (a suggested starting point was 40% reliability, 20% completeness, 20% freshness, 20% source credibility).
- Exact price formula coefficients, caps, and numeric price bands.
- Exposure thresholds and per-event consequences.
- Exact stock sizes, report catalog size, and research project count.
- Exact command spellings beyond preserving the existing Broker command.
- Exact module/file names and whether each suggested responsibility needs a new file.

These values must be centralized, tested, and balanced after a fresh source/economy audit. Do not silently treat example numbers as owner-approved final balance.

## Hard constraints

- Entirely fictional, local, deterministic, and offline.
- No real network scanning/connection, shell execution, credential collection, external data feeds, external actors, or online marketplace.
- No puzzle-answer sales or direct answer disclosure.
- No fake intelligence or rival action may make required objectives, primary contracts, or extraction impossible.
- Preserve existing Broker/Fixer behavior unless a separate change is approved.
- No Save V3 schema change.
- Implementation requires separate explicit owner authorization.

## Validation expectations

The task brief defines the complete acceptance criteria and handoff. At minimum, tests must cover deterministic market derivation, exact-price atomic purchases, one-time/repeatable policies, provenance independence, all cross-reference relations, event-driven freshness, both fake-Research outcomes, Exposure event idempotency, active rival actions, mission safety, Save V3 compatibility, and existing Broker/Fixer regression behavior.
