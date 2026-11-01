---
Template: TechNote
Name: VisualizingLambdaCompilation
Title: From Recursor Programs to Lambda Reductions
Description: Inspect compiled terms and a finite beta-reduction trajectory with Wolfram/Lambda
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/VisualizingLambdaCompilation
Keywords: [lambda calculus, compilation, beta reduction, computational essay]
RelatedGuides: [Compilation, Recursor, Visualization]
RelatedTutorials: [LanguageSemantics, UniversalComputation]
---

## Inspect a compiled program

What structure is introduced when a small arithmetic program is compiled?
This essay follows successor applied to two, so the result can be checked
independently. It uses the optional [Wolfram/Lambda paclet](https://github.com/WolframInstitute/WolframLambda),
installed with `PacletInstall["Wolfram/Lambda"]` if necessary. The examples were
verified with version 1.2.5. Recursor's evaluator and compiler do not depend on it.

Load the visualization tools:

```wl
Needs["Wolfram`Lambda`"]
```

The compiler's formal lambda head and one-based de Bruijn indices can be
passed directly to these tools. Draw its abstraction and application tree;
the display distinguishes abstractions, applications and variables:

```wl
LambdaTree[CompileRecursor[Succ[Var]]]
```

Connect each variable occurrence to its binding abstraction with a loopback edge:

```wl
LambdaLoopbackGraph[CompileRecursor[Succ[Var]]]
```

## Follow one reduction trajectory

Apply the compiled successor to Church numeral two. Compute at most 120
normal-order beta reductions, stopping at a normal form, and show the number
of reductions performed:

```wl
Length[reductionPath = BetaReduceList[ CompileRecursor[Succ[Var]][ChurchNumeral[2]], UpTo[120], TreeTraversalOrder -> "Normal", ProgressReporting -> False]] - 1
```

Decode the final numeral and check that no reducible positions remain:

```wl
{FromChurchNumeral[Last[reductionPath]], BetaReducePositions[Last[reductionPath]]}
```

The measured trajectory has ten reductions and ends at numeral three. This
is one external reduction strategy; its steps are not Recursor's interpreter
visits or its call-by-need machine transitions.

Plot expression size throughout the trajectory:

```wl
ListLinePlot[LeafCount /@ reductionPath, DataRange -> {0, Length[reductionPath] - 1}, AxesLabel -> {"Beta reduction", "Term leaves"}, PlotRange -> All]
```

The term can grow or shrink as substitution copies or removes subexpressions.
Compare a late intermediate state with the final state, merging repeated
variable names in each graph:

```wl
GraphicsRow[LambdaGraph[reductionPath[[1 + #]], PlotLabel -> Row[{"Step ", #}]] & /@ {6, Length[reductionPath] - 1}]
```

Inspect the final Church numeral as a tree:

```wl
LambdaTree[Last[reductionPath]]
```

The final pair of abstractions binds the successor function and initial value;
three applications encode the number three. This finite example checks the
compiler's representation and one execution. Universality follows from the
counter-machine simulation in the companion tutorial, rather than from a
single reduction trace.
