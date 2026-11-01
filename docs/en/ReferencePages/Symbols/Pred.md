---
Template: Symbol
Name: Pred
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Pred
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Pred]()[*expression*]</code> subtracts one, stopping at zero.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Pred[Const[0]] denotes zero.

## Basic Examples

Represent the node as inert program syntax:

```wl
Pred[Var]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[Pred[Var], n], {n, 0, 4}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Pred[Var]]
```

## Applications

Plot saturation at the lower boundary:

```wl
ListLinePlot[Table[EvaluateRecursor[Iter[Const[4],Var,Pred[Acc]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Inspect a loop that decrements to zero:

```wl
RecursorProgramTree[WhileLoop[Var,Acc,Pred[Acc]]]
```
