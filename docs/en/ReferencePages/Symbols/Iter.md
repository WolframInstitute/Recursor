---
Template: Symbol
Name: Iter
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Iter
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Iter]()[*count*, *base*, *step*]</code> repeats a step a bounded number of times.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- count is evaluated first, then base, even when count is zero. Each step binds Acc. The iteration count is fixed before the loop starts.

## Basic Examples

Represent the node as inert program syntax:

```wl
Iter[Var,Const[1],Mul[Const[2],Acc]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Iter[Var, Const[1], Mul[Const[2], Acc]], 5]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Iter[Var,Const[1],Mul[Const[2],Acc]]]
```

## Applications

Construct powers of two:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["PowerOfTwo"], n], {n, 0, 10}], 2^Range[0,10]}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Observe periodic modular doubling:

```wl
ListLinePlot[Table[EvaluateRecursor[Iter[Var,Const[1],Rem[Mul[Const[2],Acc],Const[7]]], n], {n, 0, 24}], DataRange -> {0, 24}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```
