# Coding guides

Three guides set the standard for Wolfram Language code in this repository.

| Guide | Governs |
| --- | --- |
| [WOLFRAMCODINGGUIDE.md](WOLFRAMCODINGGUIDE.md) | Names, usage messages, patterns, scoping, options, error handling, control flow, formatting and tests |
| [WOLFRAMVISUALIZATION.md](WOLFRAMVISUALIZATION.md) | Plots and other visual output |
| [MANIPULATEFUNCTIONCREATION.md](MANIPULATEFUNCTIONCREATION.md) | Building a `Manipulate` around a function that exists |

Read the coding guide before you write or change kernel code, a script or a
test. Read the visualization guide before you write a plotting function. Read
the third guide before you build a `Manipulate`.

The three files are kept as received on 2026-11-12. Do not edit them here.
When a new version arrives, replace the files, run `make style`, and update
this page and [GUIDE.md](../../GUIDE.md) where a rule changed. The files hold
code fragments that are wrong on purpose.

The arrangement follows the Ruliology repository: the same guides, the same
check and the same list of files not yet converted.

## How the repository applies the guides

The guides were written for any project. This section says how their rules
apply here, and what was decided where a guide leaves a choice or two rules
meet.

### Arguments and failures

- **Catch-all.** Every public function ends with one definition for any
  other arguments: `Name[___] := invalidArgumentsFailure[Name]`. The helper,
  in `Recursor/Kernel/Failures.wl`, issues the inherited message `Name::args`
  and gives `Failure["InvalidArguments", ...]`, as Rule 3 of the coding guide
  asks. The sequence has no name. No file defines its own `::args` message.
- **Predicates.** A function whose name ends in `Q` ends with
  `NameQ[___] := False`.
- **Symbolic heads.** The syntax nodes of the language, such as `Succ`,
  `Fold` and `Let`, are data and must stay unevaluated. They have no
  definitions, so they need no catch-all; a test checks that they stay as
  written.
- **Failed computations.** A call that matches a definition and then cannot
  finish gives a `Failure`, through `Enclose` and `Confirm`. No function
  gives a bare `$Failed`.
- **Cost.** Use `Enclose` and `Confirm` in the public function and in helpers
  that run once per call, not inside the interpreter's step or a search's
  inner loop.

### Names

- Arguments, pattern names and local variables have at least three letters
  and say what they hold: `program`, `examples` and `count`, not `p`, `e`
  and `n`.
- The check does not look at iterator variables or the parameters of
  `Function`. Name those with words too, unless the code is an index over a
  short range.
- A file-level value starts with `$`, such as `$requiredHeldOut`.
- Options that this paclet coins have string names, such as `"LibraryCost"`.
  Options that exist in the System context keep their symbols, such as
  `Method`.
- The syntax nodes keep their compact names. Public actions use
  operation-first names, as [the naming skill](../../.agent-skills/wolfram-api-naming/SKILL.md) says.

### Code

- **`With`.** Use `Module` for computation. A `With` may hold one or two
  short constants in one list, or values that must be put into held code:
  a delayed definition, `Dynamic`, `Manipulate`, `Hold` or `Compile`.
- **`Part`.** A position computed from data, such as `values[[index]]`, is
  fine. A fixed position, such as `pair[[1]]`, is not: use a named pattern,
  `First`, `Last`, `Rest` or `Most`.
- **Local functions.** A function defined inside a `Module` keeps its memory
  after the call. Write a file-level helper and pass the state of a search
  along, as an association or as file-level values set with `Block` for one
  call. Tests check that a search leaves no symbols behind.
- **Loops in searches.** The rules against `For`, `Do`, `While` and
  `AppendTo` cannot be waived. The interpreter and the synthesizer use
  `NestWhile`, `Fold` and `Scan`, and advance many values at once as array
  arithmetic. Measure a hot loop before and after rewriting it.
- **`Quiet`.** Name the messages. `Quiet[expr, All]` is for code of other
  packages or for candidate code that is run only to see its values, with a
  comment that says so.
