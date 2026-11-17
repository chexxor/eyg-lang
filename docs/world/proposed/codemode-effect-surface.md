---
id: codemode-effect-surface
type: runbook
owner: delegate
status: draft
verified_at: 2026-11-17
verify: "grep -q 'pub const rule_mapping' packages/gleam_cli/src/eyg/cli/overlay.gleam && grep -q 'read_write = (roots)' eyg_packages/overlay/policy.eyg && test -f pi-eyg-codemode/policies/agent-roots.eyg && test -f guides/cli_effects_reference.md && test -f pi-eyg-codemode/skills/eyg-codemode/SKILL.md"
confidence: high
sources: [guides/cli_effects_reference.md, packages/gleam_cli/src/eyg/cli/overlay.gleam, eyg_packages/overlay/policy.eyg, pi-eyg-codemode/README.md, pi-eyg-codemode/policies/agent-roots.eyg, pi-eyg-codemode/skills/eyg-codemode/SKILL.md]
supersedes: null
superseded_by: null
---

# Proposal: make the codemode effect surface answerable in two lookups

## Why

A session that asks "which effects can I perform here?" currently derives the answer
from three places: the runtime's effects (`packages/loam/src/loam/platform/computer.gleam`),
the gate mapping in `packages/gleam_cli/src/eyg/cli/overlay.gleam` (`rule_mapping`, 23 entries,
4 of them `policy.Unchecked`), and the preset in force
(`pi-eyg-codemode/policies/agent-roots.eyg`, which calls `policy.read_write(roots)`).
That derivation cost 8 tool calls on 2026-11-16. Two further defects made it worse:
`guides/cli_effects_reference.md` has no `Search` section while
`pi-eyg-codemode/skills/eyg-codemode/SKILL.md` says its semantics live there, and the
complete effect list exists only under the policy-authoring heading in
`pi-eyg-codemode/README.md`, one file the skill does not point at for a capability question.

## The change, in order

1. `guides/cli_effects_reference.md`: add `## Every effect at a glance` after the intro - one
   row per effect in `rule_mapping`, columns Effect | policy field | gate class | return type.
   First column is the bare name, no backticks. Classes: `path-gated`, `constant`,
   `unchecked`, `refused by default`, `passed`. Add a `### Search` section under `## File system`
   with semantics copied from `pi-eyg-codemode/README.md`, not invented: `Search` shares
   `PolicyField("read_file")`, returns `Result(List(String), String)` of absolute paths.
   Name `DecodeJSON`, `EYGParse`, `Hash` and `Sign` in the preamble as bypassing the gate.
   Leave `## Authenticated services` untouched; whether the CLI has those effects is reported,
   not edited.
2. `pi-eyg-codemode/README.md`: one sentence under "Configuring effects for a pi session"
   pointing at the guide table.
3. `docs/world/entities/codemode.effect-surface.md`: the claim that pins the table. Its `verify`
   greps the table rows and counts the `PolicyField` lines, so adding a gated effect fails it.
   No backticks inside the YAML `verify` string.
4. `pi-eyg-codemode/skills/eyg-codemode/SKILL.md`: fix the pointer, lead the read-first list with
   the table and a one-line smoke test, keep the file at or under 80 lines.
5. Timeboxed 30-minute spike: can an EYG program import a policy module and observe
   `Pass`/`Mock`? If yes, add `action: "effects"` to `ACTIONS` in
   `pi-eyg-codemode/extensions/eyg-codemode.ts` with a test under `pi-eyg-codemode/test/`.
   If no, no code change - report the finding and the fallback (a table asserted against
   `rule_mapping` by a test that reads the Gleam source).
6. `docs/world/traps.md`: the backtick-heading trap and the missing-`Search`-section trap.

## Verification performed

```sh
node pi-simple-world-model/bin/world_lint.mjs   # clean, exit 0
node pi-simple-world-model/bin/world_map.mjs --check
```

The map check exits 1: the generated tier-0 region is stale on the baseline tree,
before this page exists, because 18 `docs/world` pages carry a bumped `verified_at`
and are uncommitted. Regenerate with `node pi-simple-world-model/bin/world_map.mjs`
when claims move; the exit code is then 0.

## Not this

The page records the plan and its costs; it is not the table. The table lives in the guide
and is pinned by `docs/world/entities/codemode.effect-surface.md`.
