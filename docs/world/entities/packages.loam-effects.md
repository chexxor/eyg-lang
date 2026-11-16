---
id: packages.loam-effects
type: entity
owner: delegate
status: current
verified_at: 2026-11-16
verify: "test -f packages/loam/src/loam/platform/computer.gleam"
confidence: high
sources: [packages/loam/src/loam/platform/computer.gleam, guides/cli_effects_reference.md]
supersedes: null
superseded_by: null
---

# Where the CLI's effects come from

An EYG program reaches the outside world only through effects, and each runtime
declares its own. The CLI runtime's computer effects (file system, process, time)
are implemented in `packages/loam/src/loam/platform/computer.gleam`.

That file is the answer to "can this effect exist at all" before any EYG is
written. Prefer implementing a feature with the effects already there; add an
effect only when the feature cannot be built without one, and say why in the note
that carries it.

## Not this

Not the effect *types* - those are declared in `touch_grass` and documented in
`guides/cli_effects_reference.md`. `unixfs` is a different, smaller runtime.
