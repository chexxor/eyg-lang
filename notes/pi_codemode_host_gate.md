---
name: the codemode gate is host-side, and a pure-EYG mediated runner cannot exist
description: Why EYG codemode restricts effects in the process that starts the interpreter rather than in the program or in a mediated EYG runner; the decision, not the procedure.
date: 2026-11-15
---

# The gate sits between the program and the host, not inside the program

An EYG program performs effects and the runtime performs them
(`packages/loam/src/loam/execute.gleam` turns an unhandled effect into
`computer.extrinsic(effect, meta.origin)`), so a policy expressed inside the
program is a request, not a constraint: the program that decides to skip its own
check is the same program that asks. Nothing about the interpreter changes that.

The only place a restriction can live is the runner that starts the interpreter,
which is why the fix is `eyg run --policy <module.eyg>`
(`packages/gleam_cli/src/eyg/cli/policy_runner.gleam`) reusing the Pass/Mock gate
the overlay session already binds (`packages/gleam_cli/src/eyg/cli/overlay.gleam`).

## Why not an EYG mediated runner

The tempting design is an EYG program that reads a request and runs it through a
policy - the agent talks to a helper process written in EYG. It cannot work as a
restriction: the helper would need an effect that evaluates EYG source or calls a
tool, and `packages/loam/src/loam/platform/computer.gleam` has no such effect
(`computer.effects()` lists file, network, time, randomness, process IO and
cryptography only). Adding one would be the single largest security hole in the
language: an effect that evaluates arbitrary EYG is an effect that performs every
effect. So the mediation is written in Gleam, on the host side, where the effect
loop is.

## Consequences the code does not show

- The policy module is host authored configuration, so it is evaluated with the
  *ungated* evaluator and may itself perform effects - reading a token from the
  environment. The program under the gate cannot see that token.
- Paths are resolved to absolute before the policy sees them
  (`resolve_policy_input` in `packages/gleam_cli/src/eyg/cli/overlay.gleam`), so a
  policy never reasons about relative paths and a program cannot dodge a root with
  `..`.
- A refusal resumes the program with an EYG error rather than aborting it, because
  "this effect was refused" is a value the program can branch on. The runner turns a
  program that ends on an unhandled `Error` into exit 1 with the reason on stderr, so
  a denial is never silent on the command line.
- `DecodeJSON`, `EYGParse`, `Hash` and `Sign` are `Unchecked`: they compute and touch
  nothing outside the process, so no policy field is consulted for them and no
  preset can forbid them. Anything that must be refused has to be an effect that
  reaches outside the process.
- Loosening a committed rule must break the suite, so necessity is a test:
  `scripts/mutation-check.mjs` (13.5 s wall, `@measured 2026-11-15`).
