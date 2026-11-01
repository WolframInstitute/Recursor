---
Template: Symbol
Name: Idx
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Idx
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Idx]()</code> denotes the current recursion index.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Rec binds indices 0 through count - 1. CoRec binds indices 0 through count. Iter and WhileLoop inherit an outer index without introducing one.

## Basic Examples

Represent the node as inert program syntax:

```wl
Idx
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Rec[Const[3], Const[0], Add[Acc, Idx]], 0]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Rec[Var,Const[0],Add[Acc,Idx]]]
```

## Applications

Use the recursion index to construct triangular numbers:

```wl
ListLinePlot[Table[EvaluateRecursor[Rec[Var,Const[0],Add[Acc,Idx]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Build a factorial from successive indices:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["Factorial"], n], {n, 0, 6}], Factorial[Range[0,6]]}, DataRange -> {0, 6}, PlotLegends -> {"Recursor", "Reference"}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
