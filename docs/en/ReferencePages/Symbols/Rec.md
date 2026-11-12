---
Template: Symbol
Name: Rec
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Rec
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Rec]()[*count*, *base*, *step*]</code> performs primitive recursion.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- count is evaluated first, then base. Each step binds Acc and Idx; Idx starts at zero. The result at count zero is base.

## Basic Examples

Represent the node as inert program syntax:

```wl
Rec[Var,Const[1],Mul[Succ[Idx],Acc]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Rec[Var, Const[1], Mul[Succ[Idx], Acc]], 5]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Rec[Var,Const[1],Mul[Succ[Idx],Acc]]]
```

## Applications

Compute factorials:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["Factorial"], n], {n, 0, 6}], Factorial[Range[0,6]]}, DataRange -> {0, 6}, PlotLegends -> {"Recursor", "Reference"}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Count multiples to express integer division:

```wl
ListLinePlot[Table[EvaluateRecursor[Rec[Var,Const[0],Ifz[Rem[Succ[Idx],Const[3]],Succ[Acc],Acc]], n], {n, 0, 24}], DataRange -> {0, 24}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```
