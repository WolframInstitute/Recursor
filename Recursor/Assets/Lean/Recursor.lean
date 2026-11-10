module

@[expose] public section

/-!
Recursor operational semantics. No mathlib, admitted proofs, or native_decide.
The machine's transition budget differs from the Wolfram interpreter's node budget.
-/
set_option autoImplicit false

namespace RecursorProofs

inductive Expr where
  | var | acc | idx
  | const (n : Nat)
  | succ (e : Expr) | pred (e : Expr) | half (e : Expr)
  | add (a b : Expr) | mul (a b : Expr) | monus (a b : Expr) | rem (a b : Expr) | quot (a b : Expr)
  | ifz (condition zero positive : Expr)
  | iter (count base step : Expr) | recur (count base step : Expr)
  | corec (count step : Expr) | cget (index : Expr)
  | whileLoop (base condition step : Expr)
  | letE (value body : Expr)
  deriving DecidableEq, Repr

structure Env where
  input : Nat
  accumulator : Nat := 0
  index : Nat := 0
  history : List Nat := []
  deriving DecidableEq, Repr

inductive Unary where
  | succ | pred | half
  deriving DecidableEq, Repr

inductive Binary where
  | add | mul | monus | rem | quot
  deriving DecidableEq, Repr

def Unary.apply : Unary → Nat → Nat
  | .succ, n => n + 1
  | .pred, n => n.pred
  | .half, n => n / 2

def Binary.apply : Binary → Nat → Nat → Nat
  | .add, a, b => a + b
  | .mul, a, b => a * b
  | .monus, a, b => a - b
  | .rem, a, b => a % b
  | .quot, a, b => a / b

inductive Frame where
  | unary (op : Unary)
  | binaryLeft (op : Binary) (right : Expr) (env : Env)
  | binaryRight (op : Binary) (left : Nat)
  | branch (zero positive : Expr) (env : Env)
  | iterCount (base step : Expr) (env : Env)
  | iterBase (count : Nat) (step : Expr) (env : Env)
  | iterNext (remaining : Nat) (step : Expr) (env : Env)
  | recCount (base step : Expr) (env : Env)
  | recBase (count : Nat) (step : Expr) (env : Env)
  | recNext (remaining index : Nat) (step : Expr) (env : Env)
  | corecCount (step : Expr) (env : Env)
  | corecNext (remaining : Nat) (step : Expr) (env : Env) (history : List Nat)
  | historyRead (history : List Nat)
  | whileBase (condition step : Expr) (env : Env)
  | whileCondition (value : Nat) (condition step : Expr) (env : Env)
  | whileNext (condition step : Expr) (env : Env)
  | letBody (body : Expr) (env : Env)
  deriving DecidableEq, Repr

inductive State where
  | evaluate (expression : Expr) (env : Env) (stack : List Frame)
  | returning (value : Nat) (stack : List Frame)
  | halt (value : Nat)
  deriving DecidableEq, Repr

/-- A deterministic transition, including strict arithmetic and lazy branches. -/
def step : State → State
  | .halt v => .halt v
  | .evaluate e env stack => match e with
    | .var => .returning env.input stack
    | .acc => .returning env.accumulator stack
    | .idx => .returning env.index stack
    | .const n => .returning n stack
    | .succ a => .evaluate a env (.unary .succ :: stack)
    | .pred a => .evaluate a env (.unary .pred :: stack)
    | .half a => .evaluate a env (.unary .half :: stack)
    | .add a b => .evaluate a env (.binaryLeft .add b env :: stack)
    | .mul a b => .evaluate a env (.binaryLeft .mul b env :: stack)
    | .monus a b => .evaluate a env (.binaryLeft .monus b env :: stack)
    | .rem a b => .evaluate a env (.binaryLeft .rem b env :: stack)
    | .quot a b => .evaluate a env (.binaryLeft .quot b env :: stack)
    | .ifz c z p => .evaluate c env (.branch z p env :: stack)
    | .iter c b s => .evaluate c env (.iterCount b s env :: stack)
    | .recur c b s => .evaluate c env (.recCount b s env :: stack)
    | .corec c s => .evaluate c env (.corecCount s env :: stack)
    | .cget i => .evaluate i env (.historyRead env.history :: stack)
    | .whileLoop b c s => .evaluate b env (.whileBase c s env :: stack)
    | .letE v b => .evaluate v env (.letBody b env :: stack)
  | .returning v [] => .halt v
  | .returning v (frame :: stack) => match frame with
    | .unary op => .returning (op.apply v) stack
    | .binaryLeft op right env => .evaluate right env (.binaryRight op v :: stack)
    | .binaryRight op left => .returning (op.apply left v) stack
    | .branch z p env => .evaluate (if v = 0 then z else p) env stack
    | .iterCount b s env => .evaluate b env (.iterBase v s env :: stack)
    | .iterBase 0 _ _ | .iterNext 0 _ _ => .returning v stack
    | .iterBase (n + 1) s env | .iterNext (n + 1) s env =>
      .evaluate s {env with accumulator := v} (.iterNext n s env :: stack)
    | .recCount b s env => .evaluate b env (.recBase v s env :: stack)
    | .recBase 0 _ _ | .recNext 0 _ _ _ => .returning v stack
    | .recBase (n + 1) s env =>
      .evaluate s {env with accumulator := v, index := 0} (.recNext n 1 s env :: stack)
    | .recNext (n + 1) i s env =>
      .evaluate s {env with accumulator := v, index := i} (.recNext n (i + 1) s env :: stack)
    | .corecCount s env =>
      .evaluate s {env with index := 0, history := []} (.corecNext v s env [] :: stack)
    | .corecNext 0 _ _ _ => .returning v stack
    | .corecNext (n + 1) s env history =>
      .evaluate s {env with index := history.length + 1, history := history ++ [v]}
        (.corecNext n s env (history ++ [v]) :: stack)
    | .historyRead history => .returning (history[v]?.getD 0) stack
    | .whileBase c s env | .whileNext c s env =>
      .evaluate c {env with accumulator := v} (.whileCondition v c s env :: stack)
    | .whileCondition a c s env =>
      if v = 0 then .returning a stack
      else .evaluate s {env with accumulator := a} (.whileNext c s env :: stack)
    | .letBody b env => .evaluate b {env with input := v} stack

