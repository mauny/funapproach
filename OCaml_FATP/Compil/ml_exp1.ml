(** +ml_binop+*)
type ml_unop = Ml_fst | Ml_snd ;;

type ml_binop = Ml_add | Ml_sub | Ml_mult | Ml_eq | Ml_less ;;

(** +ml_exp+*)
type ml_exp =
  | Ml_int_const of int                           (* integer constant *)
  | Ml_bool_const of bool                         (* Boolean constant *)
  | Ml_pair of ml_exp * ml_exp                                (* pair *)
  | Ml_unop of ml_unop * ml_exp                    (* unary operation *)
  | Ml_binop of ml_binop * ml_exp * ml_exp        (* binary operation *)
  | Ml_var of string                                      (* variable *)
  | Ml_if of ml_exp * ml_exp * ml_exp                  (* conditional *)
  | Ml_fun of string * ml_exp                             (* function *)
  | Ml_app of ml_exp * ml_exp                          (* application *)
  | Ml_let of string * ml_exp * ml_exp                 (* declaration *)
  | Ml_letrec of string * ml_exp * ml_exp ;; (* recursive declaration *)

(** +valu+*)
type valu =
  | Int_Const of int
  | Bool_Const of bool
  | Pair of valu * valu
  | Clo of (string * valu) list * ml_exp ;;
