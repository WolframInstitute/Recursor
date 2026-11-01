# Verification record

Checked on 2026-11-01 with Wolfram Language 15.0 on macOS ARM64.

## Reproduce

```sh
make check
make test
make check-proofs
make check-publish
```

The proof check requires the external libraries installed by
`InstallRecursorLibraries[{"LeanLink", "MathlibLink"}]`. It uses the packaged
Lean source and MathlibLink's shared, pinned mathlib checkout. Publishing is a
separate command; these checks do not publish to Wolfram Cloud.

## Language and implementation

The source check covers 43 exported symbols and their reference pages.
All 111 Wolfram tests passed, including syntax and scope, parser round trips,
strictness and divergence budgets, both evaluation backends, counter-machine
and partial-recursive translations, genetic operators, seeded search,
visualizations, installation behavior and proof-workspace configuration.

The partial-recursive translator was also reviewed against the formal
translation. Its eight constructors agree, including strict composition,
forcing the base at recursion count zero, and blocking search on an undefined
earlier test. Nested translated programs can require much larger execution
budgets than their mathematical descriptions suggest.

## Lean proofs

Lean is pinned to 4.35.0; mathlib is pinned to commit
56a005855ea17e0b0958f73ec801ae140b0a1679, the v4.35.0 release. LeanLink 1.2.5
replayed all 535 declarations of Recursor and all 175 declarations of
Universality successfully. The following twelve designated theorems have no
axiom dependencies beyond propext, Classical.choice and Quot.sound:

- run_sound, reaches_complete and computes_iff_observed
- run_stable and computes_deterministic
- countdown_correct, pack_address and pack_payload
- compile_correct, translate_correct, translate_scoped and universal

The compiler theorem equates partial denotations for every Nat.Partrec.Code;
it covers both returned values and undefined computations. The scope theorem
establishes lexical closure. The universality theorem combines these facts
with mathlib's representation theorem for partial recursive functions.

TypeTheory 0.16.1 also accepted the imported countdown_correct and
pack_address declarations through LeanLink's independent-checking bridge.
This additional check covers those declarations and their dependencies, not
the entire universality development or all of mathlib.

## Documentation and walkthrough

All 278 evaluated Markdown inputs, in 194 independent groups, and all 65
walkthrough Input cells completed without unexpected messages. Installation
examples marked `eval: false` were not run as documentation side effects.
Changed examples received additional checks of their actual result shapes.

The documentation and walkthrough contain 169 computed figures and tables.
All were rendered in light and dark appearances. Visual review checked labels,
legends, contrast, orientation and bounded display sizes. The final transition
budget map uses MatrixPlot so both outcomes remain visible in dark appearance.
The walkthrough's table style applies only to its dedicated output cells and
does not override the global Grid style used by notebook controls.

## Scope of the result

The universality theorem is about the formal denotational DSL. The separate
operational model has its own checked results, but equivalence between these
two formal models has not been proved. The Wolfram interpreter, its source
translators and its lambda compiler are tested implementations; they are not
certified equivalent to the formal semantics. Finite tests and finite budgets
do not decide general program equivalence or nontermination.
