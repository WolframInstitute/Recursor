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
terms. The search is deterministic. It returns the program together with its
cost and the method that found it.

Synthesize a program from ten terms of a sequence:

```wl
triangular = SynthesizeRecursor[{0, 1, 3, 6, 10, 15, 21, 28, 36, 45}]
```

Draw the program:

```wl
RecursorProgramTree[triangular["Program"]]
```

A program is a prediction. Compare its later values with the closed formula:

```wl
ListLinePlot[{Table[EvaluateRecursor[triangular["Program"], n], {n, 0, 30}], Table[n (n + 1)/2, {n, 0, 30}]}, DataRange -> {0, 30}, PlotLegends -> {"Program", "Formula"}, AxesLabel -> {"Input", "Output"}]
```

## Three ways to find a program

Enumeration lists programs by increasing cost and keeps one program for each
distinct list of values on the example inputs. A recurrence is checked on the
terms themselves, so its step never has to be run from the start. Exact solving
supplies constants that enumeration would not reach.

Find one sequence with each method and compare the costs:

```wl
methods = AssociationMap[SynthesizeRecursor[2^Range[0, 11] - 1, Method -> #] &, {"Enumeration", "Recurrence", "Solving"}]
```

Show the three programs:

```wl
FormatRecursor /@ methods[[All, "Program"]]
```

Count the candidates each method examined:

```wl
BarChart[methods[[All, "Candidates"]], ChartLabels -> Automatic, AxesLabel -> {None, "Candidates"}]
```

## Recurrences read their first terms from the data

A recurrence takes its initial terms from the examples. Each initial term adds
to the cost, so a recurrence is preferred only when its step is simple.

Synthesize the Lucas numbers, which differ from Fibonacci numbers only in
their first terms:

```wl
lucas = SynthesizeRecursor[LucasL[Range[0, 11]]]
```

Check twenty later terms:

```wl
Table[EvaluateRecursor[lucas["Program"], n], {n, 12, 31}] === LucasL[Range[12, 31]]
```

## Few terms can mislead

A program explains only the terms it was given. The first terms of the
prime-counting function have cheaper explanations than counting primes.

Synthesize from eight terms and from twenty:

```wl
counting = AssociationMap[SynthesizeRecursor[Table[{n, PrimePi[n]}, {n, 1, #}]] &, {8, 20}]
```

The explanation of twenty terms costs three times as much:

```wl
counting[[All, "Cost"]]
```

Compare both predictions with the true counts. Each program follows its own
examples and leaves the sequence soon after them:

```wl
ListStepPlot[Append[Table[EvaluateRecursor[counting[k]["Program"], n], {k, {8, 20}}, {n, 1, 40}], PrimePi[Range[40]]], DataRange -> {1, 40}, PlotLegends -> {"From 8 terms", "From 20 terms", "Prime count"}, AxesLabel -> {"Input", "Output"}]
```

Solved means agreement on the examples. It is evidence for a rule, not a
proof of it. Hold terms back and test them, as the
[OEIS benchmark](paclet:WolframInstitute/Recursor/tutorial/MeasuringOEISSequenceDiscovery)
does.
