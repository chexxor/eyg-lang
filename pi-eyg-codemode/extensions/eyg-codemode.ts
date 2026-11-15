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
 * There is no shell, no `edit` and no `write` in a session configured by this
 * package: those built-ins are removed from the tool selection, and the
 * built-in JavaScript codemode is disabled so no script can reach a tool that
 * was not gated.
 *
 * Configure the runner and the policy with environment variables so a host can
 * point one session at one policy without editing this file:
 *
 *   EYG_CODEMODE_RUNNER  absolute path to the runner (default: `eyg` on PATH)
 *   EYG_POLICY           absolute path to the policy module (required)
 *   EYG_CODEMODE_TIMEOUT ms for one call (default 30000, capped at 120000)
 */

import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_RUNNER = "eyg";
const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_TIMEOUT_MS = 120_000;

function refuseToRun(reason: string) {
  return {
    content: [{ type: "text", text: `eyg refused: ${reason}` }],
    details: { gated: true, ran: false },
  };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool(defineTool({
    name: "eyg",
    label: "EYG codemode",
    description: [
      "Run an EYG program. A program reaches the outside world only through EYG",
      "effects (ReadFile, WriteFile, AppendFile, DeleteFile, MakeDirectory, ReadDirectory,",
      "Fetch, Env, Exit, StandardOut, ...) and the host policy module decides each one",
      "before the host performs it. A refused effect resumes the program with an EYG",
      "error such as `write_file denied by policy: /abs/path` and nothing on disk changes",
      "- treat that as a fact about the permission, not as a failure of the program.",
      "There is no shell, no package manager and no way to change the policy from inside",
      "a program; a program that needs a denied effect must ask for it and stop.",
      "mode `eval` is pure and prints the value; mode `run` performs effects.",
      "An effect is performed with the `perform` keyword and one argument: `let text = perform ReadFile({path: \"/abs/file\", offset: 0, limit: 2000})`, `let written = perform WriteFile({path: \"/abs/file\", contents: !string_to_binary(\"text\")})`, `perform StandardOut(\"text\")` on the last line. A performed effect that is not the last line must be bound with `let`, otherwise the program does not parse.",
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
    ],
    parameters: Type.Object({
      code: Type.String({
        description: "EYG source. The last expression is the value; use Exit or the record `script` field for a status.",
      }),
      mode: Type.Optional(
        Type.String({ description: `"run" (default, effects allowed by the policy) or "eval" (pure)` }),
      ),
      policy: Type.Optional(
        Type.String({ description: "Absolute path to the policy module for this call; defaults to EYG_POLICY." }),
      ),
      timeout_ms: Type.Optional(
        Type.Number({ description: `Wall time for the call in ms, at most ${MAX_TIMEOUT_MS}.` }),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const policy = params.policy ?? process.env.EYG_POLICY ?? "";
      if (policy === "") {
        return refuseToRun(
          "no policy module was configured. Set EYG_POLICY to an absolute path, or pass policy. " +
            "A program is never run ungated.",
        );
      }
      if (!policy.startsWith("/")) {
        return refuseToRun(`policy must be an absolute path, got ${policy}`);
      }
      const mode = params.mode ?? "run";
      if (mode !== "run" && mode !== "eval") {
        return refuseToRun(`mode must be "run" or "eval", got ${mode}`);
      }
      const wanted = params.timeout_ms ?? Number(process.env.EYG_CODEMODE_TIMEOUT ?? DEFAULT_TIMEOUT_MS);
      const timeout = Math.min(Math.max(Math.trunc(wanted), 100), MAX_TIMEOUT_MS);

      const runner = process.env.EYG_CODEMODE_RUNNER ?? DEFAULT_RUNNER;
      const args = [mode, "--policy", policy, "-c", params.code];
      const result = await pi.exec(runner, args, { signal, timeout, cwd: ctx.cwd });

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
          runner,
          exit: result.code,
          killed: result.killed,
          truncated: result.truncated,
          timeoutMs: timeout,
        },
      };
    },
  }));
}
