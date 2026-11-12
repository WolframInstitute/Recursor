---
Template: TechNote
Name: LanguageSemantics
Title: The Recursor Language
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/LanguageSemantics
RelatedGuides: [Recursor]
---

## Programs and values

A program is a finite expression computing a partial function from natural
numbers to natural numbers. Partial means that some inputs may never yield a
value. Values are arbitrary-precision integers.

The atoms are Var, Acc and Idx. Const[n] has an integer payload. Unary heads
are Succ, Pred, Half and CGet; binary heads are Add, Mul, Monus, Rem, Quot,
CoRec and Let; ternary heads are Ifz, Iter, Rec and WhileLoop. Arity is exact.

Check syntax and lexical closure:

```wl
RecursorProgramQ /@ {Mul[Var, Var], Acc, Const[-1], Add[Var]}
```

Draw a closed expression. The leaves are inputs and constants; internal nodes
specify operations:

```wl
RecursorProgramTree[Add[Mul[Var, Var], Const[1]]]
```

## Arithmetic and branching

Pred and Monus stop at zero. Half is division by two rounded down. Rem[a,b]
gives a when b is zero, otherwise the usual remainder. Quot[a,b] gives zero
when b is zero, otherwise the quotient rounded down. Arithmetic evaluates
both arguments fully, from left to right. Multiplying a diverging expression
by zero still diverges. Ifz evaluates its condition fully, then only the
selected zero or positive branch.

Select the zero branch without evaluating the other branch:

```wl
EvaluateRecursor[Ifz[Const[0], Const[7], RecursorExamples["Nonterminating"]], 0]
```

## Bounded recursion

Iter[count,base,step] evaluates count and then base, even for count zero.
Each of count steps binds Acc to the preceding value. Rec additionally binds
Idx to 0 through count-1.

Compute factorials with primitive recursion and show their growth on a
logarithmic vertical scale:

```wl
ListLogPlot[Table[EvaluateRecursor[Rec[Var, Const[1], Mul[Succ[Idx], Acc]], n], {n, 0, 8}], DataRange -> {0, 8}, Frame -> True, FrameLabel -> {"Input", "Factorial"}]
```

CoRec[count,step] computes every index from 0 through count, inclusive.
It binds Idx and CGet. CGet[j] reads an earlier result, or gives zero for a
current or future index. Every intermediate step is evaluated.

Compute Fibonacci numbers from earlier values:

```wl
ListLinePlot[Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 10}], DataRange -> {0, 10}, Frame -> True, FrameLabel -> {"Input", "Fibonacci"}]
```

## Lexical scope

The nearest enclosing binder wins. Other outer bindings remain visible.

| Construct | Bound children | New bindings |
| --- | --- | --- |
| Iter | step | Acc |
| Rec | step | Acc, Idx |
| CoRec | step | Idx, CGet |
| WhileLoop | condition, step | Acc |
| Let | body | Var |

CoRec does not bind Acc. It inherits an outer accumulator. In this tree, the
Acc leaf refers to the enclosing Iter even though it occurs inside CoRec:

```wl
RecursorProgramTree[Iter[Const[1], Const[9], CoRec[Const[2], Acc]]]
```

Read an outer accumulator through a course-of-values recursion:

```wl
EvaluateRecursor[Iter[Const[1], Const[9], CoRec[Const[2], Acc]], 0]
```

## Local input

Let[value,body] evaluates value in the enclosing scope, then body with Var
bound to that value. Acc, Idx and CGet stay as they were. A closed program
used as the body is thereby applied to value, so programs compose.

Apply the factorial program to twice the input:

```wl
Table[EvaluateRecursor[Let[Mul[Const[2], Var], RecursorExamples["Factorial"]], n], {n, 0, 5}]
```

Sum a program over the indices of a loop. The body reads the loop index
through Let and the running sum through Acc:

```wl
ListLinePlot[Table[EvaluateRecursor[Rec[Var, Const[0], Add[Acc, Let[Idx, RecursorExamples["DivisorCount"]]]], n], {n, 0, 40}], DataRange -> {0, 40}, Frame -> True, FrameLabel -> {"Input", "Sum of divisor counts"}]
```

## Unbounded iteration

WhileLoop[base,condition,step] evaluates base once. With Acc set to that value,
it evaluates condition. Zero returns Acc. Otherwise step supplies the next
Acc and the condition is tested again. There is no semantic bound on the
number of iterations or the accumulator size. Idx and CGet are inherited.
The base lies outside the new binding scope.

Count down from one hundred to zero:

```wl
EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 100]
```

Follow six predecessor updates from six. Each directed edge is one accumulator
update, and the loop stops at the zero vertex:

```wl
Graph[DirectedEdge @@@ Partition[NestList[EvaluateRecursor[Pred[Var], #] &, 6, 6], 2, 1], VertexLabels -> "Name"]
```

## Operational limits

The interpreter counts one step per visited syntax node. The lambda method
counts machine transitions and readback work. Time and memory limits apply
independently. Their defaults are documented on EvaluateRecursor.

Inspect a finite-budget failure:

```wl
EvaluateRecursor[WhileLoop[Const[0], Const[1], Acc], 0, "MaxSteps" -> 30]["Tag"]
```

A limit produces Failure tagged StepLimit, TimeLimit or MemoryLimit. It does
not establish nontermination. Each resource option accepts Infinity to remove
that limit; real runs still depend on available physical resources.

## Source text

ParseRecursor accepts only this grammar and never evaluates Wolfram source.
FormatRecursor is its inverse for closed programs. Direct Wolfram expressions
have normal Wolfram argument evaluation; the other APIs are not a sandbox
for arbitrary Wolfram code.

Round-trip portable source text:

```wl
ParseRecursor[FormatRecursor[RecursorExamples["Factorial"]]]
```
