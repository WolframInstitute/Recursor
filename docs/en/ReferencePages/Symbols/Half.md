---
Template: Symbol
Name: Half
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Half
RelatedGuides: [Language, Recursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[Half]()[*expression*]</code> gives the integer quotient by two.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. -->

## Details & Options

- This is inert Recursor syntax.
- The result is Floor[e/2].

## Basic Examples

Represent the node as inert program syntax:

```wl
Half[Var]
```

---

Evaluate it in a closed program:

```wl
Table[EvaluateRecursor[Half[Var], n], {n, 0, 6}]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Half[Var]]
```

## Applications

Plot integer division as a staircase:

```wl
ListLinePlot[Table[EvaluateRecursor[Half[Var], n], {n, 0, 24}], DataRange -> {0, 24}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Follow repeated binary shifts from 255:

```wl
ListStepPlot[NestList[EvaluateRecursor[Half[Var], #] &, 255, 9], DataRange -> {0,9}, AxesLabel -> {"Update", "Value"}, PlotRange -> All ]
```
