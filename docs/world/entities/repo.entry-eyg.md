---
id: repo.entry-eyg
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q 'aok.all(tests)' entry.eyg"
confidence: high
sources: [entry.eyg, eyg_packages/aok/entry.eyg, CONTRIBUTING.md]
supersedes: null
superseded_by: null
---

# The repository-level test runner

`entry.eyg` is the whole EYG suite. It flattens the `tests` field of each
`eyg_packages` entry module and calls `aok.all(tests)`; it exits 0 only when
`counts.failed` is 0. CI runs it as `eyg script entry.eyg`.

A package whose tests are not listed here is not covered by the suite, and a
change to a listed package has to keep the list green.

## Not this

It does not test the Gleam packages in `packages/`; those run per package under
`gleam test`, in `.github/workflows/test.yml`.
