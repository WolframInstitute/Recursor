# Public API names

Actions put the operation before the subject: `MutateRecursor`,
`EvaluateRecursor` and `CompileRecursor`. Use complete words with capitalized
initials, and choose names that describe the specific operation. This follows
the user's requested convention and Wolfram's guidance on
[names](https://reference.wolfram.com/language/tutorial/SomeGeneralNotationsAndConventions.html)
and [specificity](https://resources.wolframcloud.com/FunctionRepository/style-guidelines).

Wolfram does not impose verb-first names universally. Results and properties
remain noun phrases (`RecursorProgramTree`, `RecursorNodeCount`,
`RecursorFreeVariables`); boolean predicates retain `Q` (`RecursorProgramQ`).
`RandomRecursor` follows `RandomInteger` and `RandomGraph`. `ToRecursor`
converts a counter-machine instruction list into a Recursor program, using
the target-type naming pattern of `ToExpression`.

These names replace the initial unpublished draft API. There are no duplicate
public aliases. Original DSL constructors such as `Rec`, `Iter` and `CoRec`
keep their source-language spellings. The optional NotebookCompatibility
asset maps legacy notebook entry points to the current API.

| Initial draft | Current name |
| --- | --- |
| RecursorCompile | CompileRecursor |
| RecursorCrossover | CrossoverRecursor |
| RecursorEvaluate | EvaluateRecursor |
| RecursorEvolve | EvolveRecursor |
| RecursorFormat | FormatRecursor |
| RecursorMutate | MutateRecursor |
| RecursorNormalize | NormalizeRecursor |
| RecursorParse | ParseRecursor |
| RecursorRandom | RandomRecursor |
| RecursorReplace | ReplaceRecursorPart |
| RecursorScore | ScoreRecursor |
| RecursorSimplify | SimplifyRecursor |
| CounterMachineToRecursor | ToRecursor |

The same names are used by kernel exports, usage messages, options, tests,
PacletInfo, Markdown pages and the evaluated walkthrough. Future changes
follow the [API naming skill](../../.agent-skills/wolfram-api-naming/SKILL.md).
