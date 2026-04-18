(** Runtime Meta-Programming: Arithmetic Expression DSL
    Defines an AST (Abstract Syntax Tree) for arithmetic
    expressions and implements:
      - A recursive interpreter (evaluator)
      - A pretty-printer
      - Expression builder combinators
      - Partial evaluation against an environment
      - AST comparison and size metrics
*)

(* 1. THE AST - the "data representation" of programs *)

(** An arithmetic expression in our DSL. *)
type expr =
  | Const of int              (** Literal integer constant          *)
  | Var   of string           (** Named variable (e.g. "x")        *)
  | Add   of expr * expr      (** Addition:       e1 + e2          *)
  | Sub   of expr * expr      (** Subtraction:    e1 - e2          *)
  | Mul   of expr * expr      (** Multiplication: e1 * e2          *)
  | Div   of expr * expr      (** Division:       e1 / e2          *)
  | Neg   of expr             (** Negation:       -e               *)
  | Let   of string * expr * expr  (** Let binding: let x = e1 in e2 *)

(** Environment mapping variable names to integer values. *)
type env = (string * int) list

(* 2. INTERPRETER
   Evaluates an expression to an integer given an environment. *)

(** Evaluate expression [e] under variable environment [env].
    Raises [Failure] for division by zero or unbound variables. *)
let rec eval (env : env) (e : expr) : int =
  match e with
  | Const n          -> n
  | Var x            ->
      (match List.assoc_opt x env with
       | Some v -> v
       | None   -> failwith ("Unbound variable: " ^ x))
  | Add (e1, e2)     -> eval env e1 + eval env e2
  | Sub (e1, e2)     -> eval env e1 - eval env e2
  | Mul (e1, e2)     -> eval env e1 * eval env e2
  | Div (e1, e2)     ->
      let d = eval env e2 in
      if d = 0 then failwith "Division by zero"
      else eval env e1 / d
  | Neg e1           -> - (eval env e1)
  | Let (x, e1, e2)  ->
      let v = eval env e1 in
      eval ((x, v) :: env) e2

(* 3. PRETTY PRINTER
   Converts an AST back into a human-readable string. *)

(** Convert expression [e] to a parenthesized string representation. *)
let rec to_string (e : expr) : string =
  match e with
  | Const n          -> string_of_int n
  | Var x            -> x
  | Add (e1, e2)     -> "(" ^ to_string e1 ^ " + " ^ to_string e2 ^ ")"
  | Sub (e1, e2)     -> "(" ^ to_string e1 ^ " - " ^ to_string e2 ^ ")"
  | Mul (e1, e2)     -> "(" ^ to_string e1 ^ " * " ^ to_string e2 ^ ")"
  | Div (e1, e2)     -> "(" ^ to_string e1 ^ " / " ^ to_string e2 ^ ")"
  | Neg e1           -> "(-" ^ to_string e1 ^ ")"
  | Let (x, e1, e2)  ->
      "(let " ^ x ^ " = " ^ to_string e1 ^ " in " ^ to_string e2 ^ ")"

(* 4. EXPRESSION BUILDER COMBINATORS
   Construct expressions programmatically - this IS meta-programming:
   OCaml code generating OCaml DSL programs. *)

let const (n : int)    : expr = Const n
let var   (x : string) : expr = Var x
let add   (a : expr) (b : expr) : expr = Add (a, b)
let sub   (a : expr) (b : expr) : expr = Sub (a, b)
let mul   (a : expr) (b : expr) : expr = Mul (a, b)
let div   (a : expr) (b : expr) : expr = Div (a, b)
let neg   (e : expr)            : expr = Neg e
let let_  (x : string) (e1 : expr) (e2 : expr) : expr = Let (x, e1, e2)

(** Dynamically build the sum of a list of expressions. *)
let sum_of (exprs : expr list) : expr =
  match exprs with
  | []      -> Const 0
  | e :: es -> List.fold_left add e es

(** Dynamically build the product of a list of expressions. *)
let product_of (exprs : expr list) : expr =
  match exprs with
  | []      -> Const 1
  | e :: es -> List.fold_left mul e es

(** Generate a polynomial: c0 + c1*x + c2*x^2 + ... *)
let build_polynomial (coeffs : int list) (x : string) : expr =
  let xv = var x in
  let terms =
    List.mapi (fun i c ->
      if i = 0 then const c
      else
        let xn = List.init i (fun _ -> xv) |> product_of in
        mul (const c) xn
    ) coeffs
  in
  sum_of terms

(* 5. PARTIAL EVALUATION
   Substitute known variables and reduce where possible. *)

(** Partially evaluate [e] using [env], leaving unknowns as Var nodes. *)
let rec partial_eval (env : env) (e : expr) : expr =
  match e with
  | Const _ -> e
  | Var x   ->
      (match List.assoc_opt x env with
       | Some v -> Const v
       | None   -> Var x)
  | Add (e1, e2) ->
      let e1' = partial_eval env e1 in
      let e2' = partial_eval env e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 + n2)
       | _ -> Add (e1', e2'))
  | Sub (e1, e2) ->
      let e1' = partial_eval env e1 in
      let e2' = partial_eval env e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 - n2)
       | _ -> Sub (e1', e2'))
  | Mul (e1, e2) ->
      let e1' = partial_eval env e1 in
      let e2' = partial_eval env e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 * n2)
       | _ -> Mul (e1', e2'))
  | Div (e1, e2) ->
      let e1' = partial_eval env e1 in
      let e2' = partial_eval env e2 in
      (match e1', e2' with
       | Const n1, Const n2 when n2 <> 0 -> Const (n1 / n2)
       | _ -> Div (e1', e2'))
  | Neg e1 ->
      let e1' = partial_eval env e1 in
      (match e1' with
       | Const n -> Const (-n)
       | _ -> Neg e1')
  | Let (x, e1, e2) ->
      let e1' = partial_eval env e1 in
      (match e1' with
       | Const v -> partial_eval ((x, v) :: env) e2
       | _ -> Let (x, e1', partial_eval env e2))

(* 6. AST METRICS *)

(** Count the number of nodes in an expression tree. *)
let rec size (e : expr) : int =
  match e with
  | Const _ | Var _ -> 1
  | Neg e1          -> 1 + size e1
  | Add (a, b) | Sub (a, b) | Mul (a, b) | Div (a, b) ->
      1 + size a + size b
  | Let (_, e1, e2) -> 1 + size e1 + size e2

(** Count the depth of the expression tree. *)
let rec depth (e : expr) : int =
  match e with
  | Const _ | Var _ -> 0
  | Neg e1          -> 1 + depth e1
  | Add (a, b) | Sub (a, b) | Mul (a, b) | Div (a, b) ->
      1 + max (depth a) (depth b)
  | Let (_, e1, e2) -> 1 + max (depth e1) (depth e2)

(** Collect all unique variable names in an expression. *)
let rec free_vars (e : expr) : string list =
  let dedup lst =
    List.fold_right
      (fun x acc -> if List.mem x acc then acc else x :: acc)
      lst []
  in
  match e with
  | Const _         -> []
  | Var x           -> [x]
  | Neg e1          -> free_vars e1
  | Add (a, b) | Sub (a, b) | Mul (a, b) | Div (a, b) ->
      dedup (free_vars a @ free_vars b)
  | Let (x, e1, e2) ->
      dedup (free_vars e1 @ (List.filter (fun v -> v <> x) (free_vars e2)))
