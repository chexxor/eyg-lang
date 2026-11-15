# Run a pi agent whose side effects are EYG effects only

A pi agent normally codes in JavaScript (`builtin:codemode`) and can call `bash`,
`edit`, `write` and `read`. This workspace runs the agent in EYG instead, through
`pi-eyg-codemode/`: the model gets one tool, `eyg`, and an EYG program reaches the
outside world **only** through effects, each decided by a host-side policy module
before the host performs it. A denied effect is an EYG error such as
`write_file denied by policy: /abs/path` and nothing happened on disk, so the
model can read the permission it was refused and act on it.

The runner that makes this possible is `packages/gleam_cli/src/eyg/cli/policy_runner.gleam`
(`eyg run --policy <module.eyg>`), described by
`docs/world/entities/overlay.policy-gate.md` and `docs/world/entities/cli.run-effect-path.md`.
The gate already existed; what this adds is installing it on the host side of a
one-shot run, because a policy written inside the program cannot constrain that
program (see `notes/pi_codemode_host_gate.md` for why).

## The gap, before the fix

A one-shot evaluation is not gated, and that is the trap this whole design works
around: `eyg run -c 'perform WriteFile({path: "/tmp/eyg-gap-proof/outside/escape.txt", ...})'` wrote
the file (8 bytes, 0.06 s wall `@measured 2026-11-15`) and an ungated `Fetch` through
`eyg_packages/http` wrote 577 bytes from `example.com` (1.46 s wall). Put in front of a
model, that is a program that can write anywhere this user can. The fix is not a policy
inside the program - the program that checks itself is the program that can skip the
check - it is starting the runner with rules: `--policy <module.eyg>`. `docs/world/traps.md`
carries the same fact with the command that re-proves it.

## Configure the session

`.pi/settings.json` in this repository does the tool selection:

```json
{
  "packages": ["../pi-simple-world-model", "../pi-eyg-codemode"],
  "extensions": ["-builtin:codemode"],
  "defaultTools": []
}
```

`defaultTools: []` removes every built-in tool (`read`, `bash`, `edit`, `write`,
`grep`, `find`, `ls`) - an empty array disables built-ins but not extension tools,
so the `eyg` tool from the package stays. `-builtin:codemode` disables the built-in
JavaScript codemode, so no script can reach an ungated tool.

Install it (0.30 s wall, `@measured 2026-11-15`):

```bash
pi install ./pi-eyg-codemode -l   # this project only
pi list                           # prints /home/chexxor/Git/eyg-lang/pi-eyg-codemode
```

`pi list` prints the resolved absolute path; the entry reads `../pi-eyg-codemode`
because a local package is written relative to `.pi/settings.json` (see
`docs/world/traps.md`).

Then point the tool at one policy for the session:

```bash
export EYG_CODEMODE_RUNNER=/home/chexxor/Git/eyg-lang/packages/gleam_cli/dist/eyg
export EYG_POLICY=/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg
export EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang,/tmp/agent-workspace
```

The prebuilt `eyg` on `PATH` is v0.1.0 and predates `--policy`, so set
`EYG_CODEMODE_RUNNER` to the binary built from this tree
(`packages/gleam_cli/bin/compile`, 0.82 s wall `@measured 2026-11-15`).
No roots means no roots: `agent-roots.eyg` refuses every file effect.

## One-shot session, and what it costs

`--print` is what makes pi run once; `pi --mode json` without it stays interactive
and never exits (see `docs/world/traps.md`). A session with a real model call is an
event, not a loop: 44 s for a two-call session, 142 s for a four-call one,
`@measured 2026-11-15` with `/usr/bin/time`.

```bash
pi --print --mode json --approve "write /tmp/agent-workspace/outside/probe.txt containing hello"
```

The tool call and its result are events in the stream; a refusal looks like:

```json
{"type":"tool_execution_end","toolName":"eyg",
 "result":{"content":[{"text":"eyg run: exit 1\nwrite_file denied by policy: /tmp/agent-workspace/outside/probe.txt"}],
 "details":{"gated":true,"ran":true,"exit":1,"policy":".../agent-roots.eyg"}}}
```

