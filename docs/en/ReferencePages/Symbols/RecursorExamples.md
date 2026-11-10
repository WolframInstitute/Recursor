---
Template: Symbol
Name: RecursorExamples
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorExamples
RelatedGuides: [Evaluation, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[RecursorExamples]()[]</code> gives an association of named programs.

<code>[RecursorExamples]()[*name*]</code> gives a named program.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Names are Catalan, Countdown, DigitSum, DivisorCount, Factorial, Fibonacci, Nonterminating, PopulationCount, PowerOfTwo, Prime and Square.
- Prime gives the primes from input zero. It searches upward and tests each candidate with DivisorCount through Let.
- Unknown names return Missing. The Nonterminating example needs a finite evaluation budget.

## Basic Examples

Evaluate a small example:

```wl
RecursorExamples[]
```

## Scope

Select one named program:

```wl
RecursorExamples["PopulationCount"]
```

## Applications

Compare two sequence programs:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples[name],n], {name,{"Fibonacci","PopulationCount"}},{n,0,12}], DataRange->{0,12}, PlotLegends->{"Fibonacci","Population count"}, AxesLabel->{"Input","Output"} ]
```

---

Inspect the factorial example:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```
