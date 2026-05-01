(** Example 4: Offline Staged Compilation
    Demonstrates compiling an optimized AST directly into native
    OCaml source code. This entirely bypasses the runtime 
    interpreter (`eval`) for maximum performance.
  *)

open Runtime_meta
open Runtime_meta.Dsl
open Runtime_meta.Optimizer
open Runtime_meta.Codegen

let () =
  print_endline "";
  print_endline "╔══════════════════════════════════════════════════════╗";
  print_endline "║    EXAMPLE: Offline Staged Compilation (CodeGen)    ║";
  print_endline "╚══════════════════════════════════════════════════════╝";
  print_endline "";

  let run_codegen_test name ast =
    print_endline ("\n* " ^ name);
    print_endline "--------------------------------------------------------";
    Printf.printf "Original AST:  %s\n" (Dsl.to_string ast);
    
    let opt_expr = aggressive_optimizer ast in
    Printf.printf "Optimized AST: %s\n" (Dsl.to_string opt_expr);
    
    let generated_code = to_ocaml_function "compute_value" opt_expr in
    print_endline "\nGenerated Native OCaml Code:";
    print_endline "```ocaml";
    print_endline generated_code;
    print_endline "```";
  in

  (* Test Case 1: Complex expression with variables and let-bindings *)
  let expr1 =
    let_ "z" (mul (var "x") (const 2))
      (mul 
        (add (var "z") (var "y"))
        (add (mul (const 10) (const 0)) (sub (const 15) (const 5)))
      )
  in
  run_codegen_test "Test 1: Complex Let-Binding & Strength Reduction" expr1;

  (* Test Case 2: Division and Negation (Edge Case Testing) *)
  let expr2 =
    let_ "y" (neg (var "x"))
      (add (div (var "y") (const 2)) (neg (const 5)))
  in
  run_codegen_test "Test 2: Division and Negation" expr2;

  (* Test Case 3: Constant-only expression (Testing empty arguments) *)
  let expr3 =
    sub (mul (const 10) (const 2)) (const 5)
  in
  run_codegen_test "Test 3: Constant-Only Expression (No arguments)" expr3;

  (* Test Case 4: Float Generation (Staged Meta-Programming Magic) *)
  print_endline "\n* Test 4: Floating Point Generation (Staged Magic)";
  print_endline "--------------------------------------------------------";
  let expr4 = div (add (var "score") (const 5)) (const 2) in
  Printf.printf "Original AST:  %s\n" (Dsl.to_string expr4);
  let opt_expr4 = aggressive_optimizer expr4 in
  Printf.printf "Optimized AST: %s\n" (Dsl.to_string opt_expr4);
  
  let float_code = to_float_ocaml_function "compute_average" opt_expr4 in
  print_endline "\nGenerated Native OCaml Code (FLOAT OPERATORS):";
  print_endline "```ocaml";
  print_endline float_code;
  print_endline "```";

  print_endline "  CODEGEN COMPLETE";
  print_endline "  What was demonstrated:";
  print_endline "    ✓ Taking an in-memory optimized AST.";
  print_endline "    ✓ Extracting free variables for function signature (or () if none).";
  print_endline "    ✓ Generating safe, strict-precedence OCaml source code.";
  print_endline "    ✓ Handling edge cases like negation and division.";

