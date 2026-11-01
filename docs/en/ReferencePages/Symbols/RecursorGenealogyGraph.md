---
Template: Symbol
Name: RecursorGenealogyGraph
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorGenealogyGraph
RelatedGuides: [Recursor, Visualization]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorGenealogyGraph]()[*result*]</code> draws recorded ancestry.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- The default plot fits in 520 by 360 points.

- Includes initial programs, offspring and proposed candidates.
- Both parents of a crossover can appear. Accepts Graph options.

## Basic Examples

Evaluate a small example:

```wl
RecursorGenealogyGraph[EvolveRecursor[{{0, 7}}, "PopulationSize" -> 4, "MaxGenerations" -> 2, "RandomSeed" -> 2 ]]
```

## Applications

Inspect ancestry after three generations:

```wl
RecursorGenealogyGraph[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> 41, "IncludeWhile" -> False]]
```

---

Relate ancestry to fitness:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> 41, "IncludeWhile" -> False]]
```
