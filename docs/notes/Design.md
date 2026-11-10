# Design decisions

The paclet contains the DSL, compiler, normalizer, genetic operators, proposal
validation, search and program visualizations. It uses StructuredPackageFormat
and a paclet, documentation and test layout adapted from Ruliology.

- Retain compact syntax names for recognizable program trees. Public actions
  use operation-first names; queries and representations use descriptive noun
  phrases. See [API naming](Naming.md) for the convention and rename map.
- Add WhileLoop rather than unbounded minimization or recursive-call syntax:
  its state semantics give a direct counter-machine simulation.
- Keep natural numbers as the sole value type. Integer encodings provide
  unbounded storage without adding lists or mutable source variables.
- Keep the original strict interpreter semantics. Sequence natural-number
  computations in the lambda compiler so divergence is preserved too.
- Build named intermediate lambda terms before de Bruijn numbering. This
  replaces ad hoc index shifting at each source-language binder.
- Refactor call-by-need normalization into local heap and frame operations.
  No global cache, notebook directory or Lambda paclet is required.
- Enforce evaluation fuel. The original interpreter ignored reductioncap.
- Separate validity from the original 60-node search budget.
- Parse generated text directly, without ToExpression or ReleaseHold.
- Use model-independent proposal callbacks. Target sequence catalogs and the
  notebook's separate Wolfram/Lambda experiments are outside this DSL paclet.
- Add Quot beside Rem. A quotient by a non-constant divisor otherwise needs a
  loop, which put floor formulas out of reach of search. Quot[a, 0] is zero,
  as in Lean's natural-number division, so the formal model needs no case
  split and Add[Mul[b, Quot[a, b]], Rem[a, b]] is always a.
- Add Let as the only construct that rebinds Var. A closed program placed in
  its body is applied to a value, so programs compose: sums and products of a
  subprogram, searches for the n-th number with a property and compositions
  need no further primitives. Acc, Idx and CGet keep their scoping, so every
  earlier program means what it meant. A scope-escape form was considered and
  left out: Let covers the measured needs and keeps Env a flat record in Lean.
- Synthesize deterministically before evolving. SynthesizeRecursor enumerates
  programs by cost up to observational equivalence, checks recurrence steps
  against the data, and solves for constants exactly. The corpus experiments
  showed that sampling 464 trees per sequence finds little beyond constants
  and lines, while exhaustive enumeration with equivalence classes covers
  every function of small cost. EvolveRecursor stays for stochastic studies.
- Price constants by magnitude in the synthesizer's cost: 0 to 3 cost one
  node, every further two bits one more. Initial terms read from data then
  pay for what they say, and a recurrence with several large seeds no longer
  beats a short closed program. RecursorNodeCount is unchanged.

Turing completeness concerns unbounded semantics. Physical resources still
bound real runs. Counter translation favors a simple proof over performance;
the direct interpreter is the practical default and lambda evaluation is
useful for semantic comparisons on small examples.
