# pi-eyg-codemode

A pi package: the agent's coding tool is EYG, and an EYG program reaches the outside
world only through effects, each decided by a host-side policy module before the host
performs it. See `guides/pi_codemode_agent.md` in this repository for how to run such a
session, and `docs/world/entities/pi.codemode-gate.md` for the claim behind it.

## What it installs

| path | what |
| --- | --- |
| `extensions/eyg-codemode.ts` | registers the one tool, `eyg`, and spawns the gated runner through argv (no shell) |
| `policies/agent-roots.eyg` | a policy preset built from `eyg_packages/overlay/policy.eyg` over `EYG_ALLOWED_ROOTS` |
| `skills/eyg-codemode/SKILL.md` | the EYG forms and the meaning of a refusal, loaded when the model writes EYG |

## Install

```bash
pi install ./pi-eyg-codemode -l   # this project only
pi list                           # prints /home/chexxor/Git/eyg-lang/pi-eyg-codemode
```

`.pi/settings.json` then carries the tool selection (`../pi-eyg-codemode` in
`packages`, `-builtin:codemode` in `extensions`, `defaultTools: []` to remove the
built-in `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`).

## Environment

| variable | meaning |
| --- | --- |
| `EYG_POLICY` | absolute path to the policy module; unset means the tool refuses to run anything |
| `EYG_CODEMODE_RUNNER` | the runner binary; default `eyg` on `PATH`. The prebuilt v0.1.0 binary predates `--policy`, so point this at `packages/gleam_cli/dist/eyg` |
| `EYG_ALLOWED_ROOTS` | comma-separated absolute roots the preset allows; empty means no roots |
| `EYG_CODEMODE_TIMEOUT` | milliseconds, default 30000, capped at 120000 |

## A refusal, as the model sees it

```
eyg run: exit 1
write_file denied by policy: /tmp/agent-workspace/outside/probe.txt
```

Nothing was written: the policy answered the effect and the host never performed it.
The reason names the effect and the resolved absolute path.

## Not this package

The gate itself lives in the language: `packages/gleam_cli/src/eyg/cli/overlay.gleam`
(`rule_mapping`) and `packages/overlay/src/overlay/policy.gleam` (`decide`). The policy
vocabulary lives in `eyg_packages/overlay/policy.eyg` and the presets an agent picks
from in `eyg_packages/codemode_policy/index.eyg`. Their security suite is
`eyg_packages/codemode_policy/test/security_test.eyg`.
