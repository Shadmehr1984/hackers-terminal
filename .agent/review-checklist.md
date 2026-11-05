# Independent Change Review Checklist

Ideally, a second reviewer inspects the diff independently rather than relying only on the implementer's summary.

## Correctness
- [ ] Does the change meet acceptance criteria?
- [ ] Are existing commands, progression, and state invariants preserved?
- [ ] Are invalid inputs and failure paths handled?
- [ ] Are success, rejection, and important edge cases tested?

## Architecture
- [ ] Does each module retain a coherent responsibility?
- [ ] Are dependencies one-way, with no circular imports?
- [ ] Is the implementation appropriately simple?
- [ ] Are transient and persistent state boundaries respected?

## Compatibility and safety
- [ ] Are V2, V1, and legacy saves preserved or deliberately migrated?
- [ ] Are save path, field order, and defaults unchanged unless intended?
- [ ] Does hacking remain fictional, offline, and self-contained?
- [ ] Is there no shell execution, real network action, or credential collection?

## Delivery
- [ ] Zig 0.13.0 format/build/test pass, or unrun checks are identified.
- [ ] README and relevant docs are accurate.
- [ ] AGENTS.md reflects lasting rules and decisions.
- [ ] Roadmap, known issues, and ADRs are updated only when justified.
- [ ] Diff is focused; commit and CI result are verified and reported.
