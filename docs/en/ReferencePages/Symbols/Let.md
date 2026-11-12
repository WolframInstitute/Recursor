---
Template: Symbol
Name: Let
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/Let
RelatedGuides: [Language, Recursor]
SeeAlso: [Var, Iter, CoRec]
RelatedTutorials: [LanguageSemantics, SynthesizingSequences]
---

## Usage

<code>[Let]()[*value*, *body*]</code> evaluates a body with a new input.

<!-- #| annotation: This page documents inert natural-number syntax, distinct from evaluating Wolfram expressions. Let is the only construct that rebinds Var, so it is how one closed program is applied inside another. -->

## Details & Options

- This is inert Recursor syntax.
- value is evaluated first, in the enclosing scope, also when body ignores it. body is then evaluated with Var bound to that value.
- Acc, Idx and CGet keep their enclosing bindings inside body. The nearest enclosing Let supplies Var.
- A closed program placed in body is applied to value.

## Basic Examples

Represent the node as inert program syntax:

```wl
Let[Add[Var,Const[2]],Mul[Var,Var]]
```

---

Evaluate it in a closed program:

```wl
EvaluateRecursor[Let[Add[Var, Const[2]], Mul[Var, Var]], 5]
```

---

Inspect its surrounding syntax:

```wl
RecursorProgramTree[Let[Add[Var,Const[2]],Mul[Var,Var]]]
```

## Scope

Apply a closed program to an expression:

```wl
Table[EvaluateRecursor[Let[Mul[Const[2], Var], RecursorExamples["Factorial"]], n], {n, 0, 5}]
```

---

Read an enclosing index and accumulator inside the body:

```wl
EvaluateRecursor[Rec[Var, Const[0], Add[Acc, Let[Idx, Mul[Var, Var]]]], 5]
```

## Applications

Add the divisor counts of the numbers below the input:

```wl
ListLinePlot[Table[EvaluateRecursor[Rec[Var, Const[0], Add[Acc, Let[Idx, RecursorExamples["DivisorCount"]]]], n], {n, 0, 40}], DataRange -> {0, 40}, Frame -> True, FrameLabel -> {"Input", "Sum of divisor counts"}]
```

---

Search for primes by applying a divisor test to each candidate:

```wl
ListPlot[Table[EvaluateRecursor[RecursorExamples["Prime"], n], {n, 0, 30}], DataRange -> {0, 30}, Frame -> True, FrameLabel -> {"Input", "Prime"}]
```

## Properties and Relations

The scope of a binding ends with its body:

```wl
EvaluateRecursor[Add[Let[Const[5], Var], Var], 7]
```
