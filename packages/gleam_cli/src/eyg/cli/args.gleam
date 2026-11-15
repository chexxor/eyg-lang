import gleam/option.{type Option, None, Some}
import loam/source

pub type Args {
  Shell(Option(source.Input))
  Tui(Option(source.Input))
  Run(input: source.Input, policy: Option(source.Input))
  Script(
    input: source.Input,
    arguments: List(String),
    policy: Option(source.Input),
  )
  Eval(input: source.Input, policy: Option(source.Input))
  Check(input: source.Input)
  Compile(input: source.Input)
  Parse(input: source.Input)
  Share(input: source.Input)
  Fetch(cid: String)
  SignatoryInitial(name: String)
  SignatoryList
  SignatoryShow(alias: String)
  Publish(package: String, file: String)
  Overlay(input: source.Input)
  InvalidArguments(message: String)
  Help
  Version
}

pub fn parse(args) {
  case args {
    [] -> Shell(None)
    ["shell", "-c", code] | ["shell", "--code", code] ->
      Shell(Some(source.Code(code)))
    ["shell", "-"] | ["shell", "--stdin"] -> Shell(Some(source.Stdin))
    ["shell", "#" <> _ as code] | ["shell", "@" <> _ as code] ->
      Shell(Some(source.Code(code)))
    ["shell", file] -> Shell(Some(source.File(file)))
    ["tui"] -> Tui(None)
    ["tui", "-c", code] | ["tui", "--code", code] ->
      Tui(Some(source.Code(code)))
    ["tui", "-"] | ["tui", "--stdin"] -> Tui(Some(source.Stdin))
    ["tui", "#" <> _ as code] | ["tui", "@" <> _ as code] ->
      Tui(Some(source.Code(code)))
    ["tui", file] -> Tui(Some(source.File(file)))
    ["run", ..rest] -> run_args(rest)
    ["eval", ..rest] -> eval_args(rest)
    ["script", ..rest] -> script_args(rest)
    ["check", "-c", code] | ["check", "--code", code] ->
      Check(source.Code(code))
    ["check", "-"] | ["check", "--stdin"] -> Check(source.Stdin)
    ["check", "#" <> _ as code] | ["check", "@" <> _ as code] ->
      Check(source.Code(code))
    ["check", file] -> Check(source.File(file))
    ["compile", "-c", code] | ["compile", "--code", code] ->
      Compile(source.Code(code))
    ["compile", "-"] | ["compile", "--stdin"] -> Compile(source.Stdin)
    ["compile", "#" <> _ as code] | ["compile", "@" <> _ as code] ->
      Compile(source.Code(code))
    ["compile", file] -> Compile(source.File(file))
    ["parse", "-c", code] | ["parse", "--code", code] ->
      Parse(source.Code(code))
    ["parse", "-"] | ["parse", "--stdin"] -> Parse(source.Stdin)
    ["parse", "#" <> _ as code] | ["parse", "@" <> _ as code] ->
      Parse(source.Code(code))
    ["parse", file] -> Parse(source.File(file))
    ["share", "-c", code] | ["share", "--code", code] ->
      Share(source.Code(code))
    ["share", "-"] | ["share", "--stdin"] -> Share(source.Stdin)
    ["share", file] -> Share(source.File(file))
    ["fetch", cid] -> Fetch(cid:)
    ["publish", package, file] -> Publish(package:, file:)
    ["signatory", "initial", name] -> SignatoryInitial(name:)
    ["signatory", "list"] -> SignatoryList
    ["signatory", "show", alias] -> SignatoryShow(alias:)
    ["signatory", ..] ->
      InvalidArguments(
        "usage: eyg signatory initial <name> | eyg signatory list | eyg signatory show <name>",
      )
    ["overlay"] | ["overlay", "--help"] | ["overlay", "-h"] ->
      InvalidArguments(
        "usage: eyg overlay <file> | eyg overlay -c <code> | eyg overlay -",
      )
    ["overlay", "-c", code] | ["overlay", "--code", code] ->
      Overlay(source.Code(code))
    ["overlay", "-"] | ["overlay", "--stdin"] -> Overlay(source.Stdin)
    ["overlay", file] -> Overlay(source.File(file))
    // overlay doesn't support using a release or content reference as auth should not be included
    ["help"] | ["--help"] | ["-h"] -> Help
    ["version"] | ["--version"] | ["-V"] -> Version
    ["#" <> _ as code, ..arguments] | ["@" <> _ as code, ..arguments] ->
      Script(source.Code(code), arguments, None)
    [file, ..arguments] -> Script(source.File(file), arguments, None)
  }
}

