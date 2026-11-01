module

public import Recursor
public import Mathlib.Computability.PartrecCode
public import Mathlib.Data.Nat.Sqrt

@[expose] public section

set_option autoImplicit false
set_option backward.isDefEq.respectTransparency false

namespace RecursorProofs
open Part

/-- Denotational semantics of the same syntax, with partiality represented by `Part`. -/
noncomputable def denote : Expr → Env → Part Nat
  | .var, env => pure env.input
  | .acc, env => pure env.accumulator
  | .idx, env => pure env.index
  | .const n, _ => pure n
  | .succ e, env => (· + 1) <$> denote e env
  | .pred e, env => Nat.pred <$> denote e env
  | .half e, env => (· / 2) <$> denote e env
  | .add a b, env => do return (← denote a env) + (← denote b env)
  | .mul a b, env => do return (← denote a env) * (← denote b env)
  | .monus a b, env => do return (← denote a env) - (← denote b env)
  | .rem a b, env => do return (← denote a env) % (← denote b env)
  | .ifz c z p, env => do
      let n ← denote c env
      if n = 0 then denote z env else denote p env
  | .iter count base body, env => do
      let n ← denote count env
      let a ← denote base env
      Nat.rec (pure a) (fun _ value => value >>= fun v => denote body {env with accumulator := v}) n
  | .recur count base body, env => do
      let n ← denote count env
      let a ← denote base env
      Nat.rec (pure a) (fun i value => value >>= fun v => denote body {env with accumulator := v, index := i}) n
  | .corec count body, env => do
      let n ← denote count env
      let history ← Nat.rec (pure ([] : List Nat)) (fun _ previous => do
        let history ← previous
        let v ← denote body {env with index := history.length, history := history}
        pure (history ++ [v])) (n + 1)
      pure (history[n]?.getD 0)
  | .cget index, env => do
      let n ← denote index env
      pure (env.history[n]?.getD 0)
  | .whileLoop base condition body, env => do
      let a ← denote base env
      PFun.fix (fun a => do
        let c ← denote condition {env with accumulator := a}
        if c = 0 then pure (Sum.inl a)
        else Sum.inr <$> denote body {env with accumulator := a}) a

/-- Execute an index-parameterized program on a new argument. The early
iterations retain the argument; only the last iteration evaluates the body. -/
def call (body argument : Expr) : Expr :=
  .recur (.succ argument) argument (.ifz (.monus .acc .idx) body .acc)

private theorem call_prefix (body : Expr) (env : Env) (value : Nat) :
    ∀ count, count ≤ value →
      Nat.rec (motive := fun _ => Part Nat) (pure value : Part Nat)
        (fun i previous => previous >>= fun v =>
          if v - i = 0 then denote body {env with accumulator := v, index := i} else pure v) count =
      pure value := by
  intro count
  induction count with
  | zero => intro _; rfl
  | succ count ih =>
    intro h
    have lt : count < value := by omega
    have nonzero : value - count ≠ 0 := Nat.ne_of_gt (Nat.sub_pos_of_lt lt)
    dsimp only
    rw [ih (by omega)]
    simp [nonzero]

/-- A call forces its argument before entering the body, including when the
body does not use that argument. -/
theorem denote_call (body argument : Expr) (env : Env) :
    denote (call body argument) env =
      denote argument env >>= fun value =>
        denote body {env with accumulator := value, index := value} := by
  apply Part.ext
  intro result
  simp only [call, denote, Part.bind_eq_bind, Part.map_eq_map,
    Part.mem_bind_iff, Part.mem_map_iff]
  constructor
  · rintro ⟨count, ⟨value, hv, rfl⟩, base, hb, hout⟩
    have eq : base = value := Part.mem_unique hb hv
    subst base
    simp only [Part.pure_eq_some, Part.bind_some] at hout
    change result ∈ ((Nat.rec (motive := fun _ => Part Nat) (pure value) (fun i previous => previous >>= fun v => if v - i = 0 then denote body {env with accumulator := v, index := i} else pure v) value) >>= fun v => if v - value = 0 then denote body {env with accumulator := v, index := value} else pure v) at hout
    rw [call_prefix body env value value (Nat.le_refl _)] at hout
    simpa [denote] using (show ∃ v ∈ denote argument env,
      result ∈ denote body {env with accumulator := v, index := v} from ⟨value, hv, by simpa [denote] using hout⟩)
  · rintro ⟨value, hv, hout⟩
    refine ⟨value + 1, ⟨value, hv, rfl⟩, value, hv, ?_⟩
    simp only [Part.pure_eq_some, Part.bind_some]
    change result ∈ ((Nat.rec (motive := fun _ => Part Nat) (pure value) (fun i previous => previous >>= fun v => if v - i = 0 then denote body {env with accumulator := v, index := i} else pure v) value) >>= fun v => if v - value = 0 then denote body {env with accumulator := v, index := value} else pure v)
    rw [call_prefix body env value value (Nat.le_refl _)]
    simpa [denote] using hout

