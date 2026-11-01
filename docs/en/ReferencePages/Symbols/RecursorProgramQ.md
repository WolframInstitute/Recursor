---
Template: Symbol
Name: RecursorProgramQ
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorProgramQ
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorProgramQ]()[*program*]</code> checks a closed program.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Returns True exactly when syntax is valid and Acc, Idx and CGet are bound.
- There is no program-size limit in this predicate. The generator and parser have separate resource options.
- Validity does not imply termination.

## Basic Examples

Evaluate a small example:

```wl
RecursorProgramQ[WhileLoop[Var,Acc,Pred[Acc]]]
```

## Applications

Select a closed program before drawing its syntax:

```wl
RecursorProgramTree[First[Select[{Acc,Mul[Var,Var]},RecursorProgramQ]]]
```

---

Run only a validated source proposal:

```wl
With[{p=ParseRecursor["Mul[Var,Var]"]}, If[RecursorProgramQ[p], ListLinePlot[Table[EvaluateRecursor[p,n],{n,0,12}], DataRange->{0,12}, AxesLabel->{"Input","Output"}] ]]
```
