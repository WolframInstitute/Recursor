---
Template: Symbol
Name: EvaluateRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/EvaluateRecursor
RelatedGuides: [Evaluation, Recursor]
SeeAlso: [CompileRecursor, NormalizeRecursor, RecursorProgramQ, ScoreRecursor]
RelatedTutorials: [HaltingAndBudgets]
---

## Usage

<code>[EvaluateRecursor]()[*program*, *n*]</code> evaluates a program.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- n is a natural number. Invalid programs or input types remain unevaluated.
- Method is "Interpreter" (default) or "Lambda". The latter compiles and normalizes a Church-numeral application.
- "MaxSteps" defaults to 100000 and accepts a nonnegative integer or Infinity. The interpreter counts syntax visits; the lambda machine counts transitions and readback work. Budgets are not comparable between methods.
- "TimeLimit" defaults to 5 seconds; "MemoryLimit" defaults to 268435456 bytes. Each accepts a positive value (integer bytes) or Infinity.
- Resource exhaustion returns Failure tagged StepLimit, TimeLimit or MemoryLimit. A finite limit cannot decide whether the program would eventually halt.
- The three limits can all be Infinity. Arithmetic has no machine-integer bound.


The following options are available:

| | | |
| --- | --- | --- |
| Method | "Interpreter" | Use the direct interpreter or "Lambda" compilation and reduction. |
| "MaxSteps" | 100000 | Maximum syntax visits or lambda-machine transitions; accepts Infinity. |
| "TimeLimit" | 5 | Seconds per evaluation; accepts Infinity. |
| "MemoryLimit" | 268435456 | Additional bytes per evaluation; accepts Infinity. |

## Basic Examples

Evaluate a small example:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 6]
```

## Scope

Evaluate a computation with a natural number beyond machine integer range:

```wl
EvaluateRecursor[Mul[Var, Var], 10^30]
```

## Options

Compare the two execution methods on a small program:

```wl
Table[EvaluateRecursor[Mul[Var, Var], 3, Method -> method], {method, {"Interpreter", "Lambda"}}]
```

---

Return a structured result when the step budget is exhausted:

```wl
EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 20, "MaxSteps" -> 10]
```

---

Remove the time and memory limits for a known terminating calculation:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 10, "TimeLimit" -> Infinity, "MemoryLimit" -> Infinity]
```

## Applications

Compare a computed sequence with an independent reference:

```wl
ListLinePlot[{Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 10}], Fibonacci[Range[0,10]]}, DataRange -> {0, 10}, PlotLegends -> {"Recursor", "Reference"}, AxesLabel -> {"Input", "Output"}, PlotRange -> All ]
```

---

Show residue classes for divisors one through eight:

```wl
ArrayPlot[Table[EvaluateRecursor[Rem[Var,Const[d]], n], {d,1,8}, {n,0,31}], FrameLabel -> {"Divisor", "Input"}, PlotLegends -> Automatic, FrameTicks -> {Range[8], Table[{n+1,n},{n,0,31,4}]} ]
```
