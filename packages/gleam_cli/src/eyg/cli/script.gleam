import eyg/cli/internal/arguments as cli_arguments
import eyg/cli/internal/config
import eyg/hub/cache
import eyg/interpreter/cast
import eyg/interpreter/state
import gleam/option.{None, Some}
import loam/execute
import loam/source
import loam/system

pub fn execute(
  input: source.Input,
  arguments: List(String),
  config: config.Config,
) -> system.Effect(Result(Int, String)) {
  use cwd <- system.then(system.cwd())
  use cwd <- system.try(cwd)
  use input <- system.try(source.normalize_input(cwd, input))
  use code <- system.then(source.read_input(input))
  use code <- system.try(code)
  use source <- system.try(source.parse_input(code, input))

  let state = execute.State(config.client.origin, cache.empty())
  // The synthetic `.script(arguments)` wrapper carries the user source's
  // location so any error here is rendered against the actual source.
  let user_meta = source.1
  let source = cli_arguments.wrap_call(source, arguments, user_meta)

  use #(result, _) <- system.map(execute.block(source, [], state))
  case result {
    Ok(#(Some(exit_code), _)) ->
      case cast.as_integer(exit_code) {
        Ok(exit_code) -> Ok(exit_code)
        Error(reason) ->
          Error(execute.render_error(reason, user_meta, state.Empty, cwd))
      }
    Ok(#(None, _)) -> Ok(0)
    Error(#(reason, location, _, k)) -> {
      Error(execute.render_error(reason, location, k, cwd))
    }
  }
}
