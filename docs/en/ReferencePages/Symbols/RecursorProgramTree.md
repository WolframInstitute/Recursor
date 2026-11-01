---
Template: Symbol
Name: RecursorProgramTree
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorProgramTree
RelatedGuides: [Recursor, Visualization]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorProgramTree]()[*program*]</code> draws a syntax tree.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Accepts TreeGraph options and inherits its presentation defaults, including `ImageSize -> Automatic`.
- `VertexLabels -> Automatic` labels vertices with syntax constructors, constants and variable names. Use `VertexLabels -> None` to omit them.
- Constants and variable atoms are leaves. Repeated subexpressions have separate vertices.

## Basic Examples

Evaluate a small example:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```

## Applications

Inspect course-of-values recursion:

```wl
RecursorProgramTree[RecursorExamples["Fibonacci"]]
```

---

Compare a program and its simplification:

```wl
GraphicsRow[RecursorProgramTree /@ {Mul[Var,Const[1]],SimplifyRecursor[Mul[Var,Const[1]]]}]
```
