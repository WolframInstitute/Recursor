---
Template: TechNote
Name: UniversalComputation
Title: Universal Computation with Recursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/UniversalComputation
RelatedGuides: [Recursor, Compilation]
RelatedTutorials: [FormalVerification, LanguageSemantics]
---

## Bounded and unbounded computation

The bounded fragment contains iteration, primitive recursion and
course-of-values recursion. Structural induction shows that every closed
program in that fragment terminates: each recursion computes a finite count and
then invokes terminating subexpressions. Compiling this fragment into
untyped lambda calculus does not itself make the source language universal.

WhileLoop adds unbounded state transitions. Natural-number state encoding
lets these transitions simulate counter machines.

## A concrete translation

Counter instruction {r,0,{next}} increments register r and jumps to next.
Instruction {r,1,{positive},{zero}} decrements a positive register and jumps
to positive, or jumps to zero if that register is already zero. A machine
with m instructions halts at address m+1. This is the deterministic format
used by Ruliology's register-machine tools.

Translate and run a one-instruction increment machine:

```wl
With[{program = ToRecursor[{{1, 0, {2}}}]}, {RecursorProgramQ[program], Table[EvaluateRecursor[program, n], {n, 0, 3}]} ]
```

This program increments its input and halts. The translation contains only
public Recursor syntax: there is no hidden counter-machine evaluator.

## State encoding and proof

Let B=m+2. Encode the state as s=B P+pc, with
P equal to the product of Prime[r]^register[r] over the finitely many
registers used. Then pc is s mod B and P is Floor[s/B]. Initially pc=1,
register 1 holds input n, all other registers hold zero, and P=2^n.

For positive constant d, bounded recursion expresses Floor[x/d] by counting
multiples of d from 1 through x:

Compute eleven divided by three with bounded recursion:

```wl
EvaluateRecursor[Rec[Var, Const[0], Ifz[Rem[Succ[Idx], Const[3]], Succ[Acc], Acc] ], 11]
```

One simulated transition is built from terminating bounded expressions:

1. Increment register r by multiplying P by Prime[r].
2. Test positivity by divisibility of P by Prime[r]. On the positive branch,
   divide P by that prime; on the zero branch leave P unchanged.
3. Select the instruction with a finite nest of Ifz tests on pc.
4. Reconstruct B P+next as the next accumulator.
5. Repeat while Monus[Const[m+1],Rem[Acc,Const[B]]] is nonzero. Valid control
   flow keeps pc in 1 through m+1, so zero occurs exactly at the halt address.

Induction on machine steps shows that every completed WhileLoop iteration
represents exactly one counter-machine transition. Each individual transition
terminates. The loop terminates exactly when the machine does. The final
output is the exponent of 2 in P, obtained by finite divisibility tests. The
translator stores P in course-of-values history so decoding does not rerun
the machine or accidentally capture an accumulator binding.

Increment and conditional-decrement counter machines are universal; even two
registers suffice with encodings. See the constructions for
[universal register machines](https://www.wolframscience.com/nks/notes-11-12--universal-register-machines/)
and [encoding many registers in two](https://wolframscience.com/nks/notes-11-6--register-machines-with-many-registers-from-2-registers/)
in Stephen Wolfram's A New Kind of Science. The translation therefore gives
Turing completeness for Recursor's unbounded semantics. Conversely, its finite
syntax and effective operational rules are interpretable by a Turing machine.

This counter-machine construction is a mathematical argument backed by
regression tests. Its complete simulation proof is not formalized. Recursor's
machine-checked universality theorem uses the separate partial-recursive
translation below.

## A machine-checked universal model

Mathlib's Nat.Partrec.Code presents every partial recursive function from
natural numbers to natural numbers. Its eight constructors cover zero,
successor, pair projections, pairing, composition, primitive recursion and
unbounded search. The Lean theorem compile_correct proves that translating
any code preserves its partial denotation. Equality of partial values includes
both terminating results and undefined computations.

Translate two successive increments:

```wl
successorTwice = ToRecursor[{"Compose", "Successor", "Successor"}, "PartialRecursive"]
```

Compare the translated function with its expected values:

```wl
ListLinePlot[Table[EvaluateRecursor[successorTwice, n], {n, 0, 8}], DataRange -> {0, 8}, AxesLabel -> {"Input", "Output"}]
```

Primitive recursion uses input pair(a,n). The base receives a; each step
receives pair(a,pair(index,previous)). Define addition in this representation:

```wl
additionCode = {"Recurse", {"Pair", "Left", "Right"}, {"Compose", "Successor", {"Compose", "Right", "Right"}}}
```

Compute on the first nine paired inputs:

```wl
Table[EvaluateRecursor[ToRecursor[additionCode, "PartialRecursive"], n], {n, 0, 8}]
```

The Lean theorem translate_scoped proves that each translated program has no
free accumulator, index or history binding. The final theorem universal
combines these results with mathlib's exists_code: every partial recursive
unary natural-number function has a closed Recursor expression with the same
denotation. All eight constructors are covered by the proof.

This theorem concerns the formal DSL semantics in Universality.lean. It does
not certify the Wolfram implementation or its lambda backend. The separate
operational model in Recursor.lean has checked determinism and finite-run
soundness/completeness, but its equivalence to the denotational model is not
proved here. See [Formal Verification](paclet:WolframInstitute/Recursor/tutorial/FormalVerification)
for reproducible checks and the remaining implementation proof obligations.

The formal construction follows the pinned
[mathlib code model](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Computability/PartrecCode.lean).
Its computability developments connect partial recursive functions with
machine models; the live [API documentation](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Computability/PartrecCode.html)
may describe a newer release.

## Nontermination and resources

A one-instruction machine can increment forever:

Run an incrementing loop under a finite step budget:

```wl
EvaluateRecursor[ToRecursor[{{1, 0, {1}}}], 0, "MaxSteps" -> 500]["Tag"]
```

The finite run reports StepLimit. A fixed budget is a research tool, not part
of the language's unbounded definition. Prime-power encoding and bounded
integer division can be expensive. This translator supplies a construction,
not a fast machine emulator.

## Lambda compilation

WhileLoop compiles with a fixed-point combinator. The compiler first builds
named intermediate terms, then lowers them to one-based de Bruijn indices
under the formal lambda symbol. There is no external Lambda dependency.

Evaluate countdown through the lambda backend:

```wl
Table[EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], n, Method -> "Lambda"], {n, 0, 4}]
```

Normal-order reduction must not erase a diverging strict operand. The compiler
sequences natural-number term n before a continuation using n I I, with I the
identity combinator. A fully evaluated Church numeral yields I; a partial
numeral stays partial. Branch bodies remain lazy. Differential tests check
both methods on terminating programs and strict operands that diverge.
