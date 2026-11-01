---
Template: Symbol
Name: Acc
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Acc
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Acc]()</code> denotes the current accumulator.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Iter and Rec bind Acc in their step. WhileLoop binds it in its condition and step. The nearest enclosing binder wins. CoRec inherits an outer Acc; it does not introduce one.

## Basic Examples

Represent the node as inert program syntax:

```wl
Acc
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Iter[Const[3], Const[2], Succ[Acc]], 0]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Iter[Var,Const[0],Add[Acc,Const[3]]]]
```

## Applications

Accumulate a triangular-number sequence:

```wl
ListLinePlot[Table[EvaluateRecursor[Rec[Var,Const[0],Add[Acc,Succ[Idx]]], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Compare accumulation with the closed formula:

```wl
ListLinePlot[{Table[EvaluateRecursor[Rec[Var,Const[0],Add[Acc,Succ[Idx]]], n], {n, 0, 10}], Range[0,10] (Range[0,10]+1)/2}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
