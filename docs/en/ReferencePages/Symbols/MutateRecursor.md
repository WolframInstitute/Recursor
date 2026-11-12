---
Template: Symbol
Name: MutateRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/MutateRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [EvolutionaryExperiments]
---

## Usage

<code>[MutateRecursor]()[*program*, *depth*]</code> replaces one random subtree.

<code>[MutateRecursor]()[*program*]</code> uses the default mutation depth.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- depth defaults to 3 and controls the replacement depth.
- Options are the same as RandomRecursor. A parent that already exceeds MaxNodes produces Failure.
- Available binders at the chosen site constrain the replacement. The resulting program remains closed.


The following options are available:

| | | |
| --- | --- | --- |
| "MaxConstant" | 3 | Largest generated constant. |
| "MaxNodes" | 60 | Maximum syntax nodes in a generated program. |
| "IncludeWhile" | True | Whether generation can introduce WhileLoop. |

## Basic Examples

Fix the random seed:

```wl
SeedRandom[42]
```

Evaluate a small example:

```wl
MutateRecursor[RecursorExamples["Factorial"], 2]
```

## Scope

Use the default mutation depth:

```wl
BlockRandom[SeedRandom[9]; MutateRecursor[Mul[Var, Var]]]
```

## Options

Set generation bounds for a reproducible sample:

```wl
BlockRandom[SeedRandom[24]; MutateRecursor[Mul[Var, Var], 3, "MaxConstant" -> 1, "MaxNodes" -> 12, "IncludeWhile" -> False] ]
```

## Applications

Fix the random seed:

```wl
SeedRandom[42]
```

Measure sizes along a sequence of mutations:

```wl
ListLinePlot[RecursorNodeCount /@ NestList[MutateRecursor[#,2,"IncludeWhile"->False] &, Mul[Var,Var],20], DataRange->{0,20}, Frame->True, FrameLabel->{"Mutation","Nodes"} ]
```

---

Fix the random seed:

```wl
SeedRandom[42]
```

Inspect a mutated factorial program:

```wl
RecursorProgramTree[MutateRecursor[RecursorExamples["Factorial"],2,"IncludeWhile"->False]]
```
