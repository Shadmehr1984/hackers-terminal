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
.agent/tasks/HT-005-reputation-contacts.md
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

echo "Agent documentation structure check passed."
