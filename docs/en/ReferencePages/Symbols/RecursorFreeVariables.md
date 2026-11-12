---
Template: Symbol
Name: RecursorFreeVariables
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorFreeVariables
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorFreeVariables]()[*expression*]</code> gives the unbound binding symbols.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Returns a subset of {Acc, Idx, CGet}. Var is the program input.
- Only bindings introduced by a child position are removed.

## Basic Examples

Evaluate a small example:

```wl
RecursorFreeVariables[Rec[Var, Const[0], Add[Acc, CGet[Idx]]]]
```

## Scope

Observe that a loop base is outside its own accumulator binding:

```wl
RecursorFreeVariables[WhileLoop[Acc, Acc, Pred[Acc]]]
```

## Applications

Measure free bindings across factorial subtrees:

```wl
With[{sites=RecursorSites[RecursorExamples["Factorial"]]}, BarChart[Length[RecursorFreeVariables[#]] & /@ Lookup[sites,"Expression"], Frame->True, FrameLabel->{"Subtree","Free bindings"}] ]
```

---

Inspect the program whose binders close the subtrees:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
