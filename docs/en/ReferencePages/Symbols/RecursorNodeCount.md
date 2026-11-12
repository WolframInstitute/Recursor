---
Template: Symbol
Name: RecursorNodeCount
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorNodeCount
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorNodeCount]()[*expression*]</code> counts syntax nodes.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Const[n] counts as one node. Literal integer payloads and expression heads are not counted separately.

## Basic Examples

Evaluate a small example:

```wl
RecursorNodeCount[WhileLoop[Var, Acc, Pred[Acc]]]
```

## Applications

Compare structural sizes of example programs:

```wl
BarChart[RecursorNodeCount /@ Lookup[RecursorExamples[],{"Square","Factorial","Fibonacci","PopulationCount"}], ChartLabels->{"Square","Factorial","Fibonacci","Popcount"}, Frame->True, FrameLabel->{None,"Nodes"} ]
```

---

Relate a size count to its visible tree:

```wl
RecursorProgramTree[RecursorExamples["PopulationCount"]]
```
