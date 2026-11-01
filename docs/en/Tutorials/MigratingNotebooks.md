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
