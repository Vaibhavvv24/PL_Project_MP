(** 
    Compile-Time Meta-Programming: ppx_log 
    A PPX (pre-processor extension) that instruments OCaml
    functions at COMPILE TIME by rewriting their AST.

    USAGE in source code:
      [%%log let f x = x + 1]

    EFFECT (what the compiler sees after preprocessing):
      let f x =
        print_endline "-> [LOG] Entering: f";
        let __result__ = x + 1 in
        print_endline "<- [LOG] Exiting: f";
        __result__

    The transformation happens at ZERO runtime cost for the
    instrumentation infrastructure - it is baked into the binary. 
*) 

open Ppxlib

(* HELPER: Build a [print_endline "msg"] expression at [loc]. *) 
let make_print_call ~(loc : location) (msg : string) : expression =
  let open Ast_builder.Default in
  eapply ~loc
    (evar ~loc "print_endline")
    [estring ~loc msg]

(* 
   HELPER: Wrap a function body [body_expr] with enter/exit logs.
   The transformation sequence:
     original body   ->   let __result__ = <body> in <exit_log>; __result__
   Then wrap with entry log.*)
let instrument_body ~(loc : location) (fn_name : string) (body_expr : expression)
    : expression =
  let open Ast_builder.Default in
  (* 1. entry log expression: print_endline "-> [LOG] Entering: fn_name" *)
  let entry_msg  = Printf.sprintf "[LOG] >> Entering: %s" fn_name in
  let entry_log  = make_print_call ~loc entry_msg in
  (* 2. exit log expression *)
  let exit_msg   = Printf.sprintf "[LOG] << Exiting:  %s" fn_name in
  let exit_log   = make_print_call ~loc exit_msg in
  (* 3. let __result__ = <original body> in (exit_log; __result__) *)
  let result_pat = ppat_var ~loc { txt = "__result__"; loc } in
  let result_var = evar ~loc "__result__" in
  let body_with_exit =
    pexp_let ~loc Nonrecursive
      [ value_binding ~loc ~pat:result_pat ~expr:body_expr ]
      (esequence ~loc [exit_log; result_var])
  in
  (* 4. prepend entry log: entry_log; body_with_exit *)
  esequence ~loc [entry_log; body_with_exit]


let name_of_pattern (pat : pattern) : string =
  match pat.ppat_desc with
  | Ppat_var { txt; _ } -> txt
  | _                   -> "<anonymous>"

let expand ~(loc : location) ~path:_ (payload : structure) : structure_item =
  match payload with
  (* Match exactly one [let <rec?> <pattern> = <expr>] binding *)
  | [ { pstr_desc =
          Pstr_value (rec_flag, [ binding ]);
        pstr_loc
      } ] ->
      let fn_name      = name_of_pattern binding.pvb_pat in
      let new_body     = instrument_body ~loc fn_name binding.pvb_expr in
      let new_binding  =
        { binding with
          pvb_expr       = new_body
        ; pvb_constraint = None
        }
      in
      { pstr_desc = Pstr_value (rec_flag, [new_binding])
      ; pstr_loc
      }

  (* Anything else is an error *)
  | _ ->
      Location.raise_errorf ~loc
        "[%%%%log] must be applied to a single 'let' binding.\n\
         Example: [%%%%log let f x = x + 1]"



let extension =
  Extension.declare
    "log"
    Extension.Context.structure_item
    Ast_pattern.(pstr __)
    expand

let () =
  Driver.register_transformation "ppx_log"
    ~rules:[ Context_free.Rule.extension extension ]
