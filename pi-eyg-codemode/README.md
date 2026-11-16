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

What the session shows, copied from three `eyg` tool calls made on 2026-11-16 with no
`policy` argument. The fenced blocks are the tool results verbatim.

Find files under the session root - `libraries: ["search"]`, so `search_lib` is bound:

```
eyg run: ran
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/libraries/search.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/deny-all.eyg
/home/chexxor/Git/eyg-lang/pi-eyg-codemode/policies/agent-roots.eyg
```

Read a file inside the session root:

```
eyg run: ran
![penelopea mascot for EYG](https://eyg.run/assets/pea.8C463
```

Write outside it - `mode run`, program `let w = perform WriteFile({path:
"/tmp/eyg-codemode-outside-root/probe.txt", contents: !string_to_binary("escaped\n")})`
then `perform StandardOut` of the value of `w`:

```
eyg run: ran
write_file denied by policy: /tmp/eyg-codemode-outside-root/probe.txt
```

Nothing exists at `/tmp/eyg-codemode-outside-root`; the refusal is the value the program
printed, and `eyg run: ran` means the program ran to its end, not that the write happened.

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
| timeout | 30000 ms, capped at 120000 ms | `extensions/eyg-codemode.ts` (`DEFAULT_TIMEOUT_MS`, `MAX_TIMEOUT_MS`) |
| argv | `[mode, "--policy", policy, "-c", code]`, spawned with no shell | `extensions/eyg-codemode.ts` |

| environment variable | meaning when set |
| --- | --- |
| `EYG_POLICY` | absolute path to another policy module for the session |
| `EYG_ALLOWED_ROOTS` | comma-separated absolute roots, replacing the session directory as the default roots |
| `EYG_CODEMODE_RUNNER` | absolute path to a runner that accepts `--policy` |
| `EYG_CODEMODE_TIMEOUT` | milliseconds for one call |

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
`ReadDirectory`, `ReadFile`, `Sign`, `Sleep`, `StandardError`, `StandardIn`,
`StandardOut`, `WriteFile` - and the policy decides, per effect and per call, before the
host performs it. Three consequences of that split, none of which a tool of the first
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

## Finding files, and what an effect would take

Search is a library, not an effect: `libraries/search.eyg` walks directories with
`ReadDirectory`, the same effect the policy gates, so a search rooted outside the roots
returns nothing rather than an error - every directory it opens is refused and the walk
skips what it cannot read. The pattern semantics are written in the file: at most one
`*`, prefix before it and suffix after it, matched against the path relative to the root,
`**/` removed first, case sensitive, no character classes. `limit` stops the walk; it is
not a slice taken afterwards. `eyg_packages/fs/index.eyg` in the standard library has the
same walk with `list` and `list_files` and is the one to import when you want entries
with their types.

If a search really must be one effect - one that reads a whole tree in one host action,
so the policy decides it once instead of per directory - that is a change to the language,
not to this package, and it is out of scope here. It would go in
`packages/loam/src/loam/platform/computer.gleam` (the CLI runtime's `extrinsic`, which is
where every CLI effect is implemented), declared through the toolchain in
`packages/touch_grass/src/touch_grass/harness/computer.gleam` and the interface
`packages/touch_grass/src/touch_grass.gleam`, mapped to a policy field in
`packages/gleam_cli/src/eyg/cli/overlay.gleam`, and tested in
`packages/loam/test/computer_test.gleam` and the package's own test module. The gate for
that change is `bin/agent/gate.sh <pkg>` per package, and the EYG suite for
`eyg_packages/` is `eyg script entry.eyg`. `AGENTS.md` names changing an effect as an
escalation: it needs a rationale that the effect is general, and the operator's decision,
not an agent's.

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
| `extensions/eyg-codemode.ts` | registers the one tool, `eyg`, resolves defaults from inside the package, and spawns the gated runner through argv (no shell) |
| `policies/agent-roots.eyg` | the default preset: files under `EYG_ALLOWED_ROOTS`, nothing else |
| `policies/deny-all.eyg` | the narrowest preset, for a session that may only compute |
| `libraries/search.eyg` | a search helper over `ReadDirectory`, bound as `search_lib` by the `libraries` parameter |
| `skills/eyg-codemode/SKILL.md` | the EYG forms and the meaning of a refusal, loaded when the model writes EYG |
