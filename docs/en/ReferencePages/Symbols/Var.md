---
Template: Symbol
Name: Var
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Var
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Var]()</code> is the program input.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- The input is a nonnegative integer and remains visible inside Iter, Rec, CoRec and WhileLoop.
- Inside the body of Let, Var is the value bound by the nearest enclosing Let.

## Basic Examples

Represent the node as inert program syntax:

```wl
Var
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Var, 7]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Var]
```

## Applications

Compare identity evaluation with the input sequence:

```wl
ListLinePlot[{Table[EvaluateRecursor[Var, n], {n, 0, 10}], Range[0, 10]}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Inspect input reuse in a polynomial:

```wl
RecursorProgramTree[Add[Mul[Var,Var],Var]]
```
