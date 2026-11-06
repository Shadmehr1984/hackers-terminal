# ADR 0013 — Corporate Ghost as the fifth contract

- **Status:** Accepted; implemented on `main`
- **Date:** 2026-11-06
- **Feature:** HT-010.1 — Corporate Ghost
- **Decision owner:** Project owner

## Context

HT-010 derives faction standing from global Reputation and completed contract affiliations. After job-01 and job-02, a player with Reputation 2 has Nexus Dynamics standing -2 (Hostile), so a Nexus-commissioned contract is faction-locked. Quiet Exit is available at level 3 and can raise Reputation without changing the Nexus-owned completion flags, creating the recovery path for the fifth contract.

## Decisions

1. Add `job-05`, Corporate Ghost, as a standard contract (not a Contact-exclusive offer).
2. Nexus Dynamics is the client faction; Null Syndicate owns the target.
3. Target `relay-05.local`; Hard / Infiltration; required level 2 and Reputation 2; reward $1,200 and 275 XP.
4. Add a seven-node graph with a hidden Traffic Mirror branch that rejoins at the Encrypted Data Vault.
5. Required objectives are scan, authenticate, decrypt, extract, and metadata verification. The visible optional metadata objective pays $200; the hidden mirror-fragment objective is worth $0 and is discovered by entering `mirror-node`.
6. Password `vaultkeeper`, encrypted file `access-ledger.enc`, and decryption key `auditlog`; existing modifier allowlist remains unchanged.
7. Append at catalog index 4. Preserve indices 0–3 and the Save V3 writer/legacy readers exactly; old saves with three or four flags leave job-05 incomplete.
8. No new commands, Contact offer, persistence fields, faction mechanics, branching narrative, or real-world network interaction.

## Consequences

- With job-01/job-02 complete and Reputation 2, job-05 is faction-locked. Completing job-03 without optional-objective Reputation bonus raises standing to Wary and opens access.
- The existing derived standing algorithm and save format remain unchanged.
- Broker intelligence UI must not advertise a contract whose client faction is Hostile; the existing transaction path already rejects such purchases.
- Future missions continue to append after the current catalog and must include tests for faction access and old-save defaults.
