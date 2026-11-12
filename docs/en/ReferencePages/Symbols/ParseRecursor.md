---
Template: Symbol
Name: ParseRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/ParseRecursor
RelatedGuides: [Language, Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[ParseRecursor]()[*text*]</code> reads closed source text.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Uses a dedicated parser; it does not call ToExpression on the text.
- Rejects arbitrary Wolfram expressions, context-qualified names, operators, comments, strings and free bindings. Whitespace is allowed between tokens.
- Returns Failure for malformed source or resource limits.
- "MaxNodes" defaults to Infinity; "MaxDepth" defaults to 256. Both accept positive integers or Infinity.


The following options are available:

| | | |
| --- | --- | --- |
| "MaxNodes" | Infinity | Maximum accepted syntax nodes. |
| "MaxDepth" | 256 | Maximum accepted nesting depth. |

## Basic Examples

Evaluate a small example:

```wl
ParseRecursor["WhileLoop[Var, Acc, Pred[Acc]]"]
```

## Options

Reject source exceeding the declared node budget:

```wl
ParseRecursor["Add[Var, Const[1]]", "MaxNodes" -> 2]
```

---

Accept a shallow program with an explicit depth budget:

```wl
ParseRecursor["Succ[Var]", "MaxDepth" -> 2]
```

## Applications

Draw a parsed loop:

```wl
RecursorProgramTree[ParseRecursor["WhileLoop[Var,Acc,Pred[Acc]]"]]
```

---

Compute behavior directly from source text:

```wl
ListLinePlot[Table[EvaluateRecursor[ParseRecursor["Rem[Var,Const[5]]"], n], {n, 0, 24}], DataRange -> {0, 24}, Frame -> True, FrameLabel -> {"Input", "Output"}, PlotRange -> All ]
```
