---
id: notes.format
type: entity
owner: delegate
status: current
verified_at: 2026-11-18
verify: "for f in notes/*.md; do grep -q ^date: $f || exit 1; done"
confidence: high
sources: [notes/reference-resolution.md, notes/mutable-file-systems.md, AGENTS.md]
supersedes: null
superseded_by: null
---

# Notes are this repository's decision record

`notes/` is where trade-offs go when they are not clear from the code: one file
per subject, `name:`, `description:` and `date:` in front-matter. There is no
memory system here; a decision that is not written down did not happen.

Notes go stale. Prefer a test or a `docs/world/` claim with a `verify` command
over a note, and delete a note once the code or a guide says the same thing.

## Not this

Not the language reference (`guides/`), and not task state: a note is a settled
explanation, not a to-do list.
