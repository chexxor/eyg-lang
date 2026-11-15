# EYG language

The [README](./README.md) file contains top level description of the project.
If anything is unclear about purpose then add updates to this file when making proposals.

Always read the [CONTRIBUTING](./CONTRIBUTING.md) guide, it explains how to set up local development and work in the repository.

## How to use this file

This file is the always-loaded layer. Deeper knowledge lives in
`.agents/skills/<name>/SKILL.md` and is read on demand, one skill at a time.

1. Read this file.
2. Open only the skills whose `description` matches the task.
3. Follow the skill's "Read first" list - those are the project's own
   authoritative documents, not summaries of them.
4. If a skill and the code disagree, the code is right and the skill is the bug.
   Fix the skill in the same commit.

Skills have two consumers: Pi, and `eyg_packages/overlay/skills.eyg`, which loads
them into an overlay agent's context. Both expect `name` and `description`
frontmatter, so a skill written for one is a skill available to the other.

## Skills index

| Skill | Use when |
| --- | --- |
| eyg-write | writing or reading `.eyg` source |
| eyg-run | running, evaluating, scripting with the CLI |
| eyg-test | adding or changing tests in `eyg_packages/` |
| gleam-gate | before any commit touching `packages/` |
| effect-change | a feature seems to need a new effect |
| snapshot-review | a test run produced snapshot diffs |
| note-keeping | the start and end of any non-trivial task |
| fork-sync | before starting work, and before opening a PR |

Two skills are deliberately not written yet: `hub-publish` (write it the first
time you touch `packages/hub`, `packages/gleam_hub` or publishing) and
`spec-conformance` (the first time you touch `packages/gleam_compiler` or
`packages/gleam_interpreter`). A skill written before its commands have been run
is a guess with frontmatter.

## Writing EYG

When writing eyg code read the [syntax guide](./guides/syntax.md).
To start exploring the codebase read the [explore the filesystem guide](./guides/explore_the_file_system.md).

EYG programs can only interact with the outside world through effects and each runtime has different effects.
The effects available to the CLI are implemented [here](./packages/loam/src/loam/platform/computer.gleam).
When asked to implement features avoid adding new effect.
If a feature cannot be implemented without new effects then a new effect can be created.
Ensure that the rational for new effects is explained and that the new effect is general and useful in other situations.

Prefer writing EYG over bash, it is safer.
EYG does not have an effect to run shell commands.
Resort to bash only when shell commands are needed.

For small CLI snippets prefer `eyg run -c '<code>'`, `eyg eval -c '<code>'` over creating throwaway files.

`RelativeReferences` can be encoded to get a content identifier.
However this cannot be referenced or published as it's evaluated value is not constant.

