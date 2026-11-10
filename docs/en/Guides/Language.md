---
Template: Guide
Name: Language
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/guide/Language
Title: Language
Description: Language tools for computing with natural-number programs
Keywords: [program synthesis, computation, Recursor]
RelatedGuides: [Recursor]
RelatedTutorials: [EvolvingLambdaExpressions, ArithmeticPatterns, LanguageSemantics, SynthesizingSequences, UniversalComputation]
---

## Abstract

Language tools for the Recursor natural-number language.

## Functions

- `RecursorExpressionQ` checks syntax
- `FormatRecursor` serializes source
- `RecursorFreeVariables` gives the unbound binding symbols
- `RecursorNodeCount` counts syntax nodes
- `ParseRecursor` reads closed source text
- `RecursorProgramQ` checks a closed program
- `ReplaceRecursorPart` replaces a subtree
- `RecursorSites` lists its subtrees and scopes

### Syntax

- `Acc` Acc denotes the current accumulator.
- `Add` Add[a, b] adds two values.
- `CGet` CGet[index] reads an earlier course-of-values result.
- `CoRec` CoRec[count, step] performs course-of-values recursion.
- `Const` Const[n] denotes a natural-number constant.
- `Half` Half[e] gives the integer quotient by two.
- `Idx` Idx denotes the current recursion index.
- `Ifz` Ifz[condition, zero, positive] branches on zero.
- `Iter` Iter[count, base, step] repeats a step a bounded number of times.
- `Let` Let[value, body] evaluates a body with a new input.
- `Monus` Monus[a, b] subtracts b from a, stopping at zero.
- `Mul` Mul[a, b] multiplies two values.
- `Pred` Pred[e] subtracts one, stopping at zero.
- `Quot` Quot[a, b] computes an integer quotient.
- `Rec` Rec[count, base, step] performs primitive recursion.
- `Rem` Rem[a, b] computes a remainder.
- `Succ` Succ[e] adds one to e.
- `Var` Var is the program input.
- `WhileLoop` WhileLoop[base, condition, step] repeats while condition is nonzero.
