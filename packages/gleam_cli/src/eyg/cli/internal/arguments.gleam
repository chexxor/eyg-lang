//// The synthetic `script(arguments)` call that carries the CLI's remaining
//// arguments. Shared so `eyg script` and the policy gated runner call exactly
//// the same shape.

import eyg/ir/tree as ir
import gleam/list

pub fn wrap_call(
  program: ir.Node(m),
  arguments: List(String),
  meta: m,
) -> ir.Node(m) {
  let arguments =
    list.map(arguments, fn(arg) { #(ir.String(arg), meta) })
    |> wrap_list(meta)
  #(
    ir.Apply(
      #(ir.Apply(#(ir.Select("script"), meta), program), meta),
      arguments,
    ),
    meta,
  )
}

fn wrap_list(items, meta) {
  list.fold_right(items, #(ir.Tail, meta), fn(acc, item) {
    #(ir.Apply(#(ir.Apply(#(ir.Cons, meta), item), meta), acc), meta)
  })
}
