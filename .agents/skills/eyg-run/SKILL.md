---
name: eyg-run
description: Run, evaluate, script and type-check EYG with the CLI, and build the CLI itself. Use when you need to execute EYG, or when a command involving `eyg` fails.
verified: 2026-11-14
---

# Running EYG

The full reference is `packages/gleam_cli/README.md`. Read it rather than guessing
at flags. The subcommands are defined in
`packages/gleam_cli/src/eyg/cli/args.gleam` - that file, not memory, is the list.

## Which execute command
| Need | Do |
|---|---|
| Production script with args and an exit code | `eyg script <file>.eyg` |
| One-liner with side effects | `eyg run -c '<code>'` |
| Pure expression, want the value printed | `eyg eval -c '<code>'` |
| Type check without running | `eyg check <file>.eyg` |
| See the IR | `eyg parse <file>.eyg` (JSON to stdout) |
| The whole EYG suite | `eyg script entry.eyg` from the repository root |

`eval` is pure: it does not run effects. `script` returns the `Int` from the
`script` field as the exit code, so a script file must expose
`{script: (List(String)) -> Int, ..}`.

## Other subcommands
`compile` (to JavaScript), `share`, `fetch <cid>`, `publish <pkg> <file>`,
`signatory initial|list|show`, `tui`, `overlay <file>`, `version`.

## Environment
- `EYG_ORIGIN=http://localhost:8001` points the CLI at the local hub instead of
  `https://eyg.run`. Use it for every `share`, `signatory` and `publish` in dev.

## Two traps this repo has already burned people on
- `eyg shell` is not a shell. It is the REPL, configured by a module - the
  `shell:` field of a record. EYG still has no effect that runs shell commands.
- `.env.eyg` files hold credentials. Do not read, print, commit or paste them.
  `eyg_packages/overlay/policy.eyg` denies reading them by design; keep that
  invariant intact.

## On this host the CLI is not installed
`command -v eyg` returns nothing here, so any command in this skill is an event,
not a loop: install first (`install.sh`, `guides/install_from_source.md`), then
run. Report results you could not produce as unverified, never as passing.

## Prove it
```sh
bin/agent/audit.sh   # checks every `eyg <subcommand>` named in the skills really exists
```
