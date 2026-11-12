---
Template: Symbol
Name: FormatRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/FormatRecursor
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[FormatRecursor]()[*expression*]</code> serializes source.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Writes only the Recursor grammar, with no context prefixes.
- Closed programs round-trip through ParseRecursor.

## Basic Examples

Evaluate a small example:

```wl
FormatRecursor[RecursorExamples["Factorial"]]
```

## Applications

Round-trip source before inspecting a program:

```wl
RecursorProgramTree[ParseRecursor[FormatRecursor[RecursorExamples["Factorial"]]]]
```

---

Compare serialization lengths of four programs:

```wl
BarChart[StringLength[FormatRecursor[#]] & /@ Lookup[RecursorExamples[],{"Square","Factorial","Fibonacci","PopulationCount"}], ChartLabels->{"Square","Factorial","Fibonacci","Popcount"}, Frame->True, FrameLabel->{None,"Characters"} ]
```
