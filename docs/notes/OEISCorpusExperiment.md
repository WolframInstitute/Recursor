# OEIS corpus experiment

This study measures sequence discovery, held-out prediction and the contribution
of mutation in Recursor. It extends the [40-sequence pilot](OEISBenchmark.md)
to a complete, pinned OEIS snapshot. The protocol is frozen before the main run;
results are written as jobs finish. An unfinished run is reported with its
actual coverage, never as a completed corpus experiment.

The [9,110-fit checkpoint report](OEISMeasurements9110.md) includes the
measured loss curves, mutation comparisons, prediction checks and an
evaluated Mathematica notebook. It is an interim result at 07:26:05 UTC on
6 November 2026; the workers continued after that checkpoint.

## Data and coverage

The source is [WolframInstitute/OEIS](https://github.com/WolframInstitute/OEIS),
revision `d82309e7f1436b641490aa8abf426c39e0d158a7`, with `oeisdata` revision
`69c667df437a093151042e2cbec1f1198e70765a`. All 393,450 sequence files were
checked against their Git blobs. The inventory SHA-256 is
`2f6091f44c70386249e517303de5ff48c0ab590ac92b191e904c545373ca4431`.

The complete inventory remains in the results, including excluded entries.
Recursor operates on natural numbers. The experiment admits records with the
`nonn` keyword, a nonnegative first offset, at least twenty terms, no negative
recorded terms, and neither `dead` nor `full`. This admits 283,167 sequences.
The other 110,283 records retain their exclusion reasons. A `fini` keyword
alone does not exclude a record. The experiment uses terms in the pinned
sequence files; linked b-files are outside this protocol.

Each input is its original OEIS index. The first eight terms are training data;
the next twelve are the primary test. All further recorded terms form a
separate extended test. Names, formulas, existing WL implementations and test
terms are unavailable to search. Existing OEIS WL code is preserved as
unexecuted reference text in the exported records.

## Search budget

The runtime is pinned to Recursor revision
`e7786c8b9200a308e495a91e6bb66000d0fa0462`. Each standard run uses population
24, twenty generations, two elites, tournament size three, crossover rate
0.8, mutation rate 0.3, initial depth two, replacement depth three, at most
sixty syntax nodes and generated constants zero through three. Unbounded-loop
constructors are enabled. No seed programs or proposer callback are supplied.
Search continues through all generations after a training fit.

This gives 464 candidate proposals per standard run. Fitness is the count of
exact training matches; training loss is `1 - fitness/8`. Syntax size breaks
ties. Every evaluation has a 2,000-step, one-second and 64 MiB budget. Whole
standard searches have thirty seconds and 512 MiB; final validation has 120
seconds. Exhausted budgets are recorded as failures, not nontermination.

The main arm has seeds 9101, 9102 and 9103 for every eligible sequence.
Programs from different seeds are selected by independently checked training
matches, then fewer nodes, then lower seed. Test outcomes never select the
reported program. The count of sequences with *any* successful seed is also
reported, separately from the training-selected result.

Identical indexed training prefixes with the same seed and arm share a
completed search. Each reuse identifies its source job, and each sequence has
independent held-out validation. There are 222,297 distinct indexed training
prefixes. Shared prefixes are not independent evidence.

## Mutation and search comparisons

Sort eligible IDs by SHA-256 of `Recursor-OEIS-corpus-v1:` followed by the
A-number. Excluding all forty pilot IDs, the first 2,048 form a fixed comparison
cohort. The same three seeds run four arms:

- Standard evolution.
- Evolution with mutation probability zero.
- Evolution with crossover probability zero.
- Independent random search with 464 grammar-generated candidates of depth
  three, ranked by the same training fitness and syntax size.

These comparisons match candidate proposals, not execution time. Paired
success comparisons include attempted trials with resource failures as
unsuccessful. Loss-curve comparisons use completed matched trials and report
their separate denominator. Differences cannot be inferred from unmatched
interim totals.

The first 1,024 IDs in that cohort also receive a deeper search at seed 9101:
population 64, one hundred generations, initial depth three and replacement
depth four, giving 6,264 proposals with a 180-second search budget. This tests
whether a larger search budget changes the measured outcome.

Two inexpensive baselines are evaluated over the same indexed windows: the
last training value and the affine rule through the first two training terms.
Their results are reported on the same covered subset as Recursor, as well as
on the full eligible corpus. Constant prefixes and repeated prefixes are
identified so easy or redundant records do not masquerade as broad discovery.

## Records and interpretation

Every trial records its sequence ID, seed, arm, program, node count, training
fitness, generation history, candidate counts, timings and resource outcomes.
Final checks preserve each input, expected term, returned value or failure,
and exact-match flag. Very large returned integers retain their digit count
and hash; their match flags are computed using the full integers.

The standalone WL function is generated by structural translation, safe
Recursor simplification, arithmetic simplification where applicable and a
small set of exact constructor-pattern translations. The shortest candidate
agreeing with every completed Recursor output is retained. This is a compact
verified candidate, not a claim of global minimality or a machine-checked
compiler theorem. Translation checks covered 1,017 programs, 4,232 completed
structural comparisons and 777 compact-candidate comparisons without a
discrepancy; budget-limited reference evaluations were counted separately.

The report distinguishes training fits, joint training-and-primary-test fits,
and extended-test fits with the number of available further terms. It includes
loss curves, exact-match distributions, prediction agreement by distance from
training, matched arm comparisons, larger-budget comparisons and example
program trees. Per-position prediction agreement is not a cumulative survival
curve. A fit to every recorded term is finite evidence, not a proof of an
infinite sequence identity.

## Execution and reproducibility

The plan contains 868,957 jobs. Scheduling prioritizes one seed across all
283,167 eligible records, then the first comparison and deeper-search pass,
then further full-corpus seeds and remaining comparisons. A 264-trial timing
calibration used ten workers; the overnight run uses twelve workers with a
24-hour dispatch limit. These resource settings are recorded per trial.
Pending jobs remain resumable if the full plan exceeds that limit.

The local experiment is in `build/oeis-corpus-v1`. `results.sqlite3` checkpoints
each job. `progress.md` and `summary.json` update each minute. Detailed reports,
CSV exports and scientific figures update hourly and at shutdown. The export
`sequence-results.csv.gz` includes all records and exclusions; `generalized.csv`
includes training-selected programs fitting all eight training and twelve
primary test terms, with extended-test results in separate columns.

[The frozen experiment archive](OEISCorpusExperiment.zip) contains the runners,
protocol, cohort IDs, source hashes, verification results and reproduction
instructions. The source manifest is checked whenever a worker starts. Raw
corpus data and growing trial databases stay outside Git. Search data are
copyright the OEIS Foundation Inc. and contributors, under CC BY-SA 4.0;
Recursor and the experiment code use the MIT license.
