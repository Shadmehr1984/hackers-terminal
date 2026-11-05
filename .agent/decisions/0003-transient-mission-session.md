# ADR 0003: Keep Mission Session Progress Runtime-Only

- Status: Accepted
- Date: 2026-11-05

## Context
Mission progress, connection state, authentication/decryption stages, and objective completion are represented by the active mission session. The save format stores the active mission index and completed-mission flags, not in-session stages.

## Decision
Keep session progress transient. Restoring an active mission restarts its session at the accepted stage. Do not serialize objective completion as part of unrelated changes.

## Consequences
- The player repeats session actions after restart.
- Save compatibility remains simpler.
- Persisting session state later requires a separately designed and documented save migration.
