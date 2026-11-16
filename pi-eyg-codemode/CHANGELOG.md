# Changelog

## 1.3.0 - 2026-11-16

- The tool renders like the built-in `bash` tool: `renderCall` and `renderResult` are
  registered on it, so the collapsed row names the effects the program performs plus the
  first 4 source lines, and `Ctrl+O` expands to the whole program and the whole output plus
  a policy/runner/roots provenance line. Wall time is in both the render and the model-facing
  status line (`ran in 0.81 s wall`, `timed out after 2 s in 2.01 s wall`), and a run that is
  still going answers `eyg running, 4.20 s so far`.
- The time knob is `timeout` in SECONDS (default 30, cap 120) as bash spells it. `timeout_ms`
  and `mode`, sent by sessions resumed from 1.2.0 and earlier, are mapped in `prepareArguments`
  rather than added to the schema the model sees; `EYG_CODEMODE_TIMEOUT` keeps its milliseconds,
  and the mismatch is stated in the README tables rather than silently renamed.
- A registry of re-usable EYG functions, read-only: one `.eyg` module per function-set with a
  `let metadata = {name, description, signature, effects}` record, scopes read in order
  workspace `<cwd>/.pi/eyg-functions` then home `$HOME/.pi/eyg-functions` then the package's
  own `libraries/`, first match wins and a shadow is reported. `action` selects `run` (default),
  `eval`, `list_functions` or `describe_function`; the same `libraries` parameter now resolves a
  registry name through that scope order, so `libraries: ["search"]` is unchanged. Declared
  effects are cross-checked against the `perform` names in the module, both directions are a
  registry error, and effect availability is re-probed at every query, is advisory, and does not
  block a run.
- `lib/render-helpers.mjs` holds the pure shapes (`callLines`, `resultLines`, `formatDuration`,
  `effectsUsed`, `findMetadata`, `checkDeclaredEffects`, `probeArguments`,
  `buildRegistry`, `prepareCallArguments`) and `test/render-helpers.test.mjs` asserts them -
  `node --test test/render-helpers.test.mjs`, 41 ms in process, pass 1 fail 0 on 2026-11-16.
  Plain JS, not TS: jiti does not transform a `.mjs`, so an annotation in it is a parse error
  at load.
- Tried and rejected: availability probes at `/dev/null` (the agent preset refuses every path
  probe, so a root-relative probe is what makes `ReadDirectory` read as `available` in a session
  that can read); `MAX_TIMEOUT_MS` left in the new constants, which the tool's own output caught
  as `MAX_TIMEOUT_MS is not defined`; testing `code === 0` before `killed` for a timed-out run,
  which pi reports with both.
- The gate for this package is still SKIP in `bin/agent/gate.sh`: it walks `packages/*/` and
  `eyg_packages/` and this package sits at the repository root as a pi package. The loops that
  did run are the `node --test` above, `pi --world-model-check` (lint clean, 36 claims, 0 failing)
  and fresh headless `pi -p --no-session --no-builtin-tools --tools eyg` runs, quoted verbatim in
  `README.md`.

## 1.2.0 - 2026-11-16

- The `Search` effect exists in the CLI runtime, so the tool and the skill ask for it
  before the library: `perform Search({path, pattern, limit})` answers absolute paths in
  one host action, and the policy decides the whole walk under its `read_file` rule
  (`packages/gleam_cli/src/eyg/cli/overlay.gleam`). The walk itself is a change outside
  this package - `packages/loam/src/loam/platform/computer.gleam` (`search_the_tree`,
  `search_max_depth = 32`) over the interface published in `touch_grass` 0.4.4 - made the
  same day, with tests in `packages/loam/test/computer_test.gleam`; `README.md` names the
  route, the gate run for it, and the boundary a search keeps: names under an allowed root
  come through, contents never do.
- `libraries/search.eyg` remains the route for a runtime that lacks the effect: one import,
  and the same roots rule gates every directory it opens.

## 1.1.0 - 2026-11-16

- Defaults, so a first session configures nothing: the policy is resolved inside the
  installed package (`packageDir`, `defaultPolicy` in `extensions/eyg-codemode.ts`) rather
  than requiring `EYG_POLICY`, and the roots default to the session working directory,
  passed to the preset as `EYG_ALLOWED_ROOTS` for one call and restored after it.
- The runner is probed, not assumed (`resolveRunner`): a runner is usable only if its help
  text advertises `--policy`, because the gate lives in the runner and the prebuilt CLI
  release predates that flag. The old default, `eyg` on `PATH`, used to hand `run` to that
  release as a program path (`error: no such file: <cwd>/run`) and run the program ungated.
- `libraries/search.eyg` and a `libraries` tool parameter: search is a library over
  `ReadDirectory`, bound as `search_lib`, and the effects it performs go through the policy
  like the program's own.
- `README.md` carries a worked transcript copied from runs on 2026-11-16, the defaults
  table (each row names the file its default comes from), and why permissioning at the
  effect level is the point.

## 1.0.0 - 2026-11-15

- First release: one tool, `eyg`, that runs EYG source through the gated CLI runner
  (`packages/gleam_cli/src/eyg/cli/policy_runner.gleam`, `eyg run|eval|script --policy <module.eyg>`).
  Every effect of the program is decided by the host policy module before the host
  performs it, so this package has no shell, no file editor and no JavaScript sandbox.
- `policies/agent-roots.eyg` is a policy preset built from
  `eyg_packages/overlay/policy.eyg`: `agent(roots)` allows reading and writing inside
  `EYG_ALLOWED_ROOTS` and refuses everything else, including every `.env.eyg`.
- `skills/eyg-codemode/SKILL.md` carries the EYG forms the model needs (`perform` with
  one argument, `let _ =` binding, no infix operators) and what a refusal means.
- The tool refuses to run anything when no policy module is configured: a session
  cannot fall back to an ungated run.
- `pi.exec` is used with argv, not a shell, so no quoting can smuggle a second command
  past the policy.