pub const help_text =
  "eyg — run EYG programs and interact with the EYG hub
usage: eyg [<command> [<args>]]
commands:
  (no args)              start the shell
  shell <file>           start a shell with the file as shell config
  shell #<mod>, @<pkg>   start a shell with a module or package as shell config
  shell -, --stdin       start a shell with stdin as shell config
  shell -c, --code <code>start a shell with inline shell config
  tui                    start the tui
  tui <file>             start a tui with the file as shell config
  tui #<mod>, @<pkg>     start a tui with a module or package as shell config
  tui -, --stdin         start a tui with stdin as shell config
  tui -c, --code <code>  start a tui with inline shell config
  script <file>          run the script from the provided file
  script -, --stdin      run a script read from stdin
  script -c, --code <code>
  script #<mod>, @<pkg>  run a script from a module or package
                         run a script from inline source
  script --policy <m> <file> [args...]
                         run a script with every effect decided by the policy
                         module <m>
  <file> [args...]       run a script with the remaining CLI args
  #<cid> [args...]       run a script fetched by content id
  @<pkg> [args...]       run a script from a published package
  eval <file>            evaluate and print an expression with no side effects
  eval -, --stdin        evaluate EYG source read from stdin
  eval -c, --code <code> evaluate inline EYG source with no side effects
  eval --policy <m>      load the policy module <m>, then evaluate as above
  eval #<mod>, @<pkg>    evaluate a module or package
  check <file>           type check a script
  check -, --stdin       type check EYG source read from stdin
  check -c, --code <code>type check inline EYG source
  check #<mod>, @<pkg>   type check a module or package
  run <file>             run EYG source from file
  run -, --stdin         run EYG source read from stdin
  run -c, --code <code>  run inline EYG source
  run --policy <m> <src>
                         run EYG source with every effect decided by the policy
                         module <m>; <src> is a file, -, --stdin, -c <code> or #<cid>
  run #<mod>, @<pkg>     run a module or package
  compile <file>         compile a script to JavaScript
  compile -, --stdin     compile EYG source read from stdin
  compile -c, --code <code>
                         compile inline EYG source to JavaScript
  compile #<mod>, @<pkg> Compile a module or package to JavaScript
  parse <file>           parse EYG source from file and write JSON to stdout
  parse -, --stdin       parse EYG source read from stdin and write JSON to stdout
  parse -c, --code <code>parse inline EYG source and write JSON to stdout
  parse #<mod>, @<pkg>   parse a module or package and write JSON to stdout
  share <file>           share EYG source from file
  share -, --stdin       share EYG source read from stdin
  share -c, --code <code>share inline EYG source
  fetch <cid>            fetch a module by content id
  publish <pkg> <file>   publish a module under a package name
  signatory initial <n>  create a signatory principal called <n>
  signatory list         list local signatory metadata and current hub status
  signatory show <name>  show signatory metadata and complete hub event history
  overlay <file>         start an overlay session with config file
  overlay -, --stdin     start an overlay session with config from stdin
  overlay -c, --code <code>
                         start an overlay session with inline config
  help, --help, -h       show this message
  version, --version, -V show the eyg version
