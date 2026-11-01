# Recursor

A universal natural-number language for program synthesis and evolution.

Recursor includes a direct interpreter, a compiler to closed lambda terms, a
text parser, scope-aware genetic operators, evolutionary search and program
and ancestry plots.

Requires Wolfram Language 15.0 or later.

## Why a DSL for AI?

A compact DSL gives AI systems a small, explicit language for proposing,
testing and transforming programs, with clear rules for scope and execution.
Recursor compiles directly to lambda expressions, giving these programs a
portable computational meaning and a basis for formal reasoning.

Wolfram Language supports the experiments and visualizations. Arbitrary WL
expressions can depend on definitions, attributes, evaluation order and side
effects; a faithful lambda translation would need to reproduce those behaviors.
WL can implement the system, while Recursor gives generated programs a small,
explicit semantics that can be translated and verified independently.

## Get started

Load the source paclet from this repository:

```wl
PacletDirectoryLoad[FileNameJoin[{Directory[], "Recursor"}]]
Needs["WolframInstitute`Recursor`"]
```

Compute a factorial:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 6]
(* 720 *)
```

Run a countdown:

```wl
EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 100]
(* 0 *)
```

`WhileLoop` provides unbounded iteration. `ToRecursor` translates counter
machines and partial-recursive codes. Lean checks the formal language's
universality theorem. Evaluations use finite resource budgets by default
and return `Failure` when a limit is reached.

## External libraries

Open the local library installer:

```wl
SetupRecursor[]
```

For scripts, install the selected libraries directly:

```wl
InstallRecursorLibraries[{"LeanLink", "MathlibLink", "Lambda"}]
```

Use `RecursorLibraries[]` to check their status. See
[external libraries](docs/notes/OptionalLibraries.md) for setup details.

Run `CheckRecursorProofs[]` to build and check the packaged Lean proofs.

## Documentation

- [Computational walkthrough](notebooks/RecursorWalkthrough-01.nb) — runnable Input cells with saved results.
- [Language semantics](docs/en/Tutorials/LanguageSemantics.md) — syntax, scope and evaluation.
- [Formal verification](docs/en/Tutorials/FormalVerification.md) — checked statements and their scope.
- [Programs for AI](docs/en/Tutorials/ProgramsForAI.md) — explicit programs and portable lambda terms.
- [Universal computation](docs/en/Tutorials/UniversalComputation.md) — counter machines and the checked universality theorem.
- [Arithmetic patterns](docs/en/Tutorials/ArithmeticPatterns.md) — recurrences, binary digits and residues.
- [Halting and budgets](docs/en/Tutorials/HaltingAndBudgets.md) — trajectories and finite observation.
- [Lambda reductions](docs/en/Tutorials/VisualizingLambdaCompilation.md) — compiled terms and reduction graphs.
- [Evolutionary experiments](docs/en/Tutorials/EvolutionaryExperiments.md) — mutation, search and ancestry.

## Development

| Command | Purpose |
| --- | --- |
| `make check` | Check source, metadata and reference coverage |
| `make check-proofs` | Build and check the Lean proofs |
| `make test` | Run tests |
| `make notebooks` | Build documentation with PacletPage |
| `make check-publish` | Build the paclet archive without publishing |
| `make publish` | Publish the paclet and documentation |

See [GUIDE.md](GUIDE.md) for development conventions and
[API naming](docs/notes/Naming.md) for public-name conventions.
