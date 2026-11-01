---
Template: Symbol
Name: InstallRecursorLibraries
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/InstallRecursorLibraries
RelatedGuides: [Recursor]
SeeAlso: [CheckRecursorProofs, RecursorLibraries, SetupRecursor]
RelatedTutorials: [FormalVerification, VisualizingLambdaCompilation]
---

## Usage

<code>[InstallRecursorLibraries]()[{*name1*, *name2*, *…*}]</code> installs and checks selected external libraries.

## Details & Options

- In a desktop notebook, use [SetupRecursor]() to review and install libraries individually.
- Supported names are "Lambda", "LeanLink" and "MathlibLink".
- Results are an association indexed by library name. Successful paclet installations return PacletObject; the MathlibLink setup returns its PacletObject after checking the shared mathlib installation. Failures include diagnostic details and, when setup is required, a setup link.
- Ready installations are kept. Duplicate names are processed once. Unknown names and invalid argument shapes remain unevaluated without starting an installation.
- When both proof libraries are selected, MathlibLink prepares the Lean toolchain before checking LeanLink. Results retain the requested library order.
- Lambda supplies lambda-calculus diagrams. LeanLink supplies the native Lean bridge. MathlibLink supplies the pinned mathematical library and a bridge to its declarations.
- MathlibLink prepares its runtime locally, installing missing elan, Git and curl tools automatically. It installs the pinned Lean toolchain without changing the global default and prepares the full mathlib library.
- Setup downloads can be substantial. Runtime details are returned by RecursorLibraries["MathlibLink"].
- An installed paclet that cannot load reports LibrarySetupRequired. Restart the kernel after updating a loaded paclet. Run InstallRecursorLibraries[{"MathlibLink"}] again to resume incomplete mathlib runtime setup.
- The MathlibLink paclet is taken first from MATHLIBLINK_PACLET, then a sibling Mathematics/MathlibLink/dist archive, then its versioned GitHub release.
- Run [CheckRecursorProofs]() to build and check the formalization against the shared mathlib installation. The terminal equivalent is make check-proofs.
- No library is installed automatically when loading Recursor or checking library status.

## Basic Examples

Install the proof libraries when needed:

```wl
#| eval: false
InstallRecursorLibraries[{"LeanLink", "MathlibLink"}]
```

An empty selection performs no work:

```wl
InstallRecursorLibraries[{}]
```

## Scope

Install the optional visualization library:

```wl
#| eval: false
InstallRecursorLibraries[{"Lambda"}]
```

## Possible Issues

Unknown libraries remain unevaluated:

```wl
InstallRecursorLibraries[{"Unknown"}]
```
