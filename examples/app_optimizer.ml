(** Example 2: DSL Expression Optimizer Showcase
    Demonstrates:
      - Building DSL expressions programmatically
      - AST pretty-printing and tree visualization
      - Constant folding, algebraic simplification,
        strength reduction
      - Partial evaluation
      - Named transform registry
*)

open Runtime_meta.Dsl
open Runtime_meta.Optimizer
open Runtime_meta.Transformer

let separator () = print_endline (String.make 56 '-')
let section s   = Printf.printf "\n* %s\n" s; separator ()

let () =
  print_endline "";
  print_endline "";
  print_endline "       EXAMPLE: Runtime Meta-Programming — DSL       ";
  print_endline "";

  (* 1. Build and Evaluate Expressions *)
  section "1. Building & Evaluating DSL Expressions";

  let e1 = mul (const 3) (add (const 4) (const 6)) in
  Printf.printf "Expression:  %s\n" (to_string e1);
  Printf.printf "AST nodes:   %d,  depth: %d\n" (size e1) (depth e1);
  Printf.printf "Evaluated:   %d\n" (eval [] e1);

  let e2 = let_ "x" (const 10) (add (var "x") (mul (var "x") (const 2))) in
  Printf.printf "\nExpression:  %s\n" (to_string e2);
  Printf.printf "Evaluated:   %d  (let x=10 in x + x*2 = 30)\n" (eval [] e2);

  (* 2. Constant Folding *)
  section "2. Constant Folding";
  let cf1 = add (const 100) (mul (const 3) (const 7)) in
  let cf2 = fold_constants cf1 in
  Printf.printf "Before: %s\n" (to_string cf1);
  Printf.printf "After:  %s\n" (to_string cf2);
  Printf.printf "AST nodes: %d ->%d\n" (size cf1) (size cf2);

  (* 3. Algebraic Simplification *)
  section "3. Algebraic Simplification";
  let rules_to_show =
    [ add (var "x") (const 0),       "x + 0 -> x"
    ; mul (var "x") (const 1),       "x * 1 -> x"
    ; mul (var "x") (const 0),       "x * 0 -> 0"
    ; sub (var "y") (const 0),       "y - 0 -> y"
    ; sub (var "z") (var "z"),       "z - z -> 0"
    ; div (var "a") (const 1),       "a / 1 -> a"
    ; div (var "b") (var "b"),       "b / b -> 1"
    ]
  in
  List.iter (fun (e, rule) ->
    let s = simplify e in
    Printf.printf "  %-22s  ->  %s\n" (to_string e) (to_string s);
    ignore rule
  ) rules_to_show;

  (* 4. Strength Reduction *)
  section "4. Strength Reduction";
  let sr_cases =
    [ mul (var "x") (const 2), "x*2 -> x+x"
    ; mul (var "x") (const 4), "x*4 -> ((x+x)+(x+x))"
    ]
  in
  List.iter (fun (e, note) ->
    let r = strength_reduce e in
    Printf.printf "  %-18s  ->  %-26s  (%s)\n"
      (to_string e) (to_string r) note
  ) sr_cases;

  (* 5. Full Optimizer Pipeline *)
  section "5. Full Optimizer Pipeline";
  let complex =
    add
      (mul (var "y") (const 0))      (* y*0 → 0 *)
      (add (const 5) (const 10))     (* 5+10 → 15 *)
  in
  Printf.printf "Original:  %s\n" (to_string complex);
  let opt1 = fold_constants complex in
  Printf.printf "After fold: %s\n" (to_string opt1);
  let opt2 = simplify opt1 in
  Printf.printf "After simp: %s\n" (to_string opt2);

  show_optimization_diff "Full Optimizer" complex (full_optimize complex);

  (* 6. AST Visualization *)
  section "6. AST Tree Visualization";
  let tree_expr = mul (add (var "a") (const 3)) (sub (const 10) (var "b")) in
  Printf.printf "Expression: %s\n\n" (to_string tree_expr);
  Printf.printf "AST Tree:\n";
  print_expr_tree tree_expr;

  (* 7. Partial Evaluation *)
  section "7. Partial Evaluation";
  let poly = build_polynomial [1; 2; 3] "x" in  (* 1 + 2x + 3x^2 *)
  Printf.printf "Polynomial (symbolic): %s\n" (to_string poly);
  let env_partial = [("x", 0)] in
  let after_pe = partial_eval env_partial poly in
  Printf.printf "Partial eval (x=0):    %s\n" (to_string after_pe);
  let env_full = [("x", 2)] in
  let after_full = partial_eval env_full poly in
  Printf.printf "Full eval   (x=2):     %s = %d  (expected 17)\n"
    (to_string after_full)
    (match after_full with Const n -> n | _ -> eval env_full poly);

  (* 8. Named Transform Registry *)
  section "8. Transform Classification Registry";
  List.iter (fun t ->
    Printf.printf "  [%-23s]  class=%-15s  %s\n"
      t.name
      (class_to_string t.class_)
      t.desc
  ) transform_registry;

  print_endline "\n All optimizer examples complete.\n"
