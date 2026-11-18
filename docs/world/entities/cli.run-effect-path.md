---
id: cli.run-effect-path
type: entity
owner: delegate
status: current
verified_at: 2026-11-18
verify: "grep -q 'computer.extrinsic(effect, meta.origin)' packages/loam/src/loam/execute.gleam && ! grep -q policy packages/loam/src/loam/execute.gleam"
confidence: high
sources: [packages/loam/src/loam/execute.gleam, packages/loam/src/loam/platform/computer.gleam, packages/gleam_cli/src/eyg/cli/run.gleam, packages/gleam_cli/src/eyg/cli/eval.gleam]
supersedes: null
superseded_by: null
---

# One-shot EYG evaluation is not gated

`eyg run`, `eyg eval` and `eyg script` evaluate a program and hand unhandled effects
straight to the host: `packages/loam/src/loam/execute.gleam:84-92` turns an
unhandled effect into `computer.cast(label, lift)` then
`computer.extrinsic(effect, meta.origin)`, and nothing in that file consults a policy.
A program run this way can read, write and delete any file this user can, and can
`Fetch`.

Consequence for anything that puts EYG in front of an agent: the restriction has to
sit on the runner side - the process the runner starts has to be started with rules -
or the runner has to reject the program before evaluating it. A policy written in the
EYG program itself does not constrain that run.

## Not this

Not the gate mechanism - that is `overlay.policy-gate`, reached from `eyg overlay`
(`packages/gleam_cli/src/eyg/cli/overlay.gleam`) and, for one-shot commands, from the
`--policy` flag handled in `packages/gleam_cli/src/eyg/cli/policy_runner.gleam`. Not a claim about the
CLI's own effects being wrong; the effects are as `packages.loam-effects` says, this
claim is only about which of them a caller may perform.
