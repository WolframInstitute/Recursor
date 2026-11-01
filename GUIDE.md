# Code and documentation conventions

Kernel code follows Wolfram Language conventions: StructuredPackageFormat,
one public context, private helpers, tab indentation, complete API names,
specific patterns and structured failures. Syntax nodes retain their original
compact spellings. Wrong-type function inputs stay unevaluated; predicates
are boolean. Evaluation limits do not decide termination.

Documentation follows the local .agent-skills playbooks and Ruliology conventions. Markdown is authoritative; PacletPage generates notebooks.
Use Symbol, Guide and TechNote templates, real Usage signatures, headerless
option tables, and reciprocal related-page links. Context names need doubled
Markdown backticks. Keep a caption ending in a colon before each wl fence.

Reference examples are independent across headings and separators. Tutorials
thread state in order. One expression per cell shows one main output; bind
intermediate results visibly. Seed stochastic examples explicitly. State
inputs, budgets, run lengths, measurements and censoring conventions.

Applications should primarily show computed scientific visuals. A curve,
array, graph or comparison must explain the computation. Label axes and color
keys, keep scales comparable and avoid decorative charts. Use built-in plots
or the paclet's graph functions, with small reproducible inputs.

Run every example. A successful Markdown conversion alone does not verify
its output. Read back the notebook outputs and render every figure. With a
Wolfram front end, use a one-cell notebook with LightDark -> "Light" and then
"Dark", for example:

```wl
Rasterize[Notebook[{Cell[BoxData[ToBoxes[graphic]], "Output"]}, LightDark -> "Light"]]
```

Inspect the images for clipped labels, illegible scales and misleading colors.
Prefer the visualization functions' defaults and concise inputs. Follow
[the example-style skill](.agent-skills/wolfram-example-style/SKILL.md).

Use `make check`, `make test`, `make notebooks` and `make check-publish`.
Temporary experiment and rendering code belongs under build, not additional
permanent scripts. The only maintained scripts are check.wls, test.wls and
docs.wls. `make publish` is the separate cloud release action.

Computational walkthroughs use standard Input cells and section groups.
Follow [wolfram-example-style](.agent-skills/wolfram-example-style/SKILL.md) for
both notebooks and Markdown: one-line examples where practical, no explicit
ItemSize in walkthroughs, and no unnecessary presentation options.

Public actions use operation-first names; result names use descriptive noun
phrases and boolean predicates end in Q. Follow
[the API naming skill](.agent-skills/wolfram-api-naming/SKILL.md).
