---
Template: Symbol
Name: SynthesizeRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/SynthesizeRecursor
RelatedGuides: [Synthesis, Recursor]
SeeAlso: [EvolveRecursor, EvaluateRecursor, ScoreRecursor, RecursorNodeCount]
RelatedTutorials: [SynthesizingSequences, MeasuringOEISSequenceDiscovery]
---

## Usage

<code>[SynthesizeRecursor]()[*examples*]</code> finds the cheapest closed program matching input-output pairs.

<code>[SynthesizeRecursor]()[*terms*]</code> uses the inputs 0, 1, 2, ….

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. The search is deterministic: it uses no random numbers. -->

## Details & Options

- Returns Program, Solved, Cost, Nodes, Method and Candidates. Solved means exact agreement on these examples, not a proof of generalization. Without a match, Program is Missing["NotFound"].
- Enumeration lists programs by increasing cost and keeps one program for each distinct vector of values on the example inputs. It includes conditionals, bounded loops and the closure c1 x + c0 with solved constants.
- Recurrence checks a step against the examples themselves: the step must give each term from the recorded earlier terms. Initial terms are read from the examples. It needs consecutive inputs and at least six terms.
- Solving finds constants exactly for linear recurrences with polynomial coefficients, periodic increments, polynomials and constant tails. It needs consecutive inputs and spare terms that confirm the result.
- Cost counts syntax nodes chosen by the search. A constant up to three costs one; every further two bits cost one more. Each initial term of a recurrence costs as a constant.
- Method reports Constant, ClosedForm, Affine, Recurrence, LinearRecurrence, Hypergeometric, Holonomic, Polynomial, Periodic or ConstantTail.
- Every returned program is checked on the examples with EvaluateRecursor.

The following options are available:

| | | |
| --- | --- | --- |
| Method | Automatic | Automatic, or any of "Enumeration", "Recurrence" and "Solving". |
| "MaxCost" | 8 | Largest cost enumerated. Recurrence steps are enumerated to three less. |
| "MaxConstant" | 3 | Largest constant used as a leaf. |
| "MaxLoopBody" | 4 | Largest enumerated loop step; zero disables loops. |
| "TimeLimit" | 20 | Seconds after which no further cost level is started. |

## Basic Examples

Find a program for the squares:

```wl
SynthesizeRecursor[{0, 1, 4, 9, 16, 25, 36, 49}]
```

---

Find a recurrence and its initial terms:

```wl
FormatRecursor[SynthesizeRecursor[{0, 1, 1, 2, 3, 5, 8, 13, 21, 34}]["Program"]]
```

---

Compare predicted later terms with factorials:

```wl
ListLogPlot[{Table[EvaluateRecursor[SynthesizeRecursor[{1, 1, 2, 6, 24, 120, 720, 5040}]["Program"], n], {n, 0, 14}], Range[0, 14]!}, DataRange -> {0, 14}, PlotLegends -> {"Program", "Factorial"}, AxesLabel -> {"Input", "Output"}]
```

## Scope

Give inputs explicitly for a sequence that starts at one:

```wl
FormatRecursor[SynthesizeRecursor[Table[{n, n! + 1}, {n, 1, 9}]]["Program"]]
```

---

Inputs can have gaps; enumeration then searches closed forms only:

```wl
SynthesizeRecursor[{{0, 1}, {2, 5}, {5, 26}, {9, 82}}]
```

## Options

### Method

Restrict the search to exact solving:

```wl
KeyTake[SynthesizeRecursor[LinearRecurrence[{10, -1}, {0, 2}, 10], Method -> "Solving"], {"Program", "Method", "Cost"}]
```

### MaxCost

A smaller cost bound can leave the examples unexplained:

```wl
SynthesizeRecursor[Table[Quotient[n^2, 3], {n, 0, 11}], Method -> "Enumeration", "MaxCost" -> #]["Solved"] & /@ {4, 5}
```

### MaxConstant

Larger constants enter closed forms through the affine closure:

```wl
KeyTake[SynthesizeRecursor[Table[n^2 + 41, {n, 0, 9}], Method -> "Enumeration"], {"Program", "Method"}]
```

### MaxLoopBody

Enumerated loops need a step of at least three nodes for the powers of two:

```wl
SynthesizeRecursor[2^Range[0, 9], Method -> "Enumeration", "MaxLoopBody" -> #]["Solved"] & /@ {0, 3}
```

### TimeLimit

A short time limit stops the enumeration between cost levels:

```wl
SynthesizeRecursor[{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8}, "TimeLimit" -> 1]["Solved"]
```

## Applications

Recover the binary digit count from sixteen terms:

```wl
RecursorProgramTree[SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]]["Program"]]
```

---

Count the candidates each family examines for one sequence:

```wl
BarChart[AssociationMap[SynthesizeRecursor[CatalanNumber[Range[0, 11]], Method -> #]["Candidates"] &, {"Solving", "Recurrence", "Enumeration"}], ChartLabels -> Automatic, AxesLabel -> {None, "Candidates"}]
```

## Properties and Relations

The result of the automatic method is never more costly than one family alone:

```wl
SynthesizeRecursor[Fibonacci[Range[0, 11]], Method -> #]["Cost"] & /@ {Automatic, "Solving"}
```

## Possible Issues

A few terms can have a cheaper explanation than the intended one. Eight terms of the prime-counting function fit a closed form that fails from the ninth term:

```wl
With[{program = SynthesizeRecursor[Table[{n, PrimePi[n]}, {n, 1, 8}]]["Program"]}, Table[EvaluateRecursor[program, n], {n, 1, 12}] - PrimePi[Range[12]]]
```
