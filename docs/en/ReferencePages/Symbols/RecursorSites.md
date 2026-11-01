---
Template: Symbol
Name: RecursorSites
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorSites
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorSites]()[*expression*]</code> lists its subtrees and scopes.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Each association has Path, Expression and Bindings.
- Paths are lists of one-based child positions; {} is the root. Const has no traversable children.

## Basic Examples

Evaluate a small example:

```wl
RecursorSites[Succ[Var]]
```

## Applications

Measure available bindings at each recursion site:

```wl
BarChart[Length /@ Lookup[RecursorSites[RecursorExamples["Factorial"]],"Bindings"], AxesLabel->{"Site","Available bindings"} ]
```

---

Inspect the corresponding syntax tree:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
