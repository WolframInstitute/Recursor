---
Template: TechNote
Name: FormalVerification
Title: Checking Recursor with Lean
Description: Inspect operational proofs, finite certificates and the mathlib universality statement
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/FormalVerification
Keywords: [formal verification, Lean, computability, mathlib]
RelatedGuides: [Recursor, Compilation, Evaluation]
RelatedTutorials: [UniversalComputation, HaltingAndBudgets, ProgramsForAI]
---

## A theorem has a specified model

The paclet includes Lean source for Recursor's syntax, an explicit transition
machine and partial-function semantics. A theorem about those definitions is
more precise than agreement on selected test inputs. It is also narrower than
a claim about every layer of the software: the Wolfram interpreter, the
lambda backend and the formal definitions have separate proof obligations.

The core file uses Lean without mathlib. Load its proof environment through
[LeanLink](https://github.com/WolframInstitute/LeanLink):

```wl
Needs["Wolfram`LeanLink`"]
```

Locate the packaged source:

```wl
coreSource = FileNameJoin[{PacletObject["WolframInstitute/Recursor"]["AssetLocation", "Lean"], "Recursor.lean"}]
```

Compile and load it:

```wl
coreProofs = LeanImport[coreSource]
```

Inspect the theorem that countdown returns zero for every natural input:

```wl
coreProofs["RecursorProofs.countdown_correct"]["TypeForm"]
```

Ask Lean's kernel to replay its declaring module:

```wl
coreProofs["RecursorProofs.countdown_correct"]["KernelCheck"]
```

This checks the proof term. It is not a loop over a finite set of inputs.

## Finite observations and unbounded execution

The operational model makes each machine transition explicit. The function
run returns an optional result under a transition budget. The relation
Computes describes a finite execution ending in a result without fixing that
budget. The theorem computes_iff_observed connects the two:

```wl
coreProofs["RecursorProofs.computes_iff_observed"]["TypeForm"]
```

Other core results establish soundness of completed observations, stability
under larger budgets, determinism, and the address/payload laws for packed
natural-number machine states. Inspect their axiom dependencies:

```wl
Grid[Prepend[Table[{name, coreProofs["RecursorProofs." <> name]["Axioms"]}, {name, {"run_sound", "run_stable", "computes_deterministic", "countdown_correct", "pack_address", "pack_payload"}}], {"Theorem", "Axioms"}]]
```

The allowed dependencies are Lean's standard propext, Classical.choice and
Quot.sound. An admitted proof such as sorryAx is not accepted by the project's
proof audit. The audit also replays modules with KernelCheck, rather than
relying on axiom names alone.

Compute which countdown runs finish for inputs zero through twelve, with
budgets zero through seventy-two in steps of six:

```wl
Dimensions[completion = LeanEvaluate["(List.range 13).map fun n => (List.range 13).map fun k => (RecursorProofs.run (6 * k) (RecursorProofs.initial RecursorProofs.countdown n)).isSome", "Source" -> Import[coreSource, "Text"]]]
```

Show completed observations as 1 and unfinished observations as 0:

```wl
MatrixPlot[Map[Boole, completion, {2}], FrameLabel -> {"Input", "Transition budget"}, FrameTicks -> {{{1, 0}, {7, 6}, {13, 12}}, {{1, 0}, {7, 36}, {13, 72}}}, PlotLegends -> Automatic]
```

LeanEvaluate computes these observations. The preceding theorem establishes
why a completed run witnesses an unbounded execution. An unfinished run says
only that its budget was insufficient. The formal machine counts transitions;
EvaluateRecursor counts syntax visits, so their budget numbers differ.

## A finite certificate

A closed calculation can also be checked as a theorem. Here Lean's decide
tactic constructs a proof of the finite result, which its kernel checks:

```wl
certificate = LeanImportString[{Import[coreSource, "Text"], "theorem countdown_twelve : RecursorProofs.run 100 (RecursorProofs.initial RecursorProofs.countdown 12) = some 0 := by decide"}]
```

Check that certificate:

```wl
certificate["countdown_twelve"]["KernelCheck"]
```

For independent checking, LeanLink can translate selected declarations into
[TypeTheory](https://github.com/WolframInstitute/TypeTheory). That is a separate
implementation of the proof rules. It is useful additional evidence; checking
one imported theorem is not a claim that all of mathlib has been checked by
that implementation.

## The universality statement

The mathlib development uses
[Nat.Partrec.Code](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Computability/PartrecCode.html),
whose constructors represent the partial recursive functions on natural
numbers. Its exists_code theorem supplies a code for every such function.
Recursor's structural translator covers every constructor, including
unbounded minimization. The compiler-simulation statement equates partial
results, so undefined computations are part of the statement too.

The packaged Universality.lean defines the translation and its proofs.
The universal theorem states that each partial recursive function has a
closed Recursor expression with the same denotation on every natural input.
The formal target is the denotational language in that file. This statement
does not by itself verify the Wolfram interpreter or the lambda compiler.
The equivalence between this denotational semantics and the separate
operational transition model has not yet been proved in Lean.
The counter-machine translator has its separate mathematical argument and
regression tests in Universal Computation.

Install the proof libraries explicitly when needed:

```wl
#| eval: false
InstallRecursorLibraries[{"LeanLink", "MathlibLink"}]
```

Run the complete packaged proof audit:

```wl
#| eval: false
CheckRecursorProofs[]
```

The equivalent terminal command is `make check-proofs`. This uses the pinned Lean 4.35.0
and mathlib v4.35.0 sources, builds the proof modules, checks their axiom
closure, and asks the kernel to replay them. The proof workspace shares the
mathlib installation managed by MathlibLink. Online mathlib documentation may
show a newer version; the project pins the exact source revision.
