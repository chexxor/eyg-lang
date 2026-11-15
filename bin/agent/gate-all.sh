#!/usr/bin/env bash
# bin/agent/gate-all.sh - the pre-PR gate: every package on every target it
# supports, plus the EYG suite.
#
#   bin/agent/gate-all.sh              full gate
#   bin/agent/gate-all.sh --dry-run    show the matrix without running anything
#
# This is bin/agent/gate.sh --all. It exists as its own name so the pre-PR step
# is a thing you can type, and so the summary it prints can be pasted into the
# PR body or the commit message. A gate that is never run because it is awkward
# to name is not a gate.
set -euo pipefail
exec "$(dirname "$0")/gate.sh" --all "$@"
