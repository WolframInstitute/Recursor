---
Template: Symbol
Name: RecursorExpressionQ
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorExpressionQ
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorExpressionQ]()[*expression*]</code> checks syntax.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Checks every head, arity and constant.
- Open expressions are allowed; use RecursorProgramQ to check binding.

## Basic Examples

Evaluate a small example:

```wl
RecursorExpressionQ[Acc]
```

## Applications

Visualize the syntax of a valid open expression:

```wl
If[RecursorExpressionQ[Add[Acc,Idx]], RecursorProgramTree[Add[Acc,Idx]]]
```

---

Inspect a closed program admitted by the syntax checker:

```wl
If[RecursorExpressionQ[RecursorExamples["Factorial"]], RecursorProgramTree[RecursorExamples["Factorial"]]]
```
