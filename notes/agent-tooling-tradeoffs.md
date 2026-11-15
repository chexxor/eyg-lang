---
name: agent-tooling-tradeoffs
description: Why the agent skills live in .agents/skills, why the gate reads CONTRIBUTING.md at run time, and why both fail closed.
date: 2026-11-14
---

# The agent tooling: what was traded

The code shows what the scripts do; it does not show why these shapes and not the
obvious ones.

## Skills in `.agents/skills/`, nowhere else
Two consumers read that path: Pi (project skill discovery, per its skills docs) and
`eyg_packages/overlay/skills.eyg`, which loads every `<root>/.agents/skills/<dir>/SKILL.md`
into an overlay agent's context. Putting the same instructions in a second place
would give two sources of truth that drift; the shared path means a skill written
for the coding agent is also available to the overlay agent, and vice versa.

## The gate derives its target lists from CONTRIBUTING.md
Hardcoding the BEAM and JavaScript package lists would be faster to read and would
drift the moment the document changed. `bin/agent/gate.sh` parses the two
`for pkg in packages/{...}` loops instead. The cost is a dependency on the document's
shape: if CONTRIBUTING.md is rewritten, the gate stops with "could not read the target
lists" rather than silently testing the wrong packages. Failing loudly is the point.

Measured 2026-11-14, wall time on this host: `gate.sh --dry-run` 0.02 s, `gate.sh --all`
0.04 s, `audit.sh` 0.25 s. All offline.

## Both gates fail closed
`gate.sh` reports UNVERIFIED and exits 1 when `gleam` or `eyg` is absent. On this host
the toolchain is not installed, so every gate run exits 1 and no change here can be
reported as gated. The alternative - skipping silently - lets an agent say "the suite
passes" having run nothing. A gate whose absence looks like a pass is worse than a gate
that cannot be satisfied yet.

Nine packages with a `gleam.toml` are in neither CONTRIBUTING loop (`loam`, `hub`,
`cloud`, `overlay`, `overlay_public`, `overlay_web`, `pal`, `plinthx`, `unixfs`). The
gate prints them as UNCOVERED. That is a finding about the repository, not a pass, and
it is the kind of gap a hardcoded list would hide.

## The audit reports, it does not fix
Stale paths, dead index rows and 90-day-old notes are listed; nothing is rewritten.
Deciding that a skill is dead is a judgement, and an autofix that deletes context
cannot be reviewed. `audit.sh` only checks paths whose first segment is a directory in
this tree; references to other workspaces (`~/Git/...`) are skipped by design so they
do not read as broken links.

## Two skills are unwritten on purpose
`hub-publish` and `spec-conformance` are named in the AGENTS.md index with their
trigger. Writing them before their commands have been run would produce exactly the
kind of confident, stale context this pack was built to remove.
