---
Template: Symbol
Name: Quot
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Quot
RelatedGuides: [Language, Recursor]
SeeAlso: [Rem, Half]
RelatedTutorials: [ArithmeticPatterns, LanguageSemantics]
---

## Usage

<code>[Quot]()[*a*, *b*]</code> computes an integer quotient.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Both arguments are evaluated. If b is zero, the result is zero; otherwise it is Quotient[a,b].
- Add[Mul[b, Quot[a, b]], Rem[a, b]] equals a for every b, including zero.

## Basic Examples

Represent the node as inert program syntax:

```wl
Quot[Var,Const[3]]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[Quot[Const[7], Const[d]], 0], {d, 0, 4}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Quot[Var,Const[3]]]
```

## Applications

Show quotients for divisors one through four:

```wl
ListStepPlot[Table[EvaluateRecursor[Quot[Var, Const[d]], n], {d, 1, 4}, {n, 0, 24}], DataRange -> {0, 24}, PlotLegends -> Range[4], Frame -> True, FrameLabel -> {"Input", "Quotient"}]
```

---

Sum decimal digits by reading the result for the quotient by ten:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples["DigitSum"], n], {n, 0, 120}], DataRange -> {0, 120}, Frame -> True, FrameLabel -> {"Input", "Digit sum"}]
```

## Properties and Relations

A quotient and a remainder reconstruct the dividend:

```wl
Table[EvaluateRecursor[Add[Mul[Const[d], Quot[Var, Const[d]]], Rem[Var, Const[d]]], 17], {d, 0, 6}]
```
