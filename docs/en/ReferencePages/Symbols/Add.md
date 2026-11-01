---
Template: Symbol
Name: Add
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Add
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Add]()[*a*, *b*]</code> adds two values.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Both arguments are evaluated, from left to right.

## Basic Examples

Represent the node as inert program syntax:

```wl
Add[Var,Const[3]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Add[Var, Const[3]], 5]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Add[Var,Const[3]]]
```

## Applications

Sum successive integers:

```wl
ListLinePlot[{Table[EvaluateRecursor[Rec[Var,Const[0],Add[Acc,Succ[Idx]]], n], {n, 0, 10}], Range[0,10] (Range[0,10]+1)/2}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Compute Fibonacci values from two earlier terms:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 12}], DataRange -> {0, 12}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
