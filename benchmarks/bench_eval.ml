(** ============================================================
    Benchmark 1: Optimizer Performance Evaluation
    ============================================================
    Measures execution time of:
      - Naive (unoptimized) evaluation of a deeply nested AST
      - Optimized evaluation after constant folding
    Reports speedup factor and qualitative analysis.
    ============================================================ *)

open Runtime_meta.Dsl
open Runtime_meta.Optimizer

(* ── Timing utility ──────────────────────────────────────── *)
let time_it (f : unit -> 'a) : float * 'a =
  let t0  = Unix.gettimeofday () in
  let res = f () in
  let t1  = Unix.gettimeofday () in
  (t1 -. t0, res)

(** Build a tree of nested additions: 1 + (1 + (1 + ... 0)) *)
let rec make_chain (n : int) : expr =
  if n <= 0 then Const 0
  else Add (Const 1, make_chain (n - 1))

(** Build a balanced binary tree of additions [depth n, 2^n leaves]. *)
let rec make_balanced (n : int) : expr =
  if n = 0 then Const 1
  else
    let half = make_balanced (n - 1) in
    Add (half, half)

let _use_balanced = make_balanced  (* suppress unused warning *)

(* ── Print formatting helpers ────────────────────────────── *)
let bar label pct =
  let width  = 40 in
  let filled = int_of_float (pct *. float_of_int width) in
  let filled = min filled width in
  Printf.printf "  %-20s [%s%s] %.1f%%\n"
    label
    (String.make filled '#')
    (String.make (width - filled) '.')
    (pct *. 100.0)

let () =
  print_endline "";
  print_endline "╔══════════════════════════════════════════════════════╗";
  print_endline "║       BENCHMARK 1: Optimizer Performance             ║";
  print_endline "╚══════════════════════════════════════════════════════╝";
  print_endline "";

  (*─────────────────────────────────────────────────────────
    TEST 1: Linear chain AST
   ─────────────────────────────────────────────────────────*)
  let chain_size  = 5000 in
  let iterations  = 2000 in

  Printf.printf "▶ Test 1: Linear chain of %d additions\n" chain_size;
  Printf.printf "  Evaluating %d times each.\n\n" iterations;

  let chain  = make_chain chain_size in
  let opt_chain = default_optimizer chain in

  Printf.printf "  AST size  (unoptimized): %d nodes\n" (size chain);
  Printf.printf "  AST size  (optimized):   %d nodes\n\n" (size opt_chain);

  let (t_raw, _) = time_it (fun () ->
    for _ = 1 to iterations do ignore (eval [] chain) done)
  in
  let (t_opt, _) = time_it (fun () ->
    for _ = 1 to iterations do ignore (eval [] opt_chain) done)
  in

  Printf.printf "  Unoptimized: %.6f s\n" t_raw;
  Printf.printf "  Optimized:   %.6f s\n" t_opt;
  let speedup1 = if t_opt > 0.0 then t_raw /. t_opt else 999.0 in
  Printf.printf "  Speedup:     %.1fx\n\n" speedup1;

  let max_t = max t_raw t_opt in
  bar "Unoptimized" (t_raw /. max_t);
  bar "Optimized"   (t_opt /. max_t);

  (*─────────────────────────────────────────────────────────
    TEST 2: Algebraic simplification
   ─────────────────────────────────────────────────────────*)
  print_endline "";
  print_endline (String.make 56 '-');
  Printf.printf "▶ Test 2: Algebraic simplification benchmark\n\n";

  let alg_iters = 50000 in
  (* expression with many zero/identity terms *)
  let alg_expr =
    add
      (mul (add (var "x") (const 0)) (const 1))
      (mul (const 0) (add (var "y") (const 99)))
  in
  let alg_opt = default_optimizer alg_expr in

  Printf.printf "  Before: %s  (%d nodes)\n" (to_string alg_expr) (size alg_expr);
  Printf.printf "  After:  %s  (%d nodes)\n\n" (to_string alg_opt) (size alg_opt);

  let env = [("x", 5); ("y", 3)] in
  let (t_raw2, _) = time_it (fun () ->
    for _ = 1 to alg_iters do ignore (eval env alg_expr) done)
  in
  let (t_opt2, _) = time_it (fun () ->
    for _ = 1 to alg_iters do ignore (eval env alg_opt) done)
  in

  Printf.printf "  Unoptimized (%d iters): %.6f s\n" alg_iters t_raw2;
  Printf.printf "  Optimized   (%d iters): %.6f s\n" alg_iters t_opt2;
  let speedup2 = if t_opt2 > 0.0 then t_raw2 /. t_opt2 else 999.0 in
  Printf.printf "  Speedup:    %.1fx\n" speedup2;

  (*─────────────────────────────────────────────────────────
    SUMMARY
   ─────────────────────────────────────────────────────────*)
  print_endline "";
  print_endline (String.make 56 '=');
  print_endline "  BENCHMARK SUMMARY";
  print_endline (String.make 56 '=');
  Printf.printf "  %-30s  %6.1fx speedup\n" "Constant folding (chain)" speedup1;
  Printf.printf "  %-30s  %6.1fx speedup\n" "Algebraic simplification" speedup2;
  print_endline (String.make 56 '=');
  print_endline "";
  print_endline "✓ Benchmark 1 complete.\n"
