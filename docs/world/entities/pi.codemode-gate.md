---
id: pi.codemode-gate
type: entity
owner: delegate
status: current
verified_at: 2026-11-15
verify: "grep -q -- '--policy' pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q 'policy_runner.run' packages/gleam_cli/src/eyg_cli.gleam && grep -q -- '-builtin:codemode' .pi/settings.json && grep -q codemode_policy entry.eyg"
confidence: high
sources: [pi-eyg-codemode/extensions/eyg-codemode.ts, pi-eyg-codemode/package.json, pi-eyg-codemode/policies/agent-roots.eyg, .pi/settings.json, packages/gleam_cli/src/eyg_cli.gleam, eyg_packages/codemode_policy/test/security_test.eyg]
supersedes: null
superseded_by: null
---

# The pi agent's coding tool is EYG behind the CLI gate

The workspace declares one pi package (`pi-eyg-codemode/`, keyword `pi-package`,
peer dependency `@earendil-works/pi-coding-agent`) whose single extension registers
one tool, `eyg`. The session has no `bash`, `edit`, `write`, `read`, `grep`, `find`,
`ls` and no built-in JavaScript codemode, so the only channel the model has to the
outside world is an EYG program, and every effect of that program goes through the
per-effect gate described by `overlay.policy-gate`.

- `.pi/settings.json` is the wiring: `packages` declares `../pi-eyg-codemode` beside
  the world model package, `extensions: ["-builtin:codemode"]` disables the built-in
  JS codemode (a project entry overrides the user scope), and `defaultTools: []`
  removes every built-in tool while extension tools stay (`--tools` / `defaultTools`
  accept `+name` and `-name`; `[]` disables built-ins only).
- `pi-eyg-codemode/extensions/eyg-codemode.ts` builds the argv
  `[mode, "--policy", policy, "-c", code]` and runs it through `pi.exec`, which has no
  shell, so no quoting can smuggle a second command. `cwd` is the session's, and the
  tool refuses to run anything when `EYG_POLICY` is unset - a session cannot fall back
  to an ungated run.
- The policy is an absolute path read from the environment, so the model cannot swap
  it from inside the program; `pi-eyg-codemode/policies/agent-roots.eyg` builds the
  rules from `eyg_packages/overlay/policy.eyg` over `EYG_ALLOWED_ROOTS`.
- A refusal is reported, not swallowed: the runner exits 1 with the reason on stderr,
  and the tool result carries `gated: true, ran: true, exit: 1` plus
  `write_file denied by policy: /abs/path` - the bytes were never written.
- `entry.eyg` runs the suite of `eyg_packages/codemode_policy/`, whose security test
  attempts every gated effect outside the allowed roots and asserts the EYG reason
  `denied(effect, path)` rather than an OS error.

## Not this

Not the gate mechanism - `overlay.policy-gate` owns that, and
`packages/gleam_cli/src/eyg/cli/policy_runner.gleam` is the runner side. Not the
EYG language reference - `guides/pi_codemode_agent.md` is how to run such a session,
`guides/syntax.md` is the language.
