---
Template: Symbol
Name: RandomRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RandomRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [EvolutionaryExperiments]
---

## Usage

<code>[RandomRecursor]()[*depth*]</code> generates a closed program.

<code>[RandomRecursor]()[]</code> uses the default depth.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- depth defaults to 3; zero produces a leaf.
- "MaxConstant" defaults to 3; "MaxNodes" defaults to 60; "IncludeWhile" defaults to True.
- The node budget is divided between children. Sampling is not uniform over all programs.
- Use BlockRandom and SeedRandom for reproducible samples. These search restrictions are not language restrictions.


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
RandomRecursor[2]
```

## Scope

Use the default generation depth:

```wl
BlockRandom[SeedRandom[8]; RandomRecursor[]]
```

## Options

Set generation bounds for a reproducible sample:

```wl
BlockRandom[SeedRandom[24]; RandomRecursor[3, "MaxConstant" -> 1, "MaxNodes" -> 12, "IncludeWhile" -> False] ]
```

## Applications

Fix the random seed:

```wl
SeedRandom[42]
```

Measure sizes in a fixed sample of bounded programs:

```wl
Histogram[Table[RecursorNodeCount[RandomRecursor[3,"IncludeWhile"->False]],{40}], Frame->True, FrameLabel->{"Nodes","Programs"} ]
```

---

Fix the random seed:

```wl
SeedRandom[42]
```

Inspect another sampled syntax tree:

```wl
RecursorProgramTree[RandomRecursor[3,"IncludeWhile"->False]]
```
