---
name: wolfram-code-style
description: Write or refactor Wolfram Language code in this repository (kernel, tests, scripts) so that it follows the coding guides and passes the style check.
---

# Write Wolfram Language code to the coding guides

Use this for any change to a `.wl`, `.wls` or `.wlt` file. Read
[the coding guide](../../docs/coding-guides/WOLFRAMCODINGGUIDE.md) and the
[page on how this repository applies it](../../docs/coding-guides/README.md).
For a plotting function, also read
[the visualization guide](../../docs/coding-guides/WOLFRAMVISUALIZATION.md).
For a `Manipulate`, read
[the Manipulate guide](../../docs/coding-guides/MANIPULATEFUNCTIONCREATION.md).

## Order of work

1. **Understand.** Read the whole file and its tests. For a refactor, note
   every input form, result and message that callers and tests rely on.
2. **Name.** Choose names before bodies. Check a new public name with
   `` NameQ["System`" <> name] `` in the target kernel, and follow
   [the naming skill](../wolfram-api-naming/SKILL.md).
3. **Usage messages.** Write one for every function and parameter, public or
   private, before the definitions. Start with the calling form.
4. **Definitions.** Write one definition per input form with specific
   patterns. End a public function with
   `Name[___] := invalidArgumentsFailure[Name]`, and a predicate with
   `NameQ[___] := False`. Use `Enclose` and `Confirm` for a step that can
   fail.
5. **Bodies.** Use `Module` with one named step per line. Use `Table`, `Map`,
   `Fold`, `Nest` and `Scan`, not loops. Take a fixed position with a named
   pattern, `First` or `Last`, not `Part`. Write helpers at file level; a
   function defined inside a `Module` keeps its memory after the call unless
   it is removed.
6. **Tests.** Update the tests in the same change. Test the catch-all
   (`"InvalidArguments"`, with `Name::args` as the expected message).
7. **Check.** Run the commands below until they report nothing.

```bash
make style-fix FILES="<files>"   # tabs, spacing, brackets, message strings
make style FILES="<files>"       # every rule the program can decide
make test FILES="<test files>"
```

## What the check cannot see

Read the code once more for the rules no program decides:

- A name that passes the length rule and still says nothing, such as `data2`.
- A usage message that no longer matches the patterns.
- A pattern that could be more specific.
- `==` between exact values; use `===`.
- An `Enclose` inside the interpreter's step or a search's inner loop.
- A helper that repeats what another helper or a built-in does.

Run through the Code Quality Checklist at the end of the coding guide before
you call the work done.

## Changing behavior

A refactor keeps behavior. When a rule forces a visible change, such as a
`Failure` where a call used to stay unevaluated, change the tests, the usage
message and the reference page in the same commit, and say so in the release
notes. Do not rename a public symbol, an option or a property without a
request. Change the grammar, binding rules, interpreter, compiler and
generators together, as AGENTS.md says.

## Waivers

Fix the code when a rule fits. Waive a rule only when the guide's own
exception applies, with `(* allow RuleName: reason *)` on the line before.
Typical reasons: a syntax node that stays unevaluated by design, a position
computed by a parser, a loop kept as array arithmetic for speed. A reviewer
reads every waiver.
