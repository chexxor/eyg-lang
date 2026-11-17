---
id: ci.workflows
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q 'eyg script entry.eyg' .github/workflows/test.yml && grep -q 'gleam test --target erlang' .github/workflows/test.yml"
confidence: high
sources: [.github/workflows/test.yml, .github/workflows/release.yml]
supersedes: null
superseded_by: null
---

# What CI proves

`.github/workflows/test.yml` has four jobs: `test-beam` (gleam build/test/format
per package, Erlang target), `test-bun` (the same, JavaScript target on bun),
`test-db` (the hub against a postgres service), and `test-eyg-packages`, which
installs the pinned `eyg-linux-x64` CLI and runs `eyg script entry.eyg`.

The matrix names the versions CI expects: gleam 1.19.2, OTP 28.4, rebar3 3.25,
bun 1.3.13, `EYG_CLI_VERSION=gleam_cli-v0.0.4`. A package commented out of the
matrix is a package CI does not cover - that list is the coverage fact.

## Not this

Not release packaging (`.github/workflows/release.yml`) and not the world model
gate; nothing here checks `docs/world/`.
