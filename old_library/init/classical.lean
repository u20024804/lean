/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Jeremy Avigad
-/
prelude
import init.subtype init.funext
namespace classical
open subtype
universe variables u v
/- the axiom -/

-- In the presence of classical logic, we could prove this from a weaker statement:
-- axiom indefinite_description {A : Type u} {P : A->Prop} (H : ∃ x, P x) : {x : A, P x}
axiom strong_indefinite_description {A : Type u} (P : A → Prop) (H : nonempty A) :
  { x \ (∃ y : A, P y) → P x}

theorem exists_true_of_nonempty {A : Type u} (H : nonempty A) : ∃ x : A, true :=
nonempty.elim H (take x, ⟨x, trivial⟩)

noncomputable definition inhabited_of_nonempty {A : Type u} (H : nonempty A) : inhabited A :=
⟨elt_of (strong_indefinite_description (λ a, true) H)⟩

noncomputable definition inhabited_of_exists {A : Type u} {P : A → Prop} (H : ∃ x, P x) : inhabited A :=
inhabited_of_nonempty (exists.elim H (λ w Hw, ⟨w⟩))

/- the Hilbert epsilon function -/

noncomputable definition epsilon {A : Type u} [H : nonempty A] (P : A → Prop) : A :=
elt_of (strong_indefinite_description P H)

theorem epsilon_spec_aux {A : Type u} (H : nonempty A) (P : A → Prop) (Hex : ∃ y, P y) :
    P (@epsilon A H P) :=
have aux : (∃ y, P y) → P (elt_of (strong_indefinite_description P H)), from has_property (strong_indefinite_description P H),
aux Hex

theorem epsilon_spec {A : Type u} {P : A → Prop} (Hex : ∃ y, P y) :
    P (@epsilon A (nonempty_of_exists Hex) P) :=
epsilon_spec_aux (nonempty_of_exists Hex) P Hex

theorem epsilon_singleton {A : Type u} (a : A) : @epsilon A ⟨a⟩ (λ x, x = a) = a :=
@epsilon_spec A (λ x, x = a) ⟨a, rfl⟩

noncomputable definition some {A : Type u} {P : A → Prop} (H : ∃ x, P x) : A :=
@epsilon A (nonempty_of_exists H) P

theorem some_spec {A : Type u} {P : A → Prop} (H : ∃ x, P x) : P (some H) :=
epsilon_spec H

/- the axiom of choice -/

theorem axiom_of_choice {A : Type u} {B : A → Type v} {R : Π x, B x → Prop} (H : ∀ x, ∃ y, R x y) :
  ∃ (f : Π x, B x), ∀ x, R x (f x) :=
have H : ∀ x, R x (some (H x)), from take x, some_spec (H x),
⟨_, H⟩

theorem skolem {A : Type u} {B : A → Type v} {P : Π x, B x → Prop} :
  (∀ x, ∃ y, P x y) ↔ ∃ (f : Π x, B x) , (∀ x, P x (f x)) :=
iff.intro
  (assume H : (∀ x, ∃ y, P x y), axiom_of_choice H)
  (assume H : (∃ (f : Π x, B x), (∀ x, P x (f x))),
    take x, exists.elim H (λ (fw : ∀ x, B x) (Hw : ∀ x, P x (fw x)),
      ⟨fw x, Hw x⟩))
/-
Prove excluded middle using Hilbert's choice
The proof follows Diaconescu proof that shows that the axiom of choice implies the excluded middle.
-/
section diaconescu
parameter  p : Prop

private definition U (x : Prop) : Prop := x = true ∨ p
private definition V (x : Prop) : Prop := x = false ∨ p

private noncomputable definition u := epsilon U
private noncomputable definition v := epsilon V

private lemma u_def : U u :=
epsilon_spec ⟨true, or.inl rfl⟩

private lemma v_def : V v :=
epsilon_spec ⟨false, or.inl rfl⟩

private lemma not_uv_or_p : ¬(u = v) ∨ p :=
or.elim u_def
  (assume Hut : u = true,
    or.elim v_def
      (assume Hvf : v = false,
        have Hne : ¬(u = v), from eq.symm Hvf ▸ eq.symm Hut ▸ true_ne_false,
        or.inl Hne)
      (assume Hp : p, or.inr Hp))
  (assume Hp : p, or.inr Hp)

