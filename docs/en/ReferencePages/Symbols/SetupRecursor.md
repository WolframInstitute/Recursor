---
Template: Symbol
Name: SetupRecursor
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/ref/SetupRecursor
RelatedGuides: [Recursor]
SeeAlso: [RecursorLibraries, InstallRecursorLibraries, CheckRecursorProofs]
RelatedTutorials: [FormalVerification, VisualizingLambdaCompilation]
---

## Usage

<code>[SetupRecursor]()[]</code> opens a desktop dialog to review, install or uninstall external libraries.

## Details & Options

- The dialog lists Lambda, LeanLink and MathlibLink, with their status and setup instructions.
- Each library has its own Install or Uninstall button and a link to copy the corresponding command. The order remains Lambda, LeanLink, MathlibLink after installation or removal.
- Installation reports progress in the dialog. Cancel download stops the current cancellable transfer; failed or cancelled operations can be retried. Installation and removal leave the dialog open.
- Uninstall removes the library's paclet. It keeps separately installed Lean toolchains and the shared mathlib files. Restart the kernel to clear code that was already loaded.
- Close dismisses the dialog. Calling SetupRecursor[] again selects an open dialog or creates a new one.
- A desktop load can show a reminder about missing libraries until setup has been used or dismissed. Loading Recursor never opens the dialog or installs a library automatically.
- SetupRecursor[] returns Null after opening the dialog. It returns Failure["NotebookRequired", ...] in scripts, cloud evaluations, CI and parallel kernels. Use [InstallRecursorLibraries]() for scripted installation.
- MathlibLink installs missing prerequisites and prepares the pinned Lean toolchain and mathlib. It keeps compatible existing tools.
- The MathlibLink paclet is taken first from MATHLIBLINK_PACLET, then a sibling Mathematics/MathlibLink/dist archive, then its versioned GitHub release. A missing release reports how to build or select one.
- If MathlibLink's paclet is installed but its runtime setup is incomplete, its button reads Uninstall. Resume runtime setup with InstallRecursorLibraries[{"MathlibLink"}], or uninstall the paclet and install it again in the dialog.
- Libraries that need manual setup retain their setup instructions. Older MathlibLink releases without cancellable runtime setup show an indeterminate installation indicator while that operation runs.

## Basic Examples

Review the libraries in a desktop notebook:

```wl
#| eval: false
SetupRecursor[]
```

Inspect the available library names without starting an installation:

```wl
Keys[RecursorLibraries[]]
```

## Scope

Use the command-line installer in a script:

```wl
#| eval: false
InstallRecursorLibraries[{"LeanLink", "MathlibLink"}]
```

## Possible Issues

A headless kernel cannot open the dialog:

```wl
Block[{$Notebooks = False}, SetupRecursor[]]
```
