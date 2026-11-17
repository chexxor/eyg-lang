---
id: proposal.entry-suite-list
type: invariant
owner: delegate
status: current
verified_at: 2026-11-17
verify: "! grep -q 'eyg_packages/spotless' entry.eyg"
confidence: medium
sources: [entry.eyg, eyg_packages/spotless/entry.eyg, eyg_packages/eyg/entry.eyg, CONTRIBUTING.md]
supersedes: null
superseded_by: null
---

# Proposal: strengthen invariant.entry-suite-list

## Why

The invariant says a package published in `eyg_packages/` is a package the root
`entry.eyg` runs. Its current verify command checks only two packages:

```sh
grep -q 'eyg_packages/overlay/entry.eyg' entry.eyg
```

Three packages are in the tree and not run by the suite as of 2026-11-14:
`catfact` (has only `index.eyg.json`, no entry module), `spotless` (has
`entry.eyg`, not imported), and `eyg` (imported in a commented-out line, which the
weak grep still counts as a match because it looks for the path, not for an
uncommented reference). The invariant passes while being false. The verify command
should iterate over every directory in `eyg_packages/` and require an uncommented
reference, as `bin/agent/gate.sh` now does.

The decision is the operator's: wiring `spotless` and `eyg` into the suite is a
code change, not a lint change. Until it is made, the honest status of those three
packages is "untested", and `bin/agent/gate.sh` names them on every run.

## Verification performed

```sh
bash bin/agent/gate.sh --all        # warn: ... not referenced: catfact eyg spotless
```

Exit code 1 came from the missing toolchain (UNVERIFIED), not from this check; the
warning line printed regardless.

This record's own verify is `! grep -q 'eyg_packages/spotless' entry.eyg`: it passes
while the gap is open and fails the moment `spotless` is wired into the suite, at
which point the proposal is superseded and should be deleted rather than left in
`proposed/`.
