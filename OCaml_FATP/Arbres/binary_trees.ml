open Prelud
open Orders


(* +app_right+ *)
(*
let app_left f (x,y) =(f x,y)
let app_right f (x,y) =(x,f y)
let app_both f (x,y) = (f x,f y)
*)


type equiv_option = Take_Old | Take_New | Abort ;;

let int_order =
  mk_preorder ((( < ):int -> int -> bool), (( = ) : int -> int -> bool)) ;;

(** The type for binary trees *)
(** +btree+ *)
type 'a btree = Empty | Bin of 'a btree * 'a * 'a btree ;;

(** +Btree_exc+ *)
exception Btree_exc of string ;;

(** +root+ *)
let root = function
  | Empty -> raise (Btree_exc "root: empty tree")
  | (Bin (_, a, _)) -> a ;;

(** +left_son+ *)
let left_son = function
  | Empty -> raise (Btree_exc "left_son: empty tree")
  | (Bin (t, _, _)) -> t ;;

(** +right_son+ *)
let right_son = function
  | Empty -> raise (Btree_exc "right_son: empty tree")
  | (Bin (_, _, t)) -> t ;;

(** Various binary trees iterators *)
(** +btree_hom+ *)
let rec btree_hom f v t =
  match t with
  | (Bin (t1, a, t2)) -> f (btree_hom f v t1, a, btree_hom f v t2)
  | Empty -> v ;;

(** +btree_height_size+ *)
let btree_height t = btree_hom (fun (x1, _, x2) -> 1 + maxint x1 x2) 0 t ;;
let btree_size t = btree_hom (fun (x1, _, x2) -> 1 + x1 + x2) 0 t ;;

(** +map_btree+ *)
let map_btree f t =
  btree_hom (fun (t1, a, t2) -> Bin (t1, f a, t2))
    Empty t ;;

(** +mirror_btree+ *)
let mirror_btree t = btree_hom
    (fun (t1, a, t2) -> Bin (t2, a, t1))
    Empty t ;;

(** +btree_it+ *)
let rec btree_it f t x =
  match t with
  | Empty -> x
  | Bin (t1, a, t2) ->
    btree_it f t1 (f a (btree_it f t2 x)) ;;

(** +it_btree+ *)
let rec it_btree f x t =
  match t with
  | Empty -> x
  | (Bin (t1, a, t2)) ->
    it_btree f (f (it_btree f x t1) a) t2 ;;

let rec pre_btree_it f t x =
  match t with
  | Empty -> x
  | Bin (t1, a, t2) ->
    pre_btree_it f t1 (pre_btree_it f t2 (f a x)) ;;

let rec pre_it_btree f x t =
  match t with
  | Empty -> x
  | (Bin (t1, a, t2)) ->
    pre_it_btree f (pre_it_btree f (f x a) t1) t2 ;;

let rec post_btree_it f t x =
  match t with
  | Empty -> x
  | Bin (t1, a, t2) ->
    f a (post_btree_it f t1 (post_btree_it f t2 x)) ;;

let rec post_it_btree f x t =
  match t with
  | Empty -> x
  | (Bin (t1, a, t2)) ->
    f (post_it_btree f (post_it_btree f x t1) t2) a ;;

(** General tree  depth-first traversals *)
type orientation = Left_to_right | Right_to_left ;;

type visit_order = Prefix | Infix | Postfix ;;

(*
let flat_btree spec f t =
  let consf = fun x l -> f x :: l
  and xconsf = fun l x -> f x :: l in
  match spec with
    (Left_to_right,Prefix) -> pre_btree_it consf t []
  | (Left_to_right,Infix) -> btree_it consf t []
  | (Left_to_right,Postfix) -> post_btree_it consf t []
  | (Right_to_left,Prefix) -> pre_it_btree xconsf [] t
  | (Right_to_left,Infix) -> it_btree xconsf [] t
  | (Right_to_left,Postfix) -> post_it_btree xconsf [] t ;;
*)


(** +flat_btree+*)
let flat_btree t = btree_it (fun x l -> x :: l) t [] ;;

let flat_btree' f t = btree_it (fun x l -> f x :: l) t [] ;;


