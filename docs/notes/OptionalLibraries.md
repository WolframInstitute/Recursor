# External libraries

SetupRecursor opens the desktop library installer, following PureMathSetup's
per-library workflow. InstallRecursorLibraries provides the script interface.
Both offer Lambda, LeanLink and MathlibLink. The shared registry and readiness
checks follow PureMath's OptionalLibraries.wl. Loading Recursor and checking
library status never download or install software.

Lambda provides lambda-calculus diagrams. LeanLink provides the native proof
bridge. MathlibLink manages the pinned mathlib installation and gives generic
access to its declarations, computations and proofs. These are explicit
external-library choices; documentation tooling is not part of this list.

Ready installations are kept. LeanLink readiness checks its local native
runtime before compiling a small theorem, preventing an implicit elan download.
Library checks preserve the caller's context path. An installed paclet that
cannot load returns a setup diagnostic; updating a loaded paclet can require
a fresh kernel.

## MathlibLink installation

The installer checks `MATHLIBLINK_PACLET`, then the sibling
Mathematics/MathlibLink/dist directory, then the versioned GitHub release.
The remote archive follows the same cancellable download and ZIP validation
as the other libraries. A missing release reports how to build or select a
local archive.

The first release is pending. For local development, build its archive with
`make check-publish` in Mathematics/MathlibLink. Recursor finds
`dist/WolframInstitute__MathlibLink-0.1.0.paclet` when loaded from the Institute
source tree. Set `MATHLIBLINK_PACLET` to an absolute archive path for another
layout.

After installing the bridge, Recursor delegates runtime setup to
`InstallMathlib[]`. MathlibLink installs missing elan, Git and curl tools and prepares the Lean
toolchain, mathlib checkout and cache locally. It reuses compatible existing
tools. Downloads come from upstream releases; computations run on the user's
computer. The installer does not change shell profiles or the global Lean default.
Its `MathlibInstallation[]` record reports the exact versions and directory.
The [mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)
tracks a newer development version; the installed source revision is authoritative.

## Checking the Recursor proofs

Run `CheckRecursorProofs[]` after installing MathlibLink, or use
`make check-proofs` from the repository. The check copies the packaged Lean sources into
`$UserBaseDirectory/ApplicationData/Recursor/Lean/4.35.0`, creates a local Lake
project that requires MathlibLink's mathlib directory, and builds it. There is
no second mathlib checkout or cache download.

The sources pin Lean 4.35.0 and mathlib commit
`56a005855ea17e0b0958f73ec801ae140b0a1679` (v4.35.0). A different runtime is
rejected before the proof build. Lake selects the toolchain per command;
the elan global default is unchanged. Build output is saved as
`verification.log` in the proof workspace.

After compilation, the check inspects required theorem declarations and their
axiom dependencies. Only propext, Classical.choice and Quot.sound are allowed;
sorryAx and extra assumptions fail the check. LeanLink then asks Lean's kernel
to replay the core and universality modules. The resulting theorem statements
are described in [Formal Verification](../en/Tutorials/FormalVerification.md).
These checks concern the formal models; they do not silently certify the
Wolfram runtime or lambda backend.

The maintained scripts remain check.wls, test.wls and docs.wls. All setup and
proof-check logic lives in the paclet, and caches remain outside its archive.
