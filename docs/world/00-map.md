# Project world model - tier 0

Read this first. It tells you where to look; the pages it points at carry the claims and
the command that re-checks each one. Task state and session narrative do not belong here.

<!-- BEGIN GENERATED: do not edit -->
## Layout - what is in this repository

| directory | purpose |
| --- | --- |
| bin/ | bin/agent: the executable gates agents run before they claim a change is done: gate.sh (target-aware, fails closed), gate-all.sh, audit.sh (anti-rot linter for AGENTS.md and .agents/skills), new-skill.sh. |
| dark/ | Effect work that is not safe enough for a package: site integrations (dnsimple, netlify) kept out of the public library. |
| docs/ | The world model records for this repository: docs/world/00-map.md (tier-0 index), the entity, decision, runbook and proposal pages, invariants.md, traps.md and roster.yaml. The lint, map and verify CLIs that check them live in pi-simple-world-model/. |
| examples/ | Standalone demos outside the package library, e.g. an Erlang counter agent. |
| eyg_packages/ | The EYG standard library: each package has entry.eyg (or index.eyg.json) and exposes its tests as the `tests` field. |
| guides/ | Prose guides: syntax, builtins, effects, install, embedding, and per-service recipes. |
| notes/ | Design notes with name/description/date front-matter; the record of trade-offs that are not clear in the code. |
| packages/ | Gleam packages: the toolchain (ir, parser, analysis, interpreter, cli), runtimes (loam, unixfs), the hub and the website. |
| pi-eyg-codemode/ | pi-eyg-codemode/: a pi package that gives a pi agent EYG instead of JavaScript as its coding tool, so its only channel to the outside world is the EYG effects the host policy gate allows. |
| pi-simple-world-model/ | The pi package that implements the world model: bin CLIs, lib parser, one extension, one skill, one prompt, templates. |
| scripts/ | scripts/: executable proofs that run the suites against deliberate mutations, so a committed rule is shown to be necessary rather than claimed. |
| spaces/ | Overlay agent contexts (a context layer per person), each with its own .overlay.eyg and secrets file. |
| spec/ | The language definition: spec/README.md plus spec/ir_suite.json, the test suite every implementation must pass. |

## Claim index

| id | one line | owner | verified_at |
| --- | --- | --- | --- |
| agent.tooling | Two layers, both written for this repository rather than imported. | delegate | 2026-11-18 |
| ci.workflows | `.github/workflows/test.yml` has four jobs: `test-beam` (gleam build/test/format per package, Erlang target), ... | delegate | 2026-11-18 |
| cli.prebuilt-binary | The CLI ships as one self-contained executable per platform, not as an npm package. | delegate | 2026-11-18 |
| cli.run-effect-path | `eyg run`, `eyg eval` and `eyg script` evaluate a program and hand unhandled effects straight to the host: ... | delegate | 2026-11-18 |
| codemode.effect-surface | A running program reaches the host only through effects, and the set it may perform is an intersection of three files. | delegate | 2026-11-18 |
| eyg-packages.layout | Every directory in `eyg_packages/` is one EYG package, and each one has either a source entry module `entry.eyg` or a ... | delegate | 2026-11-18 |
| guides.index | `guides/` holds the prose an agent should read before writing EYG: `syntax.md` is the surface syntax, ... | delegate | 2026-11-18 |
| notes.format | `notes/` is where trade-offs go when they are not clear from the code: one file per subject, `name:`, `description:` ... | delegate | 2026-11-18 |
| overlay.policy-gate | A running EYG program is stopped at every effect before the host performs it, and a user-supplied function decides. | delegate | 2026-11-18 |
| packages.loam-effects | An EYG program reaches the outside world only through effects, and each runtime declares its own. | delegate | 2026-11-18 |
| pi.codemode-gate | `pi-eyg-codemode/` is a local pi package (`pi list` resolves the declaration in `.pi/settings.json` to ... | delegate | 2026-11-18 |
| repo.entry-eyg | `entry.eyg` is the whole EYG suite. | delegate | 2026-11-18 |
| spec.ir-suite | `spec/README.md` states that the intermediate representation is the stable interface of EYG, and `spec/ir_suite.json` ... | delegate | 2026-11-18 |
| world-model.package | `pi-simple-world-model/` is a pi package copied in from `~/Git/social-event-publisher` and declared in ... | delegate | 2026-11-18 |
| invariant.eyg-over-bash | EYG is the scripting language of this repository and it has no effect that runs a shell command. | human | 2026-11-18 |
| invariant.entry-suite-list | A package that is published in `eyg_packages/` is a package the repository-level `entry.eyg` runs. | human | 2026-11-18 |
| invariant.notes-frontmatter | Every note carries `name:` front-matter. | human | 2026-11-18 |
| invariant.purpose-every-dir | Every top-level directory has a `PURPOSE` file, so the generated tier-0 map can name what each one is for. | human | 2026-11-18 |
| proposal.entry-suite-list | ## Why The invariant says a package published in `eyg_packages/` is a package the root `entry.eyg` runs. | delegate | 2026-11-18 |
| ADR-000-world-model | ## Context Agents rediscover the layout, act on stale assumptions, and re-litigate settled decisions. | human | 2026-11-18 |
| ADR-001-world-model-import | ## Context The world model tool (`pi-simple-world-model`) is authored in `~/Git/social-event-publisher`. | delegate | 2026-11-18 |
| codemode-effect-surface | ## Why A session that asks "which effects can I perform here?" currently derives the answer from three places: the ... | delegate | 2026-11-18 |
| runbook.check-a-change | From the repository root, in this order: Both are offline and under 0.1 s. | delegate | 2026-11-18 |

## Where to look for a claim

- entities: 14 · invariants: 5 · decisions: 2 · runbooks: 2 · traps: 23
- suspect right now: invariant.purpose-every-dir
- re-check everything: `npm run world` · gate: `npm run world:lint` · regenerate this index: `npm run world:map`
<!-- END GENERATED -->