let btree_trav f g =
  let rec trav n t =
    match t with
    | (Bin (t1, a, t2)) ->
      f (n, a, trav (n+1) t1, trav (n+1) t2)
    | Empty -> g(n)
  in
  trav 0 ;;

let btree_trav f v (g1, g2) =
  let rec trav x t =
    match t with
    | (Bin (t1, a, t2)) ->
      f (x, a, trav (g1 a x) t1, trav (g2 a x) t2)
    | Empty -> v x
  in
  trav ;;

(*
let do_btree spec h t=
  let h1 x y = h x;()
  and h2 x y = h y;() in
  match spec with
    (Left_to_right,Prefix) -> pre_it_btree h2 () t
  | (Left_to_right,Infix) -> it_btree h2 () t
  | (Left_to_right,Postfix) -> post_it_btree h2 () t
  | (Right_to_left,Prefix) -> pre_btree_it h1 t ()
  | (Right_to_left,Infix) -> btree_it h1 t ()
  | (Right_to_left,Postfix) -> post_btree_it h1 t () ;;
*)

let do_btree_left f =
  let rec do_b = function
    | Empty -> ()
    | (Bin (t1, a, t2)) ->
      do_b t1; f a; do_b t2
  in
  do_b ;;

let do_btree_right f =
  let rec do_b = function
    | Empty -> ()
    | (Bin (t1, a, t2)) ->
      do_b t2; f a; do_b t1
  in
  do_b ;;

(** +do_btree+ *)
let do_btree (f:'a -> unit) =
  let rec do_f = function
    | Empty -> ()
    | (Bin (t1, a, t2)) ->
      do_f t1; f a; do_f t2
  in
  do_f ;;


(** Functions for binary search trees *)
(** The first argument is a preorder *)
(** +Bst_exc+ *)
exception Bst_exc of string ;;

(** +Bst_search_exc+ *)
exception Bst_search_exc of string ;;

(*
(** +is_bst+ *)
let is_bst order =
  let ext_order = extend_order order in
  let rec check_bst (a, b) t =
    match t with
    | Empty -> true
    | (Bin (t1, x, t2)) ->
      let x = Plain x in
      not (ext_order a x = Greater) &&
      not (ext_order x b = Greater) &&
      check_bst (a, x) t1 &&
      check_bst (x, b) t2
  in
  check_bst (Min, Max) ;;
*)

(** +is_bst+ *)
let is_bst order =
  let ext_order = extend_order order in
  btree_trav
    (fun ((min, max), a, b1, b2) ->
       not (ext_order min (Plain a) = Greater)
       && not (ext_order (Plain a) max = Greater)
       && b1 && b2)
    (fun _ -> true)
    ((fun a (min, _max) -> min, Plain a)
    ,(fun a (_min, max) -> Plain a, max))
    (Min, Max) ;;

(** +search_bst+ *)
let search_bst order answer e =
  let rec search = function
    | Empty -> raise (Bst_search_exc "search_bst")
    | (Bin (t1, x, t2) as t) ->
      match order e x with
      | Equiv -> answer t
      | Smaller -> search t1
      | Greater -> search t2
  in
  search ;;

(** +find_bst+ *)
let find_bst order = search_bst order root ;;

(** +belongs_to_bst+ *)
let belongs_to_bst order e t =
  try find_bst order e t; true
  with Bst_search_exc _ -> false ;;

(** +change_bst+ *)
let change_bst order modify e =
  let rec change = function
    | Empty -> raise (Bst_search_exc "change_bst")
    | (Bin (t1, x, t2) as _t) ->
      (match order e x with
       | Equiv -> Bin (t1, modify x, t2)
       | Smaller -> Bin (change t1, x, t2)
       | Greater -> Bin (t1, x, change t2))
  in
  change ;;

(** Additions at the leaves *)
(** +add_bottom_to_bst+ *)
let add_bottom_to_bst option order t e =
  let rec add = function
    | Empty -> Bin (Empty, e, Empty)
    | (Bin (t1, x, t2) as _t) ->
      (match order e x with
       | Equiv -> Bin (t1, option e x, t2)
       | Smaller -> Bin (add t1, x, t2)
       | Greater -> Bin (t1, x, add t2))
  in
  add t ;;

(** +add_list_bottom_to_bst+ *)
let add_list_bottom_to_bst option order =
  List.fold_left (add_bottom_to_bst option order) ;;

(** +mk_bst+ *)
let mk_bst option order = add_list_bottom_to_bst option order Empty ;;

(** Additions at the root *)
(** +cut_bst+ *)
let cut_bst order e =
  let rec cut = function
    | Empty -> (Empty, e, Empty)
    | (Bin (t1, a, t2)) ->
      (match order e a with
       | Smaller -> let (t, e', t') = cut t1 in
         (t, e', Bin (t', a, t2))
       | Equiv -> (t1, a, t2)
       | Greater -> let (t, e', t') = cut t2 in
         (Bin (t1, a, t), e', t'))
  in
  cut ;;

