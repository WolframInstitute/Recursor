---
Template: Symbol
Name: ToRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/ToRecursor
RelatedGuides: [Compilation, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns, UniversalComputation, FormalVerification]
---

## Usage

<code>[ToRecursor]()[*instructions*]</code> translates a counter machine.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

<code>[ToRecursor]()[*code*, "PartialRecursive"]</code> translates a mathlib-style partial-recursive code.

## Details & Options

- Instruction {r, 0, {next}} increments register r and jumps to next.
- Instruction {r, 1, {positive}, {zero}} decrements a positive register and goes to positive; when it is zero, it goes to zero.
- Registers are positive integer indices. Targets are 1 through m+1, where m is the instruction count. Address m+1 halts. An empty instruction list is valid.
- The input initializes register 1; all other registers start at zero. The result is the final value of register 1.
- The output uses only the documented Recursor grammar, including WhileLoop. It has no hidden counter-machine evaluator. Prime-power state encoding favors a simple universality argument over performance.
- The "PartialRecursive" form follows mathlib's Nat.Partrec.Code. Its atomic codes are "Zero", "Successor", "Left" and "Right"; composite codes are {"Pair", f, g}, {"Compose", f, g}, {"Recurse", f, g} and {"Search", f}.
- Pairing uses pair(a,b) = b²+a when a<b and a²+a+b otherwise. Left and Right recover the coordinates. Compose[f,g] evaluates g before f.
- Recurse[f,g] reads input pair(a,n), starts with f(a) and applies g(pair(a,pair(i,value))) for i from 0 through n−1. Search[f] reads pair(a,m) and tests f(pair(a,k)) for successive k≥m until the first zero. An undefined earlier test blocks the search.
- Partial-recursive translation expands into ordinary Recursor syntax. The Lean compiler simulation proves equality of partial denotations for every code, including divergence, and proves that translated programs are closed. The Wolfram implementation follows this construction and has regression tests; it is not itself a kernel-checked program.
- See UniversalComputation for the counter-machine construction and FormalVerification for the machine-checked partial-recursive route.

## Basic Examples

Evaluate a small example:

```wl
With[{program = ToRecursor[{{1, 0, {2}}}]}, Table[EvaluateRecursor[program, n], {n, 0, 3}] ]
```

## Scope

Translate a machine that clears its first register:

```wl
Table[EvaluateRecursor[ToRecursor[{{1, 1, {1}, {2}}}], n], {n, 0, 4}]
```

Translate a composition:

```wl
Table[EvaluateRecursor[ToRecursor[{"Compose", "Successor", "Successor"}, "PartialRecursive"], n], {n, 0, 4}]
```

## Applications

Compare translated increment and decrement machines:

```wl
ListLinePlot[Table[EvaluateRecursor[ToRecursor[machine],n], {machine,{{{1,0,{2}}},{{1,1,{2},{2}}}}},{n,0,4}], DataRange->{0,4}, PlotLegends->{"Increment","Decrement"}, Frame->True, FrameLabel->{"Input","Register 1"} ]
```

---

Measure expansion as the instruction list grows:

```wl
BarChart[Table[RecursorNodeCount[ToRecursor[Table[{1,0,{i+1}},{i,1,m}]]],{m,1,5}], ChartLabels->Range[5], Frame->True, FrameLabel->{"Instructions","DSL nodes"} ]
```

---

Trace the order in which mathlib pairs enumerate a square grid:

```wl
RecursorNodeCount /@ (projections = ToRecursor[#, "PartialRecursive"] & /@ {"Left", "Right"})
```

```wl
ListLinePlot[Table[EvaluateRecursor[#, n] & /@ projections, {n, 0, 24}], Frame -> True, FrameLabel -> {"Left", "Right"}]
```

## Possible Issues

A search can exhaust the observation budget:

```wl
EvaluateRecursor[ToRecursor[{"Search", "Successor"}, "PartialRecursive"], 0, "MaxSteps" -> 500]["Tag"]
```

The finite budget does not establish nontermination. In this example the mathematical reason is that the search's successor test never returns zero.
