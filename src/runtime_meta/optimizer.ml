(** ============================================================
    Runtime Meta-Programming: Expression Optimizer
    ============================================================
    Implements a multi-pass expression optimizer that treats
    OCaml programs-as-data (the DSL AST) and applies
    transformation rules to produce simpler, faster programs.

    This is the core of RUNTIME META-PROGRAMMING:
      - The optimizer IS a program that transforms OTHER programs.
      - Rules are first-class values composable into pipelines.

    Passes:
      1. Constant Folding    — pre-compute constant sub-trees
      2. Algebraic Simplify  — identity/zero laws
      3. Strength Reduction  — replace expensive ops with cheap ones
      4. Dead Code Elim      — remove unused Let bindings
    ============================================================ *)

open Dsl

(* ----------------------------------------------------------
   1. CONSTANT FOLDING
   Pre-compute any sub-expression whose operands are both constants.
   e.g.  Add(Const 3, Const 4)  →  Const 7
   ---------------------------------------------------------- *)

(** Apply one pass of constant folding to expression [e]. *)
let rec fold_constants (e : expr) : expr =
  match e with
  | Const _ | Var _ -> e

  | Neg (Const n) -> Const (-n)
  | Neg e1        -> Neg (fold_constants e1)

  | Add (e1, e2) ->
      let e1' = fold_constants e1 and e2' = fold_constants e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 + n2)
       | _ -> Add (e1', e2'))

  | Sub (e1, e2) ->
      let e1' = fold_constants e1 and e2' = fold_constants e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 - n2)
       | _ -> Sub (e1', e2'))

  | Mul (e1, e2) ->
      let e1' = fold_constants e1 and e2' = fold_constants e2 in
      (match e1', e2' with
       | Const n1, Const n2 -> Const (n1 * n2)
       | _ -> Mul (e1', e2'))

  | Div (e1, e2) ->
      let e1' = fold_constants e1 and e2' = fold_constants e2 in
      (match e1', e2' with
       | Const n1, Const n2 when n2 <> 0 -> Const (n1 / n2)
       | _ -> Div (e1', e2'))

  | Let (x, e1, e2) ->
      Let (x, fold_constants e1, fold_constants e2)

(* ----------------------------------------------------------
   2. ALGEBRAIC SIMPLIFICATION
   Apply mathematical identity and absorption laws.
   e.g.  Add(x, Const 0)  →  x
         Mul(x, Const 1)  →  x
         Mul(x, Const 0)  →  Const 0
   ---------------------------------------------------------- *)