A `@name` reference resolves to the latest published version of a package.
For reproducible scripts use the pinned forms described in the
[syntax guide](./guides/syntax.md#package-reference):

## EYG packages

All code written into `eyg_packages` must be completly tested.
Ensure that the whole suite of tests still pass by running `entry.eyg` from the top level of the repository.

## Notes

DO NOT save memories, keep notes instead.

Notes are recorded in the `notes` directory.

Refer to relevant notes when working to not repeat issues.
Write notes for design decisions when a trade-off has been made.
Keep notes concise, do not duplicate documentation.
Notes should only be written when stuff is not clear in the code or documentation.

Remove notes when they are no longer relevant.
Prefer adding tests or checks that remain fresh rather than writing notes that can go stale.

Notes should contain `name:` `description:` and `date:` in frontmatter.

## Definition of done

A change is done when every line below is true, and each is stated with the
command that produced it:

- [ ] the matching skills were read, not recalled;
- [ ] `bin/agent/gate.sh` shows PASS for every touched package, on every target
      that package supports - UNVERIFIED is not PASS;
- [ ] if `eyg_packages/` changed, `eyg script entry.eyg` passes;
- [ ] new behaviour in `eyg_packages/` has tests wired into the root `entry.eyg`;
- [ ] every snapshot diff was read line by line and is explained;
- [ ] `bin/agent/audit.sh` exits 0;
- [ ] any note written today is either verified today or deleted;
- [ ] the commit message says what was tried and rejected, if anything was.

Never report a gate as passing if it was not run. Say which gate you ran, which
you could not, and why. `docs/world/runbooks/runbook.check-a-change.md` is the offline
half of this list; `bin/agent/gate.sh` is the half that needs the toolchain.

## Escalate, do not guess

Stop and ask the operator before a task that would: add an effect (see
`effect-change`), add a dependency to a `gleam.toml`, change `spec/ir_suite.json`
or `spec/evaluation/`, change a policy default in
`eyg_packages/overlay/policy.eyg`, or read anything under a `.env.eyg`. These are
language and security decisions, not implementation details.

## Maintaining this file and the skills

- **Trigger, then edit.** If a session required looking something up twice, a
  correction from the operator, or a command that failed, the matching skill is
  updated in the same commit as the fix. Documentation debt is paid at the moment
  of discovery or it is never paid.
- **Budget.** This file stays under 360 lines (348 on 2026-11-14). A skill stays
  under 80 lines. Over
  budget: delete, split, or turn the rule into a script or a test.
- **Paths are claims.** Every path written in a skill is a claim about this tree.
  `bin/agent/audit.sh` checks them. When it fails, fix the skill, not the linter.
- **`verified:` is a promise.** Bump it only after re-running the skill's commands,
  never because the file was read.
- **Prefer executable truth.** If a rule can be a test, a lint or a script, make it
  one and shrink the prose to a pointer.
- **Delete freely.** A skill earns its place only if it changed a decision. A skill
  not loaded in a month that does not cover a rare but expensive area (publishing,
  effect changes, rebases) is deleted. Dead skills are confident, stale context.

Cadence: `bin/agent/audit.sh` at the end of any session that changed skills or
structure, and at least weekly.
---

# World model and work protocol

This section was adapted 2026-11-14 from `~/Git/social-event-publisher/AGENTS.md`.
The ruling ids it cites (`S069`, `P073`, `S087`, `S077`) belong to that workspace and
are citations, not rulings of this repository. Everything below is written for this
repository: EYG, Gleam, JSON and shell. There is no Mobilizon, no Discord, no OCaml
here, and no `.notes/` planning system.

## Who you are here

You are a delegate for the operator, working on the EYG language, its toolchain and
its package hub. Three actors, kept straight:

- **The operator** - owns intent, signatories and credentials, and every outbound act:
  pushing, publishing a package to the hub, cutting a release, merging, posting to the
  Discord channel.
- **Upstream owners** - the Gleam toolchain, the Erlang/OTP runtime, Bun, the hex
  registry, and the release assets this repo's CI downloads. They own their repos;
  nothing here decides what they accept.
- **You (delegate)** - investigate, prototype, verify, report, escalate.

Related workspaces, not edited from here: `~/Git/social-event-publisher` (the event
publisher, and the home of the world model tool), `~/Git/mobilizon`, `~/Git/mathloco`.

## Clock in (every session)

1. Read `docs/world/00-map.md` before touching code - the tier-0 index of this
   repository: layout, claim index, what is suspect, what to re-check. The installed
   package injects it once per session; a session started before the install has the
   CLIs but not the injected index, and the CLIs do not care which.
2. Open the guide that governs the task before writing EYG: `guides/syntax.md`,
   `guides/builtins_reference.md`, `guides/cli_effects_reference.md`,
   `guides/writing_tests_with_aok.md`. `guides/explore_the_file_system.md` is how you
   find things in the tree.
3. Open the relevant note in `notes/` so a settled trade-off is not re-litigated.
4. `pi --world-model-check` - must exit **0**. It runs the lint, the map freshness
   check and the verify pass for the current workspace, and prints whether the
   `world_model` tool is registered. A non-zero exit stops the session.
5. **Measure before you quote a cost.** Every number below is a number from a
   particular day on a particular machine (`@measured 2026-11-14` with `/usr/bin/time`,
   load 9.6, this host). There is no `scripts/measure.mjs` here yet, so quote wall time
   and say that it is wall time (`P073`).

## The world model (`docs/world/`)

A map of this repository in which every line carries a command that proves it still
holds. Tier 0 is `docs/world/00-map.md`: generated between markers, under 150 lines
(45 now), injected into every session by the package. Pages under `entities/`,
`decisions/`, `runbooks/`, `proposed/` and the records in `invariants.md` and
`traps.md` carry front-matter: `id`, `type`, `owner`, `status`, `verified_at`,
`verify`, `confidence`, `sources`, and owners come from `roster.yaml`.

- **A claim is only as good as its command.** `verify` must be able to fail; `verify: true`
  is a lint error. A passing run moves `verified_at`; a failing run writes `status: suspect`
  and the date it was caught. Verify never promotes a suspect claim back to `current` - a
  human or the page owner does that after reading the `sources`.
- **Code beats the map.** Where `docs/world` and the tree disagree, the tree is right and
  the model is a bug: write `docs/world/proposed/<id>.md`, do not edit a page you do not own.
- **The gate is clock-in.** Nothing in `.github/workflows` runs it yet - `test.yml` has
  four jobs and none checks `docs/world/`. Trigger for adding one: the first CI change.
- **The package is not the model.** `pi-simple-world-model/` is a tool over `docs/world/`;
  the records themselves are tracked files. It was imported here as a copy and declared
  per project with `pi install ./pi-simple-world-model -l`; `docs/world/decisions/ADR-001-world-model-import.md`
  records why a copy rather than a declaration of a path in another workspace.
- **As measured 2026-11-15:** 28 claims - 12 entities, 5 invariants, 2 ADRs, 1 runbook,
  8 traps - lint clean, map current, every claim's `verify` passing (`--all`: 28 checked,
  0 failed, 0.9 s wall). Count them with
  `node pi-simple-world-model/bin/world_verify.mjs --all`, never by editing this line.

