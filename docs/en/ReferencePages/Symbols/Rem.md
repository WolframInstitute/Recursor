---
Template: Symbol
Name: Rem
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Rem
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Rem]()[*a*, *b*]</code> computes a remainder.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Both arguments are evaluated. If b is zero, the result is a; otherwise it is Mod[a,b].

## Basic Examples

Represent the node as inert program syntax:

```wl
Rem[Var,Const[3]]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[Rem[Const[7], Const[d]], 0], {d, 0, 4}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Rem[Var,Const[3]]]
```

## Applications

Show residue classes for divisors one through eight:

```wl
ArrayPlot[Table[EvaluateRecursor[Rem[Var,Const[d]], n], {d,1,8}, {n,0,31}], FrameLabel -> {"Divisor", "Input"}, PlotLegends -> Automatic, FrameTicks -> {Range[8], Table[{n+1,n},{n,0,31,4}]} ]
```

---

Plot a modular doubling orbit:

```wl
ListLinePlot[Table[EvaluateRecursor[Iter[Var,Const[1],Rem[Mul[Const[2],Acc],Const[7]]], n], {n, 0, 24}], DataRange -> {0, 24}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```
