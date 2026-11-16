---
id: pi.codemode-gate
type: entity
owner: delegate
status: current
verified_at: 2026-11-16
verify: "test -f pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q -- '\"--policy\"' pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q 'join(dir, \"policies\", \"agent-roots.eyg\")' pi-eyg-codemode/extensions/eyg-codemode.ts && grep -q 'policy_runner.run(input, policy, config)' packages/gleam_cli/src/eyg_cli.gleam && grep -q 'defaultTools' .pi/settings.json && grep -q 'codemode_policy' entry.eyg && grep -q 'computer.Search(input)' packages/loam/src/loam/platform/computer.gleam && grep -q 'Search.*policy.PolicyField(\"read_file\")' packages/gleam_cli/src/eyg/cli/overlay.gleam"
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
- The defaults come from inside the installed package, so a first session configures
  nothing: `packageDir` resolves the package directory from `import.meta.url` (the module
  file the extension was loaded from), `defaultPolicy` is `join(dir, "policies",
  "agent-roots.eyg")`, and the roots default to the session working directory, exported as
  `EYG_ALLOWED_ROOTS` for the one call and restored after it. Resolution order is
  `policy` argument, `EYG_POLICY`, package default, and the tool says which one it used.
- The runner is probed, not assumed: a candidate is usable only if its `--help` advertises
  `--policy`, because the gate lives in the runner and the prebuilt release on `PATH`
  predates that flag. `EYG_CODEMODE_RUNNER` overrides the probe. Using a runner without
  the flag is both ungated and a mis-parsed argv - it reads `run` as a program path.
- Search has two routes. `pi-eyg-codemode/libraries/search.eyg` is search as a library,
  bound by the tool's `libraries` parameter as `<name>_lib`: it walks with `ReadDirectory`,
  so the policy gates every directory it opens and it cannot see outside the roots. The CLI
  runtime also has a `Search` effect, landed 2026-11-16: `computer.Search(input)` in
  `packages/loam/src/loam/platform/computer.gleam` (line 89, `search_the_tree`, depth cap 32)
  over the interface in `packages/touch_grass/src/touch_grass/file_system/search.gleam`
  (`label = "Search"`, `Input(path, pattern, limit)`, `lower() = Result(List(String), String)`),
  mapped in `packages/gleam_cli/src/eyg/cli/overlay.gleam` to the existing `read_file` policy
  field, so one host action is decided once by the same roots that gate reads and no new
  policy field exists. Both routes report names under an allowed root - including the name of
  a file a read of that path would be refused for - and never its contents.
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
