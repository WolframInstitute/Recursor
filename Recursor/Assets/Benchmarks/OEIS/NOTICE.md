# OEIS benchmark data

Sequence names, terms, offsets and keywords in `Cohort.json`, and expected
sequence terms in `Results.json`, are derived from the OEIS database,
copyright OEIS Foundation Inc. and its contributors, and are licensed under
[Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
The repository's MIT license does not replace this data license.

Source: [WolframInstitute/OEIS](https://github.com/WolframInstitute/OEIS/tree/d82309e7f1436b641490aa8abf426c39e0d158a7),
using its `oeisdata` submodule at
[`69c667df437a093151042e2cbec1f1198e70765a`](https://github.com/oeis/oeisdata/tree/69c667df437a093151042e2cbec1f1198e70765a).
Every entry records its OEIS page, pinned source URL and source-file SHA-256.

Changes: select 32 eligible sequences and eight named controls, retain their
first 20 terms at the original offsets, and attach results of Recursor searches.
The derived benchmark data files are distributed under CC BY-SA 4.0.
The experiment code remains under the repository's MIT license.

Generated formulas, `PureFunction` definitions and enrichment comments are
not benchmark inputs. The upstream parser independently checked all stored
terms and offsets. See the computational essay and `docs/notes/OEISBenchmark.md`
in the source repository for the protocol, limitations and reproduction steps.