environment:
  EYG_ORIGIN             override the hub origin (default: https://eyg.run)
"

// `--policy <module.eyg>` is a runner side flag: it is read before the source
// argument so one flag form covers every way of giving the program a source.
fn run_args(rest) {
  case rest {
    ["--policy", file, "-c", code]
    | ["--policy", file, "--code", code]
    | ["--policy", file, "#" <> _ as code]
    | ["--policy", file, "@" <> _ as code] ->
      Run(source.Code(code), Some(source.File(file)))
    ["--policy", file, "-"] | ["--policy", file, "--stdin"] ->
      Run(source.Stdin, Some(source.File(file)))
    ["--policy", file, program] ->
      Run(source.File(program), Some(source.File(file)))
    ["--policy"] ->
      InvalidArguments(
        "usage: eyg run --policy <module.eyg> <file> | -c <code> | -",
      )
    ["-c", code] | ["--code", code] -> Run(source.Code(code), None)
    ["-"] | ["--stdin"] -> Run(source.Stdin, None)
    ["#" <> _ as code] | ["@" <> _ as code] -> Run(source.Code(code), None)
    [file] -> Run(source.File(file), None)
    [] -> InvalidArguments("usage: eyg run <file> | -c <code> | -")
    [_, ..] -> InvalidArguments("usage: eyg run <file> | -c <code> | -")
  }
}

fn eval_args(rest) {
  case rest {
    ["--policy", file, "-c", code]
    | ["--policy", file, "--code", code]
    | ["--policy", file, "#" <> _ as code]
    | ["--policy", file, "@" <> _ as code] ->
      Eval(source.Code(code), Some(source.File(file)))
    ["--policy", file, "-"] | ["--policy", file, "--stdin"] ->
      Eval(source.Stdin, Some(source.File(file)))
    ["--policy", file, program] ->
      Eval(source.File(program), Some(source.File(file)))
    ["--policy"] ->
      InvalidArguments(
        "usage: eyg eval --policy <module.eyg> <file> | -c <code> | -",
      )
    ["-c", code] | ["--code", code] -> Eval(source.Code(code), None)
    ["-"] | ["--stdin"] -> Eval(source.Stdin, None)
    ["#" <> _ as code] | ["@" <> _ as code] -> Eval(source.Code(code), None)
    [file] -> Eval(source.File(file), None)
    [] -> InvalidArguments("usage: eyg eval <file> | -c <code> | -")
    [_, ..] -> InvalidArguments("usage: eyg eval <file> | -c <code> | -")
  }
}

fn script_args(rest) {
  case rest {
    ["--policy", _] | ["--policy"] ->
      InvalidArguments(
        "usage: eyg script --policy <module.eyg> <file> [args...]",
      )
    ["--policy", file, "-c", code, ..arguments]
    | ["--policy", file, "--code", code, ..arguments]
    | ["--policy", file, "#" <> _ as code, ..arguments]
    | ["--policy", file, "@" <> _ as code, ..arguments] ->
      Script(source.Code(code), arguments, Some(source.File(file)))
    ["--policy", file, "-", ..arguments]
    | ["--policy", file, "--stdin", ..arguments] ->
      Script(source.Stdin, arguments, Some(source.File(file)))
    ["--policy", file, program, ..arguments] ->
      Script(source.File(program), arguments, Some(source.File(file)))
    ["-c", code, ..arguments] | ["--code", code, ..arguments] ->
      Script(source.Code(code), arguments, None)
    ["-", ..arguments] | ["--stdin", ..arguments] ->
      Script(source.Stdin, arguments, None)
    ["#" <> _ as code, ..arguments] | ["@" <> _ as code, ..arguments] ->
      Script(source.Code(code), arguments, None)
    [file, ..arguments] -> Script(source.File(file), arguments, None)
    [] -> InvalidArguments("usage: eyg script <file> [args...]")
  }
}
