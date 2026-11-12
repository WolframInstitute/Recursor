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
License: MIT
WolframVersion: 15.0+
Categories: [Core Language & Structure]
---

## Basic Description

Recursor is a small language of programs on natural numbers. Evaluate programs
under explicit budgets, compile them to lambda terms, find them from the terms
of a sequence and evolve them.

### Language

- Arithmetic: Succ, Pred, Half, Add, Mul, Monus, Quot and Rem
- Recursion: Rec, Iter and CoRec, with unbounded WhileLoop
- Choice and binding: Ifz, Let and CGet
- Universality: a Lean proof gives every partial recursive function a program

## Details & Options

- A compact natural-number DSL with bounded recursion and unbounded iteration.
- Programs can be interpreted directly or compiled to closed lambda terms.
- A deterministic synthesizer finds programs from examples by enumeration, recurrences checked against the data, exact solving and composition of loops. It counts a program as solved only when it predicts examples kept from the search.
- Programs translate to Wolfram Language functions.
- Scope-aware generation, mutation and crossover support evolutionary experiments. Guided variation works backwards from the examples to the part a program is missing.
- Evaluation limits return structured failures.
- A Lean proof translates mathlib partial-recursive codes to closed DSL programs with the same partial denotation.
- Documentation is authored in Markdown and built with PacletPage.

## Basic Examples

Compute a factorial:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 6]
```

Draw its syntax tree:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
