---
id: agent.tooling
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "test -x bin/agent/gate.sh && test -x bin/agent/gate-all.sh && test -x bin/agent/audit.sh && test -x bin/agent/new-skill.sh && bash bin/agent/audit.sh >/dev/null && grep -q '^name: eyg-write' .agents/skills/eyg-write/SKILL.md"
confidence: high
sources: [bin/agent/gate.sh, bin/agent/audit.sh, AGENTS.md, eyg_packages/overlay/skills.eyg, CONTRIBUTING.md]
supersedes: null
superseded_by: null
---

# The agent tooling: skills and gates

Two layers, both written for this repository rather than imported.

`.agents/skills/<name>/SKILL.md` holds the on-demand instructions. The location is
not a convention someone chose: `eyg_packages/overlay/skills.eyg` reads exactly that
path for overlay agents, and Pi reads the same path for its own skill discovery. A
skill written once is therefore available to both. Eight exist as of 2026-11-14
(eyg-write, eyg-run, eyg-test, gleam-gate, effect-change, snapshot-review,
note-keeping, fork-sync); two are deliberately unwritten until first contact.

`bin/agent/` holds the executable half:

```sh
bin/agent/gate.sh          # per-package, target-aware; --dry-run is 0.02 s wall
bin/agent/gate-all.sh      # every package plus the EYG suite
bin/agent/audit.sh         # 0.25 s wall, checks paths, anchors, subcommands, dates
bin/agent/new-skill.sh     # scaffold so adding a skill is one command
```

The gate reads the BEAM and JavaScript package lists out of `CONTRIBUTING.md` at run
time instead of carrying its own copy, so the gate and the document cannot diverge.
It fails closed: with no `gleam` or `eyg` installed it reports UNVERIFIED for every
package and exits 1. Nine packages with a `gleam.toml` appear in neither loop
(`loam`, `hub`, `cloud`, `overlay`, `overlay_public`, `overlay_web`, `pal`,
`plinthx`, `unixfs`) and the gate names them UNCOVERED rather than pretending they
were tested.

`audit.sh` is the anti-rot rule: it checks every path and anchor named in the skills
and in `AGENTS.md`, checks every `eyg <subcommand>` against
`packages/gleam_cli/src/eyg/cli/args.gleam`, and reports skills and notes older than
90 days. It reports, it does not autofix.

## Not this

The tooling does not define what is true about the repository - `docs/world/` does
that, with a verify command per claim. The skills point at the guides and the source;
they are not a parallel description of them. `bin/agent/gate.sh` is not CI:
`.github/workflows/test.yml` runs its own four jobs and does not call these scripts.
