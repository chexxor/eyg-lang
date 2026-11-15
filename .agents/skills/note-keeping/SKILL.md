---
name: note-keeping
description: How to use notes/ instead of agent memories - when to write a note, what frontmatter it needs, and when to delete it. Use at the start and end of any non-trivial task.
verified: 2026-11-14
---

# Notes, not memories

Persistent agent memories are forbidden here. The record of decisions is
`notes/`, and the record of what is true about the repository is `docs/world/`.
Keep them apart:

- a **note** is a trade-off the code cannot show: why one option was chosen over
  another, a constraint found by experiment, something that surprised you and
  would surprise the next reader.
- a **world claim** is a fact with a command that proves it still holds. It lives
  in `docs/world/` and carries `verify:`. If you can write the check as a command,
  it is a claim or a test, not a note.

## Frontmatter, required
```markdown
---
name: short slug
description: one sentence
date: YYYY-MM-DD
---
```
`invariant.notes-frontmatter` is lint-checked by `bin/agent/audit.sh`.

## Write a note only when
- a design trade-off was made and the reasoning is not visible in the code;
- a non-obvious constraint was discovered by experiment;
- something would surprise the next reader.

## Never
- duplicate `guides/**`, `README.md` or `CONTRIBUTING.md`;
- record a fact the code or a test already states;
- leave a note you have not re-verified.

## Style reference
`notes/reference-resolution.md`, `notes/mutable-file-systems.md`,
`notes/opaque-crypto-keys.md`, `notes/integer-precision-on-javascript.md`.

## At the end of a session
For each note you touched: still true - keep it and update `date:`; fixed by a
test or a code change - delete it; not read or edited in 90 days and no longer
load-bearing - delete it. `bin/agent/audit.sh` lists anything older than 90 days
as STALE; that is a prompt to re-read, not a licence to bump the date.
