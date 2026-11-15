#!/usr/bin/env bash
# bin/agent/audit.sh - the anti-rot linter for AGENTS.md and .agents/skills.
#
#   bin/agent/audit.sh                        audit the real tree
#   SKILLS_DIR=/tmp/skills bin/agent/audit.sh audit a scratch copy (mutation proof)
#
# It checks four things, in order:
#   1. every skill's frontmatter parses the way eyg_packages/overlay/skills.eyg
#      and Pi parse it: name, description, and name matching the directory
#   2. every repo-relative path named in a skill or in AGENTS.md still exists, and
#      every `file.md#anchor` has a heading the anchor can land on
#   3. every `eyg <subcommand>` named exists in the CLI's arg parser
#   4. staleness and index drift, reported not fatal: a skill whose verified: date
#      is older than 90 days, a note older than 90 days, a skill over the line
#      budget, an index row pointing at a skill that is not there
#
# Rules 1-3 exit non-zero. Rule 4 reports and exits zero: deciding a skill is dead
# is a judgement, and a linter that deletes context is worse than one that stops.
#
# Cost: offline, under 0.2 s. If it gets slower, that is a bug to report.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

skills_dir="${SKILLS_DIR:-.agents/skills}"
stale_days="${STALE_DAYS:-90}"
budget="${SKILL_LINE_BUDGET:-80}"

errors=0
warnings=0

fail() { echo "FAIL  $1"; errors=$((errors + 1)); }
warn() { echo "WARN  $1"; warnings=$((warnings + 1)); }

now=$(date +%s)
age_days() {
  d=$(date -d "$1" +%s 2>/dev/null || echo 0)
  echo $(( (now - d) / 86400 ))
}

sources=(AGENTS.md)
skill_files=()
if [ -d "$skills_dir" ]; then
  for dir in "$skills_dir"/*/; do
    if [ -f "$dir/SKILL.md" ]; then skill_files+=("$dir/SKILL.md"); fi
  done
else
  fail "no skills directory at $skills_dir"
fi

# ---- 1. frontmatter -----------------------------------------------------------
for file in "${skill_files[@]:-}"; do
  [ -f "$file" ] || continue
  name="$(basename "$(dirname "$file")")"

  fm_name=$(awk 'NR==1 && $0=="---" {f=1; next} f && /^---$/ {exit} f && /^name:/ {sub(/^name: */,""); print; exit}' "$file")
  fm_desc=$(awk 'NR==1 && $0=="---" {f=1; next} f && /^---$/ {exit} f && /^description:/ {sub(/^description: */,""); print; exit}' "$file")
  fm_verified=$(awk '/^verified:/ {sub(/^verified: */,""); print; exit}' "$file")

  if [ -z "$fm_name" ]; then
    fail "$file: no name: in the frontmatter - the overlay parser falls back to the directory and Pi drops the skill entirely"
  elif [ "$fm_name" != "$name" ]; then
    fail "$file: name '$fm_name' does not match the directory '$name'"
  fi
  if [ -z "$fm_desc" ]; then
    fail "$file: empty description - the description is how a skill gets routed; an unrouted skill is an unread skill"
  fi
  if [ -z "$fm_verified" ]; then
    warn "$file: no verified: date"
  else
    a=$(age_days "$fm_verified")
    [ "$a" -gt "$stale_days" ] && warn "STALE $file verified $fm_verified ($a days) - re-run its commands or delete it"
  fi
  lines=$(wc -l < "$file")
  [ "$lines" -gt "$budget" ] && warn "$file is $lines lines, over the $budget budget - split it or make it a script"
  grep -qE '(guides/|docs/world/|packages/|eyg_packages/|spec/|bin/agent/)' "$file" \
    || fail "$file: names no path into the repository - a skill with no pointer is a restatement, and restatements drift"
done

# ---- 2. paths and anchors ----------------------------------------------------
# Only paths inside this repository are checked. A reference to another workspace
# is written with a leading ~ in prose; the first segment of a checked path must be
# a top-level directory that actually exists here, otherwise it is not our tree.
checked=0; external=0
path_refs=$(grep -ohE '[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+(\.md|\.gleam|\.eyg|\.eyg\.json|\.json|\.mjs|\.erl|\.yml|\.yaml|\.toml|\.sh|\.sql)' "${sources[@]}" "${skill_files[@]:-}" 2>/dev/null | sort -u || true)
for ref in $path_refs; do
  case "$ref" in *'*'*|*'$'*|*'://'*) continue;; esac
  ref="${ref#./}"; ref="${ref#../}"
  first="${ref%%/*}"
  # a reference whose first segment is not a directory in this tree belongs to
  # another workspace; it is prose, not a claim about this repository
  if [ "$ref" != "$first" ] && [ ! -d "$first" ]; then
    external=$((external + 1))
    continue
  fi
  checked=$((checked + 1))
  [ -e "$ref" ] || fail "'$ref' is referenced but does not exist in the tree"
