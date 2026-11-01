---
Template: TechNote
Name: ArithmeticPatterns
Title: Arithmetic Patterns from Small Programs
Description: Reproducible computations with the Recursor language
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/ArithmeticPatterns
Keywords: [computational essay, natural numbers, program behavior]
RelatedGuides: [Evaluation, Language, Recursor, Visualization]
RelatedTutorials: [LanguageSemantics, UniversalComputation]
---

## Recurrences as program trees

How much numerical structure can a small natural-number program express?
The factorial, Fibonacci and population-count programs come from the original
DSL examples. The plots below use inputs zero through the stated finite
bounds; these are computations of those examples, not new sequence identities.

Inspect a factorial program:

```wl
RecursorProgramTree[RecursorExamples["Factorial"]]
```

The recursion index supplies the next factor and the accumulator holds the
product already computed. Compare outputs with the built-in factorial:

```wl
ListLogPlot[{Table[EvaluateRecursor[RecursorExamples["Factorial"],n],{n,0,10}],Factorial[Range[0,10]]}, DataRange->{0,10}, PlotLegends->{"Recursor","Factorial"}, AxesLabel->{"Input","Factorial"}]
```

## Reusing history

Fibonacci needs two earlier values rather than only the previous accumulator.
CoRec makes these values available through CGet. Compare the two sequence
computations on inputs zero through fourteen:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["Fibonacci"],n],{n,0,14}],Fibonacci[Range[0,14]]}, DataRange->{0,14}, PlotLegends->{"Recursor","Fibonacci"}, AxesLabel->{"Input","Value"}]
```

The population-count recurrence looks up the halved index and adds its parity.
The binary digits make the input structure visible. Show all six-bit inputs:

```wl
ArrayPlot[Transpose[IntegerDigits[Range[0,63],2,6]], FrameLabel->{"Bit position","Input"}, FrameTicks->{{{1,5},{6,0}},Table[{n+1,n},{n,0,63,8}]}]
```

Compare the corresponding counts of one-digits:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["PopulationCount"],n],{n,0,63}],DigitCount[Range[0,63],2,1]}, DataRange->{0,63}, PlotLegends->{"Recursor","DigitCount"}, AxesLabel->{"Input","One-digits"}, PlotRange->All]
```

## Residues and finite orbits

A residue array exposes repeated arithmetic patterns. Rows use divisors one
through eight; columns use inputs zero through thirty-one:

```wl
ArrayPlot[Table[EvaluateRecursor[Rem[Var,Const[d]],n],{d,1,8},{n,0,31}], FrameLabel->{"Divisor","Input"}, FrameTicks->{Range[8],Table[{n+1,n},{n,0,31,4}]}, PlotLegends->Automatic]
```

Iterating multiplication by two modulo seven gives a finite orbit. The input
now specifies how many updates to apply to the initial value one:

```wl
ListStepPlot[Table[EvaluateRecursor[Iter[Var,Const[1],Rem[Mul[Const[2],Acc],Const[7]]],n],{n,0,24}], DataRange->{0,24}, AxesLabel->{"Updates","Residue"}, PlotRange->{0,7}]
```

## Size and behavior

The source trees are small even when the values grow rapidly. Compare their
node counts; this counts syntax, not arithmetic cost or memory use:

```wl
BarChart[RecursorNodeCount /@ Lookup[RecursorExamples[],{"Square","Factorial","Fibonacci","PopulationCount"}], ChartLabels->{"Square","Factorial","Fibonacci","Popcount"}, AxesLabel->{None,"Syntax nodes"}]
```

Bounded recursion is sufficient for these finite arithmetic constructions.
The separate universal-computation tutorial explains what unbounded iteration
adds and why large values alone do not establish universal computation.
