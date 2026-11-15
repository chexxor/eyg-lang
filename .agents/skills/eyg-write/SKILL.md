---
name: eyg-write
description: Write correct EYG source rather than bash or Gleam. Use when writing, reading or reviewing any .eyg file, or when deciding how to express something in EYG.
verified: 2026-11-14
---

# Writing EYG

## Read first, every time
- `guides/syntax.md` - the text representation. The surface syntax is not the
  contract: `spec/README.md` states that the IR is the stable interface of the
  language, and `spec/ir_suite.json` is the suite every implementation must pass.
- `guides/builtins_reference.md` - every `!builtin` is catalogued there. The set
  is deliberately tiny; anything else is a library function from `eyg_packages/`.
- `guides/file_resolution.md` - before writing any `import`.
- `guides/explore_the_file_system.md` - the `fs` module is the replacement for
  `find`, `ls` and `grep`.

## The shape of the language
- Everything is an expression. A bare line in a block is a parse error; see
  `guides/syntax.md#blocks`.
- Builtins carry a leading `!`. Effects are `perform Name` (effect names start
  with an uppercase letter) and handlers are `handle Name`.
- `match` only deconstructs tagged values. It does not match literals, empty
  lists or nested tags - `guides/syntax.md#what-match-does-not-support` lists
  each unsupported case with the builtin to use instead. There is a parser
  snapshot named `infix_plus_is_not_valid_eyg_syntax` for a reason: do not reach
  for `+` or other infix operators.
- `todo` is the vacant placeholder (the `Vacant` node in the IR).
- Types are inferred structurally, per `guides/embedding_in_gleam.md`, so a
  record with the right fields satisfies the type; do not invent nominal types.

## References, the part that bites
- `@standard` floats to the latest release. `@standard:3` pins a version.
  `@standard:3:bafyrei...` pins version and module CID. Shared or published code
  uses the fully pinned form (`guides/syntax.md#package-reference`).
- Relative references (`import "../eyg_packages/fs/index.eyg"`) resolve at run
  time. `eyg share` rewrites them into content references, but their evaluated
  value is not constant, so they cannot be published or referenced by hash.

## Defaults
- Prefer EYG over bash. EYG has no shell effect: that constraint is the product.
  Use bash only when EYG cannot express the task, and say so in the commit.
- Prefer one-liners to throwaway files: `eyg run -c '<code>'` to execute,
  `eyg eval -c '<code>'` for a pure expression whose value you want printed.
- A feature that seems to need a new effect usually does not. See `effect-change`.

## Prove it
```sh
bin/agent/gate.sh            # if the change touched packages/**
eyg check path/to/file.eyg   # type check the source without running it
```
