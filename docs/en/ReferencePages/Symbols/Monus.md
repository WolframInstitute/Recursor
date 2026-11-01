---
Template: Symbol
Name: Monus
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Monus
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Monus]()[*a*, *b*]</code> subtracts b from a, stopping at zero.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Both arguments are evaluated. The result is Max[a-b,0].

## Basic Examples

Represent the node as inert program syntax:

```wl
Monus[Var,Const[3]]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[Monus[Var, Const[3]], n], {n, 0, 6}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Monus[Var,Const[3]]]
```

## Applications

Plot a clipped ramp:

```wl
ListLinePlot[Table[EvaluateRecursor[Monus[Var,Const[6]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Construct distance from a fixed point:

```wl
ListLinePlot[Table[EvaluateRecursor[Add[Monus[Var,Const[6]],Monus[Const[6],Var]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
