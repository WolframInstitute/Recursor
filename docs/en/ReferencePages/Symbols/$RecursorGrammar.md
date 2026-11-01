---
Template: Symbol
Name: $RecursorGrammar
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/$RecursorGrammar
RelatedGuides: [Recursor]
SeeAlso: [EvaluateRecursor, RecursorProgramQ]
RelatedTutorials: [ArithmeticPatterns]
---

## Usage

<code>[$RecursorGrammar]()</code> gives syntax-head arities.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- Var, Acc and Idx are atoms, with arity zero. Const has one literal integer payload; this is not a syntax-tree child.

## Basic Examples

Evaluate a small example:

```wl
$RecursorGrammar
```
