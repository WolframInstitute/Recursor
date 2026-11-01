---
Template: Symbol
Name: WhileLoop
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/WhileLoop
RelatedGuides: [Language, Recursor]
RelatedTutorials: [HaltingAndBudgets]
---

## Usage

<code>[WhileLoop]()[*base*, *condition*, *step*]</code> repeats while condition is nonzero.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- base is evaluated once. Acc is bound in condition and step, but not in base. A zero condition returns the current Acc. Otherwise step becomes the next Acc and the condition is tested again. There is no language-level bound on iterations. This construct can diverge. It does not bind Idx or CGet.

## Basic Examples

Represent the node as inert program syntax:

```wl
WhileLoop[Var,Acc,Pred[Acc]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 20]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[WhileLoop[Var,Acc,Pred[Acc]]]
```

## Applications

Map which countdown computations finish within each budget:

```wl
ArrayPlot[Table[Boole[IntegerQ[EvaluateRecursor[WhileLoop[Var,Acc,Pred[Acc]], n, "MaxSteps" -> budget]]], {budget,12,96,12}, {n,1,24}], FrameTicks -> {Table[{k,12 k},{k,1,8}], Table[{n,n},{n,1,24,4}]}, FrameLabel -> {"Step budget", "Input"}, PlotLegends -> Automatic ]
```

---

Visualize a parity-dependent terminating condition:

```wl
RecursorProgramTree[WhileLoop[Var,Pred[Acc],Ifz[Rem[Acc,Const[2]],Half[Acc],Succ[Mul[Const[3],Acc]]]]]
```
