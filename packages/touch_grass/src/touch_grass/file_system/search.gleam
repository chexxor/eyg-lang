//// Find the file paths under a directory whose name matches a glob pattern.
////
//// The effect is the shape `find` gives a shell: walk a tree once, report the
//// paths that match, without the program asking per directory. A program that
//// walks with `ReadDirectory` pays one gated effect per directory and re-decides
//// the same root every time; this asks once and the policy rules it once
//// (`notes/codemode_search_effect.md` records the trade-off).
////
//// Matching is done over the path relative to the searched directory:
////
////   - `*` in a segment matches any run of characters in that segment
////   - `**` as a whole segment matches any number of segments
////   - anything else compares equal
////
//// So `*.eyg` matches `entry.eyg` one level down and `**/*.eyg` matches it at
//// any depth. At most one `*` per segment.
//// The returned paths are absolute, as `find` prints them, so a program can
//// hand one straight back to `ReadFile`.

import eyg/analysis/type_/isomorphic as t
import eyg/interpreter/cast
import eyg/interpreter/value as v
import gleam/list
import gleam/result.{try}
import gleam/string

pub const label = "Search"

pub type Input {
  Input(path: String, pattern: String, limit: Int)
}

pub fn lift() {
  t.record([
    #("path", t.String),
    #("pattern", t.String),
    #("limit", t.Integer),
  ])
}

pub fn lower() {
  t.result(t.List(t.String), t.String)
}

pub fn decode(input) {
  use path <- try(cast.field("path", cast.as_string, input))
  use pattern <- try(cast.field("pattern", cast.as_string, input))
  use limit <- try(cast.field("limit", cast.as_integer, input))
  Ok(Input(path:, pattern:, limit:))
}

pub fn encode(result: Result(List(String), String)) {
  case result {
    Ok(paths) -> v.ok(v.LinkedList(list.map(paths, v.String)))
    Error(reason) -> v.error(v.String(reason))
  }
}

/// Does a path relative to the searched directory match the glob pattern?
pub fn matches(pattern: String, path: String) -> Bool {
  match_segments(string.split(pattern, "/"), string.split(path, "/"))
}

/// Match a list of pattern segments against a list of path segments. A `**`
/// segment matches zero or more path segments.
fn match_segments(patterns: List(String), segments: List(String)) -> Bool {
  case patterns {
    [] -> list.is_empty(segments)
    ["**", ..rest] -> {
      match_segments(rest, segments)
      || case segments {
        [] -> False
        [_, ..tail] -> match_segments(patterns, tail)
      }
    }
    [pattern, ..rest] ->
      case segments {
        [] -> False
        [segment, ..tail] ->
          match_segment(pattern, segment) && match_segments(rest, tail)
      }
  }
}

/// A single segment. `*` matches any run of characters, at most one per
/// segment; a segment with no `*` must compare equal.
fn match_segment(pattern: String, segment: String) -> Bool {
  case string.split_once(pattern, "*") {
    Ok(#(prefix, suffix)) ->
      string.starts_with(segment, prefix)
      && string.ends_with(segment, suffix)
      && string.byte_size(segment)
      >= string.byte_size(prefix) + string.byte_size(suffix)
    Error(Nil) -> pattern == segment
  }
}
