---
Template: Symbol
Name: RecursorEvolutionPlot
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorEvolutionPlot
RelatedGuides: [Recursor, Visualization]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorEvolutionPlot]()[*result*]</code> draws best fitness by generation.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- result is an EvolveRecursor result.
- Accepts ListLinePlot options and inherits its presentation defaults, including `ImageSize -> Automatic`.
- The default axis labels are "Generation" and "Exact matches".
- `DataRange -> Automatic` runs from generation zero, the initial population, to the recorded final generation.

## Basic Examples

Evaluate a small example:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0, 7}, {1, 8}}, "PopulationSize" -> 4, "MaxGenerations" -> 3, "RandomSeed" -> 2 ]]
```

## Applications

Compare two search seeds:

```wl
ListLinePlot[Table[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize"->6,"MaxGenerations"->4,"StopOnSolve"->False,"RandomSeed"->seed,"IncludeWhile"->False]["FitnessHistory"], {seed,{41,42}}], DataRange->{0,4}, PlotLegends->{"Seed 41","Seed 42"}, AxesLabel->{"Generation","Exact matches"} ]
```

---

Inspect a longer fixed-seed run:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> 41, "IncludeWhile" -> False], PlotRange -> {0,3}]
```