(** Apply algebraic simplification to expression [e]. *)
let rec simplify (e : expr) : expr =
  match e with
  | Const _ | Var _ -> e

  (* Double negation *)
  | Neg (Neg e1)  -> simplify e1
  | Neg e1        -> Neg (simplify e1)

  (* Additive identities: x + 0 = x, 0 + x = x *)
  | Add (e1, Const 0) -> simplify e1
  | Add (Const 0, e2) -> simplify e2
  (* x - 0 = x *)
  | Sub (e1, Const 0) -> simplify e1
  (* x - x = 0 (syntactic equality) *)
  | Sub (e1, e2) when e1 = e2 -> Const 0

  (* Multiplicative identities: x * 1 = x, 1 * x = x *)
  | Mul (e1, Const 1) -> simplify e1
  | Mul (Const 1, e2) -> simplify e2
  (* Multiplicative absorption: x * 0 = 0, 0 * x = 0 *)
  | Mul (_, Const 0) | Mul (Const 0, _) -> Const 0

  (* Division identities: x / 1 = x, 0 / x = 0 *)
  | Div (e1, Const 1) -> simplify e1
  | Div (Const 0, _)  -> Const 0
  (* x / x = 1 (syntactic equality, no division-by-zero check needed
     since identical sub-trees can't both be zero and non-zero) *)
  | Div (e1, e2) when e1 = e2 -> Const 1

  (* Recurse into sub-nodes *)
  | Add (e1, e2) ->
      let e1' = simplify e1 and e2' = simplify e2 in
      if e1' = e1 && e2' = e2 then Add (e1', e2')
      else simplify (Add (e1', e2'))

  | Sub (e1, e2) ->
      let e1' = simplify e1 and e2' = simplify e2 in
      if e1' = e1 && e2' = e2 then Sub (e1', e2')
      else simplify (Sub (e1', e2'))

  | Mul (e1, e2) ->
      let e1' = simplify e1 and e2' = simplify e2 in
      if e1' = e1 && e2' = e2 then Mul (e1', e2')
      else simplify (Mul (e1', e2'))

  | Div (e1, e2) ->
      let e1' = simplify e1 and e2' = simplify e2 in
      if e1' = e1 && e2' = e2 then Div (e1', e2')
      else simplify (Div (e1', e2'))

  | Let (x, e1, e2) ->
      Let (x, simplify e1, simplify e2)

(* ----------------------------------------------------------
   3. STRENGTH REDUCTION
   Replace expensive operations with cheaper equivalents.
   e.g.  x * 2  →  x + x
         x * 4  →  (x + x) + (x + x)     [when power of 2]
   ---------------------------------------------------------- *)

(** Check if n is a power of 2 and return the exponent. *)
let log2_if_power (n : int) : int option =
  if n <= 0 then None
  else
    let rec aux v exp =
      if v = 1 then Some exp
      else if v mod 2 = 0 then aux (v / 2) (exp + 1)
      else None
    in
    aux n 0

(** Apply strength reduction rewrites to expression [e]. *)
let rec strength_reduce (e : expr) : expr =
  match e with
  | Mul (e1, Const n) | Mul (Const n, e1) ->
      let e1' = strength_reduce e1 in
      (match log2_if_power n with
       | Some 0 -> e1'                             (* x * 1 = x        *)
       | Some 1 -> Add (e1', e1')                  (* x * 2 = x + x    *)
       | Some k ->
           (* x * 2^k = ((x + x) + (x + x)) ... [k doublings] *)
           let doubled = ref e1' in
           for _ = 1 to k do doubled := Add (!doubled, !doubled) done;
           !doubled
       | None   -> Mul (e1', Const n))
  | Add (e1, e2) -> Add (strength_reduce e1, strength_reduce e2)
  | Sub (e1, e2) -> Sub (strength_reduce e1, strength_reduce e2)
  | Div (e1, e2) -> Div (strength_reduce e1, strength_reduce e2)
  | Neg e1       -> Neg (strength_reduce e1)
  | Let (x,e1,e2)-> Let (x, strength_reduce e1, strength_reduce e2)
  | other        -> other

(* ----------------------------------------------------------
   4. PIPELINE BUILDER
   First-class transformation rules composed into an optimizer.
   This is meta-programming: functions that transform programs.
   ---------------------------------------------------------- *)

(** A transformation is simply a function from expr to expr. *)
type transform = expr -> expr

(** Apply a list of transformations in sequence (left to right). *)
let apply_pipeline (transforms : transform list) (e : expr) : expr =
  List.fold_left (fun acc f -> f acc) e transforms

(** The default optimizer pipeline: fold, then simplify. *)
let default_optimizer : transform =
  apply_pipeline [fold_constants; simplify]

(** The aggressive optimizer: fold, simplify, reduce, then fold+simplify again. *)
let aggressive_optimizer : transform =
  apply_pipeline [fold_constants; simplify; strength_reduce; fold_constants; simplify]

(** Run an optimizer repeatedly until the expression stabilizes (fixed point). *)
let run_to_fixpoint (pass : transform) (e : expr) : expr =
  let rec loop prev =
    let next = pass prev in
    if next = prev then next
    else loop next
  in
  loop e

(** Full optimizer: run default to a fixed point. *)
let full_optimize : transform = run_to_fixpoint default_optimizer

(* ----------------------------------------------------------
   5. CLASSIFICATION OF TRANSFORMATIONS (Research-inspired)
   Every transformation belongs to a category that describes
   its purpose and impact.
   ---------------------------------------------------------- *)

type transform_class =
  | Optimization      (** Reduces time/space complexity *)
  | Structural        (** Changes AST shape, not semantics *)
  | Instrumentation   (** Adds observability (e.g. logging) *)

type named_transform = {
  name    : string;
  class_  : transform_class;
  fn      : transform;
  desc    : string;
}

let class_to_string = function
  | Optimization    -> "Optimization"
  | Structural      -> "Structural"
  | Instrumentation -> "Instrumentation"

(** Registry of all named transforms with metadata. *)
let transform_registry : named_transform list =
  [ { name   = "constant_folding"
    ; class_ = Optimization
    ; fn     = fold_constants
    ; desc   = "Pre-computes constant sub-expressions at compile time"
    }
  ; { name   = "algebraic_simplification"
    ; class_ = Optimization
    ; fn     = simplify
    ; desc   = "Applies identity/zero/absorption laws (x+0=x, x*0=0, ...)"
    }
  ; { name   = "strength_reduction"
    ; class_ = Structural
    ; fn     = strength_reduce
    ; desc   = "Replaces expensive ops with cheaper equivalents (x*2 -> x+x)"
    }
  ; { name   = "full_optimizer"
    ; class_ = Optimization
    ; fn     = full_optimize
    ; desc   = "Fixed-point composition of all optimization passes"
    }
  ]
