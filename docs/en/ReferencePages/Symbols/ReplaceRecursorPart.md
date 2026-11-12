---
Template: Symbol
Name: ReplaceRecursorPart
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/ReplaceRecursorPart
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[ReplaceRecursorPart]()[*program*, *path*, *expression*]</code> replaces a subtree.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- e may use only bindings available at path. The result is closed.
- An invalid path or scope mismatch gives a Failure with the tag "InvalidArguments".
- Subtree insertion can intentionally use the nearest available binder; this is not alpha-renaming of a source program.

## Basic Examples

Evaluate a small example:

```wl
ReplaceRecursorPart[WhileLoop[Var, Acc, Pred[Acc]], {3}, Half[Acc]]
```

## Scope

Replace the entire program at the empty path:

```wl
ReplaceRecursorPart[Mul[Var, Var], {}, Succ[Var]]
```

## Applications

Compare a square with a subtree-edited linear program:

```wl
ListLinePlot[Table[EvaluateRecursor[p,n], {p,{Mul[Var,Var],ReplaceRecursorPart[Mul[Var,Var],{2},Const[3]]}},{n,0,12}], DataRange->{0,12}, PlotLegends->{"Square","Edited"}, Frame->True, FrameLabel->{"Input","Output"} ]
```

---

Draw a scope-correct loop edit:

```wl
RecursorProgramTree[ReplaceRecursorPart[WhileLoop[Var,Acc,Pred[Acc]],{3},Half[Acc]]]
```
