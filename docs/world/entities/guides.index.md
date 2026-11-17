---
id: guides.index
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q '^name: EYG syntax guide' guides/syntax.md && grep -q '^name: Builtins reference' guides/builtins_reference.md"
confidence: high
sources: [guides/syntax.md, guides/builtins_reference.md, guides/cli_effects_reference.md]
supersedes: null
superseded_by: null
---

# Guides are the language reference

`guides/` holds the prose an agent should read before writing EYG: `syntax.md` is
the surface syntax, `builtins_reference.md` catalogues every `!builtin`,
`cli_effects_reference.md` is the full effect reference for the CLI runtime, and
`writing_tests_with_aok.md` is how tests are written. Path resolution lives in
`file_resolution.md`; named-package pinning lives in `syntax.md`.

Read the guide before inventing syntax. A guide that disagrees with the compiler
is a guide bug; report it, do not code to the guide.

## Not this

Not the implementation. The rules the implementation follows are in `spec/`, not
in `guides/`.
