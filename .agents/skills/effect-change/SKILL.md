---
name: effect-change
description: Adding or changing effects, the only channel an EYG program has to the outside world. Use when a feature seems to need a new effect or a change to the computer harness.
verified: 2026-11-14
---

# Changing effects

An EYG program touches the world only through effects, and each runtime declares
its own. The pieces, in the order you will actually need them:

- effect type and harness: `packages/touch_grass/src/touch_grass/harness/computer.gleam`
  (variants `AppendFile`, `Fetch`, `ReadFile`, ... and their encoders)
- per-effect implementation: `packages/touch_grass/src/touch_grass/file_system/` and
  the sibling modules imported by the platform
- runtime wiring: `packages/loam/src/loam/platform/computer.gleam`, which composes
  Loam effects and never runs a shell
- what agents are allowed to do: `eyg_packages/overlay/policy.eyg`
- the prose contract: `guides/cli_effects_reference.md` and `guides/advanced_effects.md`

## Decision order
1. Can existing effects compose to do it? Then this is not an effect change.
2. Can it be written in EYG on top of existing effects? Prefer that.
3. Only then add the effect, and justify it.

## A new effect is acceptable only when
- it cannot be expressed by composing existing effects;
- it is general - useful to a different runtime (a game, a browser tool, an
  embedded interpreter), not only to the task at hand;
- the rationale is written down: in the PR body, and in `notes/` if it is a
  genuine trade-off (see `note-keeping`).

## Policies, the part people forget
`match_rules` in `packages/overlay/src/overlay/policy.gleam` keeps only the effects
that have a rule. An effect with no policy field is therefore **ungated**, not
denied - `policy.deny_all` has no field for `DecodeJson`, `EygParse`, `Hash` or
`Sign`, so those pass through. If you add an effect, add its field to `deny_all`,
`allow_all`, `read_only` and `read_write`, and test the default in each.
File paths handed to a policy are already absolute.

## Never
- Do not add an effect to make a shell-out possible. EYG has no shell effect; that
  absence is the product. `packages/loam/src/loam/platform/computer.gleam` is where
  you would look for such an effect, and it is deliberately composed only of
  file, process, time and network primitives.

## Prove it
```sh
bin/agent/gate.sh touch_grass loam   # UNVERIFIED here unless gleam is installed
eyg script entry.eyg                 # if any eyg_packages policy changed
```
