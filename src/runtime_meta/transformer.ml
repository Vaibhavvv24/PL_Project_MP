(**Runtime Meta-Programming: AST Visualization
    Pretty-prints expression trees in a readable tree format,
    showing ASTs before and after optimization.
    *)

open Dsl

(** Print an expression as an indented tree to stdout.
    Example output for  Add(Mul(Const 2, Var "x"), Const 5):
      Add
      ├── Mul
      │   ├── 2
      │   └── x
      └── 5
*)
let rec print_tree ?(prefix = "") ?(is_last = true) (e : expr) : unit =
  let connector = if is_last then "└── " else "├── " in
  let child_pfx = prefix ^ (if is_last then "    " else "│   ") in
  match e with
  | Const n ->
      Printf.printf "%s%s%d\n" prefix connector n
  | Var x ->
      Printf.printf "%s%s%s\n" prefix connector x
  | Neg e1 ->
      Printf.printf "%s%sNeg\n" prefix connector;
      print_tree ~prefix:child_pfx ~is_last:true e1
  | Add (e1, e2) ->
      Printf.printf "%s%sAdd\n" prefix connector;
      print_tree ~prefix:child_pfx ~is_last:false e1;
      print_tree ~prefix:child_pfx ~is_last:true  e2
  | Sub (e1, e2) ->
      Printf.printf "%s%sSub\n" prefix connector;
      print_tree ~prefix:child_pfx ~is_last:false e1;
      print_tree ~prefix:child_pfx ~is_last:true  e2
  | Mul (e1, e2) ->
      Printf.printf "%s%sMul\n" prefix connector;
      print_tree ~prefix:child_pfx ~is_last:false e1;
      print_tree ~prefix:child_pfx ~is_last:true  e2
  | Div (e1, e2) ->
      Printf.printf "%s%sDiv\n" prefix connector;
      print_tree ~prefix:child_pfx ~is_last:false e1;
      print_tree ~prefix:child_pfx ~is_last:true  e2
  | Let (x, e1, e2) ->
      Printf.printf "%s%sLet %s\n" prefix connector x;
      print_tree ~prefix:child_pfx ~is_last:false e1;
      print_tree ~prefix:child_pfx ~is_last:true  e2

(** Print a top-level expression tree (root node has no connector). *)
let print_expr_tree (e : expr) : unit =
  match e with
  | Const n -> Printf.printf "%d\n" n
  | Var x   -> Printf.printf "%s\n" x
  | Neg e1  ->
      Printf.printf "Neg\n";
      print_tree ~prefix:"" ~is_last:true e1
  | Add (e1, e2) | Sub (e1, e2) | Mul (e1, e2) | Div (e1, e2) ->
      let op = match e with
        | Add _ -> "Add" | Sub _ -> "Sub" | Mul _ -> "Mul" | _ -> "Div" in
      Printf.printf "%s\n" op;
      print_tree ~prefix:"" ~is_last:false e1;
      print_tree ~prefix:"" ~is_last:true  e2
  | Let (x, e1, e2) ->
      Printf.printf "Let %s\n" x;
      print_tree ~prefix:"" ~is_last:false e1;
      print_tree ~prefix:"" ~is_last:true  e2

(** Show before/after comparison of an optimization pass. *)
let show_optimization_diff
    (label   : string)
    (before  : expr)
    (after   : expr) : unit =
  Printf.printf "\n┌─ %s ──────────────────────────────────────\n" label;
  Printf.printf "│  Expression:  %s\n" (to_string before);
  Printf.printf "│  AST nodes:   %d → %d  (depth: %d → %d)\n"
    (size before) (size after) (depth before) (depth after);
  Printf.printf "│\n";
  Printf.printf "│  BEFORE:\n";
  print_expr_tree before;
  Printf.printf "│\n";
  Printf.printf "│  AFTER:\n";
  print_expr_tree after;
  Printf.printf "└─────────────────────────────────────────────\n"
