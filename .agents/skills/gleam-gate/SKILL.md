---
name: gleam-gate
description: The definition-of-done gate for Gleam packages - format check, warnings-as-errors build, and tests on each target a package supports. Use before any commit touching packages/**.
verified: 2026-11-14
---

# The gate

A package is done when, for every target it supports:

```sh
gleam format --check src test
gleam build --warnings-as-errors && gleam test                  # BEAM
gleam build --target javascript --warnings-as-errors
gleam test --target javascript --runtime bun                    # JavaScript
```

`--warnings-as-errors` is not a preference; CI enforces it. Format failures are
failures.

## Do not hardcode the target lists
`CONTRIBUTING.md` holds them, and they differ per package. `bin/agent/gate.sh`
reads them out of that file at run time, so the gate cannot drift from the
document humans and CI follow. As derived on 2026-11-14:

- both targets: `gleam_analysis`, `gleam_hub`, `gleam_ir`, `gleam_parser`,
  `intelligence`, `overlay_llm`, `topological`, `touch_grass`, `untethered`
- JavaScript only: `gleam_cli`, `gleam_compiler`, `gleam_interpreter`, `gleam_x`,
  `morph`, `website`

Nine packages with a `gleam.toml` are in **neither** loop: `cloud`, `hub`, `loam`,
`overlay`, `overlay_public`, `overlay_web`, `pal`, `plinthx`, `unixfs`. The gate
prints them as UNCOVERED. That is a gap in the repository's own loops, not a pass
- run that package's tests yourself and say which ones you ran.

## Run it
```sh
bin/agent/gate.sh                  # packages changed against origin/main
bin/agent/gate.sh gleam_parser     # one package
bin/agent/gate-all.sh              # everything, plus the EYG suite
bin/agent/gate.sh --dry-run        # the matrix, 0.02 s, runs nothing
```

## Fail closed
If `gleam` or `eyg` is not installed, the gate reports UNVERIFIED for every
package and exits 1. On this host the toolchain is not installed, so a change to
`packages/**` cannot be claimed as gated here. Say which gate you ran and which
you could not. Never describe an unrun gate as passing.

## If a failure looks pre-existing
Prove it, do not assert it: stash your change, run the same gate on the clean
tree, and put both results in the PR body.
