---
Template: Symbol
Name: TranslateRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/TranslateRecursor
RelatedGuides: [Compilation, Recursor]
SeeAlso: [EvaluateRecursor, CompileRecursor, SynthesizeRecursor, FormatRecursor]
RelatedTutorials: [SynthesizingSequences]
---

## Usage

<code>[TranslateRecursor]()[*program*]</code> gives a Wolfram Language function with the values of a closed program.

<!-- #| annotation: This API operates on Recursor syntax and its declared evaluation semantics; standard plotting and arithmetic remain built-in operations. -->

## Details & Options

- The result is a pure function of one natural number. Its body is held, so it shows as written until it is applied.
- Loops become Nest, Fold and NestWhile. Course-of-values recursion becomes a function that remembers its values.
- With `Method -> Automatic`, loops that add, multiply or count become Sum, Product and Count, tests for zero become comparisons, and sums and products are closed where the system closes them. Some results are recognized as built-in functions.
- A rewritten form is kept only if it gives the values of the program on the inputs 0, 1, …, `"TestInputs"` − 1, as far as the program finishes there. `Method -> "Literal"` keeps the structure of the program.
- Truncated subtraction is Max[a − b, 0]. Rem[a, 0] is a and Quot[a, 0] is 0, so a divisor that may be zero keeps a test.
- The function is not limited by the budgets of [EvaluateRecursor](). Where the program does not finish, the function does not finish.
- Variable names such as n, i and a are symbols of the current context.

## Basic Examples

Translate the factorial program:

```wl
TranslateRecursor[RecursorExamples["Factorial"]]
```

Apply the function:

```wl
TranslateRecursor[RecursorExamples["Factorial"]][10]
```

## Scope

A recurrence becomes a function that remembers its values:

```wl
TranslateRecursor[RecursorExamples["Fibonacci"]]
```

---

A search for the numbers with exactly two divisors is recognized as the primes:

```wl
TranslateRecursor[RecursorExamples["Prime"]]
```

## Options

Keep the structure of the program:

```wl
TranslateRecursor[RecursorExamples["Factorial"], Method -> "Literal"]
```

## Applications

Translate a synthesized program:

```wl
TranslateRecursor[SynthesizeRecursor[Table[n (n + 1)/2, {n, 0, 15}]]["Program"]]
```

---

Compare a translation with the interpreter:

```wl
With[{program = RecursorExamples["DigitSum"]}, TranslateRecursor[program] /@ Range[0, 30] === Table[EvaluateRecursor[program, n], {n, 0, 30}]]
```
