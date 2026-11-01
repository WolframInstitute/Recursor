---
Template: Symbol
Name: ScoreRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/ScoreRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [EvolutionaryExperiments]
---

## Usage

<code>[ScoreRecursor]()[*program*, *examples*]</code> counts exact matches.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- examples is a nonempty list of {natural input, natural output} pairs.
- "MaxSteps" defaults to 10000, "TimeLimit" to 0.2 seconds and "MemoryLimit" to 67108864 bytes per input.
- A limited or nonmatching evaluation contributes zero. No approximate matches receive credit.


The following options are available:

| | | |
| --- | --- | --- |
| "MaxSteps" | 10000 | Syntax visits per training input. |
| "TimeLimit" | 0.2 | Seconds per training input. |
| "MemoryLimit" | 67108864 | Additional bytes per training input. |

## Basic Examples

Evaluate a small example:

```wl
ScoreRecursor[Mul[Var, Var], {{0, 0}, {2, 4}, {3, 8}}]
```

## Options

Count a budget-limited evaluation as a missed example:

```wl
ScoreRecursor[WhileLoop[Var, Acc, Pred[Acc]], {{2, 0}, {20, 0}}, "MaxSteps" -> 12, "TimeLimit" -> 1, "MemoryLimit" -> 67108864]
```

## Applications

Compare candidate fits to a square target:

```wl
BarChart[ScoreRecursor[#,Table[{n,n^2},{n,0,5}]] & /@ {Var,Add[Var,Var],Mul[Var,Var]}, ChartLabels->{"Identity","Double","Square"}, AxesLabel->{None,"Exact matches"} ]
```

---

See the behaviors underlying those scores:

```wl
ListLinePlot[Table[EvaluateRecursor[p,n],{p,{Var,Add[Var,Var],Mul[Var,Var]}},{n,0,5}], DataRange->{0,5}, PlotLegends->{"Identity","Double","Square"}, AxesLabel->{"Input","Output"} ]
```
