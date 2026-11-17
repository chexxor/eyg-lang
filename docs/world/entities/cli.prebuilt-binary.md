---
id: cli.prebuilt-binary
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q 'bun-linux-x64' .github/workflows/release.yml && grep -q 'HOME/.local/bin' install.sh && test -f guides/install_prebuilt.md && grep -q 'npm package' packages/website/src/website/routes/roadmap.gleam"
confidence: high
sources: [.github/workflows/release.yml, install.sh, guides/install_prebuilt.md, .github/workflows/test.yml, packages/website/src/website/routes/roadmap.gleam]
supersedes: null
superseded_by: null
---

# How the CLI reaches a user

The CLI ships as one self-contained executable per platform, not as an npm package.
`.github/workflows/release.yml:22-40` sets up bun 1.3.13 and runs `./bin/compile
bun-linux-x64 ./dist/eyg-linux-x64` for five assets: linux x64 and arm64, macOS
x64 and arm64, and `eyg-windows-x64.exe`. Bun's single-executable-application
route is what makes the Gleam-to-JavaScript output (`packages/gleam_cli/gleam.toml:3`
`target = "javascript"`) a standalone file.

`install.sh:36-70` detects platform and arch, downloads the matching asset plus
`SHA256SUMS`, compares the checksum and moves the file to `$HOME/.local/bin/eyg`.
`guides/install_prebuilt.md` is the same thing by hand.

Sizes and times measured 2026-11-14 on this host by the GitHub release API and
`/usr/bin/time`; they are wall time on one machine on one day: assets are 103,340,352
bytes for linux-x64 (64-119 MB per platform), `eyg --version` costs 0.07 s wall and
52.7 MB RSS.

What that is for: on a host with no gleam and no OTP, installing the prebuilt binary
is the whole cost of being able to run the EYG suite. One download (5 s wall,
checksum verified) makes `eyg eval -c` an offline 0.09 s loop and `eyg script
entry.eyg` a 5.00 s run reporting 87 passed / 0 failed; hub resolution, not
evaluation, dominates that 5 s. The download is an event; the loop it earns is
offline.

No native runtime exists in this tree. `packages/website/src/website/routes/roadmap.gleam:497`
still calls it Pending and describes the shell CLI as the npm package - that page
predates the release workflow, see trap-04.

## Not this

Not building the CLI from source (`guides/install_from_source.md`, which needs gleam
plus bun), not the browser interpreter (`packages/gleam_interpreter`, also a
JavaScript target), and not the hub API in `packages/gleam_hub`.
