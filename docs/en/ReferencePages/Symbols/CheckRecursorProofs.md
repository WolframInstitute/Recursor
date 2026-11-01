---
Template: Symbol
Name: CheckRecursorProofs
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/CheckRecursorProofs
RelatedGuides: [Recursor]
SeeAlso: [SetupRecursor, InstallRecursorLibraries, RecursorLibraries, ToRecursor]
RelatedTutorials: [FormalVerification, UniversalComputation]
---

## Usage

<code>[CheckRecursorProofs]()[]</code> builds and checks the packaged Lean proofs.

## Details & Options

- Install LeanLink and MathlibLink with [SetupRecursor]() or [InstallRecursorLibraries]() before running the check. The check does not install missing libraries.
- The proof project uses Lean 4.35.0 and the pinned mathlib v4.35.0 checkout managed by MathlibLink. An incompatible runtime returns Failure.
- The sources are copied from the paclet to a user proof workspace and built with Lake. Mathlib is shared with MathlibLink; no second checkout is created.
- The build uses MathlibLink's local tools, including a managed Git runtime when needed. The caller's environment is preserved.
- The check inspects twelve theorem declarations and their transitive axiom dependencies. Only propext, Classical.choice and Quot.sound are accepted.
- Lean's kernel replays both declaring modules. A successful result is an association with keys "Directory", "Theorems", "Axioms" and "KernelChecks". A failed build or proof check returns Failure.
- "Directory" contains the proof project and verification.log. "KernelChecks" contains the kernel's Success records for Recursor and Universality.
- The universality theorem concerns the formal denotational DSL. The separate operational model has its own checked results. Equivalence between those models, the Wolfram interpreter and the lambda compiler is not established by this audit.
- The terminal command make check-proofs performs the same check.

## Basic Examples

Build and check the proofs after installing the external libraries:

```wl
#| eval: false
report = CheckRecursorProofs[]
```

Inspect the two module checks:

```wl
#| eval: false
report["KernelChecks"]
```

## Applications

List the checked theorems and their axiom dependencies:

```wl
#| eval: false
Grid[Prepend[KeyValueMap[{#1, #2} &, CheckRecursorProofs[]["Axioms"]], {"Theorem", "Axioms"}]]
```

The [computational walkthrough](paclet:WolframInstitute/Recursor/tutorial/MigratingNotebooks)
includes the installation calls, the audit and inspection of the universality theorem.

## Possible Issues

A missing or incompatible external runtime returns a setup diagnostic. Check
`RecursorLibraries[]` before rebuilding. A build failure includes the proof
directory; verification.log records the commands and their output.

The audit can take time on the first run. Later runs reuse the local Lean build.
