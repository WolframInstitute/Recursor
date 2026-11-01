---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/Recursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
Description: A universal natural-number language for program synthesis and evolution
ContributedBy: Wolfram Institute
Keywords: [computability, program synthesis, genetic programming, lambda calculus]
MainGuide: Documentation/English/Guides/Recursor.nb
WolframVersion: 15.0+
Categories: [Core Language & Structure]
---

## Details & Options

- A compact natural-number DSL with bounded recursion and unbounded iteration.
- Programs can be interpreted directly or compiled to closed lambda terms.
- Scope-aware generation, mutation and crossover support evolutionary experiments.
- Evaluation limits return structured failures.
- A Lean proof translates mathlib partial-recursive codes to closed DSL programs with the same partial denotation.
- Documentation is authored in Markdown and built with PacletPage.

## Usage

[EvaluateRecursor]() evaluates a program on a natural-number input.

## Basic Examples

Compute a factorial:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 6]
```

Draw its syntax tree:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
