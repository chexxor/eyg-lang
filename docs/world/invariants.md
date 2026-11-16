# Invariants - what must never become false

Owner-edited only. Each entry carries a verify command that can fail.

---
id: invariant.eyg-over-bash
type: invariant
owner: human
status: current
verified_at: 2026-11-16
verify: "grep -q 'does not have an effect to run shell' AGENTS.md"
confidence: high
sources: [AGENTS.md]
supersedes: null
superseded_by: null
---

EYG is the scripting language of this repository and it has no effect that runs a
shell command. Bash is for reading the tree and for work EYG cannot express, not
for doing the work the operator asked for.

---
id: invariant.entry-suite-list
type: invariant
owner: human
status: current
verified_at: 2026-11-16
verify: "grep -q 'eyg_packages/overlay/entry.eyg' entry.eyg && grep -q 'eyg_packages/json/entry.eyg' entry.eyg"
confidence: high
sources: [entry.eyg, CONTRIBUTING.md]
supersedes: null
superseded_by: null
---

A package that is published in `eyg_packages/` is a package the repository-level
`entry.eyg` runs. Adding a package without adding its tests to that file leaves a
package untested, and the suite is the promise the repository makes.

---
id: invariant.notes-frontmatter
type: invariant
owner: human
status: current
verified_at: 2026-11-16
verify: "for f in notes/*.md; do grep -q ^name: $f || exit 1; done"
confidence: high
sources: [notes/reference-resolution.md, AGENTS.md]
supersedes: null
superseded_by: null
---

Every note carries `name:` front-matter. A note without front-matter cannot be
found by the next session, and an unfound decision is a decision that did not
happen.

---
id: invariant.purpose-every-dir
type: invariant
owner: human
status: current
verified_at: 2026-11-16
verify: "for d in */; do test -f ${d}PURPOSE || exit 1; done"
confidence: high
sources: [docs/PURPOSE, pi-simple-world-model/lib/world_model.mjs]
supersedes: null
superseded_by: null
---

Every top-level directory has a `PURPOSE` file, so the generated tier-0 map can
name what each one is for. The lint refuses the tree when one is missing.