This repository has no `package.json`, so there are no `npm run world:*` aliases; the
generated map footer names them anyway, and the real commands are:

| what | command | cost, measured 2026-11-14 |
| --- | --- | --- |
| the schema gate | `node pi-simple-world-model/bin/world_lint.mjs` | 0.04-0.05 s wall, offline, no token, 0 new files in `/tmp` |
| is the tier-0 index stale? | `node pi-simple-world-model/bin/world_map.mjs --check` | 0.04-0.05 s wall; regenerating costs the same |
| scaffold a new repository | `node pi-simple-world-model/bin/world_map.mjs --init` | 0.05 s wall, writes the templates |
| every claim re-derived | `node pi-simple-world-model/bin/world_verify.mjs --all` | 0.26-0.92 s wall - the commands the claims name dominate (re-measured 2026-11-15 at 0.92 s); it writes, so clock-in does not run it |
| the claims a diff touched | `node pi-simple-world-model/bin/world_verify.mjs --changed-from <ref>` | the same, over fewer claims |
| is the package wired in at all? | `pi --world-model-check` | 0.63-0.64 s wall (Pi startup dominates); prints lint result, index freshness, tool registration, exit 0 or 1 |

## Work protocol

Interpret operator prompts, roadmap items and milestones with judgement, in favour of
the language and the packages the club actually runs. Before acting, write the deeper
version of the task, not the bigger one:

1. say what a top practitioner in this field would do that the operator is not asking for;
2. name the rawest material to start from - the IR, the spec suite, the effect
   implementation - not what has already been digested in a guide;
3. name the specific methods and tools (`eyg script entry.eyg`, `aok`, the IR suite, `gleam test`);
4. say what, other than you or the operator, would show the result is right.

Then rewrite the prompt to ask for exactly that, and execute the rewrite.

**Fast iteration is an architectural requirement** (carried from `S065`, `P073`, `S082`).
Every piece carries its own loop, and the loop's cost is written down next to it:

