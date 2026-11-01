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

Turing completeness concerns unbounded semantics. Physical resources still
bound real runs. Counter translation favors a simple proof over performance;
the direct interpreter is the practical default and lambda evaluation is
useful for semantic comparisons on small examples.
