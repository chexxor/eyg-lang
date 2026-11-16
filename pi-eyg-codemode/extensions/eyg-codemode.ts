/**
 * EYG codemode - the agent's only channel to the outside world.
 *
 * The model calls one tool, `eyg`, with EYG source. The tool spawns the gated
 * runner (`eyg run --policy <module.eyg>`) so the interpreter stops at every
 * effect and the host policy module decides Pass or Mock before the host
 * performs it. A denied effect resumes the program with an EYG error such as
 * `write_file denied by policy: /abs/path`, which the model can act on; the
 * filesystem is unchanged because the host never performed the write.
 *
 * Nothing is configured by hand. With no `policy` argument and no `EYG_POLICY`
 * the tool uses the policy the installed package ships
 * (`<package>/policies/agent-roots.eyg`) and that policy's roots default to the
 * session working directory, so a first session can read and write its own
 * workspace and nothing else. Every default below is named by the file it comes
 * from; see the README table.
 *
 * Configure the runner and the policy with environment variables to point one
 * session at one policy without editing this file:
 *
 *   EYG_CODEMODE_RUNNER   absolute path to the runner (default: probe, below)
 *   EYG_POLICY            absolute path to the policy module (default: the package's)
 *   EYG_ALLOWED_ROOTS     comma separated absolute roots for the default policy
 *   EYG_CODEMODE_TIMEOUT  ms for one call (default 30000, capped at 120000)
 *
 * A runner must accept `run --policy <module.eyg>`: a runner without that flag
 * hands every effect straight to the host, so the tool refuses to use one.
 * The probe is the cheapest honest test that the gate exists at all.
 */

import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_TIMEOUT_MS = 120_000;
const PROBE_TIMEOUT_MS = 5_000;

function refuseToRun(reason: string) {
  return {
    content: [{ type: "text", text: `eyg refused: ${reason}` }],
    details: { gated: true, ran: false },
  };
}

/// The directory of the package that carries this extension. An installed
/// package is loaded from its own path (`pi list` prints it), so the file this
/// module was loaded from is inside the package, and `policies/` is one level
/// up from `extensions/`. Null when the module was not loaded from a file on
/// disk, in which case the caller has to name the policy.
function packageDir(): string | null {
  const url = import.meta.url;
  if (typeof url !== "string" || !url.startsWith("file:")) {
    return null;
  }
  const module = fileURLToPath(url);
  const dir = dirname(dirname(module));
  return existsSync(join(dir, "package.json")) ? dir : null;
}

/// The shipped default policy, resolved inside the package rather than
/// hardcoded to an absolute path, so the same package works when installed
/// from npm, git or a local directory.
function defaultPolicy(): string | null {
  const dir = packageDir();
  if (dir === null) {
    return null;
  }
  const policy = join(dir, "policies", "agent-roots.eyg");
  return existsSync(policy) ? policy : null;
}

/// A library module shipped in this package, resolved inside the package rather
/// than by a path the caller has to know. The module is plain EYG source, so it
/// is handed over as an `import` of its absolute path - the only import form an
/// inline program can use - bound as `<name>_lib`. The effects a library
/// performs go through the policy like the program's own, so a library cannot
/// reach more than the roots allow.
function libraryFile(name: string): string | null {
  const dir = packageDir();
  if (dir === null) {
    return null;
  }
  const file = join(dir, "libraries", `${name}.eyg`);
  return existsSync(file) ? file : null;
}

/// A runner is usable only if it accepts the policy flag: `--policy` is the
/// whole gate, and a run without it is ungated (`notes/pi_codemode_host_gate.md`
/// records why a policy inside the program is not a restriction). The CLI
/// prints the flag in its help text, so the help text is the test.
/// Cached: the probe is one process, and a session makes many tool calls.
const runnerProbe: { candidates: string[]; runner: string | null } = {
  candidates: [],
  runner: null,
};

