(** 
    Core Functional Programming Module
    
    Demonstrates the foundational building blocks of functional
    programming in OCaml:
      - First-class functions
      - Closures
      - Higher-order functions (map, filter, fold)
      - Function composition
      - Dynamic function generation
      - Pipeline construction
    *)
(* 
   1. FIRST-CLASS FUNCTIONS
   Functions are values — they can be stored, passed, and returned.
   *) 

(** Apply any function [f] to a value [x]. *)
let apply (f : 'a -> 'b) (x : 'a) : 'b = f x

(** Apply a function twice to a value. *)
let apply_twice (f : 'a -> 'a) (x : 'a) : 'a = f (f x)

(*
   2. CLOSURES
   Functions that capture variables from their enclosing scope.
   *)

(** Returns a function that adds [n] to its argument. *)
let make_adder (n : int) : int -> int = fun x -> x + n

(** Returns a function that multiplies its argument by [n]. *)
let make_multiplier (n : int) : int -> int = fun x -> x * n

(** Returns a counter closure: each call increments an internal state. *)
let make_counter () : unit -> int =
  let count = ref 0 in
  fun () ->
    incr count;
    !count

(** Returns a rate limiter closure that accumulates calls. *)
let make_accumulator (init : int) : int -> int =
  let total = ref init in
  fun n ->
    total := !total + n;
    !total

(*3. FUNCTION COMPOSITION
   Build larger functions by chaining smaller ones.
   *)

(** Standard mathematical composition: (compose f g) x = f(g(x)) *)
let compose (f : 'b -> 'c) (g : 'a -> 'b) : 'a -> 'c = fun x -> f (g x)

(** Left-to-right composition (pipe): (pipe_compose g f) x = f(g(x)) *)
let pipe_compose (g : 'a -> 'b) (f : 'b -> 'c) : 'a -> 'c = fun x -> f (g x)

(** Compose a list of functions left-to-right into a single function. *)
let compose_pipeline (fns : ('a -> 'a) list) : 'a -> 'a =
  List.fold_left pipe_compose (fun x -> x) fns

(* 4. HIGHER-ORDER FUNCTIONS
   Functions that operate on other functions or collections.
   *)

(** Map: apply [f] to every element of a list. *)
let rec map (f : 'a -> 'b) : 'a list -> 'b list = function
  | []      -> []
  | x :: xs -> f x :: map f xs

(** Filter: keep elements of a list satisfying predicate [p]. *)
let rec filter (p : 'a -> bool) : 'a list -> 'a list = function
  | []      -> []
  | x :: xs -> if p x then x :: filter p xs else filter p xs

(** Fold left: reduce a list to a single value using [f] and accumulator [acc]. *)
let rec fold_left (f : 'b -> 'a -> 'b) (acc : 'b) : 'a list -> 'b = function
  | []      -> acc
  | x :: xs -> fold_left f (f acc x) xs

(** Fold right: fold from the right. *)
let rec fold_right (f : 'a -> 'b -> 'b) (lst : 'a list) (acc : 'b) : 'b =
  match lst with
  | []      -> acc
  | x :: xs -> f x (fold_right f xs acc)

(** Zip two lists into a list of pairs. *)
let rec zip (xs : 'a list) (ys : 'b list) : ('a * 'b) list =
  match xs, ys with
  | [], _ | _, [] -> []
  | x :: xs', y :: ys' -> (x, y) :: zip xs' ys'

(** Flat-map: apply f to each element and concatenate results. *)
let flat_map (f : 'a -> 'b list) (lst : 'a list) : 'b list =
  fold_right (fun x acc -> f x @ acc) lst []

(* 5. DYNAMIC FUNCTION GENERATION
   Create specialized functions programmatically at runtime.
   *)

(** Generates a power function: [dynamic_power n] returns x -> x^n *)
let dynamic_power (n : int) : int -> int =
  fun x ->
    let rec aux acc i =
      if i <= 0 then acc
      else aux (acc * x) (i - 1)
    in
    aux 1 n

(** Generate a range-checker: returns true if x is in [lo, hi] *)
let make_range_check (lo : int) (hi : int) : int -> bool =
  fun x -> x >= lo && x <= hi

(** Generate a threshold comparator *)
let make_threshold (t : int) : int -> [`Above | `Below | `Equal] =
  fun x ->
    if x > t then `Above
    else if x < t then `Below
    else `Equal

(* 6. PIPELINE BUILDING
   Show dynamic, composable transformation pipelines.
   *)

(** A pre-built numeric pipeline: add 2, then multiply by 3. *)
let numeric_pipeline : int -> int =
  compose_pipeline [make_adder 2; make_multiplier 3]

(** Build a string processing pipeline dynamically. *)
let string_pipeline : string -> string =
  compose_pipeline
    [ String.trim
    ; String.lowercase_ascii
    ; fun s -> "[" ^ s ^ "]"
    ]
