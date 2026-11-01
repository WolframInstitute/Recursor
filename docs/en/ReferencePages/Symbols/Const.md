---
Template: Symbol
Name: Const
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Const
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Const]()[*n*]</code> denotes a natural-number constant.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- n must be an exact nonnegative integer. A constant is one syntax node regardless of its magnitude.

## Basic Examples

Represent the node as inert program syntax:

```wl
Const[7]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Const[12345678901234567890], 0]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Const[7]]
```

## Applications

Control the slope through a constant multiplier:

```wl
ListLinePlot[Table[EvaluateRecursor[Mul[Const[3],Var], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Set a threshold in a piecewise program:

```wl
ListLinePlot[Table[EvaluateRecursor[Ifz[Monus[Var,Const[6]],Const[2],Const[8]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
