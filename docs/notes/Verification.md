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

The source check covers 45 exported symbols and their reference pages.
All 189 Wolfram tests passed, including syntax and scope, parser round trips,
strictness and divergence budgets, both evaluation backends, counter-machine
and partial-recursive translations, genetic operators, seeded search,
visualizations, installation behavior and proof-workspace configuration.
Visualization checks cover inherited native defaults, SetOptions, explicit
option precedence, single-node trees, syntax roots and distinct directed
paths for repeated subexpressions.

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

The documentation contains 286 executable Markdown inputs, plus two resource
examples. PacletPage evaluates pages in fresh kernels and rejects failed,
unevaluated or flagged output. Installation examples marked `eval: false` are
not run as documentation side effects.

The tutorial audit evaluated all 86 inputs without unexpected messages and
rendered 52 computed figures in both light and dark appearances. These include
syntax and scope diagrams, recurrence dependencies, finite orbits, shared
trajectories, search ancestry and theorem-to-axiom graphs. Tutorials have no
tabular computation outputs; the two Markdown tables specify binding rules
and API migration names. Graph orientation and roots were checked against the
represented computation, and crowded ancestry examples were reduced.

The unchanged walkthrough contains 89 Input cells: its 88 computational inputs
were evaluated and the desktop installer invocation was retained for
interactive use. The reference figures and walkthrough outputs also passed
their light and dark rendering review. Its table style applies only to
dedicated output cells and does not override the general Grid style used by
notebook controls. Rendering checks use saved output boxes, since
round-tripping native TreeGraph values through InputForm can lose their roots.

## Packaging

PacletPage 0.3.42, the pinned MarkdownToNotebook and WolframParser sources,
Lambda 1.2.6, LeanLink 1.2.5 and MathlibLink 0.1.0 were used in an isolated
Wolfram profile. The build contains all 61 documentation notebooks, the four
Lean project assets and the MIT license. The archive audit compares packaged
kernel code, assets and stylesheets byte-for-byte with the checkout and
rejects message/code cells and runtime caches.

Workflow validation covers YAML, actionlint, both supported ShellCheck
versions, all 23 shell blocks and embedded Python. Fifteen release fixtures
check provenance and release ordering; eight archive fixtures check the
source, license, page coverage, cell styles and forbidden paths. Hosted CI
remains a separate check after these workflows are pushed. No cloud
publication was performed during local verification.

## Scope of the result

The universality theorem is about the formal denotational DSL. The separate
operational model has its own checked results, but equivalence between these
two formal models has not been proved. The Wolfram interpreter, its source
translators and its lambda compiler are tested implementations; they are not
certified equivalent to the formal semantics. Finite tests and finite budgets
do not decide general program equivalence or nontermination.
