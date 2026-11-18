---
id: eyg-packages.layout
type: entity
owner: delegate
status: current
verified_at: 2026-11-18
verify: "for p in eyg_packages/*/; do test -f $p/entry.eyg || test -f $p/index.eyg.json || exit 1; done"
confidence: high
sources: [eyg_packages/aok/entry.eyg, eyg_packages/standard/index.eyg.json, CONTRIBUTING.md]
supersedes: null
superseded_by: null
---

# EYG standard library layout

Every directory in `eyg_packages/` is one EYG package, and each one has either a
source entry module `entry.eyg` or a pre-encoded `index.eyg.json`. A package
exposes its tests as the `tests` field of its entry module; that field is what
`entry.eyg` at the repository root collects.

`aok` is the assertion and test-running package; `overlay` carries policy and
skills helpers for agents; the rest (`standard`, `json`, `fs`, `edit`, `option`,
`http`) are the library, and `catfact` is a demo.

## Not this

Not the Gleam packages under `packages/` - those are the toolchain, written in
Gleam, not in EYG.
