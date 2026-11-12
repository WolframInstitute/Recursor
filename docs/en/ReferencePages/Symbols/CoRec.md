---
Template: Symbol
Name: CoRec
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/CoRec
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[CoRec]()[*count*, *step*]</code> performs course-of-values recursion.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Computes step at indices zero through count, inclusive. Each step binds Idx and CGet. Earlier results are available through CGet; current and future indices return zero. All steps are evaluated. It does not bind Acc.

## Basic Examples

Represent the node as inert program syntax:

```wl
CoRec[Var,Ifz[Idx,Const[0],Succ[CGet[Pred[Idx]]]]]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 8}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[CoRec[Var,Ifz[Idx,Const[0],Succ[CGet[Pred[Idx]]]]]]
```

## Applications

Compare Fibonacci values with the built-in sequence:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 10}], Fibonacci[Range[0,10]]}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Measure the number of binary one-digits:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples["PopulationCount"], n], {n, 0, 31}], DataRange -> {0, 31}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```
