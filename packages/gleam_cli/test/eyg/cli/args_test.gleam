import eyg/cli/args
import gleam/option.{None, Some}
import gleam/string
import loam/source

pub fn run_test() {
  let file = "example.eyg.json"
  assert args.Run(source.File(file), None) == args.parse(["run", file])
}

pub fn run_code_test() {
  let code = "!print(\"hello\")"
  assert args.Run(source.Code(code), None) == args.parse(["run", "-c", code])
}

pub fn run_code_long_flag_test() {
  let code = "!print(\"hello\")"
  assert args.Run(source.Code(code), None)
    == args.parse(["run", "--code", code])
}

pub fn run_stdin_test() {
  assert args.Run(source.Stdin, None) == args.parse(["run", "-"])
}

pub fn run_stdin_long_flag_test() {
  assert args.Run(source.Stdin, None) == args.parse(["run", "--stdin"])
}

pub fn run_with_policy_test() {
  assert args.Run(source.File("a.eyg"), Some(source.File("policy.eyg")))
    == args.parse(["run", "--policy", "policy.eyg", "a.eyg"])
}

pub fn run_policy_code_test() {
  let code = "!print(\"hello\")"
  assert args.Run(source.Code(code), Some(source.File("policy.eyg")))
    == args.parse(["run", "--policy", "policy.eyg", "-c", code])
}

pub fn policy_without_program_is_usage_test() {
  let assert args.InvalidArguments(message) = args.parse(["run", "--policy"])
  assert string.starts_with(message, "usage: eyg run --policy")
}

pub fn eval_code_test() {
  let code = "!int_add(1, 1)"
  assert args.Eval(source.Code(code), None) == args.parse(["eval", "-c", code])
}

pub fn eval_stdin_test() {
  assert args.Eval(source.Stdin, None) == args.parse(["eval", "-"])
}

pub fn eval_stdin_long_flag_test() {
  assert args.Eval(source.Stdin, None) == args.parse(["eval", "--stdin"])
}

pub fn eval_with_policy_test() {
  let code = "!int_add(1, 1)"
  assert args.Eval(source.Code(code), Some(source.File("policy.eyg")))
    == args.parse(["eval", "--policy", "policy.eyg", "-c", code])
}

pub fn run_policy_is_documented_test() {
  assert string.contains(args.help_text, "run --policy <m> <src>")
  assert string.contains(args.help_text, "eval --policy <m>")
  assert string.contains(args.help_text, "script --policy <m> <file> [args...]")
}

pub fn check_stdin_test() {
  assert args.Check(source.Stdin) == args.parse(["check", "-"])
}

pub fn check_stdin_long_flag_test() {
  assert args.Check(source.Stdin) == args.parse(["check", "--stdin"])
}

pub fn compile_code_test() {
  let code = "!int_add(1, 1)"
  assert args.Compile(source.Code(code)) == args.parse(["compile", "-c", code])
}

pub fn compile_stdin_test() {
  assert args.Compile(source.Stdin) == args.parse(["compile", "-"])
}

pub fn compile_stdin_long_flag_test() {
  assert args.Compile(source.Stdin) == args.parse(["compile", "--stdin"])
}

pub fn script_from_cid_test() {
  let cid = "#baguqeerat6kjk2gjedpjcv4tuh5qiozijzgbhenep5cjfbe7vgc2ehjcqlma"
  assert args.Script(source.Code(cid), [], None) == args.parse([cid])
}

pub fn script_from_cid_with_args_test() {
  let cid = "#baguqeerat6kjk2gjedpjcv4tuh5qiozijzgbhenep5cjfbe7vgc2ehjcqlma"
  assert args.Script(source.Code(cid), ["a", "b"], None)
    == args.parse([cid, "a", "b"])
}

pub fn script_from_package_test() {
  assert args.Script(source.Code("@standard"), [], None)
    == args.parse(["@standard"])
}

pub fn script_with_policy_test() {
  assert args.Script(
      source.File("a.eyg"),
      ["x"],
      Some(source.File("policy.eyg")),
    )
    == args.parse(["script", "--policy", "policy.eyg", "a.eyg", "x"])
}

pub fn signatory_inspection_commands_test() {
  assert args.parse(["signatory", "list"]) == args.SignatoryList
  assert args.parse(["signatory", "show", "personal"])
    == args.SignatoryShow("personal")
  assert string.contains(args.help_text, "signatory list")
  assert string.contains(args.help_text, "signatory show <name>")
}

pub fn malformed_signatory_commands_are_not_scripts_test() {
  let assert args.InvalidArguments(message) = args.parse(["signatory", "show"])
  assert string.starts_with(message, "usage: eyg signatory initial <name>")
  assert args.parse(["script", "signatory", "list"])
    == args.Script(source.File("signatory"), ["list"], None)
}

pub fn script_with_policy_none_for_plain_script_test() {
  assert args.Script(source.File("a.eyg"), [], None) == args.parse(["a.eyg"])
}

pub fn overlay_without_file_shows_usage_test() {
  let assert args.InvalidArguments(message) = args.parse(["overlay"])
  assert message
    == "usage: eyg overlay <file> | eyg overlay -c <code> | eyg overlay -"
  let assert args.InvalidArguments(_) = args.parse(["overlay", "--help"])
}
