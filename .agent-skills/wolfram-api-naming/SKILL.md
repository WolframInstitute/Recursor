---
name: wolfram-api-naming
description: Name public Wolfram paclet APIs and carry renames consistently through source, metadata, tests, Markdown and notebooks.
---

# Public API naming

Use complete English words with each word's first letter capitalized, or
established mathematical abbreviations. For this project, put the operation
before the subject for actions: MutateRecursor, EvaluateRecursor,
CompileRecursor, SimplifyRecursor and ReplaceRecursorPart. RandomRecursor
follows RandomInteger and RandomGraph; ToRecursor follows the ToExpression
conversion pattern. Document the representations accepted by a converter.

Use descriptive noun phrases for returned properties and representations:
RecursorNodeCount, RecursorFreeVariables and RecursorProgramTree. Boolean
predicates end in Q, such as RecursorProgramQ. Configuration and descriptive
global values start with $, such as $RecursorVersion. Do not mechanically
reverse a noun phrase or add Get merely to make every name a verb.

The user's operation-first preference is a project convention; Wolfram's
official guidance does not prescribe verb-first naming for every function.
Retain the original compact DSL constructors when changing the surrounding
API, since their names are part of the source language.

Check System context collisions. Update exported symbols, usage messages,
options, internal calls, tests, PacletInfo symbol catalogs, reference-page
filenames and URIs, links, examples and notebook inputs together. Regenerate
documentation and evaluated walkthrough outputs. Record breaking name changes
in a migration table; do not add duplicate public aliases to an unpublished
API without a concrete compatibility need.

Sources: [Wolfram naming and argument conventions](https://reference.wolfram.com/language/tutorial/SomeGeneralNotationsAndConventions.html),
[Function Repository naming specificity](https://resources.wolframcloud.com/FunctionRepository/style-guidelines),
[RandomGraph](https://reference.wolfram.com/language/ref/RandomGraph.html).
