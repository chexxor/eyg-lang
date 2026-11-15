---
id: runbook.check-a-change
type: runbook
owner: delegate
status: current
verified_at: 2026-11-15
verify: "test -f pi-simple-world-model/bin/world_verify.mjs && test -f install.sh"
confidence: high
sources: [pi-simple-world-model/README.md, CONTRIBUTING.md, guides/install_from_source.md]
supersedes: null
superseded_by: null
---

# Check a change in this workspace

From the repository root, in this order:

```sh
node pi-simple-world-model/bin/world_lint.mjs        # schema gate, exit 1 with file:line
node pi-simple-world-model/bin/world_map.mjs --check # is the tier-0 index stale?
```

Both are offline and under 0.1 s. Then the claims this change touched:

```sh
node pi-simple-world-model/bin/world_verify.mjs --all
```

`verify` writes `verified_at` on a pass and `status: suspect` on a failure; it
never promotes a suspect claim back.

## The suite is not a loop here

`eyg script entry.eyg` and the per-package `gleam test` loops in `CONTRIBUTING.md`
need a toolchain only if you are building one. The CLI itself is a single binary per
platform (`cli.prebuilt-binary`), so the event is `install.sh`: one 5 s download plus
a checksum, no gleam and no OTP. Measured 2026-11-14 on this host, wall time, after
that install: `eyg eval -c` 0.09 s offline, `eyg script entry.eyg` 5.00 s and
178 MB RSS reporting 87 passed / 0 failed, the hub fetches dominating. `gleam test`
in a `packages/` directory still needs gleam 1.19.2 and OTP 28.4 installed.

Until the binary is in place the suite stays an event: name the install step, run it
once, and say which packages were not exercised. A change that cannot be re-greened
offline is reported as unverified, not as passing.
