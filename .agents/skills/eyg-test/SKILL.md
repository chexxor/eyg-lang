---
name: eyg-test
description: Write and wire tests for EYG packages with aok - assertions, ordered effect expectations, and the repository entry runner. Use for any change under eyg_packages/.
verified: 2026-11-14
---

# Testing EYG packages

Everything in `eyg_packages/` is fully tested, including small helpers. A package
whose tests are not collected by the root `entry.eyg` is not tested, no matter how
many test files it contains.

## Read first
- `guides/writing_tests_with_aok.md` - assertions and ordered effect expectations.
- `eyg_packages/aok/` - `assert`, `expect`, and its own tests, which are the best
  worked examples in the repository.
- A `fixtures/` directory beside the test is the convention, as in
  `eyg_packages/fs/fixtures` and `eyg_packages/edit/fixtures`.

## The two things that make a test real
1. A test is a record `{name, test}` where `test` is a function that aborts on
   failure. `assert.equal`, `assert.equal_string` are the primitives.
2. The package entry module exposes its tests as the `tests` field, and the root
   `entry.eyg` flattens them:
   ```eyg
   import "./eyg_packages/json/entry.eyg".tests
   ```
   Adding a test file without adding it there means it never runs.

Effect expectations are ordered and matched against what the program performs:

```eyg
let time = expect.run((_) -> { greet("Bill") }, [
  expect.now((_) -> { 123 }),
  expect.standard_out((message) -> { assert.equal_string("Hello, Bill", message) })
])
```

`expect.exit` is special: it receives the status and returns the final value of
`expect.run`, and expectations after the exit stay unconsumed and fail the test.

## Run it
```sh
eyg script entry.eyg
```
`aok.run_all` returns results, `aok.all` prints them, `aok.debug(tests, n)` runs
one named test without catching the abort so you can see the stack trace.

## Know what is not covered
`bin/agent/gate.sh` prints the packages the root `entry.eyg` does not reference.
As measured 2026-11-14 that is `catfact` (no entry module) and `spotless`
(entry exists, not wired). Treat those as untested until wired.

## Preference
If a behaviour can be pinned by a test, pin it by a test rather than writing a
note. Tests stay fresh; notes go stale.
