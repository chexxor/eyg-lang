import birdie
import eyg/cli/helpers
import eyg/cli/policy_runner
import loam/sandbox
import loam/sandbox/fs
import loam/source

// The gate under test is the one an overlay session binds (see `overlay.gleam`
// `gated`), installed on the one-shot `--policy` runner. Each test runs inside
// `loam/sandbox`, so a refusal is proved by the virtual filesystem staying
// unchanged rather than by touching the host.

// Every effect the CLI gates gets a rule; a rule that returns `Mock` never
// reaches the host.
const deny_all =
  "{
  append_file: (_) -> { Mock(Error(\"append_file denied by policy\")) },
  create_key: (_) -> { Mock(Error(\"create_key denied by policy\")) },
  cwd: (value) -> { Pass(value) },
  delete_file: (_) -> { Mock(Error(\"delete_file denied by policy\")) },
  env: (_) -> { Mock(None({})) },
  exit: (value) -> { Pass(value) },
  fetch: (_) -> { Mock(Error(\"fetch denied by policy\")) },
  flip: (value) -> { Pass(value) },
  make_directory: (_) -> { Mock(Error(\"make_directory denied by policy\")) },
  now: (value) -> { Pass(value) },
  random: (value) -> { Pass(value) },
  read_directory: (_) -> { Mock(Error(\"read_directory denied by policy\")) },
  read_file: (_) -> { Mock(Error(\"read_file denied by policy\")) },
  sleep: (value) -> { Pass(value) },
  standard_error: (value) -> { Pass(value) },
  standard_in: (_) -> { Mock(Error(\"standard_in denied by policy\")) },
  standard_out: (value) -> { Pass(value) },
  write_file: (_) -> { Mock(Error(\"write_file denied by policy\")) },
}"

// A policy module is host configuration evaluated outside the gate, so it may
// use effects: here it opens `write_file` only when the host says so through
// the environment, which the program under the gate cannot read.
pub fn policy_opening_write_when_the_host_says_yes() -> String {
  "let base = "
  <> deny_all
  <> "\nlet open = match perform Env(\"AGENT_ALLOW_WRITE\") {\n"
  <> "  Some(text) -> { !equal(text, \"yes\") }\n"
  <> "  None({}) -> { False({}) }\n"
  <> "}\n"
  <> "match open {\n"
  <> "  True(_) -> { { write_file: (value) -> { Pass(value) }, ..base } }\n"
  <> "  False(_) -> { base }\n"
  <> "}"
}

pub fn gated_run(
  program: String,
  policy: String,
) -> #(Result(Int, String), sandbox.Sandbox(Nil)) {
  let assert #(sandbox.Returned(status), filesystem) =
    sandbox.run(
      policy_runner.run(
        source.Code(program),
        source.Code(policy),
        helpers.config,
      ),
      sandbox.sandbox(),
    )
  #(status, filesystem)
}

pub fn write_outside_the_allowed_set_is_refused_test() {
  let #(status, filesystem) =
    gated_run(
      "perform WriteFile({path: \"/outside/escape.txt\", contents: !string_to_binary(\"payload\")})",
      deny_all,
    )
  // the refusal is the policy's EYG reason and the runner reports it.
  assert status == Error("write_file denied by policy")
  // and nothing was written.
  let assert Error(_) =
    fs.read_bits(filesystem.file_system, "/outside/escape.txt")
}

pub fn fetch_is_refused_test() {
  let request =
    "perform Fetch({method: GET({}), scheme: HTTPS({}), host: \"eyg.run\", port: None({}), path: \"/\", query: None({}), headers: [], body: !string_to_binary(\"\")})"
  let #(status, _) = gated_run(request, deny_all)
  assert status == Error("fetch denied by policy")
}

pub fn a_gated_script_reports_its_own_refusal_test() {
  let program =
    "{ script: (arguments) -> {
  match perform WriteFile({path: \"/outside/escape.txt\", contents: !string_to_binary(\"payload\")}) {
    Ok(_) -> { 0 }
    Error(_) -> { 3 }
  }
} }"
  let assert #(sandbox.Returned(status), filesystem) =
    sandbox.run(
      policy_runner.script(
        source.Code(program),
        [],
        source.Code(deny_all),
        helpers.config,
      ),
      sandbox.sandbox(),
    )
  assert status == Ok(3)
  let assert Error(_) =
    fs.read_bits(filesystem.file_system, "/outside/escape.txt")
}

pub fn the_program_cannot_read_the_environment_test() {
  let space =
    sandbox.sandbox()
    |> sandbox.with_env("AGENT_TOKEN", "a-secret-the-agent-must-not-see")
  let program =
    "match perform Env(\"AGENT_TOKEN\") {
  Some(secret) -> { !never(perform Abort(!string_append(\"leaked: \", secret))) }
  None({}) -> { 0 }
}"
  let assert #(sandbox.Returned(status), _) =
    sandbox.run(
      policy_runner.run(
        source.Code(program),
        source.Code(deny_all),
        helpers.config,
      ),
      space,
    )
  assert status == Ok(0)
}

pub fn the_policy_module_reads_the_environment_test() {
  let policy = policy_opening_write_when_the_host_says_yes()
  let space = sandbox.sandbox() |> sandbox.with_env("AGENT_ALLOW_WRITE", "yes")
  let assert #(sandbox.Returned(status), filesystem) =
    sandbox.run(
      policy_runner.run(
        source.Code(
          "perform WriteFile({path: \"/a.txt\", contents: !string_to_binary(\"payload\")})",
        ),
        source.Code(policy),
        helpers.config,
      ),
      space,
    )
  assert status == Ok(0)
  let assert Ok(contents) = fs.read_bits(filesystem.file_system, "/a.txt")
  assert contents == <<"payload":utf8>>
}

pub fn a_policy_module_missing_a_gated_field_is_a_configuration_error_test() {
  let #(status, _) = gated_run("0", "{write_file: (value) -> { Pass(value) }}")
  let assert Error(reason) = status
  birdie.snap(reason, title: "policy module missing gated fields")
}

pub fn a_broken_policy_module_is_visible_for_eval_test() {
  let effect =
    policy_runner.eval(
      source.Code("int_add(1, 2)"),
      source.Code("let _ = perform Abort(\"policy module failed\")\n{}"),
      helpers.config,
    )
  let assert #(sandbox.Returned(status), _) =
    sandbox.run(effect, sandbox.sandbox())
  let assert Error(reason) = status
  birdie.snap(reason, title: "eval reports a broken policy module")
}