/-- The pairing convention used by mathlib's partial-recursive codes. -/
def pairExpr (a b : Expr) : Expr :=
  .ifz (.monus (.succ a) b) (.add (.mul b b) a) (.add (.add (.mul a a) a) b)

theorem denote_pair (a b : Expr) (env : Env) :
    denote (pairExpr a b) env = (do return Nat.pair (← denote a env) (← denote b env)) := by
  classical
  simp only [pairExpr, denote]
  generalize denote a env = va
  generalize denote b env = vb
  induction va using Part.induction_on with
  | hnone => simp
  | hsome a =>
    induction vb using Part.induction_on with
    | hnone => simp
    | hsome b =>
      by_cases h : a < b
      · simp [Nat.pair, Nat.sub_eq_zero_of_le (show a + 1 ≤ b by omega), h]
      · have nz : a + 1 - b ≠ 0 := by omega
        simp [Nat.pair, nz, h]

/-- Integer square root by a terminating search, expressed in the DSL. -/
def sqrtExpr : Expr :=
  .whileLoop (.const 0)
    (.ifz (.monus (.mul (.succ .acc) (.succ .acc)) .idx) (.const 1) (.const 0))
    (.succ .acc)

private def sqrtStep (n a : Nat) : Part (Nat ⊕ Nat) :=
  pure (if (a + 1) * (a + 1) ≤ n then Sum.inr (a + 1) else Sum.inl a)

private theorem sqrt_search (n : Nat) : ∀ distance start, start + distance = Nat.sqrt n →
    Nat.sqrt n ∈ PFun.fix (sqrtStep n) start := by
  intro distance
  induction distance with
  | zero =>
    intro start h
    have eq : start = Nat.sqrt n := by omega
    subst start
    apply PFun.fix_stop
    have hlt : n < (Nat.sqrt n + 1) * (Nat.sqrt n + 1) := Nat.lt_succ_sqrt n
    simp [sqrtStep, Nat.not_le.mpr hlt]
  | succ distance ih =>
    intro start h
    apply PFun.mem_fix_iff.mpr
    right
    refine ⟨start + 1, ?_, ih (start + 1) (by omega)⟩
    have le : (start + 1) * (start + 1) ≤ n := Nat.le_sqrt.mp (by omega)
    simp [sqrtStep, le]

theorem denote_sqrt (env : Env) : denote sqrtExpr env = pure (Nat.sqrt env.index) := by
  have step_eq : (fun a => do
      let c ← denote (.ifz (.monus (.mul (.succ .acc) (.succ .acc)) .idx) (.const 1) (.const 0)) {env with accumulator := a}
      if c = 0 then pure (Sum.inl a) else Sum.inr <$> denote (.succ .acc) {env with accumulator := a}) = sqrtStep env.index := by
    funext a
    by_cases h : (a + 1) * (a + 1) ≤ env.index
    · simp [denote, sqrtStep, Nat.sub_eq_zero_of_le h, h]
    · have nz : (a + 1) * (a + 1) - env.index ≠ 0 := by omega
      simp [denote, sqrtStep, nz, h]
  change ((pure 0 : Part Nat) >>= fun a => PFun.fix _ a) = _
  rw [step_eq]
  simp only [pure_bind]
  exact Part.eq_some_iff.mpr (sqrt_search env.index (Nat.sqrt env.index) 0 (by omega))

def unpairExpr (right : Bool) : Expr :=
  let t := Expr.monus .idx (.mul .acc .acc)
  .iter (.const 1) sqrtExpr
    (.ifz (.monus (.succ t) .acc)
      (if right then .acc else t)
      (if right then .monus t .acc else .acc))

theorem denote_unpair (right : Bool) (env : Env) :
    denote (unpairExpr right) env = pure (if right then (Nat.unpair env.index).2 else (Nat.unpair env.index).1) := by
  have sqrt := denote_sqrt env
  cases right <;> simp only [unpairExpr, denote, sqrt, pure_bind]
  all_goals
    by_cases h : env.index - Nat.sqrt env.index * Nat.sqrt env.index < Nat.sqrt env.index
    · simp [denote, Nat.unpair, h, Nat.sub_eq_zero_of_le (show env.index - Nat.sqrt env.index * Nat.sqrt env.index + 1 ≤ Nat.sqrt env.index by omega)]
    · have nz : env.index - Nat.sqrt env.index * Nat.sqrt env.index + 1 - Nat.sqrt env.index ≠ 0 := by omega
      simp [denote, Nat.unpair, h, nz]