/-- A bounded observer; `none` says only that this observation did not finish. -/
def run : Nat → State → Option Nat
  | _, .halt v => some v
  | 0, _ => none
  | fuel + 1, state => run fuel (step state)

theorem run_halt (fuel value : Nat) : run fuel (.halt value) = some value := by
  cases fuel <;> rfl

/-- Finite reachability is unbounded: no particular fuel is fixed. -/
inductive Reaches : State → State → Prop where
  | refl (state : State) : Reaches state state
  | next {state target : State} : Reaches (step state) target → Reaches state target

def initial (program : Expr) (input : Nat) : State :=
  .evaluate program {input := input} []

def Computes (program : Expr) (input output : Nat) : Prop :=
  Reaches (initial program input) (.halt output)

/-- Every successful finite observation has an unbounded execution derivation. -/
theorem run_sound {fuel : Nat} {state : State} {value : Nat}
    (h : run fuel state = some value) : Reaches state (.halt value) := by
  induction fuel generalizing state with
  | zero =>
    cases state <;> simp [run] at h
    subst value
    exact .refl _
  | succ fuel ih =>
    cases state with
    | evaluate e env stack => exact .next (ih h)
    | returning v stack => exact .next (ih h)
    | halt v =>
      simp [run] at h
      subst value
      exact .refl _

/-- Each finite execution can be observed with a sufficiently large budget. -/
theorem reaches_complete {state target : State} (h : Reaches state target) :
    ∀ value, target = .halt value → ∃ fuel, run fuel state = some value := by
  induction h with
  | refl state =>
    intro value h
    subst state
    exact ⟨0, rfl⟩
  | @next state target h ih =>
    intro value ht
    obtain ⟨fuel, hf⟩ := ih value ht
    cases state with
    | evaluate e env stack => exact ⟨fuel + 1, hf⟩
    | returning v stack => exact ⟨fuel + 1, hf⟩
    | halt v => exact ⟨fuel, hf⟩

theorem computes_iff_observed (program : Expr) (input output : Nat) :
    Computes program input output ↔ ∃ fuel, run fuel (initial program input) = some output :=
  ⟨fun h => reaches_complete h output rfl, fun ⟨_, h⟩ => run_sound h⟩

/-- Increasing the observation budget preserves every completed result. -/
theorem run_stable {fuel : Nat} {state : State} {value : Nat}
    (h : run fuel state = some value) (extra : Nat) :
    run (fuel + extra) state = some value := by
  induction fuel generalizing state with
  | zero =>
    cases state <;> simp [run] at h
    subst value
    exact run_halt _ _
  | succ fuel ih =>
    cases state with
    | evaluate e env stack =>
      simpa [Nat.succ_add, run] using ih h
    | returning v stack =>
      simpa [Nat.succ_add, run] using ih h
    | halt v => simpa only [run_halt] using h

/-- One program/input cannot compute two different natural-number outputs. -/
theorem computes_deterministic {program : Expr} {input a b : Nat}
    (ha : Computes program input a) (hb : Computes program input b) : a = b := by
  obtain ⟨fa, ha⟩ := (computes_iff_observed program input a).mp ha
  obtain ⟨fb, hb⟩ := (computes_iff_observed program input b).mp hb
  have h₁ := run_stable ha fb
  have h₂ := run_stable hb fa
  rw [Nat.add_comm fb fa] at h₂
  exact Option.some.inj (h₁.symm.trans h₂)

def countdown : Expr := .whileLoop .var .acc (.pred .acc)

def countdownState (input value : Nat) : State :=
  .evaluate .acc {input := input, accumulator := value}
    [.whileCondition value .acc (.pred .acc) {input := input}]

/-- A proof for every input, not a finite collection of executions. -/
theorem countdown_loop (input value : Nat) : Reaches (countdownState input value) (.halt 0) := by
  induction value with
  | zero => exact .next (.next (.next (.refl _)))
  | succ value ih => exact .next (.next (.next (.next (.next (.next ih)))))

theorem countdown_correct (input : Nat) : Computes countdown input 0 :=
  .next (.next (.next (countdown_loop input input)))

/-- Encoding the control location and register payload in one natural number. -/
def pack (radix payload address : Nat) : Nat := radix * payload + address

theorem pack_address (radix payload address : Nat) (h : address < radix) :
    pack radix payload address % radix = address := by
  simp [pack, Nat.add_mod, Nat.mod_eq_of_lt h]

theorem pack_payload (radix payload address : Nat) (h : address < radix) :
    pack radix payload address / radix = payload := by
  have positive : 0 < radix := Nat.lt_of_le_of_lt (Nat.zero_le address) h
  simp [pack, Nat.add_div, positive, Nat.div_eq_of_lt h, Nat.mod_eq_of_lt h, h]

#print axioms run_sound
#print axioms reaches_complete
#print axioms computes_iff_observed
#print axioms run_stable
#print axioms computes_deterministic
#print axioms countdown_correct
#print axioms pack_address
#print axioms pack_payload

end RecursorProofs
