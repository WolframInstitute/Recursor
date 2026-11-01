---
Template: TechNote
Name: ProgramsForAI
Title: A Small Program Language for AI
Description: Compare candidate programs, inspect scope and compile to lambda expressions
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/ProgramsForAI
Keywords: [program synthesis, artificial intelligence, lambda calculus]
RelatedGuides: [Recursor, Compilation, Evolution, Language]
RelatedTutorials: [FormalVerification, EvolvingPrograms, VisualizingLambdaCompilation]
---

## Programs as explicit proposals

A compact DSL gives an AI a small language for proposing and transforming
programs. Each proposal has a finite syntax tree, explicit binding rules and
a specified execution model. The same representation can be parsed, tested,
mutated and compiled. This makes experiments easier to reproduce and their
assumptions easier to state.

The experiment here compares three hand-written proposals for successor.
It demonstrates the interface an AI can use; it does not measure an AI model.
Research systems such as [DreamCoder](https://arxiv.org/abs/2006.08381) also use
program languages and learned abstractions to organize program search.
Recursor supplies a small language and experimental tools, rather than a
claim that universality alone improves learning.

Parse three proposals:

```wl
candidates = ParseRecursor /@ <|"Successor" -> "Succ[Var]", "Addition" -> "Add[Var,Const[1]]", "Guarded" -> "Ifz[Monus[Var,Const[4]],Succ[Var],Const[0]]"|>
```

The parser accepts the DSL grammar, without evaluating source as arbitrary
Wolfram Language. Inspect the conditional proposal:

```wl
RecursorProgramTree[candidates["Guarded"]]
```

## A finite fit is a finite observation

Use inputs zero through four as training examples. Fitness counts exact
matches under the evaluator's resource limits:

```wl
training = Table[{n, n + 1}, {n, 0, 4}]
```

Compare the three training scores:

```wl
BarChart[Values[ScoreRecursor[#, training] & /@ candidates], ChartLabels -> Keys[candidates], AxesLabel -> {None, "Exact matches"}]
```

All three fit this sample. Evaluate the same proposals through input nine:

```wl
ListLinePlot[Table[EvaluateRecursor[p, n], {p, Values[candidates]}, {n, 0, 9}], DataRange -> {0, 9}, PlotLegends -> Keys[candidates], AxesLabel -> {"Input", "Output"}]
```

The guarded program returns zero after the training range. An AI workflow
needs holdout experiments, explicit specifications or proofs in addition to
training fit. Even agreement on a much larger finite sample would not prove
that two arbitrary programs are equivalent.

## Scope is part of the proposal

Recursion exposes an accumulator and, for Rec, an iteration index. A change
must respect which of those variables are available at each syntax position.
Inspect the factorial program and its binding sites:

```wl
factorial = RecursorExamples["Factorial"]
```

Draw its syntax tree:

```wl
RecursorProgramTree[factorial]
```

Inspect the available bindings at each position:

```wl
Grid[Prepend[({#["Path"], #["Expression"], #["Bindings"]} & /@ RecursorSites[factorial]), {"Path", "Expression", "Bindings"}]]
```

The generator, mutation and crossover functions use these binding rules.
Closure is a syntactic property; it does not imply termination or correctness
for a target task. See the evolutionary experiments for reproducible searches.

## A portable lambda representation

A DSL whose constructs have fixed meanings can be compiled compositionally:
translate each construct and preserve its binding and evaluation rules.
Recursor uses Church numerals, lambda abstraction and application, with a
fixed-point combinator for unbounded loops. The target does not need the
Wolfram definitions of Recursor's syntax heads.

Load the optional lambda visualization tools:

```wl
Needs["Wolfram`Lambda`"]
```

Inspect the compiled successor term:

```wl
LambdaTree[CompileRecursor[candidates["Successor"]]]
```

Compare the direct and lambda evaluators on six inputs:

```wl
Grid[Prepend[Table[{n, EvaluateRecursor[candidates["Successor"], n], EvaluateRecursor[candidates["Successor"], n, Method -> "Lambda"]}, {n, 0, 5}], {"Input", "Direct", "Lambda"}]]
```

This comparison is a regression check. A compiler-correctness theorem must
also address every construct, variable binding and divergent computation.
The formal verification tutorial states which such obligations are checked.
Portable meaning also does not imply efficient reduction: encodings can
increase term size and execution cost substantially.

## Why not translate arbitrary Wolfram Language?

Wolfram Language can implement the host system and a compiler. Its full
semantics also include definitions attached to symbols, attributes that alter
evaluation, pattern-based rewriting, held arguments and side effects.
Faithfully translating arbitrary expressions would require specifying and
reproducing the relevant parts of that runtime. The official
[evaluation tutorial](https://reference.wolfram.com/language/tutorial/EvaluationOfExpressions.html)
describes these interacting rules.

A restricted WL subset could be a compilation target or source. Defining that
subset, its environments and its execution rules would itself amount to
choosing a language with explicit semantics. Recursor makes that choice small
and visible from the start. Wolfram Language remains useful for proposing
experiments, analyzing exact results and producing scientific visualizations.
