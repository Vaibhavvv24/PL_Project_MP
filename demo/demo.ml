(** ============================================================
    FINAL DEMO: Meta-Programming in Functional Programming
    ============================================================
    CLI demo that walks through the entire system end-to-end,
    showing the full meta-programming pipeline:

      1. Core FP foundations
      2. DSL construction
      3. AST before vs. after optimization
      4. Partial evaluation
      5. Compile-time PPX instrumentation (live)
      6. Memoization impact
      7. Transform classification
    ============================================================ *)

open Core_fp
open Runtime_meta.Dsl
open Runtime_meta.Optimizer
open Runtime_meta.Memoize
open Runtime_meta.Transformer
open Runtime_meta.Codegen

(* ── UI helpers ──────────────────────────────────────────── *)
let box_line w = String.make w '='
let hr  w = print_endline (String.make w '-')

let header title =
  let w = 60 in
  Printf.printf "\n%s\n" (box_line w);
  let pad = (w - String.length title - 2) / 2 in
  Printf.printf "║%s %s %s║\n"
    (String.make pad ' ') title
    (String.make (w - pad - String.length title - 2) ' ');
  Printf.printf "%s\n\n" (box_line w)

let section n title =
  Printf.printf "\n┌─[Step %d]─ %s\n" n title;
  hr 56

(* ── PPX-instrumented functions ──────────────────────────── *)
[%%log let demo_add (a : int) (b : int) = a + b]
[%%log let demo_square (x : int) = x * x]

