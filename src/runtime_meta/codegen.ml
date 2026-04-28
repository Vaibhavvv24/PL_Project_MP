(** Runtime Meta-Programming: Offline Staged Compilation
    Translates optimized AST expressions directly into native
    OCaml source code strings.
*)

open Dsl

(** Convert an AST expression into a valid OCaml source code string.
    Ensures correct precedence by parenthesizing all binary operations.
*)
let rec to_ocaml_expr (e : expr) : string =
  match e with
  | Const n -> 
      (* Handle negative constants to avoid syntax errors like `x - -5` becoming `x -- 5` *)
      if n < 0 then "(" ^ string_of_int n ^ ")" else string_of_int n
  | Var x -> x
  | Add (e1, e2) -> "(" ^ to_ocaml_expr e1 ^ " + " ^ to_ocaml_expr e2 ^ ")"
  | Sub (e1, e2) -> "(" ^ to_ocaml_expr e1 ^ " - " ^ to_ocaml_expr e2 ^ ")"
  | Mul (e1, e2) -> "(" ^ to_ocaml_expr e1 ^ " * " ^ to_ocaml_expr e2 ^ ")"
  | Div (e1, e2) -> "(" ^ to_ocaml_expr e1 ^ " / " ^ to_ocaml_expr e2 ^ ")"
  | Neg e1 -> "(- " ^ to_ocaml_expr e1 ^ ")"
  | Let (x, e1, e2) ->
      "(let " ^ x ^ " = " ^ to_ocaml_expr e1 ^ " in\n  " ^ to_ocaml_expr e2 ^ ")"

(** Generate a complete OCaml function from an expression.
    If [args] is not provided, it automatically extracts free variables
    from the AST to generate the function parameters.
    [name] is the generated function name.
*)
let to_ocaml_function ?(args=[]) (name : string) (e : expr) : string =
  let final_args =
    match args with
    | [] -> 
        (* Auto-extract from AST and sort alphabetically for determinism *)
        List.sort String.compare (free_vars e)
    | _  -> args
  in
  let args_str =
    if final_args = [] then "()"
    else String.concat " " final_args
  in
  "let " ^ name ^ " " ^ args_str ^ " =\n" ^
  "  " ^ to_ocaml_expr e

(** ==========================================================
    FLOAT GENERATION
    Because our AST is just data, we can choose to compile 
    it using OCaml's floating-point operators (+., -., *., /.)
    instead of integers!
    ========================================================== *)

let rec to_float_ocaml_expr (e : expr) : string =
  match e with
  | Const n -> 
      let fstr = string_of_float (float_of_int n) in
      if n < 0 then "(" ^ fstr ^ ")" else fstr
  | Var x -> x
  | Add (e1, e2) -> "(" ^ to_float_ocaml_expr e1 ^ " +. " ^ to_float_ocaml_expr e2 ^ ")"
  | Sub (e1, e2) -> "(" ^ to_float_ocaml_expr e1 ^ " -. " ^ to_float_ocaml_expr e2 ^ ")"
  | Mul (e1, e2) -> "(" ^ to_float_ocaml_expr e1 ^ " *. " ^ to_float_ocaml_expr e2 ^ ")"
  | Div (e1, e2) -> "(" ^ to_float_ocaml_expr e1 ^ " /. " ^ to_float_ocaml_expr e2 ^ ")"
  | Neg e1 -> "(-. " ^ to_float_ocaml_expr e1 ^ ")"
  | Let (x, e1, e2) ->
      "(let " ^ x ^ " = " ^ to_float_ocaml_expr e1 ^ " in\n  " ^ to_float_ocaml_expr e2 ^ ")"

let to_float_ocaml_function ?(args=[]) (name : string) (e : expr) : string =
  let final_args =
    match args with
    | [] -> List.sort String.compare (free_vars e)
    | _  -> args
  in
  let args_str =
    if final_args = [] then "()"
    else String.concat " " final_args
  in
  "let " ^ name ^ " " ^ args_str ^ " =\n" ^
  "  " ^ to_float_ocaml_expr e
