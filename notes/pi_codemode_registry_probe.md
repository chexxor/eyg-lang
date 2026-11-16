---
name: registry availability is a re-probed advisory, not a gate
description: Why the eyg-codemode registry probes each effect at every listing, why the probe arguments are root-relative rather than fixed, and why availability is advisory rather than a second gate that blocks a run.
date: 2026-11-16
---

# The decision: answer "can this session perform that effect" by asking, and answer it per query

A registry function-set declares the effects it needs in its `let metadata = {...,
effects: [...]}` record. Two things follow from that declaration alone being insufficient,
and both are trade-offs the code does not show.

**The declaration cannot be trusted, so it is cross-checked and not used as a decision.**
`checkDeclaredEffects` in `pi-eyg-codemode/lib/render-helpers.mjs` compares the declared names
against the `perform` names in the module's text in both directions, and each direction is a
registry error rather than a pass: an effect the body performs and the record omits is an effect
a caller needs and the listing would not have warned about, and an effect declared and never
performed is an annotation that went stale. The scan is textual, so a `perform Foo` inside a
comment counts - an over-estimate, which is the safe direction: it can name an effect a
program does not ask for, it can never hide one it does ask for.

**Availability is answered by a probe, and a probe is a question about the policy in force.**
The probe program is one effect as the last expression, so a refusal prints its reason and the
runner's answer distinguishes three cases (`classifyProbeOutput`): `denied by policy` means the
policy refused it, `unhandled effect` means this runner does not implement it, anything else -
a host error such as `No such file or directory`, or the printed value of a harmless effect -
means the policy let it through. That is exactly the meaning of "available" here: whether the
session may perform the effect, not whether performing it at an impossible path would succeed.

# Why the probe arguments are root-relative, and what was rejected

Probing at a fixed path was tried and rejected. `@measured 2026-11-16` under the package's own
preset, one program doing both probes:

```
OUTSIDE PROBE: read_file denied by policy: /dev/null/.eyg-codemode-probe
ROOT PROBE: No such file or directory
```

The first is what an argument at `/dev/null` does: the agent preset refuses every path outside
the roots, so every path probe would have read `refused by the policy in force` - including
`ReadDirectory`, in a session that can read its own workspace. A listing that says "refused"
where the session can perform the effect is a lie, and an agent that trusted it would have
stopped calling a function that works. The second line is the shape the tool uses now: the
first advertised root (`EYG_ALLOWED_ROOTS`, else the session directory) with `.eyg-codemode-probe`
appended, which is inside the roots and does not exist, so the host errors and the policy has
answered "let through".

The argument per effect is chosen so the effect cannot change anything before it fails
(`probeArguments`): a read, a search or a delete names that non-existent path; a write names the
root itself, which is a directory, so opening it to write fails; `MakeDirectory` names the root,
which already exists, so it succeeds and creates nothing; `Fetch` names a host under the reserved
TLD `.invalid`, which can never resolve. `Env`, `Exit` and `StandardIn` are never attempted -
they would read the caller's environment, stop the probe process, or swallow the runner's stdin -
and report `unknown` with that reason instead of a guess.

# Why per query, and why advisory

The probe runs at every `list_functions`/`describe_function` call, not once per session: `EYG_POLICY`
and the `policy` argument can differ between calls, and a cached answer is what makes a lost
permission invisible to the next session turn. The cost is one process per distinct effect named in
the registry, and `@measured 2026-11-16` a listing of two modules that name one effect costs
0.23 s wall - the listing prints its own wall time in its header for the same reason.

Availability is **advisory** and the tool does not block a run whose effect was probed refused.
A second gate in the listing would be a second answer to the same question, in a place the program
cannot see, and it would disagree with the runner's answer - the policy can have changed between
the probe and the call, and the refusal then surfaces as the ordinary `Error("<field> denied by
policy: ...")` value the program already handles. The listing says so in its own footer, and the
skill repeats it, so the agent does not read `available` as permission to read a path or a refusal
as a reason to skip a call. This mirrors `notes/pi_codemode_host_gate.md`: the thing that can be
trusted is the answer given by the process that runs the program, and everything else is a hint.

# Re-check it

| claim | command | cost |
| --- | --- | --- |
| the registry lists, shadows and cross-checks | `pi -p --no-session --no-builtin-tools --tools eyg 'Call the eyg tool with action "list_functions" and code ""'` | 8-14 s wall, one headless session (`pi -p` is an event, not a loop) |
| the shapes the listing prints, offline | `cd pi-eyg-codemode && node --test test/render-helpers.test.mjs` | 41-43 ms in process, 0.09 s wall `@measured 2026-11-16` |
| a probe at `/dev/null` is refused, a probe at the root is not | one gated program performing `ReadFile("/dev/null/.eyg-codemode-probe")` and `ReadDirectory("<root>/.eyg-codemode-probe")` | 0.07 s per effect, quoted verbatim above |
