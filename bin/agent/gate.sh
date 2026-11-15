#!/usr/bin/env bash
# bin/agent/gate.sh - the definition-of-done gate for this repository.
#
# Usage
#   bin/agent/gate.sh                    packages changed against origin/main
#   bin/agent/gate.sh gleam_parser loam  named packages
#   bin/agent/gate.sh --all              every package plus the EYG suite
#   bin/agent/gate.sh --dry-run          print the derived matrix, run nothing
#   bin/agent/gate.sh --baseline <ref>   change the diff base (default origin/main)
#
# Why the lists are derived, not written
#   CONTRIBUTING.md holds the two target lists. Reading them at run time means the
#   gate cannot drift from the document CI and humans actually follow. A copy of
#   the lists in this script is a second source of truth, and second sources rot.
#
# Why the gate fails closed
#   If `gleam` or `eyg` is missing, every package is reported UNVERIFIED and the
#   exit status is 1. An agent that has not run a gate must not be able to produce
#   a green line from it. UNVERIFIED is a result, not a pass.
#
# A package with a gleam.toml that appears in neither CONTRIBUTING list is reported
# UNCOVERED: that is a gap in the repository's own loops, not a green result.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

baseline="origin/main"
all=0
dry=0
wanted=()

while [ $# -gt 0 ]; do
  case "$1" in
    --all) all=1 ;;
    --dry-run) dry=1 ;;
    --baseline) baseline="${2:-}"; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    --*) echo "unknown option: $1" >&2; exit 2 ;;
    *) wanted+=("$1") ;;
  esac
  shift
done

# ---- derive the target matrix from CONTRIBUTING.md ---------------------------
declare -A targets=()

