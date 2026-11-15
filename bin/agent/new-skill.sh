#!/usr/bin/env bash
# bin/agent/new-skill.sh - scaffold a skill so "add a skill" costs one command.
#
#   bin/agent/new-skill.sh <name> "<one line: what it does AND when to use it>"
#
# The frontmatter is the form eyg_packages/overlay/skills.eyg parses (a `---`
# block of `key: value` lines) and the form Pi reads. `verified:` is set to today
# because the scaffold is written from what is true right now; bump it only after
# re-running the skill's commands.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

name="${1:-}"
description="${2:-}"

if [ -z "$name" ] || [ -z "$description" ]; then
  echo "usage: bin/agent/new-skill.sh <name> \"<description>\"" >&2
  exit 2
fi

if ! printf '%s' "$name" | grep -qE '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "error: name must be lowercase letters, digits and single hyphens" >&2
  exit 1
fi

dir=".agents/skills/$name"
if [ -e "$dir/SKILL.md" ]; then
  echo "error: $dir/SKILL.md already exists" >&2
  exit 1
fi

mkdir -p "$dir"
today=$(date +%Y-%m-%d)

cat > "$dir/SKILL.md" <<EOF
---
name: $name
description: $description
verified: $today
---

# $name

## When to use
- 

## Read first
- docs/world/00-map.md - the tier-0 index of this repository
- 

## Procedure
1. 

## Stop and escalate
- 

## Proof it is still true
\`\`\`sh
bin/agent/audit.sh
\`\`\`
EOF

echo "created $dir/SKILL.md"
echo "fill the blanks, then run bin/agent/audit.sh - a skill with no real path in it is a guess, not a skill"
