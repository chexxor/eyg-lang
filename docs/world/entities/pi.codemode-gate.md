---
id: pi.codemode-gate
type: entity
owner: delegate
status: current
verified_at: 2026-11-15
verify: "test -f pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q -- '\"--policy\"' pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q 'policy_runner.run(input, policy, config)' packages/gleam_cli/src/eyg_cli.gleam && grep -q 'defaultTools' .pi/settings.json && grep -q 'codemode_policy' entry.eyg"
confidence: high
sources: [pi-eyg-codemode/extensions/eyg-codemode.ts, pi-eyg-codemode/policies/agent-roots.eyg, pi-eyg-codemode/package.json, .pi/settings.json, packages/gleam_cli/src/eyg_cli.gleam, eyg_packages/codemode_policy/index.eyg, guides/pi_codemode_agent.md, notes/pi_codemode_host_gate.md]
supersedes: null
superseded_by: null
---

# The pi agent's coding tool is EYG behind the CLI gate

`pi-eyg-codemode/` is a local pi package (`pi list` resolves the declaration in
`.pi/settings.json` to `/home/chexxor/Git/eyg-lang/pi-eyg-codemode`) whose one
extension registers one tool, `eyg`. With `"defaultTools": []` the built-in `read`,
`bash`, `edit`, `write`, `grep`, `find`, `ls` are not declared and `"-builtin:codemode"`
disables the built-in JavaScript codemode, so the model's only channel to the outside
world is an EYG program, and every effect of that program is decided by the gate in
`overlay.policy-gate` before the host performs it.

- `packages/gleam_cli/src/eyg_cli.gleam:74-82` sends `run`, `script` and `eval` through
  `policy_runner` only when a policy module is given; without `--policy` they stay
  ungated, which is what `cli.run-effect-path` says and what
  `docs/world/traps.md` records as the gap this closes.
- `pi-eyg-codemode/extensions/eyg-codemode.ts` builds argv `[mode, "--policy", policy, "-c", code]`
  and spawns it with `pi.exec`, which has no shell, so no quoting can smuggle a second
  command past the gate; with no policy configured the tool refuses to run anything.
- `pi-eyg-codemode/policies/agent-roots.eyg` is the policy module: it imports
  `eyg_packages/overlay/policy.eyg` and answers `policy.read_write(roots)` for the
  absolute roots named in `EYG_ALLOWED_ROOTS`.
- `eyg_packages/codemode_policy/index.eyg` holds the presets an agent may be given
  (`agent`, `reader`, `fetching`, `service`, `nothing`); the suite in
  `eyg_packages/codemode_policy/test/` is collected by the repository `entry.eyg` and
  refuses every effect outside the preset's allowed set with the EYG reason
  `denied(effect, path)`.
- A refusal is reported, not swallowed: the runner exits 1 with the reason on stderr,
  and the tool result carries `gated: true, ran: true, exit: 1` plus the reason.

## Not this

Not the gate mechanism - `overlay.policy-gate` owns that, and
`packages/gleam_cli/src/eyg/cli/policy_runner.gleam` is the runner side. Not the EYG
language reference - `guides/pi_codemode_agent.md` is how to run such a session,
`guides/syntax.md` is the language.
