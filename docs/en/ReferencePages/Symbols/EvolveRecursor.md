---
Template: Symbol
Name: EvolveRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/EvolveRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [EvolutionaryExperiments, MeasuringOEISSequenceDiscovery]
---

## Usage

<code>[EvolveRecursor]()[*examples*]</code> evolves programs against input-output pairs.

<code>[EvolveRecursor]()[*examples*, Method -> "Guided"]</code> chooses each variation from the values the examples require.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Returns Program, Solved, Fitness, MaxFitness, Generations, FitnessHistory, Population and Genealogy. Solved means exact agreement on these examples, not a proof of generalization.
- Defaults: "PopulationSize" -> 40, "MaxGenerations" -> 30, "EliteCount" -> 2, "TournamentSize" -> 3, "CrossoverRate" -> 0.8, "MutationRate" -> 0.3, "InitialDepth" -> 2, "MutationDepth" -> 3.
- "InitialPopulation" defaults to {}; "RandomSeed" defaults to Automatic (the caller's random stream); "StopOnSolve" defaults to True. An explicit seed runs inside BlockRandom.
- Generation options and scoring limits are inherited from RandomRecursor and ScoreRecursor.
- "Proposer" defaults to None. A callback receives (best program, examples, requested count) and returns programs or source strings. Source is parsed and all candidates are checked. "ProposalCount" defaults to 4; "StagnationPatience" to 4 generations. No service is contacted by default.
- Each individual records ID, Program, Parents, Generation, Score and Size. Both crossover parents are retained. The population size stays fixed.
- Method -> Automatic is the search by tournament selection, crossover and mutation. Method -> "Guided" keeps the budget, the seeds and the scoring limits and replaces the variation. It enumerates a library of the distinct small programs once. A variation picks a node of a parent, works backwards from the outputs to the values that node must have, and puts the library program that fits most of them in its place. Parents are chosen by lexicase selection: the examples are taken in a random order and the programs that miss one are dropped.
- The guided method spends half of its generations on closed programs and half on the step of a recurrence, judged against the earlier outputs in the examples. That half needs consecutive inputs and at least six examples. Of two programs with the same fitness the cheaper is returned; a recurrence costs its step and its initial outputs.
- The guided method does not call "Proposer" and does not use the tournament, crossover and mutation options. With "StopOnSolve" -> False it goes on to look for a smaller program after a fit. A fit is not a prediction: on OEIS sequences one guided fit in twenty continued its sequence.


The following options are available:

| | | |
| --- | --- | --- |
| Method | Automatic | Automatic or "Tournament" for selection, crossover and mutation; "Guided" for variation that works backwards from the examples. |
| "LibraryCost" | 6 | Largest program in the library of the guided method. |
| "PopulationSize" | 40 | Number of individuals retained per generation. |
| "MaxGenerations" | 30 | Maximum breeding generations after generation zero. |
| "EliteCount" | 2 | Individuals carried into the next generation. |
| "TournamentSize" | 3 | Number of candidates sampled for each parent selection. |
| "CrossoverRate" | 0.8 | Probability of attempting crossover. |
| "MutationRate" | 0.3 | Probability of attempting mutation. |
| "InitialDepth" | 2 | Depth of newly generated initial programs. |
| "MutationDepth" | 3 | Depth of replacement subtrees. |
| "InitialPopulation" | {} | Closed seed programs, subject to MaxNodes. |
| "RandomSeed" | Automatic | Random seed, or the caller's random stream. |
| "StopOnSolve" | True | Stop at a fit to every training example. |
| "Proposer" | None | Optional local callback returning programs or source strings. |
| "ProposalCount" | 4 | Maximum proposed candidates considered per call. |
| "StagnationPatience" | 4 | Stalled generations before calling Proposer. |
| "MaxConstant" | 3 | Largest generated constant. |
| "MaxNodes" | 60 | Maximum syntax nodes in a generated program. |
| "IncludeWhile" | True | Whether generation can introduce WhileLoop. |
| "MaxSteps" | 10000 | Syntax visits per training input. |
| "TimeLimit" | 0.2 | Seconds per training input. |
| "MemoryLimit" | 67108864 | Additional bytes per training input. |

## Basic Examples

Evaluate a small example:

```wl
EvolveRecursor[{{0,0}}, "PopulationSize" -> 1, "EliteCount" -> 1, "InitialPopulation" -> {Var}, "MaxGenerations" -> 0 ]
```

## Options

Seed the population and inspect the best source after a fixed run window:

```wl
FormatRecursor[EvolveRecursor[{{0, 0}, {1, 1}, {2, 4}}, "InitialPopulation" -> {Mul[Var, Var]}, "PopulationSize" -> 6, "MaxGenerations" -> 2, "StopOnSolve" -> False, "RandomSeed" -> 42 ]["Program"]]
```

---

Specify selection, variation, grammar and per-input evaluation budgets:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0, 7}, {1, 8}, {2, 9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "EliteCount" -> 1, "TournamentSize" -> 2, "CrossoverRate" -> 0.6, "MutationRate" -> 0.4, "InitialDepth" -> 2, "MutationDepth" -> 2, "MaxConstant" -> 2, "MaxNodes" -> 25, "IncludeWhile" -> False, "RandomSeed" -> 43, "MaxSteps" -> 2000, "TimeLimit" -> 1, "MemoryLimit" -> 67108864 ]]
```

---

Inject a deterministic local proposal after zero stalled generations:

```wl
KeyTake[EvolveRecursor[{{0, 7}, {1, 8}}, "PopulationSize" -> 3, "EliteCount" -> 1, "MaxGenerations" -> 1, "InitialPopulation" -> {Var, Const[0], Const[1]}, "RandomSeed" -> 3, "StagnationPatience" -> 0, "ProposalCount" -> 1, "Proposer" -> Function[{program, examples, count}, {"Add[Var, Const[7]]"}] ], {"Program", "Solved", "Fitness"}]
```

---

Guided variation finds the recurrence of the Fibonacci numbers from eight terms:

```wl
guided = EvolveRecursor[Table[{n, Fibonacci[n]}, {n, 0, 7}], Method -> "Guided", "StopOnSolve" -> False, "RandomSeed" -> 7];
FormatRecursor[guided["Program"]]
```

The program continues the sequence:

```wl
Table[EvaluateRecursor[guided["Program"], n], {n, 8, 15}]
```

Blind variation with the same budget and seed:

```wl
KeyTake[EvolveRecursor[Table[{n, Fibonacci[n]}, {n, 0, 7}], "StopOnSolve" -> False, "RandomSeed" -> 7], {"Solved", "Fitness"}]
```

## Applications

The [OEIS sequence-discovery benchmark](paclet:WolframInstitute/Recursor/tutorial/MeasuringOEISSequenceDiscovery)
measures exact training fits, error curves and later-term predictions using
pinned data from WolframInstitute/OEIS.

Inspect best fitness over generations:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> 41, "IncludeWhile" -> False]]
```

---

Inspect parent-child relationships:

```wl
RecursorGenealogyGraph[EvolveRecursor[{{0,7},{1,8},{2,9}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> 41, "IncludeWhile" -> False]]
```