(** +add_root_to_bst+ *)
let add_root_to_bst option order e t =
  let t1, e', t2 = cut_bst order e t in
  Bin (t1, option e e', t2) ;;

(** +mk_bst2+ *)
let mk_bst2 option order l =
  List.fold_right (add_root_to_bst option order) l Empty ;;

(** Removals *)
(** +remove_biggest+ *)
let rec remove_biggest = function
  | (Bin (t1, a, Empty)) -> (a, t1)
  | (Bin (t1, a, t2)) ->
    let (a', t') = remove_biggest t2 in (a', Bin (t1, a, t'))
  | Empty -> raise (Bst_exc "remove_biggest: tree is empty") ;;

(** +rem_root_from_bst+ *)
let rem_root_from_bst = function
  | Empty -> raise (Bst_exc "rem_root_from_bst: tree is empty")
  | (Bin (Empty, _a, t2)) -> t2
  | (Bin (t1, _, t2)) ->
    let (a', t') = remove_biggest t1 in
    Bin(t', a', t2) ;;

(** +rem_from_bst+ *)
let rem_from_bst order e =
  let rec rem = function
    | Empty -> raise (Bst_search_exc "rem_from_bst")
    | (Bin (t1, a, t2) as t) ->
      (match order e a  with
       | Equiv -> rem_root_from_bst t
       | Smaller -> Bin (rem t1, a, t2)
       | Greater -> Bin (t1, a, rem t2))
  in
  rem ;;

(** +rem_list_from_bst+ *)
let rem_list_from_bst order =
  List.fold_right (rem_from_bst order) ;;


(** rotate right *)
(** +rd_bst+ *)
let rot_right = function
  | (Bin (Bin (u, p, v), q, w))
    ->   Bin (u, p, Bin (v, q, w))
  | _ -> raise (Btree_exc "rot_right") ;;

(** rotate left *)
(** +rg_bst+ *)
let rot_left = function
  | (Bin (u, p, Bin (v, q, w)))
    -> Bin (Bin (u, p, v), q, w)
  | _ -> raise (Btree_exc "rot_left") ;;

(** rotate left right *)
(** +rgd_bst+ *)
let rot_left_right = function
  | (Bin (Bin (t, p, Bin (u, q, v)), r, w))
    ->
    Bin (Bin (t, p, u), q, Bin (v, r, w))
  | _ -> raise (Btree_exc "rot_left_right") ;;

(** rotate right left *)
(** +rdg_bst+ *)
let rot_right_left = function
  | (Bin (t, r, Bin (Bin (u, q, v), p, w)))
    ->
    Bin (Bin (t, r, u), q, Bin (v, p, w))
  | _ -> raise (Btree_exc "rot_right_left") ;;


(** Balanced binary trees  (AVL) *)
(** +balance+ *)
type balance = Left | Balanced | Right ;;


let opposite_balance = function
  | Left -> Right
  | Balanced -> Balanced
  | Right -> Left ;;

(** +avltree+ *)
type 'a avltree = ('a * balance) btree ;;

(** +Avl_exc+ *)
exception Avl_exc of string ;;

