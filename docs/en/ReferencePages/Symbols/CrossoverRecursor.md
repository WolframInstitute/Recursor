---
Template: Symbol
Name: CrossoverRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/CrossoverRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [EvolutionaryExperiments]
---

## Usage

<code>[CrossoverRecursor]()[*a*, *b*]</code> combines two programs.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Chooses a site in a and a compatible donor subtree in b.
- "MaxNodes" defaults to 60.
- If no donor fits the scope and size budget, the result is a. A parent a that exceeds the budget produces Failure.


The following options are available:

| | | |
| --- | --- | --- |
| "MaxNodes" | 60 | Maximum syntax nodes in a generated program. |

## Basic Examples

Fix the random seed:

```wl
SeedRandom[42]
```

Evaluate a small example:

```wl
CrossoverRecursor[RecursorExamples["Factorial"], RecursorExamples["Fibonacci"]]
```

## Options

Restrict the size of the returned child:

```wl
BlockRandom[SeedRandom[18]; CrossoverRecursor[Var, Mul[Var, Var], "MaxNodes" -> 1] ]
```

## Applications

Fix the random seed:

```wl
SeedRandom[42]
```

Measure offspring sizes across repeated crosses:

```wl
Histogram[Table[RecursorNodeCount[CrossoverRecursor[RecursorExamples["Factorial"],RecursorExamples["Fibonacci"]]],{40}], Frame->True, FrameLabel->{"Nodes","Offspring"} ]
```

---

Fix the random seed:

```wl
SeedRandom[42]
```

Inspect one offspring:

```wl
RecursorProgramTree[CrossoverRecursor[RecursorExamples["Factorial"],RecursorExamples["Fibonacci"]]]
```
