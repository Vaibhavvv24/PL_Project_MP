(** ============================================================
    Example 1: Core Functional Programming Showcase
    ============================================================
    Demonstrates every FP construct in core_fp.ml with clear,
    annotated output.
    ============================================================ *)

open Core_fp

let separator () = print_endline (String.make 56 '-')
let section s   = Printf.printf "\n◆ %s\n" s; separator ()

let () =
  print_endline "";
  print_endline "╔══════════════════════════════════════════════════════╗";
  print_endline "║    EXAMPLE: Core Functional Programming in OCaml    ║";
  print_endline "╚══════════════════════════════════════════════════════╝";

  (* ── 1. First-class functions ────────────────────────── *)
  section "1. First-Class Functions";
  let double  = fun x -> x * 2 in
  let square  = fun x -> x * x in
  Printf.printf "apply double 7  = %d\n" (apply double 7);
  Printf.printf "apply square 5  = %d\n" (apply square 5);
  Printf.printf "apply_twice double 3  = %d\n" (apply_twice double 3);
  (* Storing functions in a list *)
  let fns = [double; square; make_adder 10] in
  let results = map (fun f -> f 4) fns in
  Printf.printf "map over [double, square, add10] for x=4: [%s]\n"
    (String.concat "; " (map string_of_int results));

  (* ── 2. Closures ─────────────────────────────────────── *)
  section "2. Closures";
  let add5  = make_adder 5 in
  let add10 = make_adder 10 in
  Printf.printf "add5 3   = %d\n" (add5 3);
  Printf.printf "add10 3  = %d\n" (add10 3);

  let counter = make_counter () in
  let c1 = counter () in
  let c2 = counter () in
  let c3 = counter () in
  Printf.printf "counter()=%d  counter()=%d  counter()=%d\n" c1 c2 c3;

  let acc = make_accumulator 100 in
  Printf.printf "accumulator: +10=%d  +20=%d  +5=%d\n"
    (acc 10) (acc 20) (acc 5);

  (* ── 3. Function Composition ─────────────────────────── *)
  section "3. Function Composition";
  let add3   = make_adder 3 in
  let times2 = make_multiplier 2 in
  let f      = compose times2 add3 in   (* f(x) = 2*(x+3) *)
  Printf.printf "compose (x*2) (x+3) applied to 7 = %d  (expected 20)\n" (f 7);

  let pipeline = compose_pipeline [add3; times2; make_adder 1] in
  Printf.printf "pipeline [+3, *2, +1] on 4 = %d  (expected 15)\n" (pipeline 4);

  Printf.printf "string_pipeline \" Hello World \" = %s\n"
    (string_pipeline " Hello World ");

  (* ── 4. Higher-Order Functions ───────────────────────── *)
  section "4. Higher-Order Functions";
  let nums = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10] in
  let sq_list   = map (fun x -> x * x) nums in
  let even_list = filter (fun x -> x mod 2 = 0) nums in
  let total     = fold_left ( + ) 0 nums in
  let product   = fold_left ( * ) 1 [1;2;3;4;5] in
  Printf.printf "map square [1..10] = [%s]\n"
    (String.concat "; " (map string_of_int sq_list));
  Printf.printf "filter even [1..10] = [%s]\n"
    (String.concat "; " (map string_of_int even_list));
  Printf.printf "fold_left (+) 0 [1..10] = %d\n" total;
  Printf.printf "fold_left (*) 1 [1..5]  = %d\n" product;

  let pairs = zip [1;2;3] ["a";"b";"c"] in
  Printf.printf "zip [1;2;3] [a;b;c] = [%s]\n"
    (String.concat "; "
       (map (fun (n,s) -> Printf.sprintf "(%d,%s)" n s) pairs));

  (* ── 5. Dynamic Function Generation ─────────────────── *)
  section "5. Dynamic Function Generation";
  let cube   = dynamic_power 3 in
  let fourth = dynamic_power 4 in
  Printf.printf "cube 3   = %d  (expected 27)\n" (cube 3);
  Printf.printf "fourth 2 = %d  (expected 16)\n" (fourth 2);

  let in_range = make_range_check 1 100 in
  Printf.printf "in_range 50  = %b  (expected true)\n"  (in_range 50);
  Printf.printf "in_range 101 = %b  (expected false)\n" (in_range 101);

  let cmp = make_threshold 50 in
  Printf.printf "threshold(50) on 75 = %s\n"
    (match cmp 75 with `Above -> "Above" | `Below -> "Below" | `Equal -> "Equal");

  print_endline "\n✓ All core FP examples complete.\n"
