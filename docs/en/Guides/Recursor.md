---
Template: Guide
Name: Recursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/guide/Recursor
Title: Recursor
Description: Recursor tools for computing with natural-number programs
Keywords: [program synthesis, computation, Recursor]
RelatedGuides: [Compilation, Evaluation, Evolution, Language, Visualization]
RelatedTutorials: [FormalVerification, ProgramsForAI,VisualizingLambdaCompilation, ArithmeticPatterns, EvolutionaryExperiments, EvolvingPrograms, HaltingAndBudgets, LanguageSemantics, MigratingNotebooks, UniversalComputation]
---

## Abstract

Recursor is a natural-number language for program synthesis and evolutionary
experiments. It supports unbounded WhileLoop iteration.
Programs have explicit lexical binding and compile to closed lambda terms.

## Functions

### [Language](paclet:WolframInstitute/Recursor/guide/Language)

- `RecursorExpressionQ` check expression syntax
- `RecursorProgramQ` check syntax and lexical closure
- `ParseRecursor` read portable source text
- `FormatRecursor` serialize a program

### [Evaluation](paclet:WolframInstitute/Recursor/guide/Evaluation)

- `EvaluateRecursor` compute a natural-number result under explicit budgets
- `RecursorExamples` select named example programs

### [Compilation](paclet:WolframInstitute/Recursor/guide/Compilation)

- `ToRecursor` translate a counter machine into DSL syntax
- `CompileRecursor` construct a closed lambda term
- `NormalizeRecursor` normalize a compiled function

### [Evolution](paclet:WolframInstitute/Recursor/guide/Evolution)

- `RandomRecursor` generate closed programs
- `MutateRecursor` replace a subtree within its scope
- `CrossoverRecursor` exchange scope-compatible subtrees
- `SimplifyRecursor` simplify with partial computations in mind
- `ScoreRecursor` count exact matches on examples
- `EvolveRecursor` evolve a population against training data

### [Visualization](paclet:WolframInstitute/Recursor/guide/Visualization)

- `RecursorProgramTree` inspect syntax
- `RecursorEvolutionPlot` compare fitness over generations
- `RecursorGenealogyGraph` inspect recorded parent-child relationships

### External libraries

- `RecursorLibraries` inspect external libraries and their status
- `InstallRecursorLibraries` install LeanLink, mathlib or Lambda
