---
Template: Symbol
Name: CGet
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/CGet
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[CGet]()[*index*]</code> reads an earlier course-of-values result.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- It belongs inside the step of a CoRec. The nearest enclosing CoRec supplies history. Current and future indices give zero.

## Basic Examples

Represent the node as inert program syntax:

```wl
CGet[Pred[Idx]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[CoRec[Const[4], Ifz[Idx, Const[2], Succ[CGet[Pred[Idx]]]]], 0]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[CoRec[Var,Ifz[Idx,Const[0],Succ[CGet[Pred[Idx]]]]]]
```

## Applications

Reuse two earlier Fibonacci values:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 12}], DataRange -> {0, 12}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Inspect the divide-and-conquer history lookup:

```wl
RecursorProgramTree[RecursorExamples["PopulationCount"]]
```
