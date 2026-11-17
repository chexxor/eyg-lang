---
id: world-model.package
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "test -f pi-simple-world-model/bin/world_lint.mjs && grep -q pi-simple-world-model .pi/settings.json"
confidence: high
sources: [pi-simple-world-model/package.json, .pi/settings.json, pi-simple-world-model/README.md]
supersedes: null
superseded_by: null
---

# The world model tool, installed in this workspace

`pi-simple-world-model/` is a pi package copied in from `~/Git/social-event-publisher`
and declared in `.pi/settings.json`, so every session rooted here loads the
`world_model` tool, the `project-world-model` skill, the `/world` command and the
tier-0 injection of `docs/world/00-map.md`.

The three CLIs run from the repository root:
`node pi-simple-world-model/bin/world_lint.mjs`, `world_map.mjs` (`--check`, `--init`)
and `world_verify.mjs` (`--all`, `--changed-from <ref>`). All are offline; `verify`
caps each claim's command at 20 s.

## Not this

It is not the model. `docs/world/` holds the claims; the package is only the tool
over them, and a session can read the records without the package installed.
