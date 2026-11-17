---
id: spec.ir-suite
type: entity
owner: delegate
status: current
verified_at: 2026-11-17
verify: "grep -q 'ir_suite' spec/README.md && test -f spec/ir_suite.json"
confidence: high
sources: [spec/README.md, spec/ir_suite.json]
supersedes: null
superseded_by: null
---

# The language has no syntax contract; the IR does

`spec/README.md` states that the intermediate representation is the stable
interface of EYG, and `spec/ir_suite.json` is the evaluation-rule test suite every
interpreter and compiler must pass. Any new runtime is judged against that file,
not against the surface syntax.

When an implementation and the suite disagree, the suite is the contract and the
implementation is wrong.

## Not this

Not a type system. Type inference is `packages/gleam_analysis/`; the suite says
what evaluation does, not what checking accepts.
