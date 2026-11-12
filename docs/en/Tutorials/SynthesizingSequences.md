---
Template: TechNote
Name: SynthesizingSequences
Title: Synthesizing Sequence Programs
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/SynthesizingSequences
RelatedGuides: [Synthesis, Recursor]
RelatedTutorials: [LanguageSemantics, EvolutionaryExperiments, MeasuringOEISSequenceDiscovery]
---

## From terms to a program

SynthesizeRecursor searches for the cheapest program that reproduces given
terms, and tests it on terms it kept aside. The search is deterministic. It
returns the program with its cost, the method that found it and the outcome
of the test.

Synthesize a program from sixteen terms of a sequence:

```wl
triangular = SynthesizeRecursor[Table[n (n + 1)/2, {n, 0, 15}]]
```

Draw the program:

```wl
RecursorProgramTree[triangular["Program"]]
```

Write it as a Wolfram Language function:

```wl
TranslateRecursor[triangular["Program"]]
```

A program is a prediction. Compare its later values with the closed formula:

```wl
ListLinePlot[{Table[EvaluateRecursor[triangular["Program"], n], {n, 0, 30}], Table[n (n + 1)/2, {n, 0, 30}]}, DataRange -> {0, 30}, PlotLegends -> {"Program", "Formula"}, Frame -> True, FrameLabel -> {"Input", "Output"}]
```

## What Solved means

A program that fits its examples need not be their rule. SynthesizeRecursor
therefore keeps the last quarter of the examples from the search. Solved is
True when the program found from the other examples reproduces the held-out
ones, and when the examples carry enough evidence.

The search for the triangular numbers saw twelve terms and was tested on four:

```wl
KeyTake[triangular, {"Solved", "TrainingExamples", "HeldOutExamples", "HeldOutMatches", "Evidence"}]
```

Evidence compares the information in the examples with the information in the
program, in bits. Terms that change little say little. Sixteen terms of the
binary digit count give the right program, yet almost as many bits go into
choosing the program as the terms contain:

```wl
few = SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]];
KeyTake[few, {"Solved", "HeldOutMatches", "Evidence"}]
```

More terms settle it. Plot the evidence against the number of terms, with the
24 bits that Solved requires:

```wl
ListLinePlot[Table[{k, SynthesizeRecursor[DigitCount[Range[0, k - 1], 2, 1]]["Evidence"]}, {k, 16, 64, 8}], GridLines -> {None, {24}}, Frame -> True, FrameLabel -> {"Terms", "Evidence"}]
```

A program that fails a held-out term is returned, but not as solved:

```wl
KeyTake[SynthesizeRecursor[Join[Range[0, 11]^2, {150, 170, 190, 215}]], {"Program", "Solved", "HeldOutMatches"}]
```

## Four ways to find a program

Enumeration lists programs by increasing cost and keeps one program for each
distinct list of values on the training inputs. A recurrence is checked on the
terms themselves, so its step never has to be run from the start. Exact solving
supplies constants that enumeration would not reach. Composition builds
programs around sums, products and counts over a loop index.

Find one sequence with three of the methods and compare the costs:

```wl
methods = AssociationMap[SynthesizeRecursor[2^Range[0, 15] - 1, Method -> #] &, {"Enumeration", "Recurrence", "Solving"}]
```

Show the three programs:

```wl
FormatRecursor /@ methods[[All, "Program"]]
```

## Programs composed from loops

A count over a loop index gives the number of divisors of n:

```wl
divisors = SynthesizeRecursor[Table[{n, DivisorSigma[0, n]}, {n, 1, 30}]]
```

The primes are the numbers for which such a count has one value. The search
finds that property from the terms: it asks which stored program separates the
terms from the numbers between them.

```wl
primes = SynthesizeRecursor[Table[{n, Prime[n]}, {n, 1, 30}]]
```

Draw the program. The count sits inside a loop that steps to the next number
with the property:

```wl
RecursorProgramTree[primes["Program"]]
```

Its translation is recognized as a built-in function:

```wl
TranslateRecursor[primes["Program"]]
```

Check thirty later primes:

```wl
Table[EvaluateRecursor[primes["Program"], n, "MaxSteps" -> 5000000], {n, 31, 60}] === Prime[Range[31, 60]]
```

## Recurrences read their first terms from the data

A recurrence takes its initial terms from the examples. Each initial term adds
to the cost, so a recurrence is preferred only when its step is simple.

Synthesize the Lucas numbers, which differ from Fibonacci numbers only in
their first terms:

```wl
lucas = SynthesizeRecursor[LucasL[Range[0, 15]]]
```

Check twenty later terms:

```wl
Table[EvaluateRecursor[lucas["Program"], n], {n, 16, 35}] === LucasL[Range[16, 35]]
```

## Few terms can mislead

The first terms of the prime-counting function have cheaper explanations than
counting primes.

Synthesize from eight terms and from forty:

```wl
counting = AssociationMap[SynthesizeRecursor[Table[{n, PrimePi[n]}, {n, 1, #}]] &, {8, 40}]
```

Only the search with forty terms is solved:

```wl
counting[[All, {"Solved", "Method", "Evidence"}]]
```

Compare both predictions with the true counts. The program from eight terms
leaves the sequence soon after them:

```wl
ListStepPlot[Append[Table[EvaluateRecursor[counting[k]["Program"], n, "MaxSteps" -> 5000000], {k, {8, 40}}, {n, 1, 60}], PrimePi[Range[60]]], DataRange -> {1, 60}, PlotLegends -> {"From 8 terms", "From 40 terms", "Prime count"}, Frame -> True, FrameLabel -> {"Input", "Output"}]
```

Solved is strong evidence for a rule, not a proof of it. Many sequences follow
a simple rule for their first terms and then leave it: the ribbon tilings of
an 8 × n strip are n! up to 8!. Only more terms can show that, so Solved
needs at least four held-out terms, sixteen terms in all by default. On
3,000 sequences of the OEIS that were not used to set the method, 248 of the
252 programs solved from twenty terms reproduced every later term on record.
Of the programs with the same evidence, 62 of 65 found from sixteen terms
did, 38 of 41 from twelve and 26 of 34 from eight. The
[OEIS benchmark](paclet:WolframInstitute/Recursor/tutorial/MeasuringOEISSequenceDiscovery)
tests programs on all recorded terms.
