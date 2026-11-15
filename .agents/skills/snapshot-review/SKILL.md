---
name: snapshot-review
description: Reviewing birdie snapshot changes in the parser, interpreter, analysis, CLI and loam. Use when a gleam test run reports a snapshot diff.
verified: 2026-11-14
---

# Snapshot review

Snapshots are written by `birdie.snap(title: "...")` in the test files, and the
accepted outputs live in `packages/gleam_parser/birdie_snapshots`,
`packages/gleam_interpreter/birdie_snapshots`, `packages/loam/test/birdie_snapshots`,
`packages/gleam_cli/test/birdie_snapshots`, `packages/gleam_analysis/test/birdie_snapshots`
and `packages/intelligence/test/birdie_snapshots`. The file name is the title;
the content is what the code produced.

They cover parser error messages, runtime stack traces, value printing and layout
width - the surfaces where a regression is invisible unless it is pinned.

## Procedure
1. Read the diff of **every** changed snapshot in full. "It looks fine" is not a
   review.
2. Ask: is this the intended behaviour change, or a regression my patch has baked
   in? If you cannot tell, revert and reproduce the change alone.
3. Accept only the snapshots your change is responsible for. If an unrelated
   snapshot moved, stop and find out why.
4. Never accept a snapshot containing machine-specific data: absolute home paths,
   temp directories, timings, PIDs. Fix the source of nondeterminism instead.
5. Say in the PR body how many snapshots changed and why, one line each.

## Checks that catch the usual slip
- Error-message snapshots: a failure inside hub content or a release module must
  still name the user's call site - see
  `packages/loam/test/birdie_snapshots/runtime_abort_in_hub_content_module_focuses_user_call.accepted`.
- Printing snapshots come in width variants. `very_narrow_width_forces_a_list_to_break`
  and `deeply_nested_structures_break_and_indent` in
  `packages/gleam_interpreter/birdie_snapshots` break when a printer change fixes
  one width and silently changes another. Test both widths, not the one you looked at.

## Prove it
```sh
bin/agent/gate.sh gleam_parser       # the package whose snapshots moved
```