async function resolveRunner(
  candidates: string[],
  exec: (binary: string, args: string[]) => Promise<{ stdout: string; stderr: string; code: number }>,
): Promise<string | null> {
  if (runnerProbe.candidates.length === candidates.length &&
    runnerProbe.candidates.every((c, i) => c === candidates[i])) {
    return runnerProbe.runner;
  }
  for (const candidate of candidates) {
    try {
      const probe = await exec(candidate, ["--help"]);
      if (/\-\-policy/.test(probe.stdout + probe.stderr)) {
        runnerProbe.candidates = candidates;
        runnerProbe.runner = candidate;
        return candidate;
      }
    } catch {
      // A candidate that cannot be spawned is not a runner.
    }
  }
  runnerProbe.candidates = candidates;
  runnerProbe.runner = null;
  return null;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool(defineTool({
    name: "eyg",
    label: "EYG codemode",
    description: [
      "Run an EYG program. A program reaches the outside world only through EYG",
      "effects (ReadFile, WriteFile, AppendFile, DeleteFile, MakeDirectory, ReadDirectory, Fetch, Env, Exit, StandardOut, ...) and the host policy module decides each one",
      "before the host performs it. A refused effect resumes the program with an EYG",
      "error such as `write_file denied by policy: /abs/path` and nothing on disk changes",
      "- treat that as a fact about the permission, not as a failure of the program.",
      "There is no shell, no package manager and no way to change the policy from inside",
      "a program; a program that needs a denied effect must ask for it and stop.",
      "By default the program runs under the package's policy over the session working",
      "directory: reads and writes inside that directory are performed, everything else",
      "is refused and reported. mode `eval` is pure and prints the value; mode `run`",
      "performs effects.",
      "An effect is performed with the `perform` keyword and one argument: `let text = perform ReadFile({path: \"/abs/file\", offset: 0, limit: 2000})`, `let written = perform WriteFile({path: \"/abs/file\", contents: !string_to_binary(\"text\")})`, `let found = perform ReadDirectory(\"/abs/dir\")`, `perform StandardOut(\"text\")` on the last line. A performed effect that is not the last line must be bound with `let`, otherwise the program does not parse.",
      "To find files, pass libraries: [\"search\"] and call `search_lib.search({root, pattern, limit})`: it walks the roots with the effects the policy gates, so it cannot see outside them.",
      "EYG has no infix operators - add integers with `!int_add(a, b)`; a bare `WriteFile(...)` is a function call and fails to parse.",
      "EYG has no infix operators - add integers with `!int_add(a, b)`; a bare `WriteFile(...)` is a function call and fails to parse.",
    ].join(" "),
    promptSnippet: "Run an EYG program whose every effect is decided by a host policy module",
    promptGuidelines: [
      "Use the eyg tool for every side effect in this session; it is the only channel to the outside world.",
      "When eyg returns a `denied by policy` message, change what the program asks for or report the refusal; do not search for another way to run a command.",
      "A refused eyg effect is a value, not a crash: bind it with a name you use (`let written = perform WriteFile(...)`) and report `written`, because `let _ =` discards the refusal and makes the call look like success when nothing was written.",
      "Use eyg mode eval for a pure computation and eyg mode run when the program performs effects.",
      "Write an eyg effect as `perform Name(argument)`, bound with `let name =` or `let _ =` when another expression follows; `Name(argument)` alone is a function call and the eyg tool reports a parse error for it.",
      "Every eyg path must be absolute: the policy sees absolute paths, and relative paths are resolved from the session's working directory before the gate sees them.",
      "Search with libraries: [\"search\"] and `search_lib.search({root, pattern, limit})` rather than walking directories yourself: the library is one import, and the same roots rule that gates reads gates every directory it opens.",
    ],
    parameters: Type.Object({
      code: Type.String({
        description: "EYG source. The last expression is the value; use Exit or the record `script` field for a status.",
      }),
      mode: Type.Optional(
        Type.String({ description: `"run" (default, effects allowed by the policy) or "eval" (pure)` }),
      ),
      policy: Type.Optional(
        Type.String({
          description:
            "Absolute path to the policy module for this call; default is the policy shipped in this package.",
        }),
      ),
      timeout_ms: Type.Optional(
        Type.Number({ description: `Wall time for the call in ms, at most ${MAX_TIMEOUT_MS}.` }),
      ),
      libraries: Type.Optional(
        Type.Array(
          Type.String({
            description:
              "Names of library modules shipped in this package (`search`) bound as `<name>_lib` before your code runs, so `search_lib.search({root, pattern, limit})` lists files under one root without writing a walk.",
          }),
        ),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const cwd = ctx.cwd || process.cwd();

      // The policy: the call, then the environment, then the package's own
      // preset. A program is never run without one - an ungated run performs
      // every effect the host can reach.
      const fromPackage = defaultPolicy();
      const policy = params.policy ?? process.env.EYG_POLICY ?? fromPackage ?? "";
      const policySource =
        params.policy !== undefined ? "argument" : process.env.EYG_POLICY ? "EYG_POLICY" : fromPackage ? "package default" : "none";
      if (policy === "") {
        return refuseToRun(
          "no policy module was configured and this package ships no preset. Set EYG_POLICY to an absolute path, or pass policy. A program is never run ungated.",
        );
      }
      if (!policy.startsWith("/")) {
        return refuseToRun(`policy must be an absolute path, got ${policy}`);
      }
      if (!existsSync(policy)) {
        return refuseToRun(`policy module not found: ${policy}`);
      }

      const mode = params.mode ?? "run";
      if (mode !== "run" && mode !== "eval") {
        return refuseToRun(`mode must be "run" or "eval", got ${mode}`);
      }
      const wanted = params.timeout_ms ?? Number(process.env.EYG_CODEMODE_TIMEOUT ?? DEFAULT_TIMEOUT_MS);
      const timeout = Math.min(Math.max(Math.trunc(wanted), 100), MAX_TIMEOUT_MS);

      // The runner: named by the environment, otherwise the first candidate
      // that actually accepts the policy flag. The prebuilt CLI release
      // predates `--policy`, so probing rather than assuming is the only way
      // to know the gate exists.
      const configured = process.env.EYG_CODEMODE_RUNNER;
      const candidates = configured
        ? [configured]
        : ["eyg", join(cwd, "packages", "gleam_cli", "dist", "eyg")];
      const runner = await resolveRunner(candidates, async (binary, args) => {
        const result = await pi.exec(binary, args, { signal: null, timeout: PROBE_TIMEOUT_MS, cwd });
        return { stdout: result.stdout ?? "", stderr: result.stderr ?? "", code: result.code ?? 1 };
      });
      if (runner === null) {
        return refuseToRun(
          `no runner that accepts \`--policy\` was found among ${candidates.join(", ")}. ` +
            "Gating happens in the runner, so an older CLI cannot be used: build the current one " +
            "(guides/install_from_source.md) or set EYG_CODEMODE_RUNNER to its absolute path.",
        );
      }

      // The roots the default policy will use. `agent-roots.eyg` reads them
      // from the environment, and a preset that is not this one may ignore the
      // variable entirely, so supplying a default changes nothing for those.
      // `pi.exec` takes signal, timeout, cwd and maxBuffer only
      // (docs/extensions.md#pimax), and a spawned child inherits `process.env`,
      // so the default is written into the environment for this call and the
      // previous value restored right after it.
      const namedRoots = process.env.EYG_ALLOWED_ROOTS;
      const roots = namedRoots && namedRoots !== "" ? namedRoots : cwd;

      // Libraries shipped in the package, bound before the program text so the
      // program can call them by name. A name that is not shipped is refused
      // rather than ignored: the program the user sees would otherwise fail on
      // an unbound name for a reason they cannot act on.
      const prelude: string[] = [];
      for (const name of params.libraries ?? []) {
        const file = libraryFile(name);
        if (file === null) {
          return refuseToRun(
            `library not shipped in this package: ${name}. Available ones live under <package>/libraries/; name one you can see, or write the program without it.`,
          );
        }
        prelude.push(`let ${name}_lib = import ${JSON.stringify(file)}\n`);
      }
      const code = `${prelude.join("")}${params.code}`;
      const args = [mode, "--policy", policy, "-c", code];
      if (namedRoots === undefined) {
        process.env.EYG_ALLOWED_ROOTS = roots;
      }
      let result;
      try {
        result = await pi.exec(runner, args, { signal, timeout, cwd });
      } finally {
        if (namedRoots === undefined) {
          delete process.env.EYG_ALLOWED_ROOTS;
        }
      }

      const out = [result.stdout, result.stderr].filter((text) => text !== "").join("\n");
      const status =
        result.code === 0
          ? "ran"
          : result.killed
            ? `terminated after ${timeout} ms`
            : `exit ${result.code}`;
      return {
        content: [{ type: "text", text: `eyg ${mode}: ${status}\n${out}` }],
        details: {
          gated: true,
          ran: true,
          mode,
          policy,
          policySource,
          runner,
          argv: args,
          exit: result.code,
          killed: result.killed,
          truncated: result.truncated,
          timeoutMs: timeout,
          roots,
        },
      };
    },
  }));
}
