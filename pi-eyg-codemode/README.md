# pi-eyg-codemode

A pi package: the agent's coding tool is EYG, and an EYG program reaches the outside
world only through effects, each decided by a host-side policy module before the host
performs it. One tool, `eyg`, replaces `read`, `edit`, `write`, `bash`, `grep`, `ls`.

See `guides/pi_codemode_agent.md` in this repository for how to run such a session, and
`docs/world/entities/pi.codemode-gate.md` for the claim behind it.

## First session, nothing to configure

```bash
pi install ./pi-eyg-codemode -l   # this project only
pi list                            # prints /home/chexxor/Git/eyg-lang/pi-eyg-codemode
```

That is all. The tool resolves its own defaults from inside the installed package, so a
call with no `policy` argument and no `EYG_POLICY` runs the policy this package ships
(`policies/agent-roots.eyg`) over the session working directory: a program can read and
write inside that directory and nothing else. A program is never run without a policy -
an ungated run performs every effect the host can reach, and the tool refuses instead.

What the session shows, copied from `eyg` tool calls made on 2026-11-16 with no
`policy` argument. The fenced blocks are the tool results verbatim. Before 1.3.0 the
status line was `eyg run: ran`; it now carries wall time as well (`eyg run: ran in 0.09 s wall`),
so the blocks below show the older, shorter status line and the same output.

Find files under the session root - `libraries: ["search"]`, so `search_lib` is bound:

```
eyg run: ran
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries/search.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/deny-all.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg
```

Read a tracked file and try to write outside the session root, one call (`mode run`,
the program prints the value of each effect):

```
eyg run: ran
READ FIRST LINE: ![penelopea mascot for EYG](https://eyg.run/assets/pea.8C463682609CAA4A5A638D66BWRITE REFUSED: write_file denied by policy: /tmp/eyg-codemode-outside-root/probe.txt
```

Nothing exists at `/tmp/eyg-codemode-outside-root` - checked with `ls -la` on 2026-11-16,
which printed `ls: cannot access '/tmp/eyg-codemode-outside-root': No such file or
directory`. The read is the first line of this repository's `README.md`, so the gate let
the read through and refused the write in the same program; `eyg run: ran` is the status of
the program, not evidence that the write happened.

The commands below are the same calls at the argv level, which is what the tool spawns and
what you can run in a shell. Each `$` line is that command and what follows is its output,
verbatim.

