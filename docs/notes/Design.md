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
- Count a synthesized program as solved only on evidence that it generalizes.
  Fitting the examples is not that evidence. The search therefore sees three
  quarters of the examples and is tested on the rest, and the examples must
  hold at least 24 bits more information than the program (a value counts by
  its distance from the one before, a unit of cost counts 2.5 bits). Both
  conditions were set on a development sample and measured on 1,000 other
  sequences of the OEIS, twenty terms each. Of the programs that reproduced
  the terms they were found from, 58% failed on later terms. Of those that
  also reproduced the held-out terms, 22% did. Of the 87 solved programs with
  later terms on record, none did; on 2,000 further sequences 4 of 165 did.
  A program that fits without that evidence is returned, not solved.
  [The measurements](OEISSynthesisAndEvolution.md) give the details.
- Require four held-out examples for Solved. Evidence in bits cannot show
  that a sequence leaves a simple rule after the terms given, and many do:
  from eight terms a quarter of the solved programs failed later, whatever
  their evidence. The share that continue rises with the terms, 93% from
  twelve and 95% from sixteen, so Solved starts at sixteen examples.
- Write the synthesizer as array arithmetic. Loop bodies of one shape advance
  together as rows of one matrix, the terms of sums and products are
  evaluated bottom-up from values already known, and segment totals are
  matrix operations. A search takes about two seconds where the first
  version took five. Local functions that refer to one another are removed
  when a search ends: left alone they kept its tables alive, some fifty
  megabytes per call, which exhausted the memory of a machine during the
  measurements.
- Offer guided variation in EvolveRecursor. Blind mutation and crossover
  sample a few hundred programs. Method -> "Guided" runs a parent backwards
  from the examples to the values one of its parts must have, and takes that
  part from a library of small programs enumerated once. It also evolves
  recurrence steps against the recorded earlier outputs. With the budget of
  the corpus experiment it predicted seven times as many sequences. The
  default method is unchanged, so seeded searches give what they gave.
- Compose programs in the synthesizer, working backwards from the examples.
  Sums, products and counts over a loop index are evaluated for all index
  pairs at once, so thousands of loops cost a few array operations. The n-th
  number with a property, counting functions, partial sums, differences and
  inner functions are found by asking which stored class the examples
  require, a lookup instead of an enumeration of every composition. Two
  enumerated parts joined at the root are found by lookup too, which doubles
  the cost that enumeration reaches. Costs count the choices of the search,
  not the nodes of a fixed wrapper, so they stay comparable across methods.
- Translate programs to Wolfram Language in two steps. A literal translation
  follows the interpreter construct by construct and is correct by
  construction. Nicer forms (sums, products, counts, comparisons, known
  functions) are rewrites of it, each kept only if it gives the values of the
  program on the tested inputs. A wrong rewrite is dropped, never returned.
- Draw syntax trees with a design of their own, the one exception to native
  visualization defaults. Names are the content of a syntax tree, so each
  node is a box holding its name instead of a dot with a label beside it,
  and color separates loops, arithmetic, choice and binding, and inputs and
  constants. Every subtree is as wide as its boxes, so no two boxes meet,
  and the picture is as wide as its tree, so names keep one size from tree
  to tree. The result stays a TreeGraph: an explicit option replaces its
  part of the design, and a layout, root, labels or shapes of the caller's
  choosing bring back the TreeGraph drawing.

Turing completeness concerns unbounded semantics. Physical resources still
bound real runs. Counter translation favors a simple proof over performance;
the direct interpreter is the practical default and lambda evaluation is
useful for semantic comparisons on small examples.
