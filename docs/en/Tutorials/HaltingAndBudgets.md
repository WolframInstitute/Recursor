---
Template: TechNote
Name: HaltingAndBudgets
Title: Halting, Trajectories and Evaluation Budgets
Description: Reproducible computations with the Recursor language
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/HaltingAndBudgets
Keywords: [computational essay, natural numbers, program behavior]
RelatedGuides: [Compilation, Evaluation, Recursor, Visualization]
RelatedTutorials: [LanguageSemantics, UniversalComputation]
---

## A loop with a known stopping rule

How does a finite execution budget change what is observed? A countdown loop
has a directly checkable answer: starting at a natural number n, it applies
predecessor n times and finishes at zero. Its interpreter visits 3n+3 syntax
nodes, including the final condition check.

Inspect its syntax:

```wl
RecursorProgramTree[WhileLoop[Var,Acc,Pred[Acc]]]
```

Plot the state after each update for an input of twelve:

```wl
ListStepPlot[NestList[EvaluateRecursor[Pred[Var],#] &,12,12], DataRange->{0,12}, Frame->True, FrameLabel->{"Update","Accumulator"}, PlotRange->All]
```

At input three, eleven visits are insufficient:

```wl
EvaluateRecursor[WhileLoop[Var,Acc,Pred[Acc]],3,"MaxSteps"->11]["Tag"]
```

Twelve visits suffice:

```wl
EvaluateRecursor[WhileLoop[Var,Acc,Pred[Acc]],3,"MaxSteps"->12]
```

Map completion over inputs 1 through 24 and budgets 12 through 96. A value of
one means a completed computation, zero means its step budget was exhausted:

```wl
ArrayPlot[Table[Boole[IntegerQ[EvaluateRecursor[WhileLoop[Var,Acc,Pred[Acc]],n,"MaxSteps"->budget]]], {budget,12,96,12},{n,1,24}], FrameTicks->{Table[{k,12 k},{k,1,8}],Table[{n,n},{n,1,24,4}]}, FrameLabel->{"Step budget","Input"}, PlotLegends->Automatic]
```

The sloping completion boundary records the loop's linear number of visits.
The zeros in this plot are censored computations, all of which would finish
with a large enough budget.

## A parity-dependent trajectory

The next step halves an even input and maps an odd input to three times its
value plus one. Its loop stops at one. The experiment considers inputs 7, 19
and 27 and at most 120 updates; it makes no claim about all starting values.

Define the one-step program:

```wl
parityStep = Ifz[Rem[Var,Const[2]],Half[Var],Succ[Mul[Const[3],Var]]]
```

Compute three bounded trajectories and compare them on a logarithmic vertical
scale:

```wl
ListLogPlot[trajectories = Table[NestWhileList[EvaluateRecursor[parityStep, #] &, start, # > 1 &, 1, 120], {start, {7, 19, 27}}], Joined -> True, PlotLegends -> {"7", "19", "27"}, Frame -> True, FrameLabel -> {"Recorded state", "Value"}, PlotRange -> All]
```

Draw the first eight updates from seven and nineteen as a shared graph.
Merging equal values shows where their trajectories meet; this bounded
prefix does not include their eventual arrival at one:

```wl
Graph[DeleteDuplicates[Catenate[DirectedEdge @@@ Partition[Take[#, UpTo[9]], 2, 1] & /@ Take[trajectories, 2]]], VertexLabels -> "Name", GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left}]
```

Compare the number of updates recorded before stopping or reaching the bound:

```wl
BarChart[Length /@ trajectories - 1, ChartLabels->{7,19,27}, Frame->True, FrameLabel->{"Initial value","Recorded updates"}]
```

Run the corresponding unbounded source construct under a finite interpreter
budget on the same three inputs:

```wl
Table[EvaluateRecursor[WhileLoop[Var,Pred[Acc], Ifz[Rem[Acc,Const[2]],Half[Acc],Succ[Mul[Const[3],Acc]]] ],start,"MaxSteps"->5000],{start,{7,19,27}}]
```

## Strictness matters

A lazy branch can omit a nonterminating computation; strict multiplication
cannot. Compare completion under the same budget for a lazy branch, a strict
zero product and an immediate zero-condition loop:

```wl
BarChart[Boole[IntegerQ[EvaluateRecursor[#,0,"MaxSteps"->100]]] & /@ { Ifz[Const[0],Const[7],WhileLoop[Const[0],Const[1],Acc]], Mul[Const[0],WhileLoop[Const[0],Const[1],Acc]], WhileLoop[Const[7],Const[0],Acc] }, ChartLabels->{"Lazy branch","Strict product","Zero condition"}, Frame->True, FrameLabel->{None,"Completed"}]
```

These outcomes explain why the extended simplifier cannot use every algebraic
identity from the original total language. They also test a semantic property
that both the direct interpreter and lambda compilation must preserve.
