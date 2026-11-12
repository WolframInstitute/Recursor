---
Template: Symbol
Name: SynthesizeRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/SynthesizeRecursor
RelatedGuides: [Synthesis, Recursor]
SeeAlso: [TranslateRecursor, EvolveRecursor, EvaluateRecursor, ScoreRecursor, RecursorNodeCount]
RelatedTutorials: [SynthesizingSequences, MeasuringOEISSequenceDiscovery]
---

## Usage

<code>[SynthesizeRecursor]()[*examples*]</code> finds a closed program from input-output pairs and tests it on pairs it was not shown.

<code>[SynthesizeRecursor]()[*terms*]</code> uses the inputs 0, 1, 2, ….

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. The search is deterministic: it uses no random numbers. -->

## Details & Options

- Returns Program, Solved, Cost, Nodes, Method, Candidates, TrainingExamples, HeldOutExamples, HeldOutMatches and Evidence. Without a program that reproduces the training examples, Program is Missing["NotFound"].
- The examples with the largest inputs are held out, a quarter of them by default. The search sees only the other examples. Solved means that the program reproduces every held-out example, that there are at least four of them, and that Evidence reaches "RequiredEvidence".
- Evidence is the information in the examples less the information in the program, in bits. A value counts by its distance from the value before it; a unit of cost counts 2.5 bits. Few terms, or terms that change little, can be fitted by chance and give little evidence. More terms give more.
- Solved is strong evidence for a rule, not a proof of it. Many sequences follow a simple rule for their first terms and then leave it, so Solved needs sixteen examples or more by default. On samples of the OEIS, 95% of the programs solved from sixteen terms and 98% of those solved from twenty reproduced every later term on record. A program that is not solved is still returned, as the cheapest one that reproduces the training examples.
- Enumeration lists programs by increasing cost and keeps one program for each distinct vector of values on the training inputs. It includes conditionals, bounded loops, the closure c1 x + c0 with solved constants, and two enumerated parts joined by Add, Mul or Monus.
- Recurrence checks a step against the examples themselves: the step must give each term from the recorded earlier terms. Initial terms are read from the examples, and a step must reproduce at least two more terms than it reads. It needs consecutive inputs and at least six terms.
- Solving finds constants exactly for linear recurrences with polynomial coefficients, periodic increments, polynomials and constant tails. It needs consecutive inputs and spare terms that confirm the result.
- Composition builds on sums, products and counts over a loop index. It finds them alone, and inside the n-th number whose value has a property, the count of such numbers up to n, partial sums, differences, and a program applied to a simple function of the input.
- Cost counts the choices of the search. An enumerated node costs one; a constant up to three costs one and every further two bits cost one more. Each initial term of a recurrence costs as a constant. A sum, product or count costs its term and one more.
- Method reports Constant, ClosedForm, Affine, Recurrence, LinearRecurrence, Hypergeometric, Holonomic, Polynomial, Periodic, ConstantTail, Fold, Search, Counting, PartialSum, Difference or Composition.
- Every returned program is checked on the examples with EvaluateRecursor.

The following options are available:

| | | |
| --- | --- | --- |
| Method | Automatic | Automatic, or any of "Enumeration", "Recurrence", "Solving" and "Composition". |
| "MaxCost" | 8 | Largest cost enumerated. Recurrence steps are enumerated to three less. Two joined parts can cost twice as much. |
| "MaxConstant" | 3 | Largest constant used as a leaf. |
| "MaxLoopBody" | 4 | Largest enumerated loop step; zero disables loops. |
| "MaxFoldTerm" | 5 | Largest term of a sum, product or count. Inside a search, a counting function, a partial sum, a difference or a composition, a term is one smaller. |
| "HoldOut" | Automatic | Number of examples kept from the search. Automatic keeps a quarter, and one of fewer than eight. Solved needs four. |
| "RequiredEvidence" | 24 | Bits of evidence a solved program needs. |
| "TimeLimit" | 20 | Seconds after which the search stops and returns what it has found. |

## Basic Examples

Find a program for the squares. Twelve terms are used for the search and four test it:

```wl
SynthesizeRecursor[Range[0, 15]^2]
```

---

Find a recurrence and its initial terms:

```wl
FormatRecursor[SynthesizeRecursor[Fibonacci[Range[0, 19]]]["Program"]]
```

---

Compare predicted later terms with factorials:

