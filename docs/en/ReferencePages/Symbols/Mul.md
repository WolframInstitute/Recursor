---
Template: Symbol
Name: Mul
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Mul
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Mul]()[*a*, *b*]</code> multiplies two values.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- Both arguments are evaluated, even if one is zero. A diverging argument makes the multiplication diverge.

## Basic Examples

Represent the node as inert program syntax:

```wl
Mul[Var,Var]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Mul[Var, Var], 5]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Mul[Var,Var]]
```

## Applications

Compare a square program with arithmetic:

```wl
ListLinePlot[{Table[EvaluateRecursor[Mul[Var,Var], n], {n, 0, 10}], Range[0,10]^2}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Measure factorial growth:

```wl
ListLogPlot[Table[EvaluateRecursor[RecursorExamples["Factorial"], n], {n,0,10}], DataRange -> {0,10}, Frame -> True, FrameLabel -> {"Input", "Factorial"} ]
```
