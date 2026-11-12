---
Template: Symbol
Name: NormalizeRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/NormalizeRecursor
RelatedGuides: [Compilation, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [VisualizingLambdaCompilation, ArithmeticPatterns]
---

## Usage

<code>[NormalizeRecursor]()[*program*]</code> normalizes its compiled function.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Uses "MaxSteps", "TimeLimit" and "MemoryLimit" with the same defaults as EvaluateRecursor.
- Normalizing a function is different from running it on one input. Some compiled functions have no normal form even when particular inputs terminate.
- For evaluation on a numeral use EvaluateRecursor with Method -> "Lambda".


The following options are available:

| | | |
| --- | --- | --- |
| "MaxSteps" | 100000 | Maximum syntax visits or lambda-machine transitions; accepts Infinity. |
| "TimeLimit" | 5 | Seconds per evaluation; accepts Infinity. |
| "MemoryLimit" | 268435456 | Additional bytes per evaluation; accepts Infinity. |

## Basic Examples

Evaluate a small example:

```wl
NormalizeRecursor[Const[2]]
```

## Options

Bound normalization of a divergent program:

```wl
NormalizeRecursor[RecursorExamples["Nonterminating"], "MaxSteps" -> 100]
```

---

Normalize identity with explicit time and memory budgets:

```wl
NormalizeRecursor[Var, "TimeLimit" -> 1, "MemoryLimit" -> 67108864]
```

## Applications

Measure simplification of compiled constant functions:

```wl
BarChart[Table[{LeafCount[CompileRecursor[p]],LeafCount[NormalizeRecursor[p]]}, {p,{Const[2],Succ[Const[1]],Add[Const[1],Const[1]]}}],  ChartLegends->{"Compiled","Normal"}, ChartLabels->{{"Constant","Successor","Addition"},None}, Frame->True, FrameLabel->{None,"Leaves"} ]
```

---

Inspect the source before normalization:

```wl
RecursorProgramTree[Add[Const[1],Const[1]]]
```

---

Load the optional Wolfram/Lambda visualization tools:

```wl
Needs["Wolfram`Lambda`"]
```

Draw the lambda structure directly:

```wl
LambdaTree[NormalizeRecursor[Var]]
```