```wl
ListLogPlot[{Table[EvaluateRecursor[SynthesizeRecursor[Range[0, 9]!]["Program"], n], {n, 0, 14}], Range[0, 14]!}, DataRange -> {0, 14}, PlotLegends -> {"Program", "Factorial"}, AxesLabel -> {"Input", "Output"}]
```

## Scope

Give inputs explicitly for a sequence that starts at one:

```wl
FormatRecursor[SynthesizeRecursor[Table[{n, n! + 1}, {n, 1, 12}]]["Program"]]
```

---

Inputs can have gaps; the search then looks for closed forms only:

```wl
SynthesizeRecursor[{{0, 1}, {2, 5}, {5, 26}, {9, 82}, {12, 145}, {15, 226}, {20, 401}, {26, 677}}]
```

---

A count over a loop index gives the number of divisors:

```wl
SynthesizeRecursor[Table[{n, DivisorSigma[0, n]}, {n, 1, 30}]]
```

---

The primes are the numbers with a property of that count:

```wl
primes = SynthesizeRecursor[Table[{n, Prime[n]}, {n, 1, 30}]]
```

Draw the program:

```wl
RecursorProgramTree[primes["Program"]]
```

Write it as a Wolfram Language function:

```wl
TranslateRecursor[primes["Program"]]
```

## Options

### Method

Restrict the search to exact solving:

```wl
KeyTake[SynthesizeRecursor[LinearRecurrence[{10, -1}, {0, 2}, 12], Method -> "Solving"], {"Program", "Method", "Cost"}]
```

### MaxCost

A smaller cost bound can leave the examples unexplained:

```wl
MissingQ[SynthesizeRecursor[Table[Quotient[n^2, 3], {n, 0, 15}], Method -> "Enumeration", "MaxCost" -> #]["Program"]] & /@ {1, 5}
```

### MaxConstant

Larger constants enter closed forms through the affine closure:

```wl
KeyTake[SynthesizeRecursor[Table[n^2 + 41, {n, 0, 11}], Method -> "Enumeration"], {"Program", "Method"}]
```

### MaxLoopBody

Enumerated loops need a step of at least three nodes for the powers of two:

```wl
MissingQ[SynthesizeRecursor[2^Range[0, 11], Method -> "Enumeration", "MaxLoopBody" -> #]["Program"]] & /@ {0, 3}
```

### HoldOut

Keep half of the examples for the test:

```wl
KeyTake[SynthesizeRecursor[Range[0, 15]^2, "HoldOut" -> 8], {"Solved", "TrainingExamples", "HeldOutExamples", "HeldOutMatches"}]
```

### RequiredEvidence

Sixteen terms of the binary digit count give the right program, but they say little more than the program does:

```wl
KeyTake[SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]], {"Solved", "HeldOutMatches", "Evidence"}]
```

Forty-eight terms give evidence enough:

```wl
KeyTake[SynthesizeRecursor[DigitCount[Range[0, 47], 2, 1]], {"Solved", "HeldOutMatches", "Evidence"}]
```

### TimeLimit

A short time limit ends the search early:

```wl
SynthesizeRecursor[{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8}, "TimeLimit" -> 1]["Solved"]
```

## Applications

Recover the binary digit count from sixteen terms:

```wl
RecursorProgramTree[SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]]["Program"]]
```

---

See the evidence grow with the number of terms:

```wl
ListLinePlot[Table[{k, SynthesizeRecursor[DigitCount[Range[0, k - 1], 2, 1]]["Evidence"]}, {k, 16, 64, 8}], GridLines -> {None, {24}}, AxesLabel -> {"Terms", "Evidence"}]
```

## Properties and Relations

The result of the automatic method is never more costly than one family alone:

```wl
SynthesizeRecursor[Fibonacci[Range[0, 15]], Method -> #]["Cost"] & /@ {Automatic, "Solving"}
```

## Possible Issues

Few terms have many explanations. Eight terms of the prime-counting function are fitted, but the program found is not solved:

```wl
KeyTake[SynthesizeRecursor[Table[{n, PrimePi[n]}, {n, 1, 8}]], {"Solved", "HeldOutMatches", "Evidence"}]
```

Forty terms are solved, by a program that counts the numbers with exactly two divisors:

```wl
KeyTake[SynthesizeRecursor[Table[{n, PrimePi[n]}, {n, 1, 40}]], {"Solved", "Method", "Evidence"}]
```
