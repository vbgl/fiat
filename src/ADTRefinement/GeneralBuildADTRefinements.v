Require Import List Arith
        Common Computation ADT.ADTSig ADT.Core
        ADT.ComputationalADT
        Common.StringBound Common.ilist IterateBoundedIndex
        ADTNotation.BuildADTSig ADTNotation.BuildADT
        ADTNotation.BuildComputationalADT
        ADTNotation.BuildADTReplaceMethods
        ADTRefinement.Core ADTRefinement.GeneralRefinements
        ADTRefinement.SetoidMorphisms ADTRefinement.BuildADTSetoidMorphisms.

(* Notation-friendly versions of the honing tactics in GeneralRefinements. *)

Section BuildADTRefinements.

  Require Import String.
  Local Hint Resolve string_dec.

  Lemma refineADT_BuildADT_ReplaceConstructor
            (Rep : Type)
            (AbsR : Rep -> Rep -> Prop)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map consID consSigs))
            (newDef : consDef (nth_Bounded consID consSigs idx))
  :
    (forall consIdx,
       refineConstructor AbsR (getConsDef consDefs consIdx) (getConsDef consDefs consIdx))
    -> (forall methIdx,
          refineMethod AbsR (getMethDef methDefs methIdx) (getMethDef methDefs methIdx))
    -> refineConstructor AbsR
                     (consBody (ith_Bounded _ consDefs idx ))
                     (consBody newDef)
    -> refineADT
      (BuildADT consDefs methDefs)
      (ADTReplaceConsDef consDefs methDefs idx newDef).
  Proof.
    intros; eapply refineADT_BuildADT_Rep with (AbsR := AbsR); eauto.
    intros; unfold getConsDef.
    unfold replaceConsDef.
    eapply ith_replace_BoundedIndex_ind; eauto.
  Qed.

  Corollary refineADT_BuildADT_ReplaceConstructor_eq
            (Rep : Type)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map consID consSigs))
            (newDef : consDef (nth_Bounded consID consSigs idx))
  :
    refineConstructor eq
                  (consBody (ith_Bounded _ consDefs idx))
                  (consBody newDef)
    -> refineADT
      (BuildADT consDefs methDefs)
      (ADTReplaceConsDef consDefs methDefs idx newDef).
  Proof.
    eapply refineADT_BuildADT_ReplaceConstructor;
    simpl; unfold refine; intros; subst; eauto.
    repeat econstructor; try destruct v; eauto.
  Qed.

  Corollary SharpenStep_BuildADT_ReplaceConstructor_eq
            (Rep : Type)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map consID consSigs))
            (newDef : consDef (nth_Bounded consID consSigs idx))
  :
    (forall d,
      refine (consBody (ith_Bounded consID consDefs idx) d) (consBody newDef d))
    -> Sharpened (ADTReplaceConsDef consDefs methDefs idx newDef)
    -> Sharpened (BuildADT consDefs methDefs).
  Proof.
    intros; eapply SharpenStep; eauto.
    destruct newDef; simpl.
    intros; eapply refineADT_BuildADT_ReplaceConstructor_eq;
    simpl; intros; subst; try reflexivity;
    setoid_rewrite refineEquiv_pick_eq'; simplify with monad laws;
    eauto.
  Defined.

  Lemma refineADT_BuildADT_ReplaceConstructor_sigma
        (RepT : Type)
        (RepInv : RepT -> Prop)
        `{forall x, IsHProp (RepInv x)}
        (consSigs : list consSig)
        (methSigs : list methSig)
        (consDefs : ilist (@consDef (sig RepInv)) consSigs)
        (methDefs : ilist (@methDef (sig RepInv)) methSigs)
        (idx : @BoundedString (List.map consID consSigs))
        (newDef : consDef (nth_Bounded consID consSigs idx))
  : refineConstructor (fun x y => proj1_sig x = proj1_sig y)
                  (consBody (ith_Bounded _ consDefs idx))
                  (consBody newDef)
    -> refineADT
         (BuildADT consDefs methDefs)
         (ADTReplaceConsDef consDefs methDefs idx newDef).
  Proof.
    intro H'.
    eapply refineADT_BuildADT_ReplaceConstructor_eq.
    simpl in *; intros; subst; eauto.
    etransitivity; [ | eapply_hyp; reflexivity ].
    eapply refine_bind; [ reflexivity | intro ].
    eapply refine_flip_impl_Pick;
      repeat intro;
      apply path_sig_hprop;
      assumption.
  Qed.

  Lemma refineADT_BuildADT_ReplaceMethod
            (Rep : Type)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map methID methSigs))
            (newDef : methDef (nth_Bounded _ methSigs idx))
            AbsR
            (AbsR_reflexive_constructor :
               forall consIdx,
                 refineConstructor AbsR (getConsDef consDefs consIdx) (getConsDef consDefs consIdx))
            (AbsR_reflexive_method :
               forall methIdx,
                 refineMethod AbsR (getMethDef methDefs methIdx) (getMethDef methDefs methIdx))
  : refineMethod AbsR
                   (methBody (ith_Bounded _ methDefs idx))
                   (methBody newDef)
    -> refineADT
         (BuildADT consDefs methDefs)
         (ADTReplaceMethDef consDefs methDefs idx newDef).
  Proof.
    intros; eapply refineADT_BuildADT_Rep with (AbsR := AbsR); trivial.
    intros; unfold getMethDef.
    unfold replaceMethDef.
    eapply ith_replace_BoundedIndex_ind; eauto.
  Qed.

  Lemma refineADT_BuildADT_ReplaceMethod_eq
            (Rep : Type)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map methID methSigs))
            (newDef : methDef (nth_Bounded _ methSigs idx))
  : refineMethod eq
                   (methBody (ith_Bounded _ methDefs idx))
                   (methBody newDef)
    -> refineADT
         (BuildADT consDefs methDefs)
         (ADTReplaceMethDef consDefs methDefs idx newDef).
  Proof.
    eapply refineADT_BuildADT_ReplaceMethod;
    reflexivity.
  Qed.

  Corollary SharpenStep_BuildADT_ReplaceMethod_eq
            (Rep : Type)
            (consSigs : list consSig)
            (methSigs : list methSig)
            (consDefs : ilist (@consDef Rep) consSigs)
            (methDefs : ilist (@methDef Rep) methSigs)
            (idx : @BoundedString (List.map methID methSigs))
            (newDef : methDef (nth_Bounded _ methSigs idx))
  :
    (forall r_n n,
      refine (methBody (ith_Bounded methID methDefs idx) r_n n) (methBody newDef r_n n))
    -> Sharpened (ADTReplaceMethDef consDefs methDefs idx newDef)
    -> Sharpened (BuildADT consDefs methDefs).
  Proof.
    intros; eapply SharpenStep; eauto.
    destruct newDef; simpl.
    intros; eapply refineADT_BuildADT_ReplaceMethod_eq;
    simpl; intros; subst; try reflexivity;
    setoid_rewrite H; setoid_rewrite refineEquiv_pick_eq';
    simplify with monad laws.
    econstructor; eauto.
    destruct v; simpl; econstructor.
  Defined.

  Lemma refineADT_BuildADT_ReplaceMethod_sigma
        (RepT : Type)
        (RepInv : RepT -> Prop)
        (consSigs : list consSig)
        (methSigs : list methSig)
        (consDefs : ilist (@consDef (sig RepInv)) consSigs)
        (methDefs : ilist (@methDef (sig RepInv)) methSigs)
        (idx : @BoundedString (List.map methID methSigs))
        (newDef : methDef (nth_Bounded _ methSigs idx))
        (AbsR_reflexive_method :
           forall methIdx,
             refineMethod (fun x y => proj1_sig x = proj1_sig y)
                          (getMethDef methDefs methIdx)
                          (getMethDef methDefs methIdx))
  : refineMethod (fun x y => proj1_sig x = proj1_sig y)
                   (methBody (ith_Bounded _ methDefs idx))
                   (methBody newDef)
    -> refineADT
         (BuildADT consDefs methDefs)
         (ADTReplaceMethDef consDefs methDefs idx newDef).
  Proof.
    intro H'.
    eapply refineADT_BuildADT_ReplaceMethod with
    (AbsR := fun r_o r_n => proj1_sig r_o = proj1_sig r_n); eauto;
    simpl in *; intros; subst; eauto.
    intro; econstructor; eauto.
  Qed.

  (* Notation-Friendly Lemmas for constructing an easily extractible
     ADT implementation. *)

  Definition Notation_Friendly_BuildMostlySharpenedcADT
             (consSigs : list consSig)
             (methSigs : list methSig)
             (DelegateSigs : list ADTSig)
             (rep : ilist cADT DelegateSigs -> Type)
             (cConstructors :
                forall (DelegateImpl : ilist cADT DelegateSigs),
                  ilist (fun Sig => cConstructorType (rep DelegateImpl) (consDom Sig)) consSigs)
             (cMethods :
                forall (DelegateImpl : ilist cADT DelegateSigs),
                  ilist (fun Sig => cMethodType (rep DelegateImpl) (methDom Sig) (methCod Sig)) methSigs)
             (DelegateImpl : ilist cADT DelegateSigs)
  : cADT (BuildADTSig consSigs methSigs) :=
             @BuildcADT (rep DelegateImpl) consSigs methSigs
                        (imap _ (@Build_cConsDef (rep DelegateImpl)) (cConstructors DelegateImpl))
                        (imap _ (@Build_cMethDef (rep DelegateImpl)) (cMethods DelegateImpl)).

  Definition Notation_Friendly_FullySharpened_BuildMostlySharpenedcADT
             (RepT : Type)
             (consSigs : list consSig)
             (methSigs : list methSig)
             (consDefs : ilist (@consDef RepT) consSigs)
             (methDefs : ilist (@methDef RepT) methSigs)
  : forall (DelegateSigs : list ADTSig)
           (rep : ilist cADT DelegateSigs -> Type)
           (cConstructors :
              forall (DelegateImpl : ilist cADT DelegateSigs),
                ilist (fun Sig => cConstructorType (rep DelegateImpl) (consDom Sig)) consSigs)
           (cMethods :
              forall (DelegateImpl : ilist cADT DelegateSigs),
                ilist (fun Sig => cMethodType (rep DelegateImpl) (methDom Sig) (methCod Sig)) methSigs)
           (DelegateSpecs : ilist ADT DelegateSigs)
           (cAbsR : forall DelegateImpl,
                      (forall n, Dep_Option_elim_T2
                                   (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                                   (ith_error DelegateSpecs n)
                                   (ith_error DelegateImpl n))
                      -> RepT -> rep DelegateImpl -> Prop),
      (forall (DelegateImpl : ilist cADT DelegateSigs)
              (ValidImpl :
                 forall n, Dep_Option_elim_T2
                             (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                             (ith_error DelegateSpecs n)
                             (ith_error DelegateImpl n)),
         Iterate_Dep_Type_BoundedIndex
              (fun idx =>
                 @refineConstructor
                   RepT (rep DelegateImpl) (cAbsR _ ValidImpl) _
                   (getConsDef consDefs idx)
                   (fun d => ret (ith_Bounded _ (cConstructors DelegateImpl) idx d))))
      -> (forall (DelegateImpl : ilist cADT DelegateSigs)
            (ValidImpl :
               forall n, Dep_Option_elim_T2
                           (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                           (ith_error DelegateSpecs n)
                           (ith_error DelegateImpl n)),
            Iterate_Dep_Type_BoundedIndex
              (fun idx =>
                 @refineMethod
                   (RepT) (rep DelegateImpl) (cAbsR _ ValidImpl) _ _
                   (getMethDef methDefs idx)
                   (fun r_n d => ret (ith_Bounded _ (cMethods DelegateImpl) idx r_n d))))
      -> FullySharpenedUnderDelegates
           (BuildADT consDefs methDefs)
           {|
             Sharpened_DelegateSigs := DelegateSigs;
             Sharpened_Implementation := Notation_Friendly_BuildMostlySharpenedcADT rep
                                           cConstructors cMethods;
             Sharpened_DelegateSpecs := DelegateSpecs |}.
  Proof.
    intros * cConstructorsRefinesSpec cMethodsRefinesSpec
                                      DelegateImpl DelegateImplRefinesSpec.
    eapply (@refinesADT _ (BuildADT consDefs methDefs)
                        (LiftcADT {|cRep := rep DelegateImpl;
                                    cConstructors := _;
                                    cMethods := _|})
                        (cAbsR DelegateImpl DelegateImplRefinesSpec)).
    - simpl; intros.
      rewrite <- ith_Bounded_imap; eauto.
      eapply (Iterate_Dep_Type_BoundedIndex_equiv_1
              _ (cConstructorsRefinesSpec DelegateImpl DelegateImplRefinesSpec) idx d).
    - simpl; intros.
       rewrite <- ith_Bounded_imap;
         eapply (Iterate_Dep_Type_BoundedIndex_equiv_1
                   _ (cMethodsRefinesSpec DelegateImpl DelegateImplRefinesSpec)
                   idx r_o r_n d H).
  Qed.

  Definition Notation_Friendly_SharpenFully
             (RepT : Type)
             (consSigs : list consSig)
             (methSigs : list methSig)
             (consDefs : ilist (@consDef RepT) consSigs)
             (methDefs : ilist (@methDef RepT) methSigs)
             (DelegateSigs : list ADTSig)
             (rep : ilist cADT DelegateSigs -> Type)
             (cConstructors :
                forall (DelegateImpl : ilist cADT DelegateSigs),
                ilist (fun Sig => cConstructorType (rep DelegateImpl) (consDom Sig)) consSigs)
             (cMethods :
              forall (DelegateImpl : ilist cADT DelegateSigs),
                ilist (fun Sig => cMethodType (rep DelegateImpl) (methDom Sig) (methCod Sig)) methSigs)
             (DelegateSpecs : ilist ADT DelegateSigs)
             (cAbsR : forall DelegateImpl,
                        (forall n, Dep_Option_elim_T2
                                     (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                                     (ith_error DelegateSpecs n)
                                     (ith_error DelegateImpl n))
                        -> RepT -> rep DelegateImpl -> Prop)
             (cConstructorsRefinesSpec :
                forall (DelegateImpl : ilist cADT DelegateSigs)
                  (ValidImpl :
                     forall n, Dep_Option_elim_T2
                                 (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                                 (ith_error DelegateSpecs n)
                                 (ith_error DelegateImpl n)),
                  Iterate_Dep_Type_BoundedIndex
                    (fun idx =>
                       @refineConstructor
                         RepT (rep DelegateImpl) (cAbsR _ ValidImpl) _
                         (getConsDef consDefs idx)
                         (fun d => ret (ith_Bounded _ (cConstructors DelegateImpl) idx d))))
             (cMethodsRefinesSpec :
                forall (DelegateImpl : ilist cADT DelegateSigs)
                       (ValidImpl :
                          forall n, Dep_Option_elim_T2
                                      (fun Sig adt adt' => @refineADT Sig adt (LiftcADT adt'))
                                      (ith_error DelegateSpecs n)
                                      (ith_error DelegateImpl n)),
                  Iterate_Dep_Type_BoundedIndex
                    (fun idx =>
                       @refineMethod
                         (RepT) (rep DelegateImpl) (cAbsR _ ValidImpl) _ _
                         (getMethDef methDefs idx)
                         (fun r_n d => ret (ith_Bounded _ (cMethods DelegateImpl) idx r_n d))))
  :  Sharpened (BuildADT consDefs methDefs)
    :=
      existT _ _
             (Notation_Friendly_FullySharpened_BuildMostlySharpenedcADT
                consDefs methDefs rep cConstructors cMethods
                DelegateSpecs cAbsR
                cConstructorsRefinesSpec cMethodsRefinesSpec).

End BuildADTRefinements.

Arguments Notation_Friendly_BuildMostlySharpenedcADT _ _ _ _ _ _ _ / .

Tactic Notation "extract" "implementation" "of" constr(adtImpl) "using" open_constr(delegateImpl) :=
  let Impl :=
      eval simpl in
  (Sharpened_Implementation (projT1 adtImpl) delegateImpl) in
      exact Impl.

(* A tactic for finishing a derivation. Probably needs a better name.*)
Tactic Notation "finish" "sharpening" constr(delegatees):=
  eexists; [ eapply reflexivityT
           | constructor 1 with (Sharpened_DelegateSpecs := delegatees); intros;
             split; simpl;
             match goal with
                 [|- forall idx : BoundedString, _] =>
                 let idx := fresh in
                 intro idx; pattern idx;
                 eapply Iterate_Ensemble_BoundedIndex_equiv;
                 unfold Iterate_Ensemble_BoundedIndex; simpl;
                 intuition;
                 repeat
                   (try simplify with monad laws;
                    first [constructor
                          | match goal with
                                |- context[if ?b then _ else _] =>
                                destruct b
                            end
                          ])
                    end ].

Tactic Notation "finish" "honing" :=
  subst_body;
  first [higher_order_2_reflexivity | higher_order_1_reflexivity ].

Ltac makeEvar T k :=
  let x := fresh in evar (x : T); let y := eval unfold x in x in clear x; k y.

Ltac ilist_of_evar C B As k :=
  match As with
    | nil => k (fun (c : C) => inil (B c))
    | cons ?a ?As' =>
      makeEvar (forall c, B c a)
               ltac:(fun b =>
                       ilist_of_evar
                         C B As'
                         ltac:(fun Bs' => k (fun c => icons a (b c) (Bs' c))))
  end.

Ltac FullySharpenEachMethod delegateSigs delegateSpecs :=
  match goal with
      |- Sharpened (@BuildADT ?Rep ?consSigs ?methSigs ?consDefs ?methDefs) =>
      ilist_of_evar
        (ilist ComputationalADT.cADT delegateSigs)
        (fun Sig => cMethodType Rep (methDom Sig) (methCod Sig))
        methSigs
        ltac:(fun cMeths => ilist_of_evar
                              (ilist ComputationalADT.cADT delegateSigs)
                              (fun Sig => cConstructorType Rep (consDom Sig))
                              consSigs
                              ltac:(fun cCons =>
                                      eapply Notation_Friendly_SharpenFully
                                      with (DelegateSpecs := delegateSpecs)
                                             (cConstructors := cCons)
                                             (cMethods := cMeths)));
        unfold Dep_Type_BoundedIndex_app_comm_cons; simpl;
        intros; repeat econstructor
  end.

Ltac BuildFullySharpenedConstructor :=
  intros;
  match goal with
      |- ret ?x ↝ ?Bod ?DelegateImpl ?d
      => let Bod' := eval pattern DelegateImpl, d in x in
         match Bod' with
           | (?Bod'' _ _) =>
             unify Bod Bod''; constructor
         end
  end.

Lemma SharpenIfComputesTo {A} :
  forall (cond : bool) (cT cE : Comp A) vT vE,
    cT ↝ vT
    -> cE ↝ vE
    -> (if cond then cT else cE) ↝ if cond then vT else vE.
Proof.
  destruct cond; eauto.
Qed.