Read a file inside the session root:

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg -c <program>  (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
![penelopea mascot for EYG](https://eyg.run/assets/pea.8C463[exit=0]
```

```eyg
let r = perform ReadFile({path: "/home/chexxor/Git/eyg-lang/README.md", offset: 0, limit: 60})
match r {
  Ok(bytes) -> { match !string_from_binary(bytes) { Ok(text) -> { perform StandardOut(text) } Error({}) -> { perform StandardOut("not utf8") } } }
  Error(reason) -> { perform StandardOut(reason) }
}
```

Write inside the roots, then delete it, so the tree is unchanged after the proof:

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg -c <program>  (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
writtendeleted again[exit=0]
```

```eyg
let w = perform WriteFile({path: "/home/chexxor/Git/eyg-lang/.eyg-codemode-probe.txt", contents: !string_to_binary("inside the roots\n")})
let _ = perform StandardOut(match w { Ok({}) -> { "written" } Error(reason) -> { reason } })
let d = perform DeleteFile("/home/chexxor/Git/eyg-lang/.eyg-codemode-probe.txt")
perform StandardOut(match d { Ok({}) -> { "deleted again" } Error(reason) -> { reason } })
```

Write outside the roots:

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg -c <program>  (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
write_file denied by policy: /tmp/eyg-codemode-outside-root/probe.txt[exit=0]
```

```eyg
let w = perform WriteFile({path: "/tmp/eyg-codemode-outside-root/probe.txt", contents: !string_to_binary("escaped\n")})
perform StandardOut(match w { Ok({}) -> { "written - the gate failed" } Error(reason) -> { reason } })
```

```
$ ls -la /tmp/eyg-codemode-outside-root
ls: cannot access '/tmp/eyg-codemode-outside-root': No such file or directory
```

Find files under the roots - the package's library, not a new effect:

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg -c <program>  (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
/home/chexxor/Git/eyg-lang/spaces/oss/kagi.eyg
/home/chexxor/Git/eyg-lang/spaces/oss/.overlay.eyg
/home/chexxor/Git/eyg-lang/entry.eyg
/home/chexxor/Git/eyg-lang/.admin.eyg
[exit=0]
```

```eyg
let search_lib = import "/home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries/search.eyg"
let found = search_lib.search({root: "/home/chexxor/Git/eyg-lang", pattern: "**/*.eyg", limit: 4})
let text = !list_fold(found, "", (p, acc) -> { !string_append(acc, !string_append(p, "\n")) })
perform StandardOut(text)
```

In the tool you do not write the import: pass `libraries: ["search"]` and call
`search_lib.search({root, pattern, limit})`.

Two things the transcript shows rather than asserts. A program in `run` mode prints only
what it asks to print - a trailing value is not shown, so end a program with
`perform StandardOut(...)`. And a statement that is followed by another `let` must be
bound (`let _ = perform StandardOut(...)`), which is why the second program has one
`let _` and the others do not need it.

## What the tool decides

| knob | default | the default comes from |
| --- | --- | --- |
| policy module | `policies/agent-roots.eyg` inside the installed package, path resolved from the module file the extension was loaded from | `extensions/eyg-codemode.ts` (`packageDir`, `defaultPolicy`) |
| roots | the session working directory, passed to the policy as `EYG_ALLOWED_ROOTS` | `extensions/eyg-codemode.ts`; the preset reads the variable in `policies/agent-roots.eyg` |
| runner | first candidate that accepts `--policy`, probed once per session: `eyg` on `PATH`, then `packages/gleam_cli/dist/eyg` in the working directory | `extensions/eyg-codemode.ts` (`resolveRunner`, `PROBE_TIMEOUT_MS`) |
| mode | `run`; `eval` is pure and prints the value | `extensions/eyg-codemode.ts` |
| timeout | 30 s, capped at 120 s; the parameter is `timeout` in SECONDS, so `timeout: 90` is ninety seconds | `extensions/eyg-codemode.ts` (`DEFAULT_TIMEOUT_S`, `MAX_TIMEOUT_S`) |
| argv | `[mode, "--policy", policy, "-c", code]`, spawned with no shell | `extensions/eyg-codemode.ts` |

| environment variable | meaning when set |
| --- | --- |
| `EYG_POLICY` | absolute path to another policy module for the session |
| `EYG_ALLOWED_ROOTS` | comma-separated absolute roots, replacing the session directory as the default roots |
| `EYG_CODEMODE_RUNNER` | absolute path to a runner that accepts `--policy` |
| `EYG_CODEMODE_TIMEOUT` | milliseconds for one call (the variable keeps its ms, the parameter does not) |

The runner matters because the gate is in the runner: a runner without `--policy`
performs every effect, so a tool that used one would be a tool with no gate. The CLI at
`~/.local/bin/eyg` on this host is the prebuilt release, whose help text has no
`--policy` flag; probing rather than assuming is what keeps that from being used
silently. Build the current one (`guides/install_from_source.md`) or point
`EYG_CODEMODE_RUNNER` at it.

## Why permissioning at the effect level is the point

The set of effects a program can name is not the set of effects it may perform. The
runtime declares what exists - `packages/touch_grass/src/touch_grass/harness/computer.gleam`
lists `AppendFile`, `CreateKey`, `Cwd`, `DecodeJson`, `DeleteFile`, `Env`, `Exit`,
`EygParse`, `Fetch`, `Flip`, `Hash`, `MakeDirectory`, `Now`, `Random`,
`ReadDirectory`, `ReadFile`, `Search`, `Sign`, `Sleep`, `StandardError`, `StandardIn`,
`StandardOut`, `WriteFile` - and the policy decides, per effect and per call, before the
host performs it. `Search` is listed there today because the walk was landed in the CLI
runtime on 2026-11-16; it is gated by the `read_file` field, so the roots that gate reads
are the roots a search may walk. Three consequences of that split, none of which a tool of the first
kind (a tool that performs a named action) can have:

- **A denial is a value, not a crash.** The program continues with `Error(reason)`, so it
  can report the refusal, ask for a different path, or stop and tell the operator to widen
  the roots. The agent's reasoning survives the boundary.
- **Roots compose with effects.** `read_file` under one root, `write_file` under a
  narrower one, `fetch` refused: one sentence in a policy, and the same effect names mean
  different things in different sessions. That is the whole configuration surface a
  workspace needs, and it is expressible in EYG rather than in a host capability flag.
- **An effect the policy refuses is invisible, not half-done.** Nothing was written above;
  the host never performed the effect, so there is no partial state for the agent to clean
  up and no window in which the tool trusted a file that was not there.

`notes/pi_codemode_host_gate.md` records the trade-off: a policy inside the program is a
suggestion, since the program cannot be trusted to consult it. The gate is the runner's
`--policy` argument, which the program cannot change and cannot reach.

## Configuring effects for a pi session

Write a preset from the vocabulary in `eyg_packages/overlay/policy.eyg`, then point the
session at it. This one reads the repository, writes only inside `notes/`, and refuses
everything else:

```eyg
let policy = import "../../eyg_packages/overlay/policy.eyg"

policy.read_write(["/home/chexxor/Git/eyg-lang/notes"])
```

```bash
export EYG_POLICY=/abs/path/to/your/preset.eyg   # absolute; a relative path is refused
```

Each effect has one field in the record the preset builds, so a policy that names an
effect either passes it, mocks it, or gates it by path. The fields, as mapped in
`packages/gleam_cli/src/eyg/cli/overlay.gleam` (`rule_mapping`):
`append_file`, `create_key`, `cwd`, `delete_file`, `env`, `exit`, `fetch`, `flip`,
`make_directory`, `now`, `random`, `read_directory`, `read_file`, `sleep`,
`standard_error`, `standard_in`, `standard_out`, `write_file`. Two shapes matter when you
gate by path: `read_directory`, `delete_file` and `make_directory` carry a bare path
string, `read_file`, `write_file` and `append_file` carry a record with a `path` field -
which is why the vocabulary has both a `path` accessor and a `request_path` one.

Presets to start from, with the security suite that checks them:
`eyg_packages/codemode_policy/index.eyg` and
`eyg_packages/codemode_policy/test/security_test.eyg`. `policies/agent-roots.eyg` in this
package is one of them, built with `policy.read_write(roots)`; `policies/deny-all.eyg` is
the narrowest. Secret files (`.env.eyg` by convention) are never readable even inside a
root, and network access is refused by this preset - `policy.fetch_hosts(hosts)` and
`policy.with_header(host, key, value, otherwise)` are the ways to open those, per
`guides/pi_codemode_agent.md`.

## Finding files

Two routes, and the one you use depends on the runtime, not on the question.

**The `Search` effect**, implemented in the CLI runtime (`packages/loam/src/loam/platform/computer.gleam`,
`search_the_tree`) on top of the interface published in `touch_grass` 0.4.4
(`packages/touch_grass/src/touch_grass/file_system/search.gleam`). One host action, one
policy decision:

```eyg
perform Search({path: "/abs/root", pattern: "**/*.eyg", limit: 20})
// -> Ok(List(String)) of absolute paths, or Error(String)
```

- matching is over the path relative to `path`: one `*` per segment (text before it is a
  prefix, text after it a suffix), a whole `**` segment spans depths, anything else
  compares equal, case sensitive, no character classes or alternation;
- the paths are absolute, so one answer can be handed straight to `ReadFile`;
- `limit` is a budget spent while walking, not a slice taken afterwards;
- a directory the walk cannot read contributes nothing, so a search reports what the
  policy let it see rather than failing;
- the walk is capped at 32 directories deep (`search_max_depth` in that file).

The policy decides the walk once, under the `read_file` field
(`packages/gleam_cli/src/eyg/cli/overlay.gleam`), which is what the transcript below shows:

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg /tmp/eygsearch/search-inside.eyg   (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
ok: /home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries/search.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/deny-all.eyg
[exit=0]
```

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg /tmp/eygsearch/search-outside.eyg   (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
read_file denied by policy: /tmp/eygsearch[exit=0]
```

```
$ eyg run --policy /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/deny-all.eyg /tmp/eygsearch/search-inside.eyg   (EYG_ALLOWED_ROOTS=/home/chexxor/Git/eyg-lang)
read_file denied by policy[exit=0]
```

The refused walk came back as a value the program printed, with exit 0, and touched nothing:
the whole tree under `/tmp/eygsearch` is the two programs themselves.

**The library** (`libraries/search.eyg`, bound as `search_lib` by the `libraries` parameter)
walks with `ReadDirectory` instead, so it works on any runtime that has that effect and its
pattern semantics are its own, written in the file. It is one import and no toolchain change;
the policy checks every directory it opens, one decision per directory instead of one per
walk.

One boundary both routes share, and it is worth stating because it surprises people: a
search reports **names** under an allowed root, including the name of a file a read would
be refused for. Measured today under the agent preset over a directory holding only `.env.eyg`:

```
read_file denied by policy: /home/chexxor/Git/eyg-lang/.search-proof/.env.eyg
/home/chexxor/Git/eyg-lang/.search-proof/.env.eyg
```

The first line is the refused `ReadFile`, the second is `Search` naming the same path. Contents
never come through a search, so a secret is not readable through it; its existence and name
are. A policy that must hide names roots the search narrower, or maps `Search` to its own
`search` field wrapped like `policy.hide_secrets` wraps `read_file` in
`eyg_packages/overlay/policy.eyg`.

The proof directory `.search-proof` was created inside the roots by the same gated program
and deleted after it; `git status --short` showed nothing for it afterwards.

## Where a new effect goes

An effect is a change to the language, not to this package: `AGENTS.md` names it as an
escalation (a rationale that the effect is general, and the operator's decision). `Search`
was landed here on 2026-11-16 in those files, and the route is what you need to repeat it:

- `packages/loam/src/loam/platform/computer.gleam` - the CLI runtime's `extrinsic`, where
  every CLI effect is implemented. `computer.Search(input) ->` sits between `ReadFile` and
  `Sign` (line 89 today) and delegates to `search_the_tree` in the same file.
- `packages/touch_grass/src/touch_grass/harness/computer.gleam` and
  `packages/touch_grass/src/touch_grass.gleam` - the interface and the effect union the
  toolchain declares; `packages/touch_grass/src/touch_grass/file_system/search.gleam` is
  where `label = "Search"`, `Input(path, pattern, limit)`, `lift`/`lower` and `matches` live.
- `packages/gleam_cli/src/eyg/cli/overlay.gleam` (`rule_mapping`) - the effect-to-policy-field
  map. `Search` maps to the existing `read_file` field, so a search is gated by exactly the
  roots that gate reads and no new policy field was invented.
- tests in `packages/loam/test/computer_test.gleam` and the package's own test module.

What the gates printed on 2026-11-16, and what they do not cover:

```
$ bash bin/agent/gate.sh touch_grass loam gleam_cli pi-eyg-codemode
== touch_grass  targets: beam javascript
error: Program not found

The program `escript` was not found. Is it installed?

   Compiled in 0.44s
   Compiled in 0.07s
    Running touch_grass_test.main
24 passed, no failures
   PASS
== loam  UNCOVERED (not in either CONTRIBUTING.md loop; run its own gleam test)
== gleam_cli  targets: javascript
   Compiled in 1.40s
   Compiled in 0.18s
    Running eyg_cli_test.main
128 passed, no failures
   PASS
== pi-eyg-codemode  SKIP (no such package directory)
note  gleam is installed but escript is not, so a beam FAIL above is a missing Erlang/OTP
      runtime on this host - guides/install_from_source.md, not a code fault
gate summary: pass=3 fail=0 unverified=0 uncovered=1 in 11s
```

Read that output as: the `beam` target of `touch_grass` did not build on this host
(`escript` absent, so `gleam build --target beam` stops), while its `javascript` target
compiled and its 24 tests passed; `gleam_cli` compiled and its 128 tests passed, which is
the suite that covers `overlay.gleam`'s mapping. `loam` is UNCOVERED by the gate, so its
own loop was run by hand and printed `Compiled in 0.20s` (build, `--warnings-as-errors`,
exit 0) and `40 passed, no failures` (test). `pi-eyg-codemode` prints SKIP because
`bin/agent/gate.sh` walks `packages/*/` and `eyg_packages/` only, and this package is a pi
package at the repository root - the same command on its own printed the SKIP line plus
the EYG suite (`== eyg_packages ... 100 passed, 0 failed`, `gate summary: pass=1`), whose
`codemode_policy` tests are the package's presets. So the package's own gate is
`eyg script entry.eyg` (exit 0, 100 passed, 0 failed, 5.6 s wall on 2026-11-16) and the
tool-level behaviour is the argv evidence above, not a Gleam suite.

Why that change is visible where it is, and where it is not. The interface is not this
package's to invent: the `Search` effect is declared and its shape fixed by the published
`touch_grass` 0.4.4 (`label = "Search"`, `Input(path, pattern, limit)`,
`lower() = Result(List(String), String)`, and `matches`), so what was missing was the runtime
walk plus the wiring. Two facts decide where such a change is visible:

- `packages/loam/manifest.toml:56` resolves `touch_grass` with `source = "hex"` (declared at
  `packages/loam/gleam.toml:32` as `touch_grass = ">= 0.4.4 and < 1.0.0"`), so `gleam build`
  in `loam` compiles the published artifact, not the local tree;
- `packages/gleam_cli/manifest.toml:107` resolves it as `touch_grass = { path = "../touch_grass" }`,
  so building the CLI compiles the local tree - which is why a local `touch_grass/` copy that
  predates the published 0.4.4 fails a CLI build (the local copy had no `file_system/search.gleam`
  before today and was synced to the published module, byte identical).

`gleam 1.19.2` has `compile-package` and no `local-packages` subcommand, so the offline way
to see a new `touch_grass` module is the CLI build, which resolves it by path; publishing a
new version, or restating the dependency as a path dependency, is what makes a standalone
`loam` build agree, and both are the operator's decision. The effect landed on 2026-11-16 and
the CLI runner was rebuilt with `packages/gleam_cli/bin/compile` (exit 0, `bundle 335 modules`,
`compile ./dist/eyg`); the transcripts above are that runner.

## How the session shows a call, and how long it took

One tool call is one row, and it renders the way the built-in `bash` tool does: a
short row by default, and pi's `Ctrl+O` toggle (or a click) expands it into the
whole thing.

| view | what the renderer puts in the call row | what it puts in the result row |
| --- | --- | --- |
| collapsed (default) | `performs: <effect names>` in the order they appear, then the first 4 lines of the program, then `... N more lines` | the status line (with wall time), plus `(N output lines)` |
| expanded | every line of the program, and no `... more lines` marker | the status line, then every line of the output, then a `policy: <path> (<source>) runner: <path> roots: <path>` line |

The effects a program performs are in the collapsed row on request: which effects a
program may ask the policy about is the fact a reader needs before reading the source,
and the policy then decides each one. The scan is textual - a `perform` followed by a
capitalised name - so a comment that names `perform ReadFile` counts too. That is the
safe direction: an over-estimate never hides an effect a program can ask for.

Wall time is stated in both places, and always labelled as wall time:

- the model-facing status line: `eyg run: ran in 0.81 s wall`, `eyg eval: ran in 0.09 s wall`,
  `eyg run: timed out after 2 s in 2.01 s wall`, `eyg run: exit 1 in 0.12 s wall`;
- the same duration in the render, taken from pi's own `context.durationMs` when it has one
  and otherwise from the tool's measurement of the spawn (`details.durationMs`) - the
  number the status line was built from, so the two agree;
- the shape of the duration: `1.24 s` under a minute, `2:03` past one, `1:02:03` past an
  hour (`formatDuration` in `lib/render-helpers.mjs`);
- a run that is still going answers `eyg running, 4.20 s so far` rather than a silent row.

The two blocks below are the tool results of those two calls, verbatim, from fresh
headless `pi -p` runs on 2026-11-16 (the first asked for `timeout: 2` and slept 5000 ms,
the second for the default 30 s and slept 700 ms):

```
eyg run: timed out after 2 s in 2.01 s wall
```

```
eyg run: ran in 0.81 s wall
done
```

Which row carries which line, collapsed and expanded, lives in `lib/render-helpers.mjs`
as `callLines` and `resultLines`, each a list of `{tone, text}` segments. `extensions/eyg-codemode.ts`
only maps those tones onto the theme, so the shapes a test asserts are the shapes the tool
renders, and neither can drift from the other. That is the offline loop for the renderer:

```
$ cd pi-eyg-codemode && node --test test/render-helpers.test.mjs
✔ test/render-helpers.test.mjs (41.431823ms)
ℹ tests 1
ℹ suites 0
ℹ pass 1
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 50.187198
```

0.09 s wall for the run, 41 ms in process. What the test does not show is that pi paints
the row from those shapes - for that an operator has to run a session and press `Ctrl+O`.

### The time limit, spelled like bash

The parameter is `timeout` in **seconds**, so `timeout: 90` asks for ninety seconds like
the bash tool does. Default 30 s, cap 120 s, floor 100 ms. `EYG_CODEMODE_TIMEOUT` stays in
milliseconds - it is an environment variable this package has shipped since 1.1.0, and
renaming its unit would break the sessions that already set it; the mismatch is stated in
both tables above rather than quietly fixed.

`timeout_ms` and `mode` are what a session resumed from an earlier version of this package
sends. They are mapped in `prepareArguments` (`prepareCallArguments` in
`lib/render-helpers.mjs`) before schema validation, so neither deprecated field appears in
the schema the model sees; every other key is carried over unchanged, so a misspelt field
still reaches validation as an error the model can fix.

## Re-usable functions

A re-usable function is a module someone wrote - not an effect, not a language feature,
not something this tool creates. One `.eyg` file is one function-set, and the record it
carries is what the listing reads:

```eyg
let tidy = (text) -> {
  !string_replace(!string_replace(text, "\n\n", "\n"), "  ", " ")
}

let metadata = {
  name: "tidy",
  description: "Collapse doubled spaces and blank lines in `text`; a pure computation, so it needs no effects.",
  signature: "tidy_lib.tidy(text) -> String",
  effects: []
}

{tidy}
```

The tool **reads** the registry scopes and never writes, moves or creates anything in
them; a function-set is authored with the ordinary effects the session already has. There
is no EYG parser in this process, so the record is read by a deliberately narrow scan -
one key per line, strings in double quotes, `effects` a list of double-quoted names - and
a module written in another shape is reported as a registry error rather than misread.

| scope | directory | what it is for |
| --- | --- | --- |
| workspace | `<cwd>/.pi/eyg-functions/` | the default: a function the agent wrote for this workspace |
| home | `$HOME/.pi/eyg-functions/` | the same function sets, in every workspace on this machine |
| package | `<the installed package>/libraries/` | what this package ships, e.g. `search` |

Scopes are read in that order and **first match wins**: a name defined in the workspace
and in home resolves to the workspace module, and the shadowed module is reported rather
than dropped silently, so an agent that redefined a home function in its workspace can see
what happened.

`action: list_functions` lists them (`code: ""` is enough - a registry query needs no
program); `action: describe_function` with `function: "<name>"` prints one of them. The
metadata `name` is the entry point: `libraries: ["tidy"]` binds `tidy_lib` by importing
that module's absolute path through the same scope order, so `libraries: ["search"]` keeps
working exactly as before and a workspace module shadows the package one. A name that
resolves in no scope is refused rather than ignored, so the program the user sees does not
fail on an unbound name for a reason they cannot act on.

The listing below is verbatim, from a fresh `pi -p` run on 2026-11-16 with one workspace
module, one home module of the same name and the package's `search` present - it names
the three scopes, resolves the clash to the workspace one, reports the shadow, and costs
0.23 s wall (the header prints the cost, since a listing re-probes the effects):

```
eyg list_functions: 2 functions in 0.23 s wall

scopes read in order, first match wins: workspace /home/chexxor/Git/eyg-lang/.pi/eyg-functions, home /home/chexxor/.pi/eyg-functions, package /home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries
this tool never writes a registry scope; a function-set is one .eyg module with a
`let metadata = {name, description, signature, effects}` record, written by whoever
needs it with ordinary effects.

tidy  [workspace] /home/chexxor/Git/eyg-lang/.pi/eyg-functions/tidy.eyg
  signature: tidy_lib.tidy(text) -> String
  description: Collapse doubled spaces and blank lines in `text`; a pure computation, so it needs no effects.
  effects: (none)

search  [package] /home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries/search.eyg
  signature: search_lib.search({root, pattern, limit}) -> List(String)
  description: Absolute paths of the files under `root` whose path relative to it matches `pattern` (`*.eyg`, `README*`, one `*` at most), at most `limit` of them, in the order the walk found them. Every directory it opens is checked by the policy, so it reaches no further than a hand written walk over the same roots.
  effects: ReadDirectory (available)

registry error: /home/chexxor/.pi/eyg-functions/tidy.eyg: tidy is shadowed by /home/chexxor/Git/eyg-lang/.pi/eyg-functions/tidy.eyg

availability is advisory: it was re-probed against /home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg for this listing,
and running a function whose effect is refused is not blocked - the refusal is the
ordinary Error("<field> denied by policy: ...") value inside the program.
```

Besides the description, the listing answers two questions per function-set:

- **the effects it needs**, cross-checked against the `perform` names in the module's own
text, in both directions and neither a silent pass: `performs WriteFile but does not
declare it` is an effect a caller needs and the listing would not have warned about, and
`declares Fetch but the body does not perform it` is an annotation that went stale.
- **whether the policy in force can perform each of them** - `available`, `refused by the
policy in force`, `not implemented by this runner`, or `unknown` with the reason. The probe
asks with arguments that can change nothing (`probeArguments` in `lib/render-helpers.mjs`):
a read, a search or a delete names `<root>/.eyg-codemode-probe`, a path that does not exist;
a write names `<root>` itself, a directory, so opening it to write errors; `MakeDirectory`
names `<root>`, which already exists, so it succeeds and creates nothing; `Fetch` names a
host under the reserved TLD `.invalid`, which can never resolve; `Env`, `Exit` and `StandardIn`
are never attempted and report `unknown`, because they would read the caller's environment,
stop the probe, or swallow the runner's stdin. Probes are written against the first root the
tool advertises, not against a fixed path: an earlier version probed at `/dev/null`, and the
agent preset refused every path probe, so `ReadDirectory` read as "refused" in a session that
can read - the question a listing answers is whether the session can perform the effect, not
whether it can perform it at an impossible path.
- **availability is advisory, and re-probed at every registry query**, because the policy in
force can change between calls. It is not a gate: running a function whose effect the probe
called refused is not blocked, and the run gets the ordinary `Error("<field> denied by policy:
...")` value - the same answer the program gets for any effect it asks for. A second gate in
the listing would be a second answer to the same question, and it would disagree with the
runner's. `notes/pi_codemode_registry_probe.md` records that trade-off.

## Not this package

The gate itself lives in the language: `packages/gleam_cli/src/eyg/cli/overlay.gleam`
(`rule_mapping`) and `packages/overlay/src/overlay/policy.gleam` (`decide`). The policy
vocabulary lives in `eyg_packages/overlay/policy.eyg` and the presets an agent picks
from in `eyg_packages/codemode_policy/index.eyg`. Their security suite is
`eyg_packages/codemode_policy/test/security_test.eyg`. This package chooses a preset,
resolves a runner and a working directory, and ships a library; it decides nothing about
what an effect may do.

## What it installs

| path | what |
| --- | --- |
| `extensions/eyg-codemode.ts` | registers the one tool, `eyg`, resolves defaults from inside the package, spawns the gated runner through argv (no shell), renders the call and result rows, and reads the registry scopes |
| `policies/agent-roots.eyg` | the default preset: files under `EYG_ALLOWED_ROOTS`, nothing else |
| `policies/deny-all.eyg` | the narrowest preset, for a session that may only compute |
| `libraries/search.eyg` | a search helper over `ReadDirectory`, bound as `search_lib` by the `libraries` parameter; carries the `metadata` record the registry reads |
| `lib/render-helpers.mjs` | the pure parts the tool and its tests share: the render shapes, the effect scan, the availability-probe arguments, the registry walk, the argument mapping; plain JS, because jiti does not transform a `.mjs`, so it carries no type annotations |
| `test/render-helpers.test.mjs` | the unit test over those shapes - `node --test test/render-helpers.test.mjs`, 41 ms in process (pass 1, fail 0, 2026-11-16) |
| `skills/eyg-codemode/SKILL.md` | the EYG forms, the meaning of a refusal, and how to ask the registry before writing a helper, loaded when the model writes EYG |