and the file does not exist, while a write under an allowed root returns
`eyg run: ran` and leaves the bytes on disk.

## The loops, with their cost

All costs are wall time from `/usr/bin/time`, `@measured 2026-11-15` on this host.

| loop | command | cost, wall |
| --- | --- | --- |
| one EYG expression | `eyg eval -c '!int_add(1, 1)'` | 0.06 s |
| one gated run (refusal) | `packages/gleam_cli/dist/eyg run --policy <module> -c '<write outside root>'` | 0.06-0.07 s |
| one ungated write | `eyg run -c '<WriteFile>'` | 0.06 s |
| the codemode package suite | `eyg script eyg_packages/codemode_policy/entry.eyg` | 2.3 s |
| the whole EYG suite | `eyg script entry.eyg` | 5.7 s (100 tests, 0 failed) |
| every committed policy rule needed? | `node scripts/mutation-check.mjs` | 13.5-15.4 s (6 suite runs) |
| the Gleam gate for the runner | `bash bin/agent/gate.sh gleam_cli` | 6.2-7.4 s (128 tests, `pass=2 fail=0 unverified=0 uncovered=0`) |
| the world model gate | `node pi-simple-world-model/bin/world_lint.mjs`, `world_map.mjs --check`, `pi --world-model-check` | 0.05 s, 0.05 s, 1.1 s |
| a live agent session | `pi --print --mode json --approve '<prompt>'` | 44-142 s - an event |

`gleam_cli` supports the javascript/bun target on this host; `erl` and `escript`
are absent, so a beam run of that gate is a missing Erlang runtime, not a code fault
(`docs/world/traps.md`).

## Reading a result

| result line | meaning |
| --- | --- |
| `eyg run: ran` | the program performed effects the policy allowed |
| `eyg run: exit 1` + `write_file denied by policy: <path>` | the policy refused; nothing on disk changed |
| `eyg run: exit 1` + `error: ...` | the program did not parse or failed; fix the program |
| `eyg refused: no policy module was configured` | the tool refuses to run anything ungated |

A refusal is a fact about the permission, not a crash: do not look for another
channel, there is none in this session. Change the path, the host, or report it.
A program that keeps going after a refusal must check its evidence with a later
`ReadFile`/`ReadDirectory` rather than assume either outcome.

## Writing the program

`skills/eyg-codemode/SKILL.md` carries the forms the model needs (`perform` with one
argument record, `let _ =` binding before a following expression, no infix operators).
`guides/syntax.md` and `guides/cli_effects_reference.md` are the language and effect
reference; `eyg_packages/overlay/policy.eyg` is the policy vocabulary.

`eyg_packages/codemode_policy/index.eyg` holds the presets to choose from:
`agent(roots)` read/write, `reader(roots)` read only, `fetching(roots, hosts)` opens
listed hosts over https, `service(roots, host, key, token, otherwise)` injects one
header on one host, `nothing` refuses everything. A token belongs in the policy module
- the policy is host authored and may read the environment, the program may not.

## Proving it

From the repository root, in this order (each measured above):

```bash
bash bin/agent/gate.sh gleam_cli                      # the runner builds and tests
eyg script entry.eyg                                  # the EYG suite, new package included
node scripts/mutation-check.mjs                       # every committed rule is necessary
pi --world-model-check                                # model lint, index, claims
```

`scripts/mutation-check.mjs` loosens one rule of
`eyg_packages/overlay/policy.eyg` at a time in a scratch copy and requires the
security suite to fail; it exits 0 only when the committed suite passes and every
loosening fails it, so a rule's necessity is a test, not a note.

## Limits

- The security suite asserts the decision the gate makes by calling the same policy
  functions the gate calls, plus real fixture evidence on disk; the host-side proof
  is the transcript above.
- `DecodeJSON`, `EYGParse`, `Hash` and `Sign` are `Unchecked` in
  `packages/gleam_cli/src/eyg/cli/overlay.gleam`: they are performed without asking
  the policy, so a preset cannot forbid them (`docs/world/traps.md`).
- Publishing a package, cutting a release or pushing remains the operator's act.
