# Phase 3 — Security Profiles, Countermeasures, and Simulated Agents

**Parent program:** [EXPANSION-001](GAMEPLAY-EXPANSION-OVERVIEW.md)  
**Status:** Planned; implementation not authorized  
**Goal:** Give fictional targets distinct security identities and make the active mission respond to the player's decisions.

## Shared baseline and constraints

Current risk is a runtime Detection meter from 0 to 100 with fixed action costs and a failure penalty. Current topologies are authored static graphs. The active mission's Detection and progress live in `MissionSession`. Re-audit `src/domain/mission.zig`, `src/domain/topology.zig`, `src/domain/mission_state.zig`, `src/application/detection.zig`, `src/application/game.zig`, `src/catalog/mission_data.zig`, and tests.

These systems are game mechanics only. Do not implement actual intrusion detection, real packet inspection, network connections, host scanning, external AI services, or shell execution.

## HT-016 — Security Profiles

### Goal
Give each fictional target a distinct authored security profile so the same player strategy does not work equally well everywhere.

### Design direction
Potential profiles include corporate monitoring, research-lab encryption, underground irregular security, government lockdown, and financial multi-layer protection. Treat these as game archetypes, not real-world security guidance.
- Profiles should define explicit, small, testable parameters and descriptive terminal intel.
- Keep mission difficulty descriptive unless a specific approved rule links it to profile behavior.
- Profile data should be static and separate from runtime security state.

### Likely scope
Security profile domain types/catalog, mission metadata, preparation intel, terminal display, tests/docs.

### Acceptance criteria
- [ ] Every profile has a distinct player-visible description and explicit mechanical parameters.
- [ ] A mission references a valid profile; missing/invalid references are detected by tests or catalog validation.
- [ ] Preparation reveals only the intended profile intel, not puzzle answers.
- [ ] Profile parameters are deterministic and do not mutate global Detection constants.
- [ ] Existing mission behavior is unchanged when no profile is assigned.

### Dependencies
HT-006 Contract Board; HT-007 Modifier snapshot design; existing Detection and mission catalog.

### Out of scope
Real-world security product emulation, real vulnerability data, live telemetry.

## HT-017 — Security Countermeasures

### Goal
Add a small set of tactical, readable security responses that change available routes or action risk during an operation.

### Design direction
Potential countermeasures include temporary node lockdown, route isolation, false signals, simulated trace injection, and system recovery.
- Each countermeasure needs a trigger, effect, duration/expiry, player notification, and reset rule.
- Prefer explicit state transitions over hidden random effects.
- Define whether countermeasures are attached to a security profile, modifier, or a specific authored mission event.
- Ensure invalid commands/rejected prerequisites do not accidentally trigger countermeasures.

### Likely scope
Security runtime state, topology availability checks, Detection integration, application transitions, terminal map/status output, tests/docs.

### Acceptance criteria
- [ ] Each countermeasure has an explicit trigger and bounded effect.
- [ ] Player receives clear feedback when a route/action becomes unavailable or risky.
- [ ] Countermeasure activation/expiry is deterministic and covered at boundaries.
- [ ] A countermeasure cannot create an unrecoverable mission unless that challenge is explicitly authored and communicated.
- [ ] Failure/retry resets the correct temporary state.
- [ ] Existing topology adjacency and operation-node constraints remain valid.

### Dependencies
HT-016 Security Profiles; HT-002 existing topology; HT-001 Detection.

### Out of scope
Real firewall rules, real packet filtering, host isolation, external system access.

## HT-023 — Security Agent Behaviors

### Goal
Represent security agents as distinct fictional roles that respond to mission events, rather than treating all security as a single Detection number.

### Design direction
Potential roles: Watcher (observes activity), Tracer (tracks simulated route), Guardian (protects selected nodes), Hunter (reacts to high exposure and constrains escape).
- Define a small state machine per role with explicit inputs, outputs, and turn/event timing.
- Keep agents deterministic initially; any randomness must be injected and seeded.
- Agent output should affect only game state (Detection, node availability, intel, or event messages).
- Avoid generic behavior frameworks until multiple real agents demonstrate a shared contract.

### Likely scope
Agent domain types/state, authored agent catalog, mission/profile association, application event hooks, terminal feedback, focused tests/docs.

### Acceptance criteria
- [ ] Each agent role has a distinct, documented, testable state machine.
- [ ] Triggering game events and agent responses are deterministic.
- [ ] Agent actions cannot bypass mission progression or mutate unrelated player state.
- [ ] Multiple agents can coexist without order-dependent or duplicate effects.
- [ ] Agent state resets on mission retry according to documented rules.
- [ ] No external AI, network, or process execution is introduced.

### Dependencies
HT-016 Security Profiles and HT-017 Countermeasures.

### Out of scope
LLM-controlled agents, real security monitoring, multiplayer opponents.

## HT-024 — Security Agent Memory

### Goal
Let simulated security agents remember relevant player behavior during an operation and adapt within bounded, understandable rules.

### Design direction
- Define exactly which events may be remembered (e.g. repeated use of one route, repeated failed authentication, repeated interaction with one node).
- Define memory capacity, decay/expiry, what the agent can infer, and how adaptation is communicated to the player.
- Memory should initially be scoped to one MissionSession and reset on retry/restart.
- Cross-session memory would be persistent player/world state and requires a separate migration and owner approval.
- Do not make the game secretly learn arbitrary play patterns.

### Likely scope
Agent memory value types and bounded storage, event hooks, agent behavior integration, mission state reset, terminal feedback, tests/docs.

### Acceptance criteria
- [ ] Only an explicit allowlist of game events enters agent memory.
- [ ] Memory capacity and expiry/decay are bounded and tested.
- [ ] Adaptation follows deterministic rules and gives fair player-visible feedback.
- [ ] Memory does not change completed objective/progression facts or duplicate rewards.
- [ ] Retry/restart reset behavior is explicit; no memory persists across sessions by accident.
- [ ] No user data, host data, or external process information is collected.

### Dependencies
HT-023 Security Agent Behaviors.

### Out of scope
Persistent profiling of the real player, telemetry, LLM memory, external services.

## Phase exit criteria

- [ ] Profiles, countermeasures, behaviors, and memory are separate responsibilities with one-way dependencies.
- [ ] Every security effect is deterministic, bounded, observable, and reversible/resettable where required.
- [ ] No real network or security tooling is added.
- [ ] Failure, retry, and save/restart semantics are covered by tests.
