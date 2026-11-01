---
Template: Symbol
Name: InstallRecursorLibraries
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/InstallRecursorLibraries
RelatedGuides: [Recursor]
SeeAlso: [RecursorLibraries]
RelatedTutorials: [FormalVerification, VisualizingLambdaCompilation]
---

## Usage

<code>[InstallRecursorLibraries]()[{*name1*, *name2*, *…*}]</code> installs and checks selected external libraries.

## Details & Options

- Supported names are "Lambda", "LeanLink" and "MathlibLink".
- Results are an association indexed by library name. Successful paclet installations return PacletObject; the MathlibLink setup returns its PacletObject after checking the shared mathlib installation. Failures include a setup link and diagnostic details.
- Ready installations are kept. Duplicate names are processed once. Unknown names and invalid argument shapes remain unevaluated without starting an installation.
- Lambda supplies lambda-calculus diagrams. LeanLink supplies the native Lean bridge. MathlibLink supplies the pinned mathematical library and a bridge to its declarations.
- MathlibLink performs explicit runtime setup. It installs the pinned Lean toolchain without changing the global default and prepares the full mathlib library.
- Setup downloads can be substantial. Runtime details are returned by RecursorLibraries["MathlibLink"].
- Installed but unusable paclets report LibrarySetupRequired. Restart the kernel after updating a loaded paclet.
- Before the first MathlibLink release, its paclet is installed from the local Mathematics/MathlibLink/dist archive. Set MATHLIBLINK_PACLET to use another local archive.
- Run make check-proofs from the Recursor repository to build its formalization against the shared mathlib installation.
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
