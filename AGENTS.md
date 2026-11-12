# Recursor development

Use one context, `` WolframInstitute`Recursor` ``, and StructuredPackageFormat.
Kernel areas and tests mirror each other. Export only documented symbols.
Retain the compact DSL syntax names. Public actions use
operation-first names such as MutateRecursor and EvaluateRecursor. Use noun
phrases for returned properties and representations, Q for predicates, and
ToRecursor for conversion. Follow [the naming skill](.agent-skills/wolfram-api-naming/SKILL.md).

Every Wolfram Language file follows the
[coding guides](docs/coding-guides/README.md): the kernel, the tests and the
scripts. Read the coding guide before you write code, and follow
[the code-style skill](.agent-skills/wolfram-code-style/SKILL.md). Run
`make style-fix` and then `make style` on the files you change; `make check`
and CI run the same check and refuse code that breaks a rule. Never add a
file to `scripts/style-legacy.txt`.

Follow the Wolfram Language style in GUIDE.md: tab indentation,
specific argument patterns, file-level helpers, no trailing top-level
semicolons, and Failure values for computations that start but cannot finish.
Every public function ends with a catch-all that gives
`Failure["InvalidArguments", ...]` for wrong-shape arguments; syntax nodes
stay unevaluated. Predicates return booleans.

Follow [the kernel-options skill](.agent-skills/wolfram-kernel-options/SKILL.md)
for function defaults and option forwarding. Use native visualization defaults,
Automatic image sizing, and consistent SetOptions behavior. RecursorProgramTree
alone has a design of its own: left Automatic, its options resolve to named
boxes colored by kind in a tidy layout, and explicit options replace its parts.

Change the grammar, binding rules, interpreter, compiler, generators and
documentation together. Test strictness and divergence when changing the
compiler or simplifier. A timeout does not prove nontermination.

Documentation sources are Markdown in docs/en. PacletPage builds notebooks
and publishes the resource and its site. The resource page shows the Basic
Description of Recursor/ResourceDefinition.md beside docs/Hero.png, which
`make hero` redraws from docs/Hero.wl. Use double-backtick Markdown spans
around context names. Never maintain generated notebooks by hand.

Run `make check` and `make test` for implementation changes. Run
`make check-publish` for documentation or packaging changes. `make publish`
writes to the Wolfram Cloud and is a separate release action.

Keep scripts limited to check.wls, test.wls, docs.wls and style.wls with its
package in scripts/style. Put language code in
the paclet, examples in documentation, and design rationale in docs/notes.

Follow the PARILink and MathlibLink CI/CD arrangement: use the official Linux
Wolfram Engine container for Wolfram checks and packaging, without desktop
installer downloads. Pin external build dependencies. Preserve test and proof
reports, verify the installed archive, and reuse the exact CI artifact for
release. Publish through PacletPage before creating the GitHub release. Require
successful CI for the tag's exact commit. See docs/workflows.md.
Release by pushing a `vX.Y.Z` tag for a commit on main whose CI has passed; the
release reuses that run's verified artifact. Pushing to main publishes nothing.
Never move an existing version tag.

Keep LICENSE and Recursor/Assets/LICENSE identical so the repository and
distributed paclet carry the same MIT license. Commit focused, verified changes.

## Documentation playbooks

Read the relevant local skill before writing docs: [symbol pages](.agent-skills/wolfram-symbol-page/SKILL.md),
[guides](.agent-skills/wolfram-guide-page/SKILL.md), [tutorials](.agent-skills/wolfram-tech-note/SKILL.md),
and [computational essays](.agent-skills/computational-essay/SKILL.md). Shared conventions are in [GUIDE.md](GUIDE.md).

Apply [the example-style skill](.agent-skills/wolfram-example-style/SKILL.md)
to all documentation and walkthrough inputs. The user explicitly requires
concise examples and no unnecessary presentation options.
