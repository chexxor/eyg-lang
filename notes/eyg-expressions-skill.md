---
name: eyg-expressions-skill
description: Why eyg-write was retired into eyg-expressions, why skill overflow goes to references/, and the one place guides/syntax.md disagrees with the CLI.
date: 2026-11-18
---

# The eyg-expressions skill

`eyg-write` said "everything is an expression" and pointed at the guides; it did
not carry the traps. `eyg-expressions` carries them as executed fences, at the
cost of being longer than one page. Three decisions came out of that.

## One skill, not two

Two skills whose descriptions both fire on "write a .eyg file" make routing a
coin toss. `eyg-write` was deleted in the same change; its unique facts (the
`file_resolution.md` pointer and structural typing) moved into
`.agents/skills/eyg-expressions/references/syntax.md`.

## Overflow goes to references/, not over the budget

`bin/agent/audit.sh` warns past 80 lines per `SKILL.md`. That budget is tighter
than the 500-line ceiling a skill package allows, so the body stays under 80 and
the detail lives in the package's `references/`, each file linked from `SKILL.md` in one hop.
Every fence is executed by the package's `scripts/verify-snippets.sh --subject <fixture>`, which is the
only
thing that keeps a reference from drifting into fiction.

## The package lives outside the language repository (2026-11-18)

`~/Git/eyg-skill-lab/` is a git repo of its own: the skill (`skills/eyg-expressions/`), the eval
harness (`instrument/`), the records (`evals/`), and `docs/world/` claims with verify commands.
Reason, measured not styled: arms run in the language repository quoted the skill they were
supposed to lack (2 of 10 pass-2 outputs cite `SKILL.md`) and wrote 10 tracked library files
plus 13 artefacts. Arms now run in a detached fixture (`git worktree add --detach`) and name it:
`instrument/sweep.sh` writes `fixture.txt` (`provider model fixture-path fixture-commit cases-sha`).
Cost: this repository's overlay agents no longer see the skill (`eyg_packages/overlay/skills.eyg`
reads only `<root>/.agents/skills/<name>/SKILL.md`) - install the package here to get it back.

## guides/syntax.md disagrees with the CLI

`guides/syntax.md` said `{..record}` is invalid. The CLI accepts it:

```sh
eyg eval -c 'let r = {a: 1}
{..r}'                      # exit 0, prints {a: 1}
```

The guide line was the bug and it is now fixed in the tree: `guides/syntax.md:244`
reads "`{..record}` on its own parses and evaluates to `record` unchanged" (`git
diff guides/syntax.md`, 3 insertions 1 deletion, 2026-11-17).

`eyg check` on a program holding a standing `todo` answers `code incomplete`
(exit 1) while `eyg parse` accepts it. That is why the verifier has an `eyg-parse`
fence: a `todo` is valid syntax, not an error.

## Re-verified 2026-11-17

The commands above still answer as written: `eyg eval -c 'let r = {a: 1}\n{..r}'`
exit 0 printing `{a: 1}`; `eyg check -c 'todo'` exit 1 `code incomplete`;
`eyg parse -c 'todo'` exit 0; `grep -n '80' bin/agent/audit.sh` answers
`budget="${SKILL_LINE_BUDGET:-80}"`; `git diff guides/syntax.md` shows the
`{..record}` correction.

## scripts/check-snippet.sh finds the CLI itself

An agent told to run a script that calls a bare `eyg` answers `check=127`
(`command not found`) under a PATH that hides the CLI - a refusal
indistinguishable from a real syntax failure, so the rule the script exists to
enforce looks enforced when it was not. The script resolves the CLI itself and
prints which one it used:

```sh
scripts/check-snippet.sh '!int_add(1, 2)'   # cli=/home/chexxor/.local/bin/eyg, exit 0
```

`command -v eyg` first, else an executable `$HOME/.local/bin/eyg` (where
`guides/install_prebuilt.md` installs the binary), else exit 127 with a message.
The fallback is one path, not a PATH entry, so it survives a stripped PATH without
adding a directory to the caller's environment. Verified today: with
`PATH=/usr/bin:/bin` it still answers `check=0 eval=0 run=0`, exit 0.

Scores in `evals/measured.md` are NOT re-measured against this version: the out10
arms ran the pre-fix script, whose `command not found` refusal is visible in those
answers.
