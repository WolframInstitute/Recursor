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

- Each node is a box with the name of its constructor, constant or variable. Its color gives its kind: loops, arithmetic, choice and binding, or inputs and constants.
- The root is at the top. With `ImageSize -> Automatic` the picture is as wide as its tree, up to a limit, so names have the same size in every tree.
- The result is a graph. Its vertices number the nodes in the order of [RecursorSites](). Constants and variable atoms are leaves. Repeated subexpressions have separate vertices.
- Accepts TreeGraph options. A value for `VertexStyle`, `VertexLabelStyle`, `EdgeStyle`, `EdgeShapeFunction`, `PlotRange` or `ImageSize` replaces that part of the design.
- A value for `VertexLabels`, `VertexShapeFunction`, `GraphLayout`, `VertexCoordinates` or `GraphRoot` gives the TreeGraph drawing instead. `VertexLabels -> None` omits the names.

## Basic Examples

Evaluate a small example:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```

## Options

Give every node one color:

```wl
RecursorProgramTree[RecursorExamples["Factorial"], VertexStyle -> LightGray]
```

---

Choose another layout, which gives the TreeGraph drawing:

```wl
RecursorProgramTree[RecursorExamples["Factorial"], GraphLayout -> "RadialEmbedding"]
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