while IFS=$'\t' read -r target list; do
  [ -z "$target" ] && continue
  for pkg in ${list//,/ }; do
    current="${targets[$pkg]:-}"
    targets[$pkg]="${current:+$current }$target"
  done
done < <(
  awk '
    /^for pkg in packages/{
      list = $0
      sub(/^for pkg in packages./, "", list)
      gsub(/[{}]/, "", list)
      sub(/;.*/, "", list)
      n = ++count
      lists[n] = list
      tgt[n] = "beam"
      next
    }
    /--target javascript/{ if (n) tgt[n] = "javascript"; next }
    /^done/{ if (n) { print tgt[n] "\t" lists[n]; n = 0 } }
  ' CONTRIBUTING.md
)

if [ ${#targets[@]} -eq 0 ]; then
  echo "error: could not read the target lists from CONTRIBUTING.md" >&2
  exit 1
fi

# yn prints a tool's presence the way a human reads it: 0 is a shell success and
# reads as "present" in a report, which is the opposite of how $?
yn() { if [ "$1" = 1 ]; then echo present; else echo missing; fi; }
have_gleam=1; have_eyg=1
command -v gleam >/dev/null 2>&1 || have_gleam=0
command -v eyg  >/dev/null 2>&1 || have_eyg=0
# gleam can be installed and still be unable to build for the beam target: it
# shells out to escript. Absent that, every beam package FAILS for a reason that
# is about the host, not about the code, so say it once instead of 16 times.
have_erl=1; command -v escript >/dev/null 2>&1 || have_erl=0

all_packages() {
  for dir in packages/*/; do
    pkg="${dir#packages/}"; pkg="${pkg%/}"
    [ -f "packages/$pkg/gleam.toml" ] && echo "$pkg"
  done
}

if [ ${#wanted[@]} -gt 0 ]; then
  pkgs=("${wanted[@]}")
elif [ "$all" -eq 1 ]; then
  pkgs=($(all_packages))
else
  if ! git rev-parse --verify "$baseline" >/dev/null 2>&1; then
    echo "note: $baseline is not a resolvable ref; gating every package instead" >&2
    pkgs=($(all_packages))
  else
    pkgs=($(git diff --name-only "$baseline"... \
      | awk -F/ '$1=="packages" && NF>2 {print $2}' | sort -u))
  fi
fi

if [ "$dry" -eq 1 ]; then
  echo "derived from CONTRIBUTING.md (baseline $baseline)"
  echo "toolchain: gleam=$(yn $have_gleam) eyg=$(yn $have_eyg) erl=$(yn $have_erl)"
  for pkg in $(printf '%s\n' "${pkgs[@]}" | sort); do
    t="${targets[$pkg]:-}"
    if [ -z "$t" ]; then
      printf '  %-18s UNCOVERED (no target in CONTRIBUTING.md)\n' "$pkg"
    else
      printf '  %-18s %s\n' "$pkg" "${t# }"
    fi
  done
  exit 0
fi

pass=0 fail=0 unver=0 uncov=0
total_checks=0
started=$(date +%s)

for pkg in "${pkgs[@]}"; do
  if [ ! -d "packages/$pkg" ]; then
    echo "== $pkg  SKIP (no such package directory)"
    continue
  fi
  target_list="${targets[$pkg]:-}"
  if [ -z "$target_list" ]; then
    echo "== $pkg  UNCOVERED (not in either CONTRIBUTING.md loop; run its own gleam test)"
    uncov=$((uncov + 1))
    continue
  fi

  echo "== $pkg  targets: ${target_list# }"
  if [ "$have_gleam" -eq 0 ]; then
    echo "   UNVERIFIED gleam is not installed; see guides/install_from_source.md"
    unver=$((unver + 1))
    continue
  fi

  (
    cd "packages/$pkg"
    gleam format --check src test
    for t in ${target_list# }; do
      if [ "$t" = "beam" ]; then
        gleam build --warnings-as-errors && gleam test
      else
        gleam build --target javascript --warnings-as-errors
        gleam test --target javascript --runtime bun
      fi
    done
  ) && { echo "   PASS"; pass=$((pass + 1)); } \
    || { echo "   FAIL"; fail=$((fail + 1)); }
done

if [ "$have_gleam" -eq 1 ] && [ "$have_erl" -eq 0 ]; then
  echo "note  gleam is installed but escript is not, so a beam FAIL above is a missing Erlang/OTP runtime on this host - guides/install_from_source.md, not a code fault"
fi

# ---- the EYG suite -------------------------------------------------------------
eyg_changed=0
if [ "$all" -eq 1 ] || git diff --name-only "$baseline"... 2>/dev/null | grep -q '^eyg_packages/'; then
  eyg_changed=1
fi

if [ "$eyg_changed" -eq 1 ]; then
  echo "== eyg_packages  (entry.eyg at the repository root)"
  if [ "$have_eyg" -eq 0 ]; then
    echo "   UNVERIFIED eyg is not installed"
    unver=$((unver + 1))
  else
    eyg script entry.eyg && { echo "   PASS"; pass=$((pass + 1)); } \
      || { echo "   FAIL"; fail=$((fail + 1)); }
  fi
fi

# ---- entry.eyg wiring, a check CONTRIBUTING.md does not make -----------------
unwired=()
for dir in eyg_packages/*/; do
  pkg="${dir#eyg_packages/}"; pkg="${pkg%/}"
  awk '!/\/\//' entry.eyg | grep -q "eyg_packages/$pkg/" || unwired+=("$pkg")
done
if [ ${#unwired[@]} -gt 0 ]; then
  echo "warn: eyg_packages not referenced by the root entry.eyg: ${unwired[*]}"
  echo "      those packages are not run by the suite (invariant.entry-suite-list)"
fi

elapsed=$(( $(date +%s) - started ))
echo "gate summary: pass=$pass fail=$fail unverified=$unver uncovered=$uncov in ${elapsed}s"
if [ "$fail" -gt 0 ] || [ "$unver" -gt 0 ]; then
  echo "gate NOT satisfied: every package above must show PASS."
  exit 1
fi
exit 0
