# Known Constraints and Open Questions

This file separates verified constraints from items that need investigation.

## Verified constraints
- Zig 0.13.0 is the target; other versions are not guaranteed.
- The command parser accepts a command and at most one argument; later tokens are ignored.
- Mission-session state and objective completion are not persisted.
- Save data is positional and has no checksum or explicit corruption recovery. Writes are staged through a temporary file and renamed after a successful write.
- The objective completion mask is eight bits; a ninth kind requires redesign.
- Mission difficulty is descriptive metadata, not a gameplay modifier.
- There is no real networking layer; all hacking/host behavior is fictional and simulated.
- The owner cannot reliably build locally at present; report CI separately from manual playtesting.

## Open questions, not confirmed bugs
- Should mission-session progress survive restart, and what migration would that require?
- Should command parsing evolve beyond one argument?
- Should future mission branches affect payout, reputation, unlocks, or narrative only?
- What representation best fits objective counts beyond the current bitset capacity?

Do not present an open question as a defect or resolve it during unrelated work.
