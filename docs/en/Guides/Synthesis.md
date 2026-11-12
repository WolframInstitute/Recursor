---
Template: Guide
Name: Synthesis
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/guide/Synthesis
Title: Synthesis
Description: Synthesis tools for finding natural-number programs from examples
Keywords: [program synthesis, integer sequences, Recursor]
RelatedGuides: [Recursor, Evolution]
RelatedTutorials: [SynthesizingSequences, MeasuringOEISSequenceDiscovery]
---

## Abstract

Deterministic search for Recursor programs that match examples.

## Functions

- `SynthesizeRecursor` finds a program from examples and tests it on examples it was not shown

### Checking a result

- `EvaluateRecursor` computes later terms of a synthesized program
- `ScoreRecursor` counts exact matches on further examples
- `RecursorNodeCount` counts the syntax nodes of a result
- `TranslateRecursor` writes a result as a Wolfram Language function