done

anchor_refs=$(grep -ohE '[A-Za-z0-9_./-]+\.(md|gleam)#[A-Za-z0-9_-]+' "${sources[@]}" "${skill_files[@]:-}" 2>/dev/null | sort -u || true)
for ref in $anchor_refs; do
  ref="${ref#./}"; ref="${ref#../}"
  f="${ref%%#*}"; anchor="${ref#*#}"
  if [ ! -e "$f" ]; then fail "anchor target '$f' does not exist"; continue; fi
  if ! awk -v a="$anchor" '
    /^#/ {
      h = $0
      sub(/^#+ /, "", h)
      h = tolower(h)
      gsub(/[^a-z0-9 -]/, "", h)
      gsub(/ /, "-", h)
      if (h == a) { found = 1 }
    }
    END { exit found ? 0 : 1 }
  ' "$f"; then
    fail "'$ref' - $f has no heading that anchors to #$anchor"
  fi
done

# ---- 3. eyg subcommands ------------------------------------------------------
# A command claim is a command in a code span or a fenced block. Prose is not
# checked: "writing eyg code" is English, not a command.
cli_args="packages/gleam_cli/src/eyg/cli/args.gleam"
if [ -f "$cli_args" ]; then
  valid=$(grep -oE '\["[a-z][a-z-]*"' "$cli_args" | tr -d '["' | sort -u)
  mentions=$(for f in "${sources[@]}" "${skill_files[@]:-}"; do
    [ -f "$f" ] || continue
    awk '/^```/ { inblock = !inblock; next } inblock { print }' "$f"
    grep -oE '`[^`]+`' "$f" || true
  done | grep -oE '(^|[^A-Za-z0-9_.])eyg [a-z][a-z-]*' | sed 's/.*eyg //' | sort -u)
  for sub in $mentions; do
    printf '%s\n' "$valid" | grep -qx "$sub" \
      || fail "'$sub' is not a subcommand of the CLI defined in $cli_args"
  done
else
  warn "could not read $cli_args, command check skipped"
fi

# ---- 4. index drift and notes ----------------------------------------------
for file in "${skill_files[@]:-}"; do
  [ -f "$file" ] || continue
  name="$(basename "$(dirname "$file")")"
  grep -q "^| $name |" AGENTS.md \
    || warn "$name is not in the AGENTS.md skills index - an unindexed skill is never loaded"
done
while IFS= read -r row; do
  name="${row#| }"; name="${name%% *}"
  [ -f "$skills_dir/$name/SKILL.md" ] || warn "the AGENTS.md index lists '$name' but $skills_dir/$name/SKILL.md is not there"
done < <(awk '/^\| Skill \|/,/^$/ { if ($0 ~ /^\| [a-z][a-z0-9-]* \|/) print $0 }' AGENTS.md)

for f in notes/*.md; do
  [ -f "$f" ] || continue
  grep -q '^name:' "$f" || fail "$f has no name: frontmatter, so the next session cannot find it"
  d=$(awk '/^date:/ {sub(/^date: */,""); print; exit}' "$f")
  if [ -n "$d" ]; then
    a=$(age_days "$d")
    [ "$a" -gt "$stale_days" ] && warn "STALE $f dated $d ($a days) - re-verify or delete"
  fi
done

unwired=()
for dir in eyg_packages/*/; do
  pkg="${dir#eyg_packages/}"; pkg="${pkg%/}"
  awk '!/\/\//' entry.eyg | grep -q "eyg_packages/$pkg/" || unwired+=("$pkg")
done
[ ${#unwired[@]} -gt 0 ] && warn "eyg_packages not run by the root entry.eyg: ${unwired[*]}"

agents_lines=$(wc -l < AGENTS.md)
[ "$agents_lines" -gt 360 ] && warn "AGENTS.md is $agents_lines lines, over the 360 line budget - delete or move a section into a skill"
echo "note  AGENTS.md is $agents_lines lines; $checked in-repo paths checked, $external references to other workspaces skipped"

echo
if [ "$errors" -gt 0 ]; then
  echo "audit: $errors error(s), $warnings warning(s) - fix the paths before trusting any of this"
  exit 1
fi
echo "audit: clean, $warnings warning(s)"
exit 0
