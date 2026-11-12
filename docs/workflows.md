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
| [Release](../.github/workflows/release.yml) | Pushed `vX.Y.Z` tag; manual retry | Exact successful CI commit, PacletPage publication, then GitHub release |

CI runs `make check`, `make test`, `make check-proofs` and `make check-publish`.
The proof check builds both Lean modules, audits twelve theorem declarations
and their axioms, and replays the modules in Lean's kernel. The formal model
and implementation have distinct verification scopes; see
[the verification record](notes/Verification.md).

PacletPage evaluates the documentation in one sequential build, resetting
definitions between pages. The proof-import tutorial runs in a separate kernel
to release its native Lean regions when it exits. The archive audit compares
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

The Wolfram job takes its license from one of two secrets, and publication
needs the cloud account. The commands prompt for values or read a file git
ignores; do not place credentials in source files.

### License: a mathpass

`WOLFRAM_MATHPASS_B64` holds a mathpass: a license line for one machine, which
the kernel knows by its MathID. With it the kernel runs offline, uses no
service credits and has no shared kernel slots to run out of. In a Linux
container the MathID comes from the machine-id and the host name, so CI fixes
both: the machine-id in `.github/actions/setup-recursor` and the host name
`ruliology-ci` in the container options of `ci.yml` and `release.yml`.
Changing either changes the MathID, and the line then needs a new password.
Both values are those of the Ruliology repository, so the two containers have
one MathID and the mathpass issued for Ruliology's CI licenses this one too.
An activation key gives a password for one MathID only.
To set the license up:

1. Start CI by hand and read the step *Install the license and start a
   kernel*. It prints the machine name and the MathID of the container, also
   when no license works yet:

   ```sh
   gh workflow run ci.yml --ref main
   ```

2. Have a password issued for that MathID and your activation key. Depending
   on the license, it comes from user.wolfram.com or from Wolfram's licensing
   team.
3. Write the line to `.mathpass`, which git ignores, with tabs between its
   four parts. Store it base64-encoded, so that the tabs survive:

   ```sh
   printf 'ruliology-ci\t%s\t%s\t%s\n' '<MathID>' '<activation key>' '<password>' > .mathpass
   base64 < .mathpass | tr -d '\n' | gh secret set WOLFRAM_MATHPASS_B64 --repo WolframInstitute/Recursor
   ```

4. Run CI again. The same step prints the license type, its expiry and the
   MathID it runs under.

### License: an on-demand entitlement

Without that secret the job uses the entitlement in
`WOLFRAMSCRIPT_ENTITLEMENTID`, which is charged to the account's service
credits:

```sh
gh secret set WOLFRAMSCRIPT_ENTITLEMENTID --repo WolframInstitute/Recursor
```

Use a dedicated Recursor entitlement to keep its kernel allowance separate
from other projects. If a fresh kernel reports "No valid password found",
check the entitlement's expiry, active kernel count and service-credit
balance. Occupied license slots can outlive a stopped runner until their
leases expire. Repeated CI runs can consume the remaining slots; wait for
capacity rather than repeatedly retrying. When both secrets are set, the
mathpass is used and the entitlement is left out.

### Cloud account

```sh
gh secret set WOLFRAM_CLOUD_USER --repo WolframInstitute/Recursor
gh secret set WOLFRAM_CLOUD_PASSWORD --repo WolframInstitute/Recursor
```

Cloud credentials belong to the account authorized to publish the resource.
No separate GitHub environment is required. Pull requests use read-only
tokens and no secrets. Cloud credentials are exposed only to the final
publishing step.

## Release and publish

Commit the version in `Recursor/PacletInfo.wl` and matching notes in
`docs/releases/X.Y.Z.md`, then push to `main`:

```sh
git push origin main
```

Pushing to `main` runs CI and publishes nothing. When CI has passed for that
commit, tag it and push the tag:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

The tag starts Release. It requires the tag to match the version in
`Recursor/PacletInfo.wl`, to point to a commit on `main` with release notes,
and to have a successful CI run for that exact commit. A tag pushed before CI
has passed fails this check; rerun the failed **Release** run once CI is green.

The release workflow downloads that commit's `Recursor-verified` CI artifact,
checks its provenance and digests, and restores the PacletPage build. It
publishes the resource and documentation, checks the live site, then creates
the GitHub release with the same archive. It never creates or moves a tag.
Publication does not submit to the Wolfram Paclet Repository.

GitHub assets include the `.paclet`, `SHA256SUMS`, `build.json` and
`pacletpage-build.tar.gz`. A retry accepts identical assets and refuses to
replace changed ones. Retry a failed **Release** run to retain its original
CI artifact. A manual **Release** dispatch from `main` for an existing tag is
also available. CI artifacts expire after 30 days.

Use `make check-publish` for a local dry run. `make publish` requires the
verified archive and its corresponding build, checks both before publication,
and disables rebuilding. Do not reuse a published version for another commit.

## Resource page

The resource page opens with the Basic Description of
`Recursor/ResourceDefinition.md` beside the image `docs/Hero.png`. The
description holds paragraphs, level-3 headings and lists whose items read
`Label: detail`, all in plain text. Publication renders the headings and rows
itself, because the stock page keeps only the prose. `make check-publish`
checks that rendering and writes it to `build/resource-description.html`.

`make hero` redraws the image from `docs/Hero.wl`, which computes each picture
with the paclet or from `docs/notes/data/OEISCorpusV2Hero.json.gz`. The file
has five designs; `HERO` in the Makefile names the one in use. Commit the
redrawn image with the change that prompted it.
