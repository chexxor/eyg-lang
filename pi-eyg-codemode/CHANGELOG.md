# Changelog

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
  like the program's own. No effect was added to the language - a search effect would be a
  change to `packages/loam/src/loam/platform/computer.gleam`, which is not this package's
  to make; `README.md` names the route and the gate for that change.
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
