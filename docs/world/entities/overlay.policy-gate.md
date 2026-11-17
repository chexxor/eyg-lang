---
id: overlay.policy-gate
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q 'pub const rule_mapping' packages/gleam_cli/src/eyg/cli/overlay.gleam && grep -q 'pub fn decide' packages/overlay/src/overlay/policy.gleam && grep -q 'pub fn decision_from_value' packages/overlay/src/overlay/policy.gleam"
confidence: high
sources: [packages/overlay/src/overlay/policy.gleam, packages/gleam_cli/src/eyg/cli/overlay.gleam, eyg_packages/overlay/policy.eyg, eyg_packages/overlay/README.md]
supersedes: null
superseded_by: null
---

# The per-effect permission gate already exists

A running EYG program is stopped at every effect before the host performs it, and a
user-supplied function decides. This is the only mechanism in the tree that restricts
what a program may do to the outside world.

- `packages/overlay/src/overlay/policy.gleam:14-59` declares `Rule` (a named policy
  field, or `Unchecked`), `Policy` and `match_rules`. An effect with no rule is
  filtered out of the harness, so it never appears in type inference and can never be
  called.
- `packages/overlay/src/overlay/policy.gleam:60-135` is the decision point: `decide`
  calls the gate function with the effect value and expects a tagged
  `Pass(value)` - perform, possibly with the value rewritten - or `Mock(value)` -
  resume the program with `value`, the host effect is never reached.
- `packages/gleam_cli/src/eyg/cli/overlay.gleam:688-710` is `rule_mapping`, the
  CLI's list of which of the computer effects are gated and the policy field that
  gates each. `DecodeJSON`, `EYGParse`, `Hash` and `Sign` are `Unchecked`.
- `packages/gleam_cli/src/eyg/cli/overlay.gleam:553-576` resolves relative file
  paths to absolute *before* the gate sees them, so a policy compares resolved paths.
- `eyg_packages/overlay/policy.eyg` is the EYG-side vocabulary for the same gate:
  `deny_all`, `allow_all`, `read_only(roots)`, `read_write(roots)`,
  `under(effect, roots, path_of)`, `fetch_hosts(hosts)`, `hide_secrets`.
  `eyg_packages/overlay/README.md` documents the `.overlay.eyg` shape that carries it.

The gate is host-side, so a program cannot opt out of it by writing different code.

## Not this

Not the effect definitions - those are in the `touch_grass` harness and in
`guides/cli_effects_reference.md`. Not `loam/sandbox.gleam`, which is an in-memory
system for tests and does not restrict the real host. Not the CLI's `run`, `eval` or
`script` commands: without `--policy` they reach the host ungated - see
`cli.run-effect-path`; with `--policy <module.eyg>` they reach this gate, which is what
`pi.codemode-gate` builds on.
