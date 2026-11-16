---
name: pi-codemode-runner-probe-and-roots
description: Why pi-eyg-codemode probes its runner for --policy, why the preset refuses when roots are unset, and why the context-budget package is project-local here
date: 2026-11-16
---

Three trade-offs that the code states but does not argue.

**The runner is probed, not configured.** The gate lives in the runner:
`packages/gleam_cli/src/eyg_cli.gleam` sends `run`/`script`/`eval` through
`policy_runner` only when `--policy` is present. The CLI installed on `PATH`
(`~/.local/bin/eyg`) is the prebuilt release and has no such flag, so a tool that
assumed it would be a tool with no gate, and the argv would be mis-parsed by that
release: it reads `run` as a program path (`error: no such file: <cwd>/run`).
Assuming either the path or the version is a guess about the host; probing `--help`
once per session costs 0.1-0.6 s wall and fails with a message that names the
remedy. `EYG_CODEMODE_RUNNER` overrides the probe for a host that wants to say no.

**The preset has no roots of its own.** `policies/agent-roots.eyg` reads
`EYG_ALLOWED_ROOTS`; unset or empty means no roots, so the preset refuses everything.
The alternative - the preset picking the process's current directory - was rejected:
a policy module is host authored and may be reused outside a pi session, where its
own idea of "here" is not the session's, and a preset that silently widens itself is
a preset whose permission set cannot be quoted. The extension, which does know the
session's working directory, supplies it, and restores the environment afterwards.

**The context-budget package is declared project-local.** `pi install
npm:@woksin/pi-context-budget -l` writes the declaration into
`.pi/settings.json` and the npm tree into `.pi/npm/`, which is gitignored: it is an
install artefact of this machine, not source. Pi resolves packages and settings at
`session_start`, so installing the package does not change a session that is running -
on 2026-11-16 the session that started before the install committed 3 native
compactions and 0 by hook, and its handoff text is unrecoverable. Check the plane a
fresh process resolves with
`node /home/chexxor/Git/pi-durable-harness/scripts/diagnose-context-budget.mjs`
(1.2 s wall, offline).
