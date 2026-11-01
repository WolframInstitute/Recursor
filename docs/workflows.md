# CI and releases

Recursor uses the official Linux Wolfram Engine 15.0 container for tests,
Lean proof checking, documentation and packaging. This follows the Wolfram
build and release arrangement in PARILink and MathlibLink. CI does not download
desktop Wolfram installers.

## Checks

| Workflow | Trigger | Checks |
| --- | --- | --- |
| [Repository checks](../.github/workflows/pull-request.yml) | Pull requests; called by CI | Source whitespace, proof pins, license and workflow syntax |
| [CI](../.github/workflows/ci.yml) | Push to `main`; manual dispatch from `main` | Wolfram tests, Lean proofs, documentation, archive contents and installation |
| [Release](../.github/workflows/release.yml) | `vX.Y.Z` tag; manual retry from `main` | Exact successful CI commit, PacletPage publication, then GitHub release |

CI runs `make check`, `make test`, `make check-proofs` and `make check-publish`.
The proof check builds both Lean modules, audits twelve theorem declarations
and their axioms, and replays the modules in Lean's kernel. The formal model
and implementation have distinct verification scopes; see
[the verification record](notes/Verification.md).

Documentation pages evaluate in fresh kernels. The archive audit compares
kernel code, Lean sources, stylesheets and the packaged license with the
checkout, verifies every documentation page is present, and rejects runtime
caches. An installed-archive check exercises the interpreter, lambda backend,
parser and packaged assets. A clean checkout then verifies that publication
can reuse the identical archive.

Hosted Wolfram and proof integration checks run on Linux x86-64. Local
verification also covers macOS ARM64. This workflow does not claim native
Windows or macOS Wolfram CI coverage. The external MathlibLink release has its
own native Lean/mathlib checks on Linux x86-64, Windows x86-64 and macOS ARM64.

## Pinned build dependencies

| Dependency | Version or source |
| --- | --- |
| MathlibLink | [0.1.0](https://github.com/WolframInstitute/MathlibLink/releases/tag/v0.1.0), with the release archive's SHA-256 verified before installation |
| Lean and mathlib | Lean 4.35.0; mathlib commit `56a005855ea17e0b0958f73ec801ae140b0a1679` |
| LeanLink | 1.2.5 |
| Lambda | 1.2.6, with the archive's SHA-256 verified before installation |
| PacletPage | [ad583493](https://github.com/WolframInstitute/PacletPage/commit/ad583493187194eeaa22d7e774a30ca475934aa4), version 0.3.42 |
| MarkdownToNotebook | [c2b5703c](https://github.com/WolframInstitute/MarkdownToNotebook/commit/c2b5703cc813ef620dd744fca82353bfbfb6ca6f) |
| WolframParser | [0697ceb7](https://github.com/sw1sh/WolframParser/commit/0697ceb787111be04f0d9f043d7674ee146c76c2) |

MathlibLink manages the external Lean runtime and shared mathlib checkout.
The build uses Recursor's library installer to prepare its proof and
visualization dependencies. Documentation tooling is installed explicitly by
the workflow; the documentation script does not download missing tools.

## Repository secrets

Configure these repository secrets before pushing the workflow. The commands
prompt for values; do not place credentials in source files:

```sh
gh secret set WOLFRAMSCRIPT_ENTITLEMENTID --repo WolframInstitute/Recursor
gh secret set WOLFRAM_CLOUD_USER --repo WolframInstitute/Recursor
gh secret set WOLFRAM_CLOUD_PASSWORD --repo WolframInstitute/Recursor
```

The entitlement licenses fresh Wolfram kernels. Cloud credentials belong to
the account authorized to publish the resource. No separate GitHub environment
is required. Pull requests use read-only tokens and no secrets. Cloud
credentials are exposed only to the final publishing step.

## Release and publish

1. Commit the version in `Recursor/PacletInfo.wl` and matching notes in
   `docs/releases/X.Y.Z.md`, then push to `main`.
2. Wait for CI to pass on that exact commit.
3. Create and push the matching `vX.Y.Z` tag.

The release workflow downloads that commit's `Recursor-verified` CI artifact,
checks its provenance and digests, and restores the PacletPage build. It
publishes the resource and documentation, checks the live site, then creates
the GitHub release with the same archive. Publication does not submit to the
Wolfram Paclet Repository.

GitHub assets include the `.paclet`, `SHA256SUMS`, `build.json` and
`pacletpage-build.tar.gz`. A retry accepts identical assets and refuses to
replace changed ones. To retry an existing tag, dispatch **Release** from
`main`. CI artifacts expire after 30 days.

Use `make check-publish` for a local dry run. `make publish` requires the
verified archive and its corresponding build, checks both before publication,
and disables rebuilding. Do not reuse a published version for another commit.
