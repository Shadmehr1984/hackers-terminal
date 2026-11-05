# QUALITY-001 — Code Review Remediation

**Status:** In Progress  
**Priority:** High  
**Approved:** 2026-11-05

## Goal
Address the verified findings from the project-wide code review without changing game balance, mission content, or the V3 save schema.

## Scope
- Repair malformed Markdown line breaks and stale command walkthroughs so documentation reflects the prepare → accept flow.
- Use one preparation-aware command dispatcher in production and tests; remove the legacy path that implicitly accepted contracts without persistent preparation state.
- Make save writes resilient to partial write failures by staging the unchanged V3 payload in a temporary file and renaming only after successful completion.
- Separate Detection/compromise handling and XP/reward progression from the command coordinator.
- Remove temporary formatter artifacts and update module contracts, architecture, README, and development guidance.

## Acceptance criteria
- [x] Documentation line breaks and command examples match runtime behavior.
- [x] Production and tests use one explicit preparation-aware command dispatcher.
- [x] Direct accept without preparation is rejected and covered by a test.
- [x] Save V3 payload and V1/V2/legacy migration behavior remain unchanged.
- [x] Save writes stage to a temporary file before replacing the previous save.
- [x] Detection and progression responsibilities have focused modules.
- [x] Progression threshold tests are registered in the aggregate suite.
- [ ] Zig 0.13.0 formatter, build, full test suite, and agent-doc check pass in CI.
- [ ] Final self-review and temporary workflow cleanup completed.

## Verification notes
- Initial CI identified formatter changes required in src/game.zig and src/progression.zig.
- No local build or manual gameplay test was performed.
