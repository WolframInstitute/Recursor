---
Template: Symbol
Name: Ifz
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Ifz
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Ifz]()[*condition*, *zero*, *positive*]</code> branches on zero.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- The condition is evaluated fully. Only the selected branch is evaluated. A nonzero condition selects positive.

## Basic Examples

Represent the node as inert program syntax:

```wl
Ifz[Var,Const[1],Const[0]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Ifz[Var, Const[10], Const[20]], 0]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Ifz[Var,Const[1],Const[0]]]
```

## Applications

Select a parity-dependent update:

```wl
ListLinePlot[Table[EvaluateRecursor[Ifz[Rem[Var,Const[2]],Half[Var],Succ[Mul[Const[3],Var]]], n], {n, 0, 20}], DataRange -> {0, 20}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Plot a threshold response:

```wl
ListLinePlot[Table[EvaluateRecursor[Ifz[Monus[Var,Const[5]],Const[1],Var], n], {n, 0, 12}], DataRange -> {0, 12}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```