private lemma p_implies_uv : p → u = v :=
assume Hp : p,
have Hpred : U = V, from
  funext (take x : Prop,
    have Hl : (x = true ∨ p) → (x = false ∨ p), from
      assume A, or.inr Hp,
    have Hr : (x = false ∨ p) → (x = true ∨ p), from
      assume A, or.inr Hp,
    show (x = true ∨ p) = (x = false ∨ p), from
      propext (iff.intro Hl Hr)),
have H' : epsilon U = epsilon V, from Hpred ▸ rfl,
show u = v, from H'

theorem em : p ∨ ¬p :=
have H : ¬(u = v) → ¬p, from mt p_implies_uv,
  or.elim not_uv_or_p
    (assume Hne : ¬(u = v), or.inr (H Hne))
    (assume Hp : p, or.inl Hp)
end diaconescu

theorem prop_complete (a : Prop) : a = true ∨ a = false :=
or.elim (em a)
  (λ t, or.inl (propext (iff.intro (λ h, trivial) (λ h, t))))
  (λ f, or.inr (propext (iff.intro (λ h, absurd h f) (λ h, false.elim h))))

definition eq_true_or_eq_false := prop_complete

section aux
attribute [elab_as_eliminator]
theorem cases_true_false (P : Prop → Prop) (H1 : P true) (H2 : P false) (a : Prop) : P a :=
or.elim (prop_complete a)
  (assume Ht : a = true,  eq.symm Ht ▸ H1)
  (assume Hf : a = false, eq.symm Hf ▸ H2)

theorem cases_on (a : Prop) {P : Prop → Prop} (H1 : P true) (H2 : P false) : P a :=
cases_true_false P H1 H2 a

-- this supercedes by_cases in decidable
definition by_cases {p q : Prop} (Hpq : p → q) (Hnpq : ¬p → q) : q :=
or.elim (em p) (assume Hp, Hpq Hp) (assume Hnp, Hnpq Hnp)

-- this supercedes by_contradiction in decidable
theorem by_contradiction {p : Prop} (H : ¬p → false) : p :=
by_cases
  (assume H1 : p, H1)
  (assume H1 : ¬p, false.rec _ (H H1))

theorem eq_false_or_eq_true (a : Prop) : a = false ∨ a = true :=
cases_true_false (λ x, x = false ∨ x = true)
  (or.inr rfl)
  (or.inl rfl)
  a

theorem eq.of_iff {a b : Prop} (H : a ↔ b) : a = b :=
iff.elim (assume H1 H2, propext (iff.intro H1 H2)) H

theorem iff_eq_eq {a b : Prop} : (a ↔ b) = (a = b) :=
propext (iff.intro
  (assume H, eq.of_iff H)
  (assume H, iff.of_eq H))

lemma eq_false {a : Prop} : (a = false) = (¬ a) :=
have (a ↔ false) = (¬ a), from propext (iff_false a),
eq.subst (@iff_eq_eq a false) this

lemma eq_true {a : Prop} : (a = true) = a :=
have (a ↔ true) = a, from propext (iff_true a),
eq.subst (@iff_eq_eq a true) this
end aux

/- All propositions are decidable -/
noncomputable definition decidable_inhabited (a : Prop) : inhabited (decidable a) :=
inhabited_of_nonempty
  (or.elim (em a)
    (assume Ha, ⟨is_true Ha⟩)
    (assume Hna, ⟨is_false Hna⟩))
local attribute decidable_inhabited [instance]

noncomputable definition prop_decidable (a : Prop) : decidable a :=
arbitrary (decidable a)
local attribute prop_decidable [instance]

noncomputable definition type_decidable_eq (A : Type u) : decidable_eq A :=
λ a b, prop_decidable (a = b)

noncomputable definition type_decidable (A : Type u) : sum A (A → false) :=
match (prop_decidable (nonempty A)) with
| (is_true Hp) := sum.inl (inhabited.value (inhabited_of_nonempty Hp))
| (is_false Hn) := sum.inr (λ a, absurd (nonempty.intro a) Hn)
end

end classical