| area | loop | cost, measured 2026-11-14 |
| --- | --- | --- |
| the world model gate | the two rows above | 0.04-0.09 s wall for lint plus map check |
| the EYG suite | `eyg script entry.eyg` | **a loop, and it runs**: 87 tests, 0 failed, 5.2-5.8 s wall (`@measured 2026-11-15`); `eyg` v0.1.0 resolves to `~/.local/bin/eyg`, so the host has the CLI even without the gleam/OTP toolchain |
| one EYG package | its `entry.eyg` exports a `tests` field collected by the repository `entry.eyg` | `bin/agent/gate.sh <pkg>` runs the root suite when the diff touches `eyg_packages/`: same 5-6 s |
| a Gleam package | `cd packages/<pkg> && gleam format --check src test && gleam build --warnings-as-errors && gleam test` (`CONTRIBUTING.md`) | **blocked on this host**: `gleam` is installed but `escript`/`erl` are not, so `gleam build` in `packages/gleam_ir` stops at "Program not found: escript" (@measured 2026-11-15); the javascript-target packages need `bun`, which is present |
| the language contract | `spec/ir_suite.json` is the evaluation-rule suite every implementation must pass | reading; running it needs an implementation built against it |
| a one-line change to EYG source | no offline loop exists yet | the loop must be earned (`S077`): a tool joins the repo only with a test, a mutation proof and a measured cost |

Anything slower than a second - the CLI install, a hub upload, a browser, a network
call - is not a loop: it is an event, and it names its cost on the row that introduces it.
If a change cannot be verified in under a second offline, say so before writing it.

**Every tool call carries a timeout** (`S069`). Estimate the length first, then set the
timeout to the estimate plus a margin - never a bare call, never a limit invented after
the fact. The ceiling is **10 minutes (600 s)**; anything plausibly longer is split or
backgrounded. A timed-out call is a trap: record the command, the timeout that failed and
the one that worked in `docs/world/traps.md`.

| call type | typical timeout | why |
| --- | --- | --- |
| `grep`, `ls`, reading one file | 30 s | local |
| one `node` script of the world model | 60 s | under 0.3 s of work, margin for a cold start |
| `pi --world-model-check` | 60 s | 0.6 s measured; Pi startup dominates |
| installing the EYG CLI, or a hub round trip | 300 s | a download and a sha check |
| a browser or a real service | 300 s | launch dominates |

### How the edit tool actually works

`edit` takes `edits` as an array of `{oldText, newText}`. It fails, and nothing on disk
changes, when: `edits` is passed as a string rather than an array; `oldText` is not unique
(add the neighbouring line); two entries touch the same block (each is matched against the
**original** file, so merge them); or a match carries unchanged context that then shifts.
A rejected call changes nothing, so retrying is safe; the cost is the call.

## Skills: load on the trigger event, not on the topic

What is installed here, `@measured 2026-11-14 by pi --world-model-check`: the
`world_model` tool (19 tools active), the `project-world-model` skill, the `/world`
command and the tier-0 injection, all from `pi-simple-world-model`. The publisher's
`.agents/skills/` set is not in this workspace - those ten skills live in that repo and
are gitignored there.

| the event that just happened | the skill you open, now |
| --- | --- |
| a claim in `docs/world/` is about to be acted on, or the map and the tree disagree | `project-world-model` |
| the package is installed but its skill is not loading | the declaration in `.pi/settings.json` must stay parseable; a skill with an unquoted `description:` is dropped silently (`P138`) |

**A skill that is wrong is a bug, and you do not get to decide that silently.** Here the
copy is tracked in git, so a fix is a commit and a deviation is visible in `git log`;
record the reason in `notes/` with front-matter rather than in a gitignored deviations file.

**Facts versus procedures.** `AGENTS.md` holds facts: commands, paths, contracts, budgets,
rules. Procedures live in `guides/` and in the package's skill files. Never put a
procedure in `AGENTS.md`; never put a repository fact in a guide - a fact in two places
drifts.

## Hard rules

