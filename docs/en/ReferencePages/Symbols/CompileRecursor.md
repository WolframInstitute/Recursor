---
Template: Symbol
Name: CompileRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/CompileRecursor
RelatedGuides: [Compilation, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [VisualizingLambdaCompilation, HaltingAndBudgets]
---

## Usage

<code>[CompileRecursor]()[*program*]</code> gives a closed lambda term.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Abstraction uses the protected formal symbol \[FormalLambda]. Variables are one-based de Bruijn indices. Application is represented by f[a].
- The result is a function from a Church numeral to a Church numeral. WhileLoop uses a fixed-point combinator.
- Arithmetic arguments, recursion bases and intermediate states are sequenced so normal-order reduction preserves the interpreter's strictness. Ifz keeps its branches lazy.
- No external Lambda paclet or notebook definitions are needed.

## Basic Examples

Evaluate a small example:

```wl
CompileRecursor[Var]
```

## Applications

Measure compiled expression sizes:

```wl
BarChart[LeafCount[CompileRecursor[#]] & /@ {Var,Succ[Var],Mul[Var,Var],WhileLoop[Var,Acc,Pred[Acc]]}, ChartLabels->{"Input","Successor","Square","Countdown"}, AxesLabel->{None,"Lambda leaves"} ]
```

---

Compare the two evaluation methods on a small square:

```wl
ListLinePlot[Table[EvaluateRecursor[Mul[Var,Var],n,Method->method], {method,{"Interpreter","Lambda"}},{n,0,4}], DataRange->{0,4}, PlotLegends->{"Interpreter","Lambda"}, AxesLabel->{"Input","Output"} ]
```

---

Load the optional Wolfram/Lambda visualization tools:

```wl
Needs["Wolfram`Lambda`"]
```

Draw the lambda structure directly:

```wl
LambdaTree[CompileRecursor[Succ[Var]]]
```

