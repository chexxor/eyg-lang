---
id: codemode.effect-surface
type: entity
owner: delegate
status: current
verified_at: 2026-11-18
verify: "grep -q '^## Every effect at a glance' guides/cli_effects_reference.md && test $(grep -c 'PolicyField(' packages/gleam_cli/src/eyg/cli/overlay.gleam) -eq 19 && for n in AppendFile CreateKey CWD DecodeJSON DeleteFile Env Exit EYGParse Fetch Flip Hash MakeDirectory Now Random ReadDirectory ReadFile Search Sign Sleep StandardError StandardIn StandardOut WriteFile; do grep -q \"^| $n \" guides/cli_effects_reference.md || exit 1; done"
confidence: high
sources: [guides/cli_effects_reference.md, packages/gleam_cli/src/eyg/cli/overlay.gleam, eyg_packages/overlay/policy.eyg, pi-eyg-codemode/policies/agent-roots.eyg, pi-eyg-codemode/README.md]
supersedes: null
superseded_by: null
---

# What an EYG program may perform, and where that answer lives

A running program reaches the host only through effects, and the set it may perform is an
intersection of three files. Read them in this order, and the answer costs one lookup:

1. `guides/cli_effects_reference.md`, section `Every effect at a glance` - one row per effect,
   with the policy field it sits under and the gate class. That is the capability question.
2. The preset in force - `pi-eyg-codemode/policies/agent-roots.eyg` calls
   `policy.read_write(roots)`, and the vocabulary in `eyg_packages/overlay/policy.eyg` says
   what each field then does. Roots come from `EYG_ALLOWED_ROOTS`.
3. The roots themselves, for a path question. The tool reports the policy it used and its
   roots in the call, so a refusal names the path it was denied.

`rule_mapping` in `packages/gleam_cli/src/eyg/cli/overlay.gleam` is the source of truth: 23
effects, 19 of them named by a `PolicyField`, 4 (`DecodeJSON`, `EYGParse`, `Hash`, `Sign`)
marked unchecked and deterministic, so available under every preset including `deny_all`.
`Search` shares the `read_file` field, which is why the walk is decided once rather than per
directory. A missing field in a preset is a configuration error, not a silent allow.

Three shapes matter when gating by path: `read_directory`, `delete_file` and `make_directory`
carry a bare path string, `read_file`, `write_file` and `append_file` carry a record with a
`path` field, and `env` refuses with `None({})` instead of an error.

## Not this

The table is not the policy: it says what the CLI can name and how a preset decides, not what
was allowed on any given day. Which preset ran, and its roots, is reported by the tool per call
(`pi-eyg-codemode/README.md`). This page does not restate the table - the verify command greps
it, so the guide and the claim move together. Effects are not added to answer a feature
request: `AGENTS.md` makes that an escalation, and `packages/loam/src/loam/platform/computer.gleam`
is the answer to whether an effect can exist at all.