(* ── Main Demo ───────────────────────────────────────────── *)
let () =
  header "META-PROGRAMMING IN FUNCTIONAL PROGRAMMING";
  print_endline "  Language: OCaml  |  Build: Dune  |  PPX: ppxlib";
  print_endline "  A complete demonstration of runtime + compile-time";
  print_endline "  meta-programming through functional techniques.";

  (* ══════════════════════════════════════════════════════
     STEP 1: CORE FP FOUNDATIONS
     ══════════════════════════════════════════════════════ *)
  section 1 "Core Functional Programming";

  Printf.printf "  Closure (make_adder 7): %d\n" (make_adder 7 3);
  Printf.printf "  Closure (make_multiplier 4): %d\n" (make_multiplier 4 5);

  let pipeline = compose_pipeline [make_adder 2; make_multiplier 3; make_adder 1] in
  Printf.printf "  Pipeline [+2, *3, +1] on 4 = %d  (expected 19)\n" (pipeline 4);

  let nums = [1;2;3;4;5;6;7;8;9;10] in
  let evens = filter (fun x -> x mod 2 = 0) nums in
  let sq_evens = map (fun x -> x * x) evens in
  let total = fold_left (+) 0 sq_evens in
  Printf.printf "  fold(+) over map(sq) over filter(even) [1..10] = %d\n" total;

  let cube  = dynamic_power 3 in
  Printf.printf "  Dynamic function: cube(5) = %d  (expected 125)\n" (cube 5);

  (* ══════════════════════════════════════════════════════
     STEP 2: DSL CONSTRUCTION
     ══════════════════════════════════════════════════════ *)
  section 2 "Runtime Meta-Programming — Building DSL Expressions";

  (* Build expression programmatically: (3 * (x + 5)) - (x * 2) + 10 *)
  let expr =
    add
      (sub
         (mul (const 3) (add (var "x") (const 5)))
         (mul (var "x") (const 2)))
         (add (const 10)  (const 5) )

  in
  Printf.printf "  Constructed DSL expr:\n    %s\n" (to_string expr);
  Printf.printf "  AST size: %d nodes, depth: %d\n" (size expr) (depth expr);
  Printf.printf "  Free variables: [%s]\n" (String.concat ", " (free_vars expr));

  (* ══════════════════════════════════════════════════════
     STEP 3: AST BEFORE VS AFTER OPTIMIZATION
     ══════════════════════════════════════════════════════ *)
  section 3 "AST Transformation — Before vs After";

  let opt_expr = full_optimize expr in
  Printf.printf "  Before: %s\n" (to_string expr);
  Printf.printf "  After:  %s\n" (to_string opt_expr);
  Printf.printf "  Nodes:  %d → %d  (%.0f%% reduction)\n"
    (size expr) (size opt_expr)
    ((1.0 -. float_of_int (size opt_expr) /. float_of_int (size expr)) *. 100.0);
  Printf.printf "\n  AST Tree (BEFORE):\n";
  print_expr_tree expr;
  Printf.printf "\n  AST Tree (AFTER):\n";
  print_expr_tree opt_expr;

  (* ══════════════════════════════════════════════════════
     STEP 4: OPTIMIZATION PASSES SHOWN STEP BY STEP
     ══════════════════════════════════════════════════════ *)
  section 4 "Multi-Pass Optimizer Pipeline";

  let passes =
    [ "fold_constants",         fold_constants
    ; "algebraic_simplify",     simplify
    ; "strength_reduction",     strength_reduce
    ; "fold_constants (again)", fold_constants
    ]
  in
  let _ = List.fold_left (fun e (name, f) ->
    let e' = f e in
    Printf.printf "  [%-24s] %s\n" name (to_string e');
    e'
  ) expr passes in

  (* ══════════════════════════════════════════════════════
     STEP 5: PARTIAL EVALUATION
     ══════════════════════════════════════════════════════ *)
  section 5 "Partial Evaluation";

  let symbolic = add (mul (var "a") (var "b")) (add (var "a") (const 10)) in
  Printf.printf "  Symbolic:     %s\n" (to_string symbolic);
  let pe1 = partial_eval [("a", 3)] symbolic in
  Printf.printf "  With a=3:     %s\n" (to_string pe1);
  let pe2 = partial_eval [("b", 4)] pe1 in
  Printf.printf "  With b=4:     %s\n" (to_string pe2);
  Printf.printf "  Fully eval:   %d  (expected 25)\n" (eval [("a",3);("b",4)] symbolic);

  (* ══════════════════════════════════════════════════════
     STEP 6: COMPILE-TIME PPX (live demonstration)
     ══════════════════════════════════════════════════════ *)
  section 6 "Compile-Time Meta-Programming (PPX)";

  print_endline "  Source before PPX:";
  print_endline "    [%%log let demo_add (a:int) (b:int) = a + b]";
  print_endline "";
  print_endline "  After ppx_log rewrites to:";
  print_endline "    let demo_add a b =";
  print_endline "      print_endline \"[LOG] >> Entering: demo_add\";";
  print_endline "      let __result__ = a + b in";
  print_endline "      print_endline \"[LOG] << Exiting: demo_add\";";
  print_endline "      __result__";
  print_endline "";
  print_endline "  LIVE CALL:";
  let r1 = demo_add 10 20 in
  Printf.printf "  demo_add 10 20 = %d\n" r1;
  print_endline "";
  print_endline "  LIVE CALL:";
  let r2 = demo_square 7 in
  Printf.printf "  demo_square 7 = %d\n" r2;

  (* ══════════════════════════════════════════════════════
     STEP 7: MEMOIZATION
     ══════════════════════════════════════════════════════ *)
  section 7 "Runtime Meta-Programming — Memoization";

  let call_count = ref 0 in
  let slow_fib x =
    incr call_count;
    let rec f n = if n <= 1 then n else f (n-1) + f (n-2) in
    f x
  in
  let memo_fib = memoize slow_fib in

  call_count := 0;
  let _ = memo_fib 20 in
  let c1 = !call_count in
  call_count := 0;
  let _ = memo_fib 20 in
  let c2 = !call_count in

  Printf.printf "  memoize(slow_fib) 20: first call  → %d underlying calls\n" c1;
  Printf.printf "  memoize(slow_fib) 20: second call → %d underlying calls\n" c2;
  Printf.printf "  Cache HIT proved: second call skips computation entirely.\n";

  (* ══════════════════════════════════════════════════════
     STEP 8: TRANSFORM CLASSIFICATION
     ══════════════════════════════════════════════════════ *)
  section 8 "Meta-Transformation Classification";

  print_endline "  ┌──────────────────────────┬───────────────┬──────────────────────────────────────┐";
  print_endline "  │ Transform Name           │ Class         │ Description                          │";
  print_endline "  ├──────────────────────────┼───────────────┼──────────────────────────────────────┤";
  List.iter (fun t ->
    Printf.printf "  │ %-24s │ %-13s │ %-36s │\n"
      t.name
      (class_to_string t.class_)
      (if String.length t.desc > 36
       then String.sub t.desc 0 33 ^ "..."
       else t.desc)
  ) transform_registry;
  print_endline "  └──────────────────────────┴───────────────┴──────────────────────────────────────┘";

  (* ══════════════════════════════════════════════════════
     STEP 9: OFFLINE STAGED COMPILATION
     ══════════════════════════════════════════════════════ *)
  section 9 "Offline Staged Compilation (CodeGen)";

  let codegen_expr =
    let_ "z" (mul (var "x") (const 2))
      (mul (add (var "z") (var "y")) (add (mul (const 10) (const 0)) (const 10)))
  in
  let opt_codegen_expr = aggressive_optimizer codegen_expr in
  let generated_code = to_ocaml_function "compute_value" opt_codegen_expr in

  print_endline "  Taking an optimized AST and generating native OCaml code:";
  Printf.printf "  Optimized AST: %s\n\n" (to_string opt_codegen_expr);
  print_endline "  Generated Code:";
  print_endline "  ```ocaml";
  print_endline generated_code;
  print_endline "  ```";

  (* ══════════════════════════════════════════════════════
     FINAL SUMMARY
     ══════════════════════════════════════════════════════ *)
  Printf.printf "\n%s\n" (box_line 60);
  print_endline "  DEMO COMPLETE";
  Printf.printf "%s\n" (box_line 60);
  print_endline "  What was demonstrated:";
  print_endline "    ✓ First-class functions, closures, HOFs";
  print_endline "    ✓ DSL AST construction via combinators";
  print_endline "    ✓ Multi-pass runtime AST optimizer";
  print_endline "    ✓ AST visualization (tree printer)";
  print_endline "    ✓ Partial evaluation";
  print_endline "    ✓ PPX compile-time function instrumentation";
  print_endline "    ✓ Memoization (higher-order meta-transformation)";
  print_endline "    ✓ Transform classification taxonomy";
  print_endline "    ✓ Offline Staged Compilation (CodeGen)";
  Printf.printf "%s\n\n" (box_line 60)
