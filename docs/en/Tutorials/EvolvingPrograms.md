---
Template: TechNote
Name: EvolvingPrograms
Title: Evolving Recursor Programs
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/EvolvingPrograms
RelatedGuides: [Recursor]
---

## Reproducible generation

Generation, mutation and crossover use the same lexical scopes as validation.
WhileLoop is included by default; disable it to compare with the original
bounded fragment. Sampling is not uniform over all programs.

Generate and draw a reproducible bounded program:

```wl
BlockRandom[ SeedRandom[42]; RecursorProgramTree[RandomRecursor[3, "IncludeWhile" -> False]] ]
```

## Search against examples

Supply explicit input-output pairs. Each candidate/input evaluation gets its
own finite budget. This example starts with a correct seed and stops at
generation zero:

Run a seeded search:

```wl
EvolveRecursor[{{0, 0}, {1, 1}, {2, 4}, {3, 9}}, "PopulationSize" -> 8, "InitialPopulation" -> {Mul[Var, Var]}, "RandomSeed" -> 42 ]["Solved"]
```

Solved means agreement on these training data, not a proof of equivalence or
generalization. Evaluate new inputs separately.

## Inspect evolution

Individuals record program, score, size, generation, ID and parent IDs. Both
crossover parents are retained. Elites keep their original IDs; new offspring
get new IDs. Population size stays fixed.

Plot the best fitness at each generation:

```wl
RecursorEvolutionPlot[EvolveRecursor[{{0, 7}, {1, 8}, {2, 9}}, "PopulationSize" -> 8, "MaxGenerations" -> 4, "RandomSeed" -> 12 ]]
```

## External proposals

A callback receives the current best program, training pairs and requested
proposal count. It returns source strings or program expressions. Strings are
parsed without evaluation, and every proposal is checked for closure and
size. The callback may use an LLM if the caller configures one; the paclet
itself contacts no service by default.

Supply a deterministic local proposal:

```wl
EvolveRecursor[{{0, 7}, {1, 8}}, "PopulationSize" -> 4, "MaxGenerations" -> 1, "StagnationPatience" -> 0, "RandomSeed" -> 3, "Proposer" -> Function[{program, examples, count}, {"Add[Var,Const[7]]"}] ]["Solved"]
```

## Simplification

A simplifier can eliminate an unselected branch. It cannot generally replace
zero multiplied by an expression with zero, because the expression may never
terminate. SimplifyRecursor conservatively preserves this case:

Preserve a potentially divergent strict operand:

```wl
SimplifyRecursor[Mul[Const[0], WhileLoop[Const[0], Const[1], Acc]]]
```
