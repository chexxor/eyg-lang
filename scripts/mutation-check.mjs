#!/usr/bin/env node
// Necessity proof for the committed policy rules in eyg_packages/overlay/policy.eyg.
//
// Every rule in that module is a decision the host gate makes before performing an
// effect. A rule is necessary when removing it makes the codemode security suite
// fail, so the suite is the evidence and not a note. The script copies the two
// packages into a scratch directory, applies one textual loosening to the copy,
// and runs `eyg script <scratch>/codemode_policy/entry.eyg`.
//
//   exit 0 - the committed suite passes and every loosened rule fails it.
//   exit 1 - a rule can be loosened without the suite noticing, or a rule text
//            was not found, or the committed suite does not pass.
//
// Nothing tracked is modified: the scratch tree lives under the system temp dir.
import { spawnSync } from "node:child_process";
import { mkdtempSync, cpSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";

const packages = ["overlay", "codemode_policy"];

// One loosening per committed rule: the rule text, and the rule made permissive.
const mutations = [
  {
    rule: "deny_all refuses write_file",
    from: '  write_file: refuse("write_file")',
    to: "  write_file: pass",
  },
  {
    rule: "deny_all answers Env with None rather than reading the environment",
    from: "  env: (_) -> { Mock(None({})) },",
    to: "  env: pass,",
  },
  {
    rule: "read_only hides secret files behind read_file",
    from: '    read_file: hide_secrets(under("read_file", roots, request_path)),',
    to: '    read_file: under("read_file", roots, request_path),',
  },
  {
    rule: "fetch_hosts refuses a host that is not listed",
    from: '      False(_) -> { Mock(Error(append("fetch denied by policy: ", request.host))) }',
    to: "      False(_) -> { Pass(request) }",
  },
  {
    rule: "with_header sends requests for other hosts to the otherwise policy",
    from: "      False(_) -> { otherwise(request) }",
    to: "      False(_) -> { Pass(request) }",
  },
];

const scratch = mkdtempSync(`${tmpdir()}/eyg-mutation-check-`);

const fresh_copy = () => {
  for (const name of packages) {
    cpSync(`eyg_packages/${name}`, `${scratch}/${name}`, { recursive: true });
  }
};

const run = (label) => {
  const started = Date.now();
  const result = spawnSync(
    "eyg",
    ["script", `${scratch}/codemode_policy/entry.eyg`],
    { encoding: "utf8" },
  );
  const wall = (Date.now() - started) / 1000;
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}`;
  const failures = output
    .split("\n")
    .filter((line) => line.startsWith("FAIL"))
    .map((line) => line.replace(/^FAIL\s+/, ""));
  return { label, exit: result.status, wall, failures };
};

const results = [];
fresh_copy();
results.push(run("committed rules"));

for (const mutation of mutations) {
  fresh_copy();
  const path = `${scratch}/overlay/policy.eyg`;
  const source = readFileSync(path, "utf8");
  const matches = source.split(mutation.from).length - 1;
  if (matches !== 1) {
    console.log(`RULE NOT FOUND in eyg_packages/overlay/policy.eyg: ${mutation.rule}`);
    rmSync(scratch, { recursive: true, force: true });
    process.exit(1);
  }
  writeFileSync(path, source.replace(mutation.from, mutation.to));
  results.push(run(mutation.rule));
}

rmSync(scratch, { recursive: true, force: true });

const baseline = results[0];
const loosened = results.slice(1);
const passed = (r) => r.exit === 0;

console.log("--- mutation check: every committed policy rule is necessary ---------");
for (const r of results) {
  console.log(`${r.label}`);
  console.log(`  suite exit ${r.exit} in ${r.wall.toFixed(2)} s wall`);
  for (const f of r.failures) {
    console.log(`  failed test: ${f}`);
  }
}

if (!passed(baseline)) {
  console.log("UNVERIFIED: the committed suite does not pass, so nothing is proven");
  process.exit(1);
}
if (loosened.some((r) => passed(r))) {
  console.log("FAIL: a rule can be loosened and the suite still passes");
  process.exit(1);
}
console.log(`PASS: ${loosened.length} of ${mutations.length} rules are necessary, suite ${baseline.wall.toFixed(2)} s wall`);
