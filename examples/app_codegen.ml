(** ============================================================
    Example 4: Offline Staged Compilation
    ============================================================
    Demonstrates compiling an optimized AST directly into native
    OCaml source code. This entirely bypasses the runtime 
    interpreter (`eval`) for maximum performance.
    ============================================================ *)

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

  (* 1. Build a complex expression with variables and constants *)
  (* Expression: let z = x * 2 in (z + y) * ((10 * 0) + (15 - 5)) *)
  let expr =
    let_ "z" (mul (var "x") (const 2))
      (mul 
        (add (var "z") (var "y"))
        (add (mul (const 10) (const 0)) (sub (const 15) (const 5)))
      )
  in

  print_endline "* 1. Initial AST Representation";
  print_endline "--------------------------------------------------------";
  Printf.printf "Expression: %s\n" (Dsl.to_string expr);
  Printf.printf "AST nodes:  %d\n" (Dsl.size expr);

  (* 2. Run the full optimization pipeline *)
  let opt_expr = aggressive_optimizer expr in

  print_endline "\n* 2. After Full Optimization Pipeline";
  print_endline "--------------------------------------------------------";
  Printf.printf "Expression: %s\n" (Dsl.to_string opt_expr);
  Printf.printf "AST nodes:  %d\n" (Dsl.size opt_expr);
  print_endline "(Notice strength reduction: x*2 -> x+x)";
  print_endline "(Notice constant folding & simplification: (10*0)+(15-5) -> 10)";

  (* 3. Generate Native OCaml Code *)
  print_endline "\n* 3. Generated Native OCaml Code";
  print_endline "--------------------------------------------------------";
  print_endline "We now auto-extract the variables (x, y) and generate a fully";
  print_endline "parenthesized, valid OCaml function string.";
  print_endline "";
  
  let generated_code = to_ocaml_function "compute_value" opt_expr in
  
  print_endline "```ocaml";
  print_endline generated_code;
  print_endline "```";

  print_endline "\n============================================================";
  print_endline "  CODEGEN COMPLETE";
  print_endline "============================================================";
  print_endline "  What was demonstrated:";
  print_endline "    ✓ Taking an in-memory optimized AST.";
  print_endline "    ✓ Extracting free variables (x, y) for function signature.";
  print_endline "    ✓ Generating safe, strict-precedence OCaml source code.";
  print_endline "    ✓ Bypassing the runtime interpreter completely.";
  print_endline "============================================================\n"
