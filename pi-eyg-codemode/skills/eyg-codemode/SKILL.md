---
name: eyg-codemode
description: "Use when a session's side effects must go through EYG instead of bash or the built-in JavaScript codemode: the `eyg` tool is registered and a host policy module gates every effect. Trigger on the `eyg` tool, a policy module, EYG_ALLOWED_ROOTS, EYG_POLICY, `--policy`, or any attempt to reach a file, the network or a process. Not for editing this package's own source."
---

# EYG codemode: effects are the only channel to the outside world

An EYG program reaches the outside world only through effects; a host policy gates each.

Read first: `guides/pi_codemode_agent.md` (the session and what each loop costs),
`guides/syntax.md` (EYG source), `guides/cli_effects_reference.md` (the effects a
runtime has), `eyg_packages/overlay/policy.eyg` (the vocabulary),
`eyg_packages/codemode_policy/index.eyg` (the presets).

## Calling the tool

An effect is performed with `perform` and takes one argument record; copy this shape.

```eyg
let text = perform ReadFile({path: "/abs/file", offset: 0, limit: 2000})
let written = perform WriteFile({path: "/abs/file", contents: !string_to_binary("text")})
perform MakeDirectory("/abs/dir")
let names = perform ReadDirectory("/abs/dir")
perform StandardOut("text")
```

An effect that is refused resumes the program with an `Error`, and `let _ =
perform WriteFile(...)` throws that answer away, so the call looks like success
even though nothing was written. Bind a name you use and branch on its value:

```eyg
let result = perform WriteFile({path: "/abs/file", contents: !string_to_binary("text")})
match result {
  Error(why) -> { perform StandardOut(why) }
  Ok(_) -> { perform StandardOut("written") }
}
```

- `code` is EYG source; the last expression is the value. In `run` mode nothing is
  printed unless the program performs `StandardOut`, so end a program with the print
  you want to see; in `eval` mode the value is printed and no effect is performed.
- with no `policy` argument the tool uses the preset it ships over the session working
  directory; a call is never ungated. One call is one process, so a `let` binding
  does not carry to the next call.
- a performed effect that is not the last expression must be bound as in
  `let _ = perform WriteFile(...)`. Two expressions on separate lines with no binding
  is a parse error, and the tool reports it as such.
- `mode` is `eval` for a pure computation and `run` when the program performs
  effects; a run is never ungated.
- paths must be absolute. The runner resolves a relative path from the session
  working directory before the policy sees it, so a policy only ever reasons
  about absolute paths; a path outside the allowed roots is refused, not truncated.
- under the agent preset `Env` is refused and returns `None({})`; a token belongs in
  the policy module, which may read the environment, never in the program.

## Reading the result

`eyg run: exit 1` plus a line such as `write_file denied by policy: /abs/path`
means the policy refused that effect - a fact about the permission, not a crash:

- do not look for another route: this session has no other channel, and a
  program cannot change the policy from inside. Report the refusal, or change what
  the program asks for (a path inside an allowed root, a listed host).
- a refused effect left nothing on disk. After a program continues past a refusal,
  check the evidence with a later `ReadFile`/`ReadDirectory`.

## Finding files

The CLI runtime declares a `Search` effect, so ask in one step:

```eyg
let found = perform Search({path: "/abs/root", pattern: "**/*.eyg", limit: 20})
// Ok(List(String)) of absolute paths, or Error(String) when the policy refuses
```

Matching is over the path relative to `path`: one `*` per segment, a whole `**` segment
spans depths, anything else compares equal, case sensitive. `limit` is a budget spent while
walking, the paths are absolute (hand one to `ReadFile`), an unreadable directory
contributes nothing, and the walk stops 32 directories deep. The policy decides the whole
walk under its `read_file` rule, so the roots that gate reads are the roots a search sees:
a search rooted outside them answers `Error("read_file denied by policy: /abs/root")` and
nothing is read.

A search reports names, including the name of a file a read of that path would be refused
for; contents never come through it. Do not treat a listed name as permission to read it.

On a runtime that lacks `Search`, ask for the package's library instead of writing a walk:
pass `libraries: ["search"]` and call `search_lib.search({root, pattern, limit})`. It walks
with `ReadDirectory` - one policy decision per directory - and its pattern rules are its own,
in `libraries/search.eyg`.

```eyg
let found = search_lib.search({root: "/abs/dir", pattern: "**/*.eyg", limit: 20})
perform StandardOut(!list_fold(found, "", (p, acc) -> { !string_append(acc, !string_append(p, "\n")) }))
```
