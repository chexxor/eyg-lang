---
id: packages.loam-effects
type: entity
owner: delegate
status: current
verified_at: 2026-11-18
verify: "test -f packages/loam/src/loam/platform/computer.gleam && grep -q 'computer.Search(input)' packages/loam/src/loam/platform/computer.gleam && grep -q 'Search(search.Input)' packages/touch_grass/src/touch_grass/harness/computer.gleam && grep -q 'Search.*policy.PolicyField(' packages/gleam_cli/src/eyg/cli/overlay.gleam"
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

The CLI runtime gained a `Search` effect on 2026-11-16: `computer.Search(input)` sits
between `ReadFile` and `Sign` in the `extrinsic` and delegates to `search_the_tree` in the
same file. Its interface is upstream-owned - `packages/touch_grass/src/touch_grass/file_system/search.gleam`,
published in `touch_grass` 0.4.4, `label = "Search"`, `Input(path, pattern, limit)`,
`lower() = Result(List(String), String)` - and the effect union in
`packages/touch_grass/src/touch_grass/harness/computer.gleam` lists `Search(search.Input)`.
The policy mapping is in `packages/gleam_cli/src/eyg/cli/overlay.gleam`, where `Search` reuses
the existing `read_file` field, so the roots that gate reads are the roots a search may walk
and no new policy field exists. Its tests are in `packages/loam/test/computer_test.gleam`.

## Not this

Not the effect *types* - those are declared in `touch_grass` and documented in
`guides/cli_effects_reference.md`. `unixfs` is a different, smaller runtime.
