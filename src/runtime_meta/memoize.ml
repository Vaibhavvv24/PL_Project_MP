(** ============================================================
    Runtime Meta-Programming: Memoization & Dynamic Generation
    ============================================================
    Demonstrates runtime meta-programming through:
      1. Memoization - dynamically wrapping any function with a cache
      2. Dynamic Function Generation — producing specialized functions
         at runtime based on parameters
      3. Transformation Chaining — building pipelines at runtime
    ============================================================ *)

(* ----------------------------------------------------------
   1. MEMOIZATION UTILITY
   Takes ANY function and returns a cache-enabled version.
   This is a higher-order meta-transformation: it transforms
   the *behaviour* of a function without changing its interface.
   ---------------------------------------------------------- *)

(** Memoize a single-argument function using a hash table cache.
    The returned function has the same type as [f] but caches results.
    Example:
      let memo_fib = memoize fib ;;
      memo_fib 30 (* only computed once *) *)
let memoize (f : 'a -> 'b) : 'a -> 'b =
  let cache : ('a, 'b) Hashtbl.t = Hashtbl.create 16 in
  fun x ->
    match Hashtbl.find_opt cache x with
    | Some v -> v
    | None   ->
        let v = f x in
        Hashtbl.add cache x v;
        v

(** Memoize with a call-count side effect for benchmarking. *)
let memoize_counted (f : 'a -> 'b) : ('a -> 'b) * (unit -> int) =
  let cache   = Hashtbl.create 16 in
  let calls   = ref 0 in
  let wrapped x =
    match Hashtbl.find_opt cache x with
    | Some v -> v
    | None   ->
        incr calls;
        let v = f x in
        Hashtbl.add cache x v;
        v
  in
  (wrapped, fun () -> !calls)

(* ----------------------------------------------------------
   2. DYNAMIC FUNCTION GENERATION
   Create specialized functions at runtime from parameters.
   ---------------------------------------------------------- *)

(** Generate a linear function: [make_linear a b] returns x -> a*x + b *)
let make_linear (a : int) (b : int) : int -> int =
  fun x -> a * x + b

(** Generate a polynomial evaluator from a coefficient list.
    [generate_poly [c0; c1; c2]] returns x -> c0 + c1*x + c2*x^2 *)
let generate_poly (coeffs : int list) : int -> int =
  fun x ->
    List.mapi (fun i c ->
      (* compute x^i *)
      let xi = List.init i (fun _ -> x)
               |> List.fold_left ( * ) 1
      in
      c * xi
    ) coeffs
    |> List.fold_left ( + ) 0

(** Generate a multiplier function capturing [n] in a closure. *)
let generate_multiplier (n : int) : int -> int = fun x -> x * n

(** Generate a bounded function that clamps output to [lo..hi]. *)
let make_bounded (f : int -> int) (lo : int) (hi : int) : int -> int =
  fun x -> max lo (min hi (f x))

(* ----------------------------------------------------------
   3. TRANSFORMATION CHAINING SYSTEM
   Build transformation pipelines at runtime from named rules.
   ---------------------------------------------------------- *)

(** A named, composable transformation step. *)
type 'a step = { step_name : string; step_fn : 'a -> 'a }

(** A pipeline is an ordered sequence of steps. *)
type 'a pipeline = 'a step list

(** Build a pipeline from a list of (name, function) pairs. *)
let build_pipeline (pairs : (string * ('a -> 'a)) list) : 'a pipeline =
  List.map (fun (name, fn) -> { step_name = name; step_fn = fn }) pairs

(** Run a pipeline on input [x], printing each step if [verbose]. *)
let run_pipeline ?(verbose = false) (pl : 'a pipeline) (x : 'a) : 'a =
  List.fold_left
    (fun acc step ->
       let result = step.step_fn acc in
       if verbose then
         Printf.printf "  [step: %s]\n" step.step_name;
       result)
    x pl

(** Compose two pipelines into one. *)
let concat_pipelines (p1 : 'a pipeline) (p2 : 'a pipeline) : 'a pipeline =
  p1 @ p2

(** Conditionally apply a step only if the predicate holds. *)
let conditional_step (name : string) (pred : 'a -> bool) (f : 'a -> 'a) : 'a step =
  { step_name = name ^ " (conditional)"
  ; step_fn   = fun x -> if pred x then f x else x
  }
