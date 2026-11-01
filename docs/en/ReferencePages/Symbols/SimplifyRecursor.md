---
Template: Symbol
Name: SimplifyRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/SimplifyRecursor
RelatedGuides: [Evolution, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[SimplifyRecursor]()[*program*]</code> simplifies while preserving partial behavior.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Folds constants and removes arithmetic identities.
- It may remove an unselected branch. It does not discard a potentially diverging strict operand.
- Bounded subexpressions are known to terminate; this conservative check can miss other safe simplifications.

## Basic Examples

Evaluate a small example:

```wl
SimplifyRecursor[Add[Mul[Const[3], Const[4]], Pred[Const[0]]]]
```

## Applications

Compare original and simplified syntax:

```wl
GraphicsRow[RecursorProgramTree /@ {Add[Mul[Var,Const[1]],Const[0]],SimplifyRecursor[Add[Mul[Var,Const[1]],Const[0]]]}]
```

---

Check a simplification through behavior curves:

```wl
ListLinePlot[Table[EvaluateRecursor[p,n], {p,{Add[Mul[Var,Const[1]],Const[0]],SimplifyRecursor[Add[Mul[Var,Const[1]],Const[0]]]}},{n,0,10}], DataRange->{0,10}, PlotLegends->{"Original","Simplified"}, AxesLabel->{"Input","Output"} ]
```
