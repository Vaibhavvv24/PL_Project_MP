(**
    Example 3: PPX Logging Showcase
    Demonstrates compile-time meta-programming using ppx_log.

    The [%%log let f x = ...] extension rewrites the function
    definition at COMPILE TIME to inject entry/exit log calls.

    This file shows the effect: running it proves the PPX
    inserted logging code automatically. *) 

(* PPX-transformed function definitions *) 
(* Each [%%log let ...] is rewritten by ppx_log before compilation *)

[%%log let add_one (x : int) = x + 1]

[%%log let multiply_by_two (x : int) = x * 2]

[%%log let factorial (n : int) =
  let rec aux acc k = if k <= 1 then acc else aux (acc * k) (k - 1)
  in aux 1 n]

[%%log let greet (name : string) = "Hello, " ^ name ^ "!"]

(* ── Main demonstration ────────────────────────────────────── *)
let () =
  print_endline "";
  print_endline "╔══════════════════════════════════════════════════════╗";
  print_endline "║    EXAMPLE: Compile-Time Meta-Programming (PPX)     ║";
  print_endline "╚══════════════════════════════════════════════════════╝";
  print_endline "";
  print_endline "Each function below was annotated with [%%log let ...].";
  print_endline "The ppx_log preprocessor injected LOG statements at";
  print_endline "compile time — no manual print calls were written!\n";
  print_endline (String.make 56 '-');

  Printf.printf "\nCalling add_one 10:\n";
  let r1 = add_one 10 in
  Printf.printf "  Result: %d\n" r1;

  Printf.printf "\nCalling multiply_by_two 7:\n";
  let r2 = multiply_by_two 7 in
  Printf.printf "  Result: %d\n" r2;

  Printf.printf "\nCalling factorial 6:\n";
  let r3 = factorial 6 in
  Printf.printf "  Result: %d  (expected 720)\n" r3;

  Printf.printf "\nCalling greet \"OCaml\":\n";
  let r4 = greet "OCaml" in
  Printf.printf "  Result: %s\n" r4;

  print_endline "";
  print_endline (String.make 56 '-');
  print_endline "Notice: every function printed [LOG] messages";
  print_endline "WITHOUT any manual print_endline in their bodies.\n";
  print_endline "This is COMPILE-TIME meta-programming in action!";
  print_endline "\n✓ PPX logging example complete.\n"
