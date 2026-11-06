#!/usr/bin/env sh
set -eu

required_files="
AGENTS.md
.agent/README.md
.agent/workflow.md
.agent/conventions.md
.agent/roadmap.md
.agent/known-issues.md
.agent/review-checklist.md
.agent/tasks/TEMPLATE.md
.agent/decisions/0001-zig-toolchain.md
.agent/decisions/0002-modular-boundaries.md
.agent/decisions/0003-transient-mission-session.md
.agent/decisions/0004-save-compatibility.md
.agent/decisions/0005-equipment-and-save-v3.md
.agent/decisions/0006-mission-preparation.md
.agent/decisions/0007-reputation-contacts.md
.agent/decisions/0012-factions.md
.agent/tasks/HT-005-reputation-contacts.md
.agent/tasks/HT-010-factions.md
docs/gameplay.md
docs/commands.md
docs/save-format.md
docs/architecture.md
docs/development.md
"

for file in $required_files; do
    if [ ! -s "$file" ]; then
        echo "Required agent/project documentation is missing or empty: $file" >&2
        exit 1
    fi
done

grep -q 'Read it before planning or changing code' AGENTS.md
grep -q 'Explore' .agent/workflow.md
grep -q 'review-checklist.md' .agent/README.md
grep -q 'V2' .agent/decisions/0004-save-compatibility.md
grep -q 'ADR 0007' .agent/decisions/0007-reputation-contacts.md
grep -q 'Acceptance criteria' .agent/tasks/HT-005-reputation-contacts.md
grep -q 'seven fictional factions' .agent/tasks/HT-010-factions.md
grep -q 'derived standing' .agent/decisions/0012-factions.md

# Guard the mandatory code-review standard against accidental truncation.
grep -q '## 3. Correctness — 40%' .agent/review-checklist.md
grep -q '## 4. Security — 20% — OWASP Top 10:2025' .agent/review-checklist.md
grep -q '## 5. Architecture and Design — 30%' .agent/review-checklist.md
grep -q '## 6. Performance — 10%' .agent/review-checklist.md
grep -q '### 7.2 ALWAYS FLAG' .agent/review-checklist.md
grep -q 'root_source_file' .agent/review-checklist.md
grep -q 'getOrPut' .agent/review-checklist.md
grep -q 'std.heap.DebugAllocator' .agent/review-checklist.md
grep -q 'OWASP Top 10:2025' .agent/review-checklist.md
grep -q 'Mandatory final report format' .agent/review-checklist.md
grep -q 'For a full review' .agent/README.md
grep -q 'Maintainability/Observability' .agent/workflow.md

echo "Agent documentation structure check passed."