- **The step loop.** The interpreter's definitions for one node take bare
  arguments, each with an allow comment: `EvaluateRecursor` has tested the
  program once, and a test per step would slow every search.
- **Equality.** Use `===` and `=!=` for programs and other exact values.
  Keep `==` for numbers that may be approximate. No program checks this; a
  reviewer does.
- **Width.** A line has at most 200 characters, and breaks near 150. A tab
  counts as four characters.

### Tests

- A test file starts with
  `PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]` and then `Needs`, so
  that `TestReport` can run the file alone. The number is the count of
  folders from the file up to the paclet folder.
- Each public function has a test of its catch-all, which expects the tag
  `"InvalidArguments"` and the message `Name::args`.
- A test reaches a helper through the ``WolframInstitute`Recursor`PackageScope` ``
  context, so a helper that a test needs is declared with `PackageScoped`.

### Plots and documentation examples

Two rules meet here. [The example-style skill](../../.agent-skills/wolfram-example-style/SKILL.md)
asks that examples read like Wolfram Language documentation: one line where
possible, with no option the example does not need. The visualization guide
asks that every plot with quantitative axes has a frame and frame labels.

- **Kernel plotting functions** follow the visualization guide by default.
  A function that plots measurements against other values sets
  `Frame -> True`, `Axes -> False` and a `FrameLabel` in its own options, and
  uses Standard colors or `LightDarkSwitched` pairs. Then an example needs no
  styling. `RecursorProgramTree` keeps its own layout, with Standard colors
  for the four kinds of node.
- **Examples** follow the example-style skill first. An example sets a
  display option only where the page documents that option, or when the
  option carries information the reader needs.
- When an example does need axis labels, it writes them as the visualization
  guide says: `Frame -> True` and `FrameLabel`, never `AxesLabel` or `Ticks`.
- `ImageSize` stays `Automatic` in kernel defaults, as the
  [kernel-options skill](../../.agent-skills/wolfram-kernel-options/SKILL.md)
  says. The visualization guide's advice to fix a size is for one figure made
  for one document, not for a function default.

## How the rules are enforced

`make style` checks every Wolfram Language file in the kernel, the tests, the
scripts and `docs/Hero.wl`. `make check` runs the same check, so CI runs it
too. Each report names the rule, says what to do and cites the guide section.

```bash
make style                                        # every file
make style FILES="Recursor/Kernel/<Area>/<Topic>.wl"
make style-fix FILES="..."                        # apply the mechanical fixes
```

`make style-fix` rewrites what a program can decide: tabs for indentation,
spaces around operators and after commas, comment spacing, closing brackets
that should start a line, statements that share a line, message strings with
raw newlines or long lines, and the first lines of a test file. It writes a
file only when the fixed text parses to the same code.

The check cannot judge whether a name is clear, whether a usage message is
true or whether a pattern is as specific as it could be. A reviewer reads for
those, with the checklist at the end of the coding guide.

The check itself is in `scripts/style`, and `make test` runs its tests in
`scripts/style/tests`.

### Waiving a rule

A rule that needs judgment can be waived for one line with a comment on the
line before it, or on the same line:

```wolfram
(* allow PartLiteral: the parser gives a fixed {line, column} pair *)
```

The comment names one or more rules, then a colon, then the reason. A waiver
without a reason, for an unknown rule, for a rule that cannot be waived, or
that waives nothing is an error. The table below says which rules can be
waived. Keep waivers rare: `make style` counts them, and a reviewer reads
each one.

### Files not yet converted

`scripts/style-legacy.txt` lists files that predate the guides. The check
counts their issues without reporting them. The list has been empty since
2026-11-12, when every file of the kernel, the tests and the scripts was
converted, and nothing may be added to it. New files are checked from the
start.

## Rules

The table is the content of `$StyleRules` in `scripts/style/style.wl`. Write
it again with `make style-fix`, with no files named, after changing a rule. A
test in `scripts/style/tests/Style.wlt` fails when the table is out of date.

<!-- style-rules:start -->
| Rule | What to do | Source | Applies to | Can be waived |
| --- | --- | --- | --- | --- |
| `SyntaxError` | The file must parse. | coding guide | Kernel, Script, Program, Test, Data | no |
| `TabIndentation` | Indent with tabs, not spaces. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `LineWidth` | Keep lines within 200 characters; break near 150. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | yes |
| `NonASCIICharacter` | Keep source ASCII: no em dashes, box-drawing characters or decorative arrows; write a character by its long name. | coding guide, non-negotiable rules | Kernel, Script, Program, Test, Data | no |
| `DoubleHyphen` | Use a hyphen, comma, colon or new sentence, not two hyphens as a dash. | coding guide, non-negotiable rules | Kernel, Script, Program, Test, Data | no |
| `CommentSpacing` | Put a space inside each end of a comment: (\* note \*). | coding guide, Rule 11 | Kernel, Script, Program, Test, Data | no |
| `NestedComment` | Keep comment delimiters out of a comment's text. | coding guide, Rule 11 | Kernel, Script, Program, Test, Data | no |
| `OperatorSpacing` | Put one space on each side of an infix operator; keep ? and :: tight. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `CommaSpacing` | Put one space after a comma and none before it. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `CommaPlacement` | End the line with the comma; never start a line with one. | coding guide, Rules 7 and 13 | Kernel, Script, Program, Test, Data | no |
| `SplitOperator` | Keep a binary operator and both operands on one line; name an intermediate value or use the head form, such as Or[...]. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `StatementPerLine` | Write one statement per line: break after each semicolon. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `HangingSemicolon` | Drop the semicolon before a comma or before the closing bracket of a scoping construct; it gives Null. | coding guide, Rule 13 | Kernel, Script, Program, Test | no |
| `TrailingSpan` | Do not end a line with ;;. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `BracketAlignment` | Put the closing bracket of a multi-line expression on its own line, indented like the line that opens it. | coding guide, Rule 13 | Kernel, Script, Program, Test, Data | no |
| `StringLineBreak` | Do not break a string with a raw newline; end the line with \n\ for a new line of text, or with \ to wrap. | coding guide, Rule 2 | Kernel, Script, Program | no |
| `PostfixApplication` | Use prefix or full application, not postfix //. | coding guide, Rule 10 | Kernel, Script, Program, Test | no |
| `InfixApplication` | Write f[a, b], not a ~f~ b. | coding guide, Rule 10 | Kernel, Script, Program, Test | no |
| `PrefixApplication` | Do not apply @ to a parenthesized expression. | coding guide, Rule 10 | Kernel, Script, Program, Test | no |
| `NestedPureFunction` | Do not nest slot functions; write Function[variable, ...] or a named helper. | coding guide, Rule 10 | Kernel, Script, Program, Test | no |
| `HeadComparison` | Use MatchQ[expr, \_head], not a comparison with Head[expr]. | coding guide, Rule 7 | Kernel, Script, Program, Test | no |
| `ApplyAndOr` | Use And[...], Or[...], AllTrue, AnyTrue or NoneTrue, not And @@ or Or @@. | coding guide, Rule 8 | Kernel, Script, Program, Test | yes |
| `ReturnCall` | Do not use Return; let the value fall out, or use Confirm with Enclose. | coding guide, Rule 6 | Kernel, Script, Program, Test | no |
| `ProceduralLoop` | Do not write For, Do or While; use Table, Map, Scan, Fold, Nest or a relative. | coding guide, Rule 7 | Kernel, Script, Program, Test | no |
| `AppendTo` | Build the list with Table, Map, Fold or Reap, not AppendTo or PrependTo. | coding guide, Rule 9 | Kernel, Script, Program, Test | no |
| `ScopeConstruct` | Use Module, Block or With, not Scope or ModuleScope. | coding guide, Rule 4 | Kernel, Script, Program, Test | no |
| `WithBindings` | Use Module for computation; With is for one or two short constants, or for values injected into held code. | coding guide, Rule 4 | Kernel, Script, Program, Test | yes |
| `NestedWith` | Write nested With as one flat With[{a = ...}, {b = ...}, body]. | coding guide, Rule 4 | Kernel, Script, Program, Test | no |
| `UnusedLocal` | Remove a local variable that is never used. | coding guide, Rule 4 | Kernel, Script, Program, Test | no |
| `OptionalArgument` | Do not give a positional argument a default; add a downvalue for the shorter calling form. | coding guide, Rule 3 | Kernel, Script, Program, Test | no |
| `OptionQPattern` | Take options with opts : OptionsPattern[], not \_\_\_?OptionQ. | coding guide, Rule 3 | Kernel, Script, Program, Test | no |
| `UntaggedControl` | Give Quiet the messages it expects, and Catch, Throw, Sow and Reap a tag. | coding guide, Rule 8 | Kernel, Script, Program, Test | no |
| `PartLiteral` | Do not reach into an expression by a fixed position; use a named pattern, First, Last, Rest or Most. | coding guide, Rule 13 | Kernel, Script, Program, Test | yes |
| `BareFailed` | Give a Failure object, not a bare $Failed. | coding guide, Rule 6 | Kernel, Script, Program | yes |
| `OptionValueTest` | Wrap a Boolean option in TrueQ, or validate it with ConfirmMatch, before testing it. | coding guide, Rule 5 | Kernel, Script, Program, Test | no |
| `ClearAtLoad` | Do not Clear, ClearAll or Remove symbols when a file loads. | coding guide, things to avoid | Kernel, Script | no |
| `QualifiedSymbol` | Import the context and use the short name; do not use internal contexts. | coding guide, Rule 14 | Kernel, Script, Program, Test | yes |
| `ShortName` | Name arguments and local variables with full words of at least three letters that say what they hold. | coding guide, Rule 1 | Kernel, Script, Program, Test | no |
| `LocalShadowsFunction` | Do not give an argument or local variable the name of a function in this codebase. | coding guide, Rule 1 | Kernel, Script | no |
| `SystemNameCollision` | Do not define or export a name that System already has. | coding guide, Rule 1 | Kernel, Script | no |
| `ParameterName` | Start the name of a file-level parameter with $. | coding guide, Rule 1 | Kernel, Script | no |
| `MissingUsage` | Give every function and parameter a usage message, public or private. | coding guide, Rule 2 | Kernel, Script | no |
| `UsageFormat` | Start a usage message with the calling template, then say what it gives. | coding guide, Rule 2 | Kernel, Script | no |
| `OwnArgsMessage` | Do not define ::args; every symbol inherits the generic message. | coding guide, Rule 3 | Kernel, Script | no |
| `MissingCatchAll` | End a public function with a catch-all that gives a Failure; a predicate ends with [\_\_\_] := False. | coding guide, Rule 3 | Kernel, Script | yes |
| `BarePattern` | Give each argument a specific pattern, not a bare blank; only a helper's fallback definition may take any argument. | coding guide, Rule 3 | Kernel, Script | yes |
| `HardCodedColor` | Use a Standard color for data and a LightDarkSwitched pair for other colors; never pin a white or black background. | coding guide, non-negotiable rules; visualization guide, Color | Kernel | yes |
| `CrossingAxes` | Frame the plot: use Frame, FrameLabel and FrameTicks, not Axes, AxesLabel and Ticks. | visualization guide, Frame Every Plot | Kernel | yes |
| `UnframedPlot` | Give a plot with quantitative axes Frame -> True and Axes -> False. | visualization guide, Frame Every Plot | Kernel | yes |
| `TestHeader` | Load the paclet with PacletDirectoryLoad[DirectoryName[$TestFileName, n]], then Needs, so that a test file runs on its own. | coding guide, Rule 15 | Test | no |
| `TestPrint` | Do not Print in a test file. | coding guide, Rule 15 | Test | no |
| `MissingTestID` | Give every VerificationTest a TestID. | coding guide, Rule 15 | Test | no |
| `UnknownAllow` | An allow comment names a rule that exists and can be waived, and gives a reason. | GUIDE.md, Style checks | Kernel, Script, Program, Test, Data | no |
| `UnusedAllow` | Remove an allow comment that waives nothing. | GUIDE.md, Style checks | Kernel, Script, Program, Test, Data | no |
<!-- style-rules:end -->
