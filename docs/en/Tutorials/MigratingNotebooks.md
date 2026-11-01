---
Template: TechNote
Name: MigratingNotebooks
Title: Migrating Notebooks to Recursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/MigratingNotebooks
RelatedGuides: [Recursor]
---

## Load the paclet

The code-only client is notebooks/RecursorWalkthrough-01.nb in the Recursor
checkout. It loads the paclet and contains computations, figures and measured
runtime comparisons. Notebook clients use the public paclet API.

Run the factorial example:

```wl
EvaluateRecursor[RecursorExamples["Factorial"], 5]
```

The source checkout can be registered with PacletDirectoryLoad. An installed
archive needs only a Needs call for the WolframInstitute Recursor context.
No NotebookDirectory lookup or FromRichard dependency remains in the DSL.

## Install external libraries

The walkthrough begins with the desktop library installer:

```wl
#| eval: false
SetupRecursor[]
```

Choose Lambda for lambda-term visuals and LeanLink and MathlibLink for proof
checking and access to mathlib. Finish installation before running the
corresponding sections. Inspect the resulting status with `RecursorLibraries[]`.

In a script, request the libraries directly:

```wl
#| eval: false
InstallRecursorLibraries[{"LeanLink", "MathlibLink", "Lambda"}]
```

Ready installations are reused. MathlibLink is installed from its published
release; its setup manages the pinned Lean and mathlib runtime. See the
external-library reference pages for setup details.

## Compute and check proofs

The walkthrough includes generic mathlib calls, a totient plot and a theorem
checked through `ProveMathlib`. It also runs Recursor's complete proof audit:

```wl
#| eval: false
CheckRecursorProofs[]
```

The audit builds the packaged sources, checks twelve theorem declarations and
replays the two Lean modules. The following notebook cells inspect the compiler
simulation, lexical closure and universality statements. These concern the
formal denotational language; the Wolfram interpreter and lambda compiler
remain tested implementations.

## Entry points

| Notebook function | Paclet API |
| --- | --- |
| WellFormedQ, ValidProgramQ | RecursorExpressionQ, RecursorProgramQ |
| InterpretProgram, EvalProgram | EvaluateRecursor |
| CompileProgram, NormalizeProgram | CompileRecursor, NormalizeRecursor |
| ParseProgramText | ParseRecursor |
| NodeCount, ScopeNeeded, Sites | RecursorNodeCount, RecursorFreeVariables, RecursorSites |
| ReplaceSubtree, ApplyLLMEdit | ReplaceRecursorPart |
| RandomProgram, Mutate, Crossover | RandomRecursor, MutateRecursor, CrossoverRecursor |
| SimplifyProgram | SimplifyRecursor |
| ScoreProgram, EvolveCombinator | ScoreRecursor, EvolveRecursor |
| ProgramTree, TreeOfLife, LiveFitnessPlot | RecursorProgramTree, RecursorGenealogyGraph, RecursorEvolutionPlot |
| LLMProgramProposer | A caller-supplied Proposer callback |

An optional asset, NotebookCompatibility.wl, supplies aliases for the common
notebook entry points. It is loaded explicitly and is not a second kernel
package. New work should use the operation-first APIs. Start legacy notebook
sessions with a clean kernel so old Global definitions cannot shadow syntax.

## Intentional changes

- WhileLoop is available throughout parsing, validation, evaluation,
  compilation, generation, mutation, crossover and simplification.
- Evaluation resource exhaustion returns Failure instead of None or $Failed.
  The old reductioncap argument was ignored by the direct interpreter;
  MaxSteps now enforces a budget.
- Validity has no 60-node cap. Search uses MaxNodes separately.
- CoRec binds Idx and CGet, not Acc. It inherits an outer Acc.
- Lambda output uses the protected formal lambda head instead of a global Lam
  alias. The compiler and normalizer are self-contained.
- Search takes explicit example pairs, keeps both crossover parents, has a
  per-run score cache and returns progress instead of changing $GPProgress.
- Model selection, network clients and target catalogs belong to callers.
- Subtree utilities are centralized and internal helpers are private.

The generalizations do not promise identical seeded search trajectories to
the notebook. Primitive arithmetic and bounded recursion semantics are
preserved and tested against factorial, Fibonacci, population count and
powers of two.
