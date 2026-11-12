---
Template: Symbol
Name: Succ
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Succ
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Succ]()[*expression*]</code> adds one to e.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Its argument is evaluated before addition. Arithmetic uses arbitrary-precision integers.

## Basic Examples

Represent the node as inert program syntax:

```wl
Succ[Var]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Succ[Var], 4]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Succ[Var]]
```

## Applications

Generate an affine recurrence:

```wl
ListLinePlot[Table[EvaluateRecursor[Iter[Var,Const[1],Succ[Acc]], n], {n, 0, 12}], DataRange -> {0, 12}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Inspect the successor in a factorial program:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
