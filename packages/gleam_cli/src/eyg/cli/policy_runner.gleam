//// Run an EYG program with every effect decided by a policy module.
////
//// This is the Pass/Mock gate an overlay session binds (see
//// `docs/world/entities/overlay.policy-gate.md`), installed on the host side of
//// a one-shot runner. A program cannot opt out of it: the interpreter stops at
//// every effect and this module asks the policy before the host performs it.
//// Filesystem paths are resolved to absolute before a policy sees them, so a
//// policy never has to know about relative paths.
////
//// The policy module is host authored configuration, not the program under the
//// gate, so it is evaluated with the ungated evaluator and may itself use
//// effects, such as reading a token from the environment.

import eyg/cli/eval as pure_eval
import eyg/cli/internal/arguments as cli_arguments
import eyg/cli/internal/config
import eyg/cli/overlay as gate
import eyg/hub/cache
import eyg/interpreter/cast
import eyg/interpreter/simple_debug
import eyg/interpreter/state
import eyg/interpreter/value
import eyg/ir/tree as ir
import gleam/option.{type Option, None, Some}
import loam/execute
import loam/platform/computer
import loam/source
import loam/system
import overlay/policy
import touch_grass/harness/computer as harness_computer
import touch_grass/interface

/// The effect set a gated run can reach, bound to the policy field for each.
/// An effect with no rule never reaches the program, and an effect ruled
/// `Unchecked` is performed without asking the policy.
pub fn gate_rules() -> List(
  #(interface.Interface(harness_computer.Effect, source.Location), policy.Rule),
) {
  policy.match_rules(computer.effects(), gate.rule_mapping)
}

/// Evaluate a policy module and decode it against the harness. A module that is
/// missing a gated field is a configuration error, not an effect denial.
pub fn load(
  input: source.Input,
  cwd: String,
  config: config.Config,
) -> system.Effect(
  Result(
    #(policy.Policy(harness_computer.Effect, source.Location), execute.State),
    String,
  ),
) {
  let empty = execute.State(config.client.origin, cache.empty())
  use input <- system.try(source.normalize_input(cwd, input))
  use code <- system.then(source.read_input(input))
  use code <- system.try(code)
  use module <- system.try(source.parse_input(code, input))
  use #(result, st) <- system.then(execute.block(module, [], empty))
  case result {
    Ok(#(Some(policy_value), _)) ->
      case policy.decode_policy(gate_rules(), policy_value) {
        Ok(policy) -> system.Done(Ok(#(policy, st)))
        Error(reason) ->
          system.Done(
            Error(execute.render_error(reason, module.1, state.Empty, cwd)),
          )
      }
    Ok(#(None, _)) ->
      system.Done(Error(
        "a policy module must evaluate to a record with a field per gated effect",
      ))
    Error(#(reason, location, _env, stack)) ->
      system.Done(Error(execute.render_error(reason, location, stack, cwd)))
  }
}

/// Run an already parsed program with each effect decided by the policy module.
pub fn evaluate(
  program: ir.Node(source.Location),
  policy_input: source.Input,
  cwd: String,
  config: config.Config,
) -> system.Effect(Result(Option(state.Value(source.Location)), String)) {
  use loaded <- system.then(load(policy_input, cwd, config))
  case loaded {
    Ok(#(policy, execution)) -> run_gated(program, policy, execution, cwd)
    Error(reason) -> system.Done(Error(reason))
  }
}

/// Hand the parsed program to the gate loop and render a failure against the
/// working directory the run started in.
fn run_gated(
  program: ir.Node(source.Location),
  policy: policy.Policy(harness_computer.Effect, source.Location),
  execution: execute.State,
  cwd: String,
) -> system.Effect(Result(Option(state.Value(source.Location)), String)) {
  use #(result, _, _) <- system.map(gate.gated(program, policy, execution))
  case result {
    Ok(#(value, _)) -> Ok(value)
    Error(#(reason, location, _env, stack)) ->
      Error(execute.render_error(reason, location, stack, cwd))
  }
}

/// `eyg run --policy <module.eyg>`: the program runs and its value is discarded,
/// as in ungated `run`. A program that ends on an unhandled `Error` value is a
/// program that was refused an effect and did not handle the refusal, so the
/// reason is returned as the CLI error: the CLI writes it to stderr and exits 1,
/// so a denial is never silent.
pub fn run(
  input: source.Input,
  policy_input: source.Input,
  config: config.Config,
) -> system.Effect(Result(Int, String)) {
  use cwd <- system.then(system.cwd())
  use cwd <- system.try(cwd)
  use input <- system.try(source.normalize_input(cwd, input))
  use code <- system.then(source.read_input(input))
  use code <- system.try(code)
  use program <- system.try(source.parse_input(code, input))
  use result <- system.then(evaluate(program, policy_input, cwd, config))
  case result {
    Ok(Some(value.Tagged("Error", reason))) -> {
      let text = case cast.as_string(reason) {
        Ok(text) -> text
        Error(_) -> simple_debug.inspect(reason)
      }
      system.Done(Error(text))
    }
    Ok(_) -> system.Done(Ok(0))
    Error(reason) -> system.Done(Error(reason))
  }
}

/// `eyg script --policy <module.eyg> <file> [args]`: the value of the program's
/// `script` field is the exit code.
pub fn script(
  input: source.Input,
  arguments: List(String),
  policy_input: source.Input,
  config: config.Config,
) -> system.Effect(Result(Int, String)) {
  use cwd <- system.then(system.cwd())
  use cwd <- system.try(cwd)
  use input <- system.try(source.normalize_input(cwd, input))
  use code <- system.then(source.read_input(input))
  use code <- system.try(code)
  use program <- system.try(source.parse_input(code, input))
  let program = cli_arguments.wrap_call(program, arguments, program.1)
  use result <- system.then(evaluate(program, policy_input, cwd, config))
  case result {
    Ok(Some(exit_code)) ->
      case cast.as_integer(exit_code) {
        Ok(exit_code) -> system.Done(Ok(exit_code))
        Error(reason) ->
          system.Done(
            Error(execute.render_error(reason, program.1, state.Empty, cwd)),
          )
      }
    Ok(None) -> system.Done(Ok(0))
    Error(reason) -> system.Done(Error(reason))
  }
}

/// `eyg eval --policy <module.eyg>`: eval is pure so the gate has no effect to
/// decide, but the module is still loaded so a broken policy is a visible error.
pub fn eval(
  input: source.Input,
  policy_input: source.Input,
  config: config.Config,
) -> system.Effect(Result(Int, String)) {
  use cwd <- system.then(system.cwd())
  use cwd <- system.try(cwd)
  use loaded <- system.then(load(policy_input, cwd, config))
  case loaded {
    Ok(_) -> pure_eval.execute(input, config)
    Error(reason) -> system.Done(Error(reason))
  }
}