/-- Partial search stops at the first zero and blocks on undefined earlier tests. -/
noncomputable def seek (f : Nat → Part Nat) : Nat → Part Nat :=
  PFun.fix (fun n => f n >>= fun value => pure (if value = 0 then Sum.inl n else Sum.inr (n + 1)))

private theorem seek_stop (f : Nat → Part Nat) (n result : Nat) :
    Sum.inl result ∈ (f n >>= fun value => pure (if value = 0 then Sum.inl n else Sum.inr (n + 1))) ↔
      result = n ∧ 0 ∈ f n := by
  simp only [Part.bind_eq_bind, Part.mem_bind_iff, Part.pure_eq_some, Part.mem_some_iff]
  constructor
  · rintro ⟨v, hv, heq⟩
    by_cases h : v = 0
    · subst v
      have eq : result = n := by simpa using heq
      exact ⟨eq, hv⟩
    · simp [h] at heq
  · rintro ⟨rfl, h⟩; exact ⟨0, h, rfl⟩

private theorem seek_next (f : Nat → Part Nat) (n next : Nat) :
    Sum.inr next ∈ (f n >>= fun value => pure (if value = 0 then Sum.inl n else Sum.inr (n + 1))) ↔
      next = n + 1 ∧ ∃ v ∈ f n, v ≠ 0 := by
  simp only [Part.bind_eq_bind, Part.mem_bind_iff, Part.pure_eq_some, Part.mem_some_iff]
  constructor
  · rintro ⟨v, hv, heq⟩
    by_cases h : v = 0
    · simp [h] at heq
    · have eq : next = n + 1 := by simpa [h] using heq
      exact ⟨eq, v, hv, h⟩
  · rintro ⟨rfl, v, hv, hn⟩; exact ⟨v, hv, by simp [hn]⟩

