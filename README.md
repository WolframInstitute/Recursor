# Recursor

[![CI](https://github.com/WolframInstitute/Recursor/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/Recursor/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/Recursor/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/Recursor/actions/workflows/release.yml)

A universal natural-number language for program synthesis and evolution.

Recursor includes a direct interpreter, a compiler to closed lambda terms, a
text parser, scope-aware genetic operators, evolutionary search and program
and ancestry plots.

Requires Wolfram Language 15.0 or later.

[Documentation](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/) ·
[Wolfram resource](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Recursor/) ·
[Releases](https://github.com/WolframInstitute/Recursor/releases)

## Why a DSL for evolving lambda expressions?

A compact DSL provides a structured search space for generating, testing and
evolving programs, with explicit rules for scope and execution. Recursor
compiles these programs directly to lambda expressions, giving them a portable
representation and a basis for formal reasoning.

Wolfram Language supports the experiments and visualizations. Arbitrary WL
expressions can depend on definitions, attributes, evaluation order and side
effects; a faithful lambda translation would need to reproduce those behaviors.
WL can implement the system, while Recursor gives generated programs a small,
explicit semantics that can be translated and verified independently.

## Get started

Install and load the paclet:

```wl
PacletInstall[ResourceObject["https://wolfr.am/1IuTobNWg"]]
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
universality theorem. The evaluator uses finite resource budgets by default
and returns `Failure` when one is exhausted. Each budget accepts `Infinity`.

## External libraries

Open the local library installer:

```wl
SetupRecursor[]
```

For scripts, install the selected libraries directly:

```wl
InstallRecursorLibraries[{"LeanLink", "MathlibLink", "Lambda"}]
```

Use [`RecursorLibraries[]`](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#ref/RecursorLibraries)
to check their status. See [library installation](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#ref/InstallRecursorLibraries)
for setup details.

Run [`CheckRecursorProofs[]`](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#ref/CheckRecursorProofs) to build and check the packaged Lean proofs.

## Documentation

- [Guides and function reference](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#guide/Recursor).
- [Computational walkthrough](notebooks/RecursorWalkthrough-01.nb) — runnable Input cells with saved results.
- [Language semantics](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/LanguageSemantics) — syntax, scope and evaluation.
- [Formal verification](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/FormalVerification) — checked statements and their scope.
- [Evolving lambda expressions](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/EvolvingLambdaExpressions) — candidate programs, finite fitness and portable lambda terms.
- [Universal computation](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/UniversalComputation) — counter machines and the checked universality theorem.
- [Arithmetic patterns](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/ArithmeticPatterns) — recurrences, binary digits and residues.
- [Halting and budgets](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/HaltingAndBudgets) — trajectories and finite observation.
- [Lambda reductions](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/VisualizingLambdaCompilation) — compiled terms and reduction graphs.
- [Evolutionary experiments](https://www.wolframcloud.com/obj/wolframinstitute/Recursor/#tutorial/EvolutionaryExperiments) — mutation, search and ancestry.
- [OEIS benchmark](docs/en/Tutorials/MeasuringOEISSequenceDiscovery.md) — measured fits, training curves and held-out predictions using WolframInstitute/OEIS data.

## Development

Load the source paclet from this repository:

```wl
PacletDirectoryLoad[FileNameJoin[{Directory[], "Recursor"}]]
Needs["WolframInstitute`Recursor`"]
```

| Command | Purpose |
| --- | --- |
| `make check` | Check source, metadata and reference coverage |
| `make check-proofs` | Build and check the Lean proofs |
| `make test` | Run tests |
| `make notebooks` | Build documentation with PacletPage |
| `make check-publish` | Build the paclet archive without publishing |
| `make publish` | Publish the paclet and documentation |

See [GUIDE.md](GUIDE.md) for development conventions and
[API naming](docs/notes/Naming.md) for public-name conventions. The
[CI and release guide](docs/workflows.md) describes automated checks and publication.

Released under the [MIT license](LICENSE).
OEIS benchmark data retain their [CC BY-SA 4.0 license and attribution](Recursor/Assets/Benchmarks/OEIS/NOTICE.md).
