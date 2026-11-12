---
Template: TechNote
Name: EvolutionaryExperiments
Title: Measuring Program Evolution
Description: Reproducible computations with the Recursor language
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/EvolutionaryExperiments
Keywords: [computational essay, natural numbers, program behavior]
RelatedGuides: [Evolution, Recursor, Visualization]
RelatedTutorials: [MeasuringOEISSequenceDiscovery, LanguageSemantics, UniversalComputation]
---

## A finite search experiment

How do syntax changes affect a program's sampled behavior? Start with a square
program and mutate one subtree at a time. Then compare six small evolutionary
runs against the same five training examples. These finite experiments measure
sampled behavior; they do not establish semantic equivalence or a population
success probability.

Fix the mutation seed:

```wl
SeedRandom[2026]
```

Construct twenty successive mutations and draw the final program:

```wl
RecursorProgramTree[Last[mutants = NestList[MutateRecursor[#, 2, "IncludeWhile" -> False, "MaxNodes" -> 30] &, Mul[Var, Var], 20]]]
```

Plot syntax size along the mutation trajectory:

```wl
ListLinePlot[RecursorNodeCount /@ mutants, DataRange->{0,20}, AxesLabel->{"Mutation","Syntax nodes"}, PlotRange->All]
```

For inputs zero through six, show log(1+output). An unfinished evaluation is
Indeterminate, not a zero output:

```wl
MatrixPlot[Table[With[{value=EvaluateRecursor[p,n,"MaxSteps"->5000]}, If[IntegerQ[value],Log[1+value],Indeterminate] ],{n,0,6},{p,mutants}], FrameLabel->{"Input","Mutation"}, FrameTicks->{Table[{n+1,n},{n,0,6}],Table[{k+1,k},{k,0,20,4}]}, PlotLegends->Automatic]
```

## Six seeded searches

Each run uses population 12, eight generations, maximum 30 nodes and the
bounded grammar. Fitness is the number of exact matches on inputs 0 through
4. Per-input evaluation is limited to 2000 visits, one second and 64 MiB.
StopOnSolve is disabled so every fitness trajectory spans the same window.

Compute the six runs, using seeds 101 through 106, and compare final best scores:

```wl
BarChart[Lookup[runs = Table[EvolveRecursor[Table[{n, n^2}, {n, 0, 4}], "PopulationSize" -> 12, "MaxGenerations" -> 8, "MaxNodes" -> 30, "InitialDepth" -> 2, "MutationDepth" -> 2, "IncludeWhile" -> False, "MaxSteps" -> 2000, "TimeLimit" -> 1, "StopOnSolve" -> False, "RandomSeed" -> seed], {seed, 101, 106}], "Fitness"], ChartLabels -> Range[101, 106], AxesLabel -> {"Seed", "Exact matches"}]
```

Compare best fitness on a shared scale:

```wl
ListLinePlot[Lookup[runs,"FitnessHistory"], DataRange->{0,8}, PlotRange->{0,5}, PlotLegends->Range[101,106], AxesLabel->{"Generation","Exact matches"}]
```

Equal scores need not mean equal programs. Inspect the best syntax tree from
each run:

```wl
Grid[Partition[MapIndexed[Labeled[RecursorProgramTree[#1["Program"]], Row[{"Seed ", 100 + First[#2]}], Top] &, runs], 3]]
```

## Beyond the training range

For each best program, compute absolute error on inputs zero through eight.
The training range ends at four; differences beyond it measure this finite
holdout experiment, not general equivalence:

```wl
MatrixPlot[Table[With[{value=EvaluateRecursor[result["Program"],n,"MaxSteps"->5000]}, If[IntegerQ[value],Abs[value-n^2],Indeterminate] ],{result,runs},{n,0,8}], FrameLabel->{"Seed","Input"}, FrameTicks->{Table[{k,k+100},{k,1,6}],Table[{n+1,n},{n,0,8}]}, PlotLegends->Automatic]
```

## Guided variation

Mutation and crossover change a program without looking at the examples.
Method -> "Guided" works backwards from them: it picks a part of a program,
finds the values that part must have for the outputs to come out right, and
takes the small program with those values from a library.

Evolve the Lucas numbers from eight terms with each method and the same seed:

```wl
searches = AssociationMap[EvolveRecursor[Table[{n, LucasL[n]}, {n, 0, 7}], Method -> #, "StopOnSolve" -> False, "RandomSeed" -> 5] &, {"Tournament", "Guided"}];
ListStepPlot[Lookup[Values[searches], "FitnessHistory"], DataRange -> {0, 30}, PlotLegends -> Keys[searches], AxesLabel -> {"Generation", "Exact matches"}]
```

The guided search returns a recurrence with its two initial terms:

```wl
RecursorProgramTree[searches["Guided"]["Program"]]
```

Test each program on the eight terms after the ones given:

```wl
Map[Table[EvaluateRecursor[#["Program"], n, "MaxSteps" -> 100000], {n, 8, 15}] === LucasL[Range[8, 15]] &, searches]
```

A guided search fits most sequences it is given. A fit is not yet a rule:
[SynthesizeRecursor](paclet:WolframInstitute/Recursor/ref/SynthesizeRecursor)
tests a program on terms it has not seen and reports the evidence.

## Ancestry at a readable scale

A smaller run makes individual parent-child relationships visible. Keep all
three generations even if a training fit appears earlier:

```wl
RecursorGenealogyGraph[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize"->5,"EliteCount"->1,"MaxGenerations"->3, "IncludeWhile"->False,"StopOnSolve"->False,"RandomSeed"->41 ]]
```

The recorded IDs distinguish individuals even when they share the same source
program. The observations are determined by these seeds, settings, training
data and evaluator budgets; changing any of them defines a different experiment.
