# Recursor development

Use one context, `` WolframInstitute`Recursor` ``, and StructuredPackageFormat.
Kernel areas and tests mirror each other. Export only documented symbols.
Retain the compact DSL syntax names. Public actions use
operation-first names such as MutateRecursor and EvaluateRecursor. Use noun
phrases for returned properties and representations, Q for predicates, and
ToRecursor for conversion. Follow [the naming skill](.agent-skills/wolfram-api-naming/SKILL.md).

Follow the Wolfram Language style in the PureMath GUIDE.md: tab indentation,
specific argument patterns, local helpers, no trailing top-level semicolons,
and Failure values for computations that start but cannot finish. Wrong-shape
arguments remain unevaluated; predicates return booleans.

Change the grammar, binding rules, interpreter, compiler, generators and
documentation together. Test strictness and divergence when changing the
compiler or simplifier. A timeout does not prove nontermination.

Documentation sources are Markdown in docs/en. PacletPage builds notebooks
and publishes the resource and its site. Use double-backtick Markdown spans
around context names. Never maintain generated notebooks by hand.

Run `make check` and `make test` for implementation changes. Run
`make check-publish` for documentation or packaging changes. `make publish`
writes to the Wolfram Cloud and is a separate release action.

Keep scripts limited to check.wls, test.wls and docs.wls. Put language code in
the paclet, examples in documentation, and design rationale in docs/notes.

## Documentation playbooks

Read the relevant local skill before writing docs: [symbol pages](.agent-skills/wolfram-symbol-page/SKILL.md),
[guides](.agent-skills/wolfram-guide-page/SKILL.md), [tutorials](.agent-skills/wolfram-tech-note/SKILL.md),
and [computational essays](.agent-skills/computational-essay/SKILL.md). Shared conventions are in [GUIDE.md](GUIDE.md).

Apply [the example-style skill](.agent-skills/wolfram-example-style/SKILL.md)
to all documentation and walkthrough inputs. The user explicitly requires
concise examples and no unnecessary presentation options.
