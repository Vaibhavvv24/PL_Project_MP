(** ============================================================
    Benchmark 2: Memoization Performance Evaluation
    ============================================================
    Measures the impact of memoization on:
      - Fibonacci (exponential without memo)
      - Polynomial evaluation (repeated queries)
    Tracks actual call counts to prove caching works.
    ============================================================ *)

open Runtime_meta.Memoize

(* ── Timing utility ──────────────────────────────────────── *)
let time_it (f : unit -> 'a) : float * 'a =
  let t0  = Unix.gettimeofday () in
  let res = f () in
  let t1  = Unix.gettimeofday () in
  (t1 -. t0, res)

(* ── Naive recursive Fibonacci (exponential time) ────────── *)
let call_count = ref 0

let rec fib_naive (n : int) : int =
  incr call_count;
  if n <= 1 then n
  else fib_naive (n - 1) + fib_naive (n - 2)

(* ── Memoized Fibonacci ──────────────────────────────────── *)
let memo_call_count = ref 0

let fib_memo : int -> int =
  (* Build memo table; inner fn tracks calls *)
  let cache = Hashtbl.create 64 in
  let rec f n =
    incr memo_call_count;
    match Hashtbl.find_opt cache n with
    | Some v -> v
    | None ->
        let v = if n <= 1 then n else f (n-1) + f (n-2) in
        Hashtbl.add cache n v;
        v
  in
  f

let () =
  print_endline "";
  print_endline "╔══════════════════════════════════════════════════════╗";
  print_endline "║       BENCHMARK 2: Memoization Performance           ║";
  print_endline "╚══════════════════════════════════════════════════════╝";
  print_endline "";

  (*─────────────────────────────────────────────────────────
    TEST 1: Fibonacci
   ─────────────────────────────────────────────────────────*)
  Printf.printf "▶ Test 1: Fibonacci comparison\n\n";

  let n = 35 in
  call_count := 0;
  let (t_naive, r_naive) = time_it (fun () -> fib_naive n) in
  let calls_naive = !call_count in

  memo_call_count := 0;
  let (t_memo, r_memo) = time_it (fun () -> fib_memo n) in
  let calls_memo = !memo_call_count in

  Printf.printf "  fib(%d) = %d\n\n" n r_naive;
  assert (r_naive = r_memo);

  Printf.printf "  %-24s  time=%.6f s  calls=%d\n"
    "Naive (recursive)" t_naive calls_naive;
  Printf.printf "  %-24s  time=%.6f s  calls=%d\n"
    "Memoized"          t_memo  calls_memo;

  let speedup  = if t_memo > 0.0 then t_naive /. t_memo else 999.0 in
  let call_red = float_of_int calls_memo /. float_of_int calls_naive *. 100.0 in
  Printf.printf "\n  Speedup:          %.1fx\n" speedup;
  Printf.printf "  Call reduction:   %.2f%% of naive calls needed\n" call_red;

  (*─────────────────────────────────────────────────────────
    TEST 2: Repeated query memoization
   ─────────────────────────────────────────────────────────*)
  print_endline "";
  print_endline (String.make 56 '-');
  Printf.printf "▶ Test 2: Repeated queries with memoize utility\n\n";

  let expensive_calls = ref 0 in
  let expensive x =
    incr expensive_calls;
    (* simulate work *)
    let acc = ref 0 in
    for i = 1 to 10000 do acc := !acc + i * x done;
    !acc
  in

  let (memo_fn, get_calls) = memoize_counted expensive in

  let queries = [1;2;3;1;2;3;4;5;1;2;3;4;5] in
  expensive_calls := 0;

  let (t_memo2, _) = time_it (fun () ->
    List.iter (fun q -> ignore (memo_fn q)) queries)
  in
  let memo_unique = get_calls () in

  expensive_calls := 0;
  let (t_raw2, _) = time_it (fun () ->
    List.iter (fun q -> ignore (expensive q)) queries)
  in
  let raw_calls = !expensive_calls in

  Printf.printf "  Queries:       %d  (unique: 5)\n" (List.length queries);
  Printf.printf "  Unmemoized:    %d expensive calls,  %.6f s\n" raw_calls t_raw2;
  Printf.printf "  Memoized:      %d expensive calls,  %.6f s\n" memo_unique t_memo2;
  let speedup2 = if t_memo2 > 0.0 then t_raw2 /. t_memo2 else 999.0 in
  Printf.printf "  Speedup:       %.1fx\n" speedup2;

  (*─────────────────────────────────────────────────────────
    SUMMARY
   ─────────────────────────────────────────────────────────*)
  print_endline "";
  print_endline (String.make 56 '=');
  print_endline "  BENCHMARK SUMMARY";
  print_endline (String.make 56 '=');
  Printf.printf "  %-30s  %6.1fx speedup\n" (Printf.sprintf "fib(%d)" n) speedup;
  Printf.printf "  %-30s  %6.1fx speedup\n" "Repeated queries" speedup2;
  print_endline (String.make 56 '=');
  print_endline "\n✓ Benchmark 2 complete.\n"
