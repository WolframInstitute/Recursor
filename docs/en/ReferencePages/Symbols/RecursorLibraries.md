---
Template: Symbol
Name: RecursorLibraries
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/RecursorLibraries
RelatedGuides: [Recursor]
SeeAlso: [InstallRecursorLibraries]
RelatedTutorials: [FormalVerification, VisualizingLambdaCompilation]
---

## Usage

<code>[RecursorLibraries]()[]</code> gives the available external libraries and their status.

<code>[RecursorLibraries]()[*name*]</code> gives information about one library.

## Details & Options

- The library names are "Lambda", "LeanLink" and "MathlibLink".
- Status is "Ready", "Not installed", "Update available" or "Needs setup".
- Checking status never installs a library. LeanLink readiness includes compiling a small proof against its local native runtime.
- Each entry includes a description and a link to its upstream project. Paclet entries include the installed and minimum versions. MathlibLink includes its pinned revision, Lean toolchain and local mathlib directory when installed.
- Loading a library during a check does not add its context to the caller's context path.
- MathlibLink installs mathlib in a separate user directory; its caches are not included in the Recursor paclet.

## Basic Examples

List the offered libraries:

```wl
Keys[RecursorLibraries[]]
```

Inspect the installed lambda library:

```wl
RecursorLibraries["Lambda"]
```

## Scope

Inspect the mathlib documentation link:

```wl
RecursorLibraries["MathlibLink"]["URL"]
```

## Applications

Show which features each library supplies:

```wl
Grid[Prepend[KeyValueMap[{#1, #2["Description"], #2["Status"]} &, RecursorLibraries[]], {"Library", "Purpose", "Status"}]]
```

## Possible Issues

An unknown name remains unevaluated:

```wl
RecursorLibraries["Unknown"]
```