theorem mem_seek (f : Nat → Part Nat) (start result : Nat) :
    result ∈ seek f start ↔ start ≤ result ∧ 0 ∈ f result ∧
      ∀ n, start ≤ n → n < result → ∃ v ∈ f n, v ≠ 0 := by
  constructor
  · intro h
    refine PFun.fixInduction' (C := fun start => start ≤ result ∧ 0 ∈ f result ∧ ∀ n, start ≤ n → n < result → ∃ v ∈ f n, v ≠ 0) h ?_ ?_
    · intro final h
      obtain ⟨rfl, hf⟩ := (seek_stop f final result).mp h
      exact ⟨Nat.le_refl _, hf, by omega⟩
    · intro n next _ step ih
      obtain ⟨rfl, hn⟩ := (seek_next f n next).mp step
      refine ⟨by omega, ih.2.1, ?_⟩
      intro k hk hk'
      by_cases eq : k = n
      · simpa [eq] using hn
      · exact ih.2.2 k (by omega) hk'
  · rintro ⟨le, hz, earlier⟩
    obtain ⟨distance, rfl⟩ := Nat.exists_eq_add_of_le le
    induction distance generalizing start with
    | zero =>
      apply PFun.fix_stop
      exact (seek_stop f start start).mpr ⟨rfl, by simpa using hz⟩
    | succ distance ih =>
      apply PFun.mem_fix_iff.mpr
      right
      refine ⟨start + 1, (seek_next f start (start + 1)).mpr ⟨rfl, earlier start (by omega) (by omega)⟩, ?_⟩
      have hrec := ih (start + 1) (by omega) (by simpa [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using hz)
        (by intro n hn hn'; exact earlier n (by omega) (by omega))
      simpa [seek, Part.bind_eq_bind, Part.pure_eq_some, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using hrec

theorem seek_eq_rfind (f : Nat → Part Nat) (start : Nat) :
    seek f start = (Nat.rfind fun n => (fun v => v = 0) <$> f (n + start)).map (· + start) := by
  classical
  apply Part.ext
  intro result
  rw [mem_seek, Part.mem_map_iff]
  simp_rw [Nat.mem_rfind]
  constructor
  · rintro ⟨le, hz, earlier⟩
    refine ⟨result - start, ⟨?_, ?_⟩, by omega⟩
    · exact (Part.mem_map_iff _).mpr ⟨0, by simpa [Nat.sub_add_cancel le] using hz, by simp⟩
    · intro k hk
      obtain ⟨v, hv, nz⟩ := earlier (k + start) (by omega) (by omega)
      exact (Part.mem_map_iff _).mpr ⟨v, hv, by simp [nz]⟩
  · rintro ⟨n, ⟨hz, earlier⟩, rfl⟩
    obtain ⟨v, hv, eq⟩ := (Part.mem_map_iff _).mp hz
    have zero : v = 0 := by simpa using eq
    subst v
    refine ⟨by omega, hv, ?_⟩
    intro k hk hk'
    obtain ⟨v, hv, nz⟩ := (Part.mem_map_iff _).mp (earlier (m := k - start) (by omega))
    refine ⟨v, by simpa [Nat.sub_add_cancel hk] using hv, ?_⟩
    simpa using nz

def precStep (body : Expr) : Expr :=
  let index := call (unpairExpr false) .acc
  let value := call (unpairExpr true) .acc
  let parameter := call (unpairExpr false) .idx
  pairExpr (.succ index) (call body (pairExpr parameter (pairExpr index value)))

def precExpr (base body : Expr) : Expr :=
  call (unpairExpr true)
    (.iter (call (unpairExpr true) .idx)
      (pairExpr (.const 0) (call base (call (unpairExpr false) .idx)))
      (precStep body))

def searchExpr (body : Expr) : Expr :=
  .whileLoop (call (unpairExpr true) .idx)
    (call body (pairExpr (call (unpairExpr false) .idx) .acc)) (.succ .acc)

/-- Structural translation of the complete mathlib code language. -/
def compileCode : Nat.Partrec.Code → Expr
  | .zero => .const 0
  | .succ => .succ .idx
  | .left => unpairExpr false
  | .right => unpairExpr true
  | .pair f g => pairExpr (compileCode f) (compileCode g)
  | .comp f g => call (compileCode f) (compileCode g)
  | .prec f g => precExpr (compileCode f) (compileCode g)
  | .rfind' f => searchExpr (compileCode f)

private theorem denote_precStep (body : Expr) (f : Nat →. Nat)
    (correct : ∀ env, denote body env = f env.index) (env : Env) :
    denote (precStep body) env =
      (Nat.pair ((Nat.unpair env.accumulator).1 + 1)) <$>
        f (Nat.pair (Nat.unpair env.index).1 (Nat.pair (Nat.unpair env.accumulator).1 (Nat.unpair env.accumulator).2)) := by
  simp [precStep, denote_pair, denote_call, denote_unpair, denote, correct, Part.bind_some_eq_map]

private theorem rec_bind (base : Part Nat) (step : Nat → Nat → Part Nat) (n : Nat) :
    (base >>= fun a => Nat.rec (motive := fun _ => Part Nat) (pure a) (fun i v => v >>= step i) n) =
      Nat.rec (motive := fun _ => Part Nat) base (fun i v => v >>= step i) n := by
  induction n with
  | zero => simp
  | succ n ih =>
    dsimp only
    simp only [Part.bind_eq_bind] at *
    rw [← Part.bind_assoc, ih]

private theorem prec_iterations (body : Expr) (f g : Nat →. Nat)
    (correctBody : ∀ env, denote body env = g env.index) (env : Env) (n : Nat) :
    Nat.rec (motive := fun _ => Part Nat)
      (Nat.pair 0 <$> f (Nat.unpair env.index).1)
      (fun _ previous => previous >>= fun v => denote (precStep body) {env with accumulator := v}) n =
    Nat.pair n <$> Nat.rec (motive := fun _ => Part Nat)
      (f (Nat.unpair env.index).1)
      (fun i previous => previous >>= fun v => g (Nat.pair (Nat.unpair env.index).1 (Nat.pair i v))) n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    dsimp only
    rw [ih]
    simp [denote_precStep body g correctBody, Part.map_bind, Part.bind_map]

theorem denote_prec (base body : Expr) (f g : Nat →. Nat)
    (correctBase : ∀ env, denote base env = f env.index)
    (correctBody : ∀ env, denote body env = g env.index) (env : Env) :
    denote (precExpr base body) env =
      Nat.rec (motive := fun _ => Part Nat) (f (Nat.unpair env.index).1)
        (fun i previous => previous >>= fun v => g (Nat.pair (Nat.unpair env.index).1 (Nat.pair i v))) (Nat.unpair env.index).2 := by
  have hb := rec_bind (Nat.pair 0 <$> f (Nat.unpair env.index).1)
    (fun _ v => denote (precStep body) {env with accumulator := v}) (Nat.unpair env.index).2
  have hi := prec_iterations body f g correctBody env (Nat.unpair env.index).2
  simp only [Part.bind_eq_bind, Part.pure_eq_some, Part.map_eq_map] at hb hi
  simp [precExpr, denote_call, denote_unpair, denote_pair, denote, correctBase, Part.bind_some_eq_map]
  have mapped := congrArg (Part.map (fun y => (Nat.unpair y).2)) (hb.trans hi)
  simpa [Part.map_bind, Part.bind_map, Part.map_map, Function.comp_def, Part.map_id'] using mapped

theorem denote_search (body : Expr) (f : Nat →. Nat)
    (correct : ∀ env, denote body env = f env.index) (env : Env) :
    denote (searchExpr body) env = seek (fun n => f (Nat.pair (Nat.unpair env.index).1 n)) (Nat.unpair env.index).2 := by
  simp [searchExpr, denote, denote_call, denote_pair, denote_unpair, correct, seek]
  congr 1
  funext n
  congr 1
  funext v
  split <;> rfl

/-- Compiler simulation, including undefined computations, for every code. -/
theorem compile_correct (code : Nat.Partrec.Code) (env : Env) :
    denote (compileCode code) env = code.eval env.index := by
  induction code generalizing env with
  | zero => rfl
  | succ => simp [compileCode, denote, Nat.Partrec.Code.eval]
  | left => exact denote_unpair false env
  | right => exact denote_unpair true env
  | pair f g ihf ihg =>
    simp [compileCode, denote_pair, ihf, ihg, Nat.Partrec.Code.eval, Part.bind_some_eq_map, seq_eq_bind_map]
  | comp f g ihf ihg =>
    simp [compileCode, denote_call, ihf, ihg, Nat.Partrec.Code.eval]
  | prec f g ihf ihg =>
    exact denote_prec (compileCode f) (compileCode g) f.eval g.eval ihf ihg env
  | rfind' f ih =>
    rw [compileCode, denote_search (compileCode f) f.eval ih, seek_eq_rfind]
    rfl

/-- Close the index-parameterized program over the ordinary input variable. -/
def translate (code : Nat.Partrec.Code) : Expr := call (compileCode code) .var

theorem translate_correct (code : Nat.Partrec.Code) (env : Env) :
    denote (translate code) env = code.eval env.input := by
  simp [translate, denote_call, denote, compile_correct]

/-- Lexical scope: the three flags say which local bindings are available. -/
def Scoped (accumulator index history : Bool) : Expr → Prop
  | .var | .const _ => True
  | .acc => accumulator = true
  | .idx => index = true
  | .succ e | .pred e | .half e => Scoped accumulator index history e
  | .add a b | .mul a b | .monus a b | .rem a b =>
      Scoped accumulator index history a ∧ Scoped accumulator index history b
  | .ifz c z p => Scoped accumulator index history c ∧ Scoped accumulator index history z ∧ Scoped accumulator index history p
  | .iter n a b => Scoped accumulator index history n ∧ Scoped accumulator index history a ∧ Scoped true index history b
  | .recur n a b => Scoped accumulator index history n ∧ Scoped accumulator index history a ∧ Scoped true true history b
  | .corec n b => Scoped accumulator index history n ∧ Scoped accumulator true true b
  | .cget n => history = true ∧ Scoped accumulator index history n
  | .whileLoop a c b => Scoped accumulator index history a ∧ Scoped true index history c ∧ Scoped true index history b

theorem compile_scoped (code : Nat.Partrec.Code) (accumulator history : Bool) :
    Scoped accumulator true history (compileCode code) := by
  induction code generalizing accumulator history <;> cases accumulator <;> cases history <;>
    simp_all [compileCode, precExpr, precStep, searchExpr, pairExpr, call, unpairExpr, sqrtExpr, Scoped]

theorem translate_scoped (code : Nat.Partrec.Code) :
    Scoped false false false (translate code) := by
  simp [translate, call, Scoped, compile_scoped]

/-- Every partial recursive unary natural-number function has a Recursor program. -/
theorem universal {f : Nat →. Nat} (computable : Nat.Partrec f) :
    ∃ program : Expr, Scoped false false false program ∧ ∀ n, denote program {input := n} = f n := by
  obtain ⟨code, hcode⟩ := Nat.Partrec.Code.exists_code.mp computable
  exact ⟨translate code, translate_scoped code, fun n => by rw [translate_correct, hcode]⟩

#print axioms compile_correct
#print axioms translate_correct
#print axioms translate_scoped
#print axioms universal

end RecursorProofs