let avl_size (t: 'a avltree) = btree_size t ;;

let avl_height = btree_height ;;

(** +balance+ *)
let balance = function
  | (Bin (_, (_, b), _)) -> b
  | Empty -> Balanced ;;

let correct_balance t =
  let rec c_b = function
    | Empty -> 0
    | (Bin (t1, (_, b), t2)) ->
      let n1 = c_b t1 and n2 = c_b t2 in
      if (b = Balanced && n1 = n2 ) then n1 + 1 else
      if (b = Left && n1 = n2 + 1) then n1 + 1 else
      if (b = Right && n2 = n1 + 1) then n2 + 1
      else raise (Avl_exc "not avl") in
  try let _ = c_b t in true
  with Avl_exc _ -> false ;;

let is_avl order t =
  correct_balance t && is_bst (fun x y -> order (fst x) (fst y)) t ;;

(** +Avl_search_exc+ *)
exception Avl_search_exc of string ;;


(** +find_avl+ *)
let find_avl order e (t: ('a * balance) btree) =
  try fst (find_bst (fun x y -> order x (fst y)) e t)
  with Bst_search_exc _ -> raise (Avl_search_exc "find_avl") ;;

(** +belongs_to_avl+ *)
let belongs_to_avl order =
  belongs_to_bst (fun x y -> order x (fst y)) ;;

let change_avl order modify e t =
  try change_bst (fun x y -> order x (fst y)) (fun (x, y) -> modify x, y) e t
  with Bst_search_exc _ -> raise (Avl_search_exc "change_avl") ;;

(* let flat_avl spec f = flat_btree spec (f % fst) ;; *)

let flat_avl  (t: ('a * balance) btree) = flat_btree' fst t ;;

let map_avl f (t: ('a * balance) btree) = map_btree (fun (x, y) -> f x, y) t ;;

let do_avl h (t: ('a * balance) btree) = do_btree (h % fst) t ;;

(** +is_avl+ *)
let  h_balanced (t: ('a * balance) btree) =
  let rec correct_balance= function
    | Empty  -> 0
    | (Bin (t1, (_x, b), t2))
      -> let n1 = correct_balance t1 and n2 = correct_balance t2 in
      if (b = Balanced && n1 = n2 ) then n1 + 1 else
      if (b = Left && n1 = n2 + 1) then n1 + 1 else
      if (b = Right && n2 = n1 + 1) then n2 + 1
      else raise (Avl_exc "not avl") in
  try let _ =  correct_balance t in true
  with Avl_exc _ -> false ;;

let is_avl order (t: ('a * balance) btree) =
  h_balanced t && is_bst (fun x y -> order (fst x) (fst y)) t ;;

(** +mirror_avl+ *)
let mirror_avl t =
  btree_hom
    (fun (t1, (x, b), t2)
      -> let b' = match b with
          | Left     -> Right
          | Balanced -> Balanced
          | Right    -> Left
        in
        Bin (t2, (x, b'), t1)
    )
    Empty t ;;


(** "Rotations " *)
(** +Avl_rotation_exc+ *)
exception Avl_rotation_exc of string ;;

(** rotate right *)
(** +rd+ *)
let rot_right = function
  | (Bin (Bin (u, (p, b), v), (q, _), w)) ->
    (match b with
     | Balanced -> Bin (u, (p, Right), Bin (v, (q, Left), w))
     | Left -> Bin (u, (p, Balanced), Bin (v, (q, Balanced), w))
     | Right -> raise (Avl_rotation_exc "rot_right"))
  | _ -> raise (Avl_rotation_exc "rot_right") ;;

(** rotate left *)
(** +rg+ *)
let rot_left = function
  | (Bin (u, (p, _), Bin (v, (q, b), w))) ->
    (match b with
     | Balanced ->
       Bin (Bin (u, (p, Right), v), (q, Left), w)
     | Right ->
       Bin (Bin (u, (p, Balanced), v), (q, Balanced), w)
     | Left -> raise (Avl_rotation_exc "rot_left"))
  | _ -> raise (Avl_rotation_exc "rot_left") ;;

(** rotate left right *)
(** +rgd+ *)
let rot_left_right = function
  | (Bin (Bin (t, (p, _), Bin (u, (q, b), v)), (r, _), w)) ->
    (match b with
     | Left -> Bin (Bin (t, (p, Balanced), u), (q, Balanced), Bin (v, (r, Right), w))
     | Right -> Bin (Bin (t, (p, Left), u), (q, Balanced), Bin (v, (r, Balanced), w))
     | Balanced -> Bin (Bin (t, (p, Balanced), u), (q, Balanced), Bin (v, (r, Balanced), w)))
  | _ -> raise (Avl_rotation_exc "rot_left_right") ;;

(** rotate right left *)
(** +rdg+ *)
let rot_right_left = function
  | (Bin (t, (r, _), Bin (Bin (u, (q, b), v), (p, _), w))) ->
    (match b with
     | Left -> Bin (Bin (t, (r, Balanced), u), (q, Balanced), Bin (v,(p, Right), w))
     | Right -> Bin (Bin (t, (r, Left), u), (q, Balanced), Bin (v, (p, Balanced), w))
     | Balanced -> Bin (Bin (t, (r, Balanced), u), (q, Balanced), Bin (v, (p, Balanced), w)))
  | _ -> raise (Avl_rotation_exc "rot_right_left") ;;


(** +avl_add_info+ *)
type avl_add_info = No_inc | Incleft | Incright ;;

(** +add_to_avl+ *)
let add_to_avl option order t e =
  let rec add = function
    | Empty ->
      Bin (Empty, (e, Balanced), Empty), Incleft
    | (Bin (t1, (x, b), t2) as _t) ->
      (match (order e x , b) with
         (Equiv, _) -> Bin (t1, (option e x, b), t2), No_inc
       | (Smaller, Balanced) ->
         let t, m = add t1 in
         if m = No_inc then Bin (t, (x, Balanced), t2), No_inc
         else Bin (t, (x, Left), t2), Incleft
       | (Greater, Balanced) ->
         let t, m = add t2 in
         if m = No_inc then Bin (t1, (x, Balanced), t), No_inc
         else Bin (t1, (x, Right), t), Incright
       | (Greater, Left) ->
         let t, m = add t2 in
         if m = No_inc then Bin (t1, (x, Left), t), No_inc
         else Bin (t1, (x, Balanced), t), No_inc
       | (Smaller, Left) ->
         let t, m = add t1 in
         (match m with
          | No_inc -> Bin (t, (x, Left), t2), No_inc
          | Incleft -> rot_right (Bin (t, (x, Balanced), t2)), No_inc
          | Incright -> rot_left_right (Bin (t, (x, Balanced), t2)), No_inc)
       | (Smaller, Right) ->
         let t, m = add t1 in
         if m = No_inc then Bin (t, (x, Right), t2), No_inc
         else Bin (t, (x, Balanced), t2), No_inc
       | (Greater, Right) ->
         let t, m = add t2 in
         (match m with
          | No_inc -> Bin (t1, (x, Right), t), No_inc
          | Incleft -> rot_right_left (Bin (t1, (x, Balanced), t)), No_inc
          | Incright -> rot_left (Bin (t1, (x, Balanced), t)), No_inc))
  in
  fst (add t) ;;

(** +add_list_to_avl+ *)
let add_list_to_avl option order = List.fold_left (add_to_avl option order) ;;

let mk_avl option order = add_list_to_avl option order Empty ;;

let merge_avl option order =
  it_btree (fun t x -> add_to_avl option order t (fst x)) ;;

(** +avl_sort+*)
let avl_sort order =
  flat_avl % (mk_avl (fun x _y -> x) order) ;;

(* let avl_sort order =
   (flat_avl (Left_to_right,Infix) I) % (mk_avl K order) ;;
*)

(** +balance_right+ *)
let balance_right (t, x, t') =
  match balance t with
  | (Left | Balanced) -> rot_right (Bin (t, (x, Balanced), t'))
  | Right -> rot_left_right (Bin (t, (x, Balanced), t')) ;;

(** +balance_left+ *)
let balance_left (t, x, t') =
  match balance t' with
  | (Right | Balanced) -> rot_left (Bin (t, (x, Balanced), t'))
  | Left -> rot_right_left (Bin (t, (x, Balanced), t')) ;;

(** +avl_rem_info+ *)
type avl_rem_info = No_dec | Dec ;;

let rec remove_biggest = function
  | (Bin (t1, (a, _), Empty)) -> (a, t1, Dec)
  | (Bin (t1, (a, Balanced), t2)) ->
    let (a', t', b) = remove_biggest t2 in
    (match b with
     | Dec -> (a', Bin (t1, (a, Left), t'), No_dec)
     | No_dec -> (a', Bin (t1, (a, Balanced), t'), No_dec))
  | (Bin (t1, (a, Right), t2)) ->
    let (a', t', b) = remove_biggest t2 in
    (match b with
     | Dec -> (a', Bin (t1, (a, Balanced), t'), Dec)
     | No_dec -> (a', Bin (t1, (a, Right), t'), No_dec))
  | (Bin (t1, (a, Left), t2)) ->
    let (a', t', b) = remove_biggest t2 in
    (match b with
     | Dec -> (a', balance_right (t1, a, t'),
               match snd (root t1) with
               | (Left | Right) -> Dec
               | Balanced -> No_dec)
     | No_dec -> (a', Bin (t1, (a, Left), t'), No_dec))
  | Empty -> raise (Avl_exc "remove_biggest: empty avl") ;;


(** +avl_remove_biggest+ *)
let rec avl_remove_biggest = function
  | (Bin (t1, (a, _), Empty)) -> (a, t1, Dec)
  | (Bin (t1, (a, Balanced), t2)) ->
    let (a', t', b) = avl_remove_biggest t2 in
    (match b with
     | Dec -> (a', Bin (t1, (a, Left), t'), No_dec)
     | No_dec -> (a', Bin (t1, (a, Balanced), t'), No_dec))
  | (Bin (t1, (a, Right), t2)) ->
    let (a', t', b) = avl_remove_biggest t2 in
    (match b with
     | Dec -> (a', Bin (t1, (a, Balanced), t'), Dec)
     | No_dec -> (a', Bin (t1, (a, Right), t'), No_dec))
  | (Bin (t1, (a, Left), t2)) ->
    let (a', t', b) = avl_remove_biggest t2 in
    (match b with
     | Dec -> (a', balance_right (t1, a, t'),
               match snd (root t1) with
               | (Left | Right) -> Dec
               | Balanced -> No_dec)
     | No_dec -> (a', Bin (t1, (a, Left), t'), No_dec))
  | Empty -> raise (Avl_exc "avl_remove_biggest: empty avl") ;;


(** +remove_from_avl+ *)
let remove_from_avl order t e =
  let rec remove = function
    | Empty -> raise (Avl_search_exc "remove_from_avl")
    | (Bin (t1, (a, b), t2)) ->
      match order e a with
      | Equiv ->
        if t1 = Empty then t2, Dec else
        if t2 = Empty then t1, Dec else
          let (a', t', m) = avl_remove_biggest t1 in
          (match m with
           | No_dec -> Bin (t', (a', b), t2), No_dec
           | Dec -> (match b with
               | Balanced -> Bin (t', (a', Right), t2), No_dec
               | Left -> Bin (t', (a', Balanced), t2), Dec
               | Right -> balance_left (t', a', t2),
                          if balance t2 = Balanced
                          then No_dec else Dec))
      | Smaller ->
        let t', m = remove t1 in
        (match m with
         | No_dec -> Bin (t', (a, b), t2), No_dec
         | Dec -> (match b with
             | Balanced -> Bin (t', (a, Right), t2), No_dec
             | Left -> Bin (t', (a, Balanced), t2), Dec
             | Right -> balance_left (t', a, t2),
                        if balance t2 = Balanced
                        then No_dec else Dec))
      | Greater ->
        let t', m = remove t2 in
        (match m with
         | No_dec -> Bin (t1, (a, b), t'), No_dec
         | Dec -> (match b with
             | Balanced -> Bin (t1, (a, Left), t'), No_dec
             | Right -> Bin (t1, (a, Balanced), t'),Dec
             | Left -> balance_right (t1, a, t'),
                       if balance t1 = Balanced
                       then No_dec else Dec))
  in
  fst (remove t) ;;

let remove_list_from_avl r = List.fold_left (remove_from_avl r) ;;

let subtract_from_avl order t e =
  try remove_from_avl order t e
  with (Avl_search_exc _) -> t ;;

let subtract_list_from_avl r = List.fold_left (subtract_from_avl r) ;;

(*
   Abbreviations to make tests
   let mk= mk_avl K int_order
   let rm=remove_from_avl int_order
   let rml =remove_list_from_avl int_order
   let sub=subtract_from_avl int_order
   let subl=subtract_list_from_avl int_order
   let add= add_to_avl K int_order
   let addl= add_list_to_avl K int_order
   let rec interval a b n=
   if a>b then []  else a::interval (a+n) b n
 *)