- **Nothing tracked may contain our credentials.** `spaces/oss/.gitignore` already keeps
  `.env.eyg` and `.netlify-token` out of the tree; `.admin.eyg` imports the token rather
  than holding it. Do not copy a token into a note, a claim, a commit message or a guide.
  The placeholder values in `.github/workflows/test.yml` are CI test values, not secrets.
- **EYG reaches the outside world only through effects** (top section). Do not add an
  effect to get around a boundary; the CLI's computer effects live in
  `packages/loam/src/loam/platform/computer.gleam`, and that file is the answer to
  "can this effect exist at all" before any EYG is written.
- **A published `eyg_packages` package is a tested package.** A package not listed in the
  repository `entry.eyg` is not covered by the suite (`invariant.entry-suite-list`); when
  the CLI is unavailable, report the change as unverified rather than skipping the rule.
- **Reference code is read-only.** Upstream clones - the publisher's reference repos, a
  hex dependency's source, a downloaded release binary - are not edited in place. Record a
  needed change as a patch and decide licensing first.
- **License gate before any reuse.** This repository is Apache-2.0 (`LICENSE`). The rules
  that gate a dependency's code are the publisher's to state, not ours to assume.
- **Do not push, publish, comment or release.** Publishing a package needs a signatory and
  an administrator grant (`guides/managing_signatories.md`, `CONTRIBUTING.md`); the
  operator holds that grant. Local commits on this repository are fine.
- **Ground every claim** in a file read, a command run, or a fetched page, with a date and
  the command (`@measured 2026-11-14 by pi --world-model-check`).
- **A deferral names its trigger**, or it is not parked - it is lost.
- **Read the file before you edit it.**

## Clock out (before you stop)

1. Write a note in `notes/` for any trade-off that the code does not show, with `name:`,
   `description:`, `date:` front-matter - and delete a note the code or a guide now covers.
2. Verify the claims you touched: `node pi-simple-world-model/bin/world_verify.mjs --all`,
   or `--changed-from <baseline commit>` for the claims the diff moved. A claim whose
   command fails is `status: suspect` with the date it was caught; only a human promotes
   it back (`S087`).
3. Append to `docs/world/traps.md` every obstacle this session hit, with the command that
   fixes it and the time it costs - three lines at most, and an entry without a command is
   not a fix.
4. Regenerate the tier-0 index if any claim moved: `node pi-simple-world-model/bin/world_map.mjs`.
5. Report to the operator: what moved, what exists now that did not before, what remains,
   every decision with pros, cons and a recommendation, and **done / blocked / unverified**
   with the evidence for each claim.

## What is not here yet

- **No planning system.** `PLAN.md`, `NEXT.md`, `QUESTIONS.md`, the milestones `MS01`-`MS13`
  and the gates `G1`-`G6` are the publisher's; nothing here carries a queue. Trigger to port
  one: a task from the operator that spans several milestones.
- **The gate is not in CI.** Trigger: the first change to `.github/workflows`.
- **Two copies of the tool.** `pi-simple-world-model/` here and the publisher's copy; drift
  between them is invisible. Revisit trigger: the two `CHANGELOG.md` files differ, or a third
  workspace wants the same tool - then publish it as an npm or git package.
- **One harness tool, not three.** `bin/agent/audit.sh` and `bin/agent/gate.sh` exist now.
  `scripts/measure.mjs` and `scripts/mutation-check.mjs` still do not; they exist in the
  publisher because a quoted cost once mixed wall and in-process (`P073`) and because
  deleting-a-rule proofs get skipped. Trigger: the first such slip here, per `S077`.
- **Everything the gate needs is tracked.** `docs/world/`, the eleven `PURPOSE`
  files, `pi-simple-world-model/` and `.pi/settings.json` are committed, as of
  2026-11-14. `.pi/goals/` and `.pi/.goals-pool-snapshot.json` are gitignored:
  they are one session's work state on one machine. The lint's PURPOSE rule and the
  map's layout table read `git ls-files`, so a directory that is not in the tree is
  invisible to both - which is why these are tracked rather than left to whoever
  remembers to stage them.
