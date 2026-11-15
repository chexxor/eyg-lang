---
name: fork-sync
description: Keeping this working copy current with the upstream repository and proving a rebase with the gate. Use before starting work and before opening a PR.
verified: 2026-11-14
---

# Syncing with upstream

The pack this came from assumed an `upstream` remote. There is none. Run
`git remote -v` before trusting any instruction about remotes; as checked
2026-11-14:

| remote | url | role |
|---|---|---|
| `origin` | `https://github.com/crowdhailer/eyg-lang` | the upstream repository |
| `chexxor` | `https://github.com/chexxor/eyg-lang` | the operator's fork, where work is pushed |

`bin/agent/gate.sh` diffs against `origin/main` by default, which is the
correct baseline because `origin` is upstream. Override with `--baseline <ref>`
when working against the fork.

```sh
git fetch origin
git rev-list --left-right --count HEAD...origin/main   # ahead behind
git log --oneline HEAD..origin/main | head -40
git rebase origin/main
```

## Rules
- Rebase, do not merge, so the history stays linear and reviewable.
- A rebase can change snapshot and spec expectations silently. After any rebase
  run `bin/agent/gate-all.sh` and `eyg script entry.eyg` before trusting the
  branch. Neither is runnable on this host without the toolchain installed, so
  on this machine a rebase is *unverified* by definition - say so.
- Conflicts in `gleam.toml` dependency pins: take upstream's side unless your
  branch deliberately changed the pin, and name which you took in the commit
  message.
- Never sync `.env.eyg` content or any credential; they are local by design and
  `spaces/oss/.gitignore` keeps them out of the tree.
- A divergence this fork carries that upstream lacks stays in its own commit
  with a message saying why, so future rebases are mechanical.

## Prove it
```sh
git remote -v
git rev-list --left-right --count HEAD...origin/main
bin/agent/gate.sh --dry-run     # 0.02 s, shows what the gate would run
```
