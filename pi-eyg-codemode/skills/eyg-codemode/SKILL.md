---
name: eyg-codemode
description: "Use when a session's side effects must go through EYG instead of bash or the built-in JavaScript codemode: the `eyg` tool is registered and a host policy module gates every effect. Trigger on the `eyg` tool, a policy module, EYG_ALLOWED_ROOTS, EYG_POLICY, `--policy`, or any attempt to reach a file, the network or a process. Not for editing this package's own source."
---

# EYG codemode: effects are the only channel to the outside world

An EYG program reaches the outside world only through effects, and the host
policy module decides each one before the host performs it. There is no shell in
this session, so there is no command to look for.

Read first: `guides/pi_codemode_agent.md` (how the session is configured and what
each loop costs), `guides/syntax.md` (EYG source), `guides/cli_effects_reference.md`
(the effects a runtime has), `eyg_packages/overlay/policy.eyg` (the policy
vocabulary), `eyg_packages/codemode_policy/index.eyg` (the presets).

## Calling the tool

An effect is performed with `perform` and takes one argument record. This is the
shape that works - copy it, do not guess a function name:

```eyg
let text = perform ReadFile({path: "/abs/file", offset: 0, limit: 2000})
let _ = perform WriteFile({path: "/abs/file", contents: !string_to_binary("text")})
perform MakeDirectory("/abs/dir")
let names = perform ReadDirectory("/abs/dir")
perform StandardOut("text")
```

- `code` is EYG source; the last expression is the value printed back. One call is
  one process, so a `let` binding does not carry to the next call.
- a performed effect that is not the last expression must be bound: `let _ =
  perform WriteFile(...)`. Two expressions on separate lines with no binding is a
  parse error, and the tool reports it as such.
- `mode` is `eval` for a pure computation and `run` when the program performs
  effects. Never assume a run is ungated: the tool refuses to start without a
  policy module.
- paths must be absolute. The runner resolves a relative path from the session
  working directory before the policy sees it, so a policy only ever reasons
  about absolute paths; a path outside the allowed roots is refused, not truncated.
- one call is one process: `let` bindings do not carry over to the next call.

## Reading the result

`eyg run: exit 1` plus a line such as `write_file denied by policy: /abs/path`
means the policy refused that effect. It is a fact about the permission, not a
crash and not a bug in the program:

- do not look for another route: this session has no other channel, and a
  program cannot change the policy from inside.
- report the refusal, or change what the program asks for (a path inside an
  allowed root, a listed host, a shorter program).
- a refused effect left nothing on disk. If the program continues after a
  refusal, check the evidence with a later `ReadFile`/`ReadDirectory` rather
  than assuming either outcome.

## Writing the program

- prefer `eval` for arithmetic, text and data - it performs no effects and is the
  cheapest loop.
- read files with `ReadFile({path, offset, limit})`, write with
  `WriteFile({path, contents: !string_to_binary(text)})`.
- a program that needs the environment can only see what the policy answers;
  under the agent preset `Env` is refused and returns `None({})`.
- the policy module may read the environment (it is host authored), so a token
  belongs in the policy, never in the program.
