# Recursor on OEIS: what 9,110 training fits predict

**Checkpoint: 6 November 2026, 10:26:05 EAT (07:26:05 UTC).** The workers continued while this fixed interim report was prepared.

[Mathematica notebook](../../notebooks/RecursorOEISMeasurements-01.nb) · [All programs, sequences and WL functions](data/OEISMeasurements9110.json.gz) · [Numerical results](data/OEISMeasurements9110-metrics.json) · [Reproduction archive](data/OEISMeasurements9110-reproduction.zip)

## Results

**9,110 entries have an eight-term training fit; 897 also pass the twelve-term test; 91 match every recorded term.** These are finite prediction checks, not proofs of infinite sequence identities.

![Training, test and all-recorded success counts](figures/OEISMeasurements9110/01-fits.svg)

*Figure 1. The primary test retains 9.85% of training fits; the all-recorded check retains 1.00%, with 20–348 available terms per entry.*

![Recursor and baseline success counts](figures/OEISMeasurements9110/02-baselines.svg)

*Figure 2. Primary successes out of 283,167 eligible entries: constant baseline 462, Recursor first seed 876, Recursor with completed seeds 897, affine baseline 1,341; second-seed coverage is partial.*

![Overlap with the affine baseline](figures/OEISMeasurements9110/03-overlap.svg)

*Figure 3. Recursor adds 110 primary successes beyond the affine baseline, 42 of which also match every recorded term; overall coverage still favors the affine baseline.*

![One program shared by four OEIS entries](figures/OEISMeasurements9110/23-shared-program.svg)

*Figure 4. The same expression fits every recorded term of these four entries; an entry count is not a count of independent discovered rules.*

![Coverage by distinct training prefixes](figures/OEISMeasurements9110/04-prefixes.svg)

*Figure 5. Only 221 distinct indexed training prefixes and 180 DSL expressions account for the 9,110 fits; prefixes are ranked by decreasing frequency.*

![Program size distributions](figures/OEISMeasurements9110/22-program-complexity.svg)

*Figure 6. Node-count distributions are normalized within each success group; the 91 all-recorded successes contain 66 distinct expressions.*

## Programs that match every recorded term

These ten examples illustrate different recovered behaviors. In prediction plots, the line is OEIS and points are Recursor; vertical guides end training and the primary test. Paired tree-and-plot panels show the first 32 terms; captions count all recorded checks.

![Two successful program trees](figures/OEISMeasurements9110/17-success-tree.svg)

*Figure 7. Syntax trees for the polynomial A028552 and the rounded arithmetic rule A037915; constants are labelled by their values.*

![A028552 predictions](figures/OEISMeasurements9110/18-success-predictions.svg)

*Figure 8. A028552: `n (n + 3)`; six nodes, all 51 recorded terms match, with the first thirty shown.*

![A037915 predictions](figures/OEISMeasurements9110/18b-success-predictions.svg)

*Figure 9. A037915: `Floor[(3 n + 4)/4]`; eight nodes, all 73 recorded terms match, with the first forty shown.*

![Square program and predictions](figures/OEISMeasurements9110/success-A000290.svg)

*Figure 10. A000290: squares, `n^2`; three nodes and all 51 recorded terms match.*

![Cubic program and predictions](figures/OEISMeasurements9110/success-A117642.svg)

*Figure 11. A117642: `3 n^3`; seven nodes and all forty recorded terms match.*

![Rounded-product program and predictions](figures/OEISMeasurements9110/success-A122656.svg)

*Figure 12. A122656: `n Floor[n/2]^2`; seven nodes and all 46 recorded terms match.*

![Program skipping multiples of three](figures/OEISMeasurements9110/success-A001651.svg)

*Figure 13. A001651: positive integers not divisible by three; five nodes and all seventy recorded terms match.*

![Periodic program and predictions](figures/OEISMeasurements9110/success-A131555.svg)

*Figure 14. A131555: repeated blocks `0, 0, 1, 1, 2, 2`; four nodes and all 105 recorded terms match.*

![Course-of-values program for residues](figures/OEISMeasurements9110/success-A010872.svg)

*Figure 15. A010872: residues modulo three, expressed through `CoRec`; five nodes and all 105 recorded terms match.*

![Conditional program and predictions](figures/OEISMeasurements9110/success-A114637.svg)

*Figure 16. A114637: nonnegative integers excluding one and two; a six-node conditional matches all 73 recorded terms.*

![Residue-class enumeration program and predictions](figures/OEISMeasurements9110/success-A047380.svg)

*Figure 17. A047380: positive integers congruent to 1, 2, 4 or 5 modulo seven; ten nodes and all 64 recorded terms match.*

## Where does mutation come from?

[MutateRecursor](https://github.com/WolframInstitute/Recursor/blob/e7786c8b9200a308e495a91e6bb66000d0fa0462/Recursor/Kernel/Evolution/Operators.wl) is a handwritten grammar operator: choose a syntax node uniformly, generate a replacement using its available bindings, and check scope and size. This run uses replacement depth three and at most sixty nodes; mutation calls do not invoke Lean or mathlib.

![A scope-valid subtree mutation](figures/OEISMeasurements9110/16-mutation.svg)

*Figure 18. Seed 2 replaces `Idx` with the in-scope `Acc`, changing factorial into the recurrence starting at 1 with update `a -> a (a + 1)`; this is an illustration, not a recovered OEIS ancestry event.*

## What are the loss curves like?

Loss is `1 - exact training matches/8`: zero means all eight training terms match, 0.125 means seven match, and one means none match. It measures exact agreement, not how close a wrong number is to the correct one. Each curve tracks the best training score so far; a downward-only curve is expected because that best score is retained.

![Mean training loss](figures/OEISMeasurements9110/05-loss.svg)

*Figure 19. Blue averages all 283,164 completed first-pass searches; orange averages the 9,110 training fits selected from completed seeds.*

**The broad search improves modestly:** mean loss falls from 70.45% to 64.43%, equivalent to increasing the average number of correct training terms from 2.36 to 2.85 out of eight. The orange curve ends at zero because it includes only eventual training fits; it cannot establish that the search usually succeeds.

![First generation with a training fit](figures/OEISMeasurements9110/06-first-fit.svg)

*Figure 20. A perfect training fit already exists at generation zero in 7,107 selected histories (78.01%); 2,003 first reach it later.*

Generation zero is the population of 24 randomly generated programs, before mutation or crossover. **Most selected training fits therefore already have a fitting candidate before evolution begins**, although evolution can subsequently find another fitting program or reduce its size. The later 2,003 fits cannot be credited specifically to mutation without a comparison that removes it.

![Individual loss histories](figures/OEISMeasurements9110/07-individual-loss.svg)

*Figure 21. A028552 first fits at generation 19, A037915 at 14 and A191967 at 11; A002837 has zero training loss from the start.*

Flat portions mean the best exact-match count stays unchanged; a drop of 0.125 means one additional training term matches. A028552's final drop adds six matches at once. Only generation boundaries were recorded, so the connecting lines do not show every candidate or identify which operator caused an improvement.

**Lower training loss is not yet evidence of discovering the sequence rule.** A002837 has zero training loss but fails at its 42nd recorded term. Of all 9,110 training fits, only 897 pass the next twelve terms and 91 match every recorded term. On the matched 2,048-entry control, evolution and evolution without mutation each achieve eight primary successes, versus nine for random search. Thus these curves show training progress and some predictive programs, but do not yet demonstrate a generalization advantage from mutation. Held-out terms were checked only for final selected programs, so there is no measured test-loss curve over generations.

## How successful is generalization?

![Matches among the twelve primary test terms](figures/OEISMeasurements9110/08-agreement.svg)

*Figure 22. Test-match counts for all 9,110 training fits; the twelve-match bar contains the 897 primary successes, covering 0.317% of eligible entries.*

![Agreement over longer prediction horizons](figures/OEISMeasurements9110/09-horizon.svg)

*Figure 23. A fixed 7,840-entry cohort with at least 48 terms distinguishes “every term correct so far” from “this term correct”; the denominator stays fixed as the horizon grows.*

![Prediction agreement map](figures/OEISMeasurements9110/10-predictions.svg)

*Figure 24. Columns are 128 hash-selected entries and rows are recorded positions from top to bottom: 0 means a match, 1 a mismatch or unfinished evaluation; rows 1–8 train, 9–20 test.*

![Constant and varying training prefixes](figures/OEISMeasurements9110/11-prefix-groups.svg)

*Figure 25. Of 3,856 constant-prefix fits, 431 pass the primary test and eight match all terms; the corresponding counts for 5,254 varying-prefix fits are 466 and 83.*

**179 of 109,320 primary-test evaluations hit the step budget.** Ten candidate programs fail this test solely through unfinished evaluations, without an observed wrong value; budget exhaustion does not prove nontermination.

![Early failure on the first-digit sequence](figures/OEISMeasurements9110/19-early-failure.svg)

*Figure 26. A000030: `Var` fits ten recorded terms, then returns 10 at input 10 where the first-digit sequence requires 1.*

![Later failure after forty-one matching terms](figures/OEISMeasurements9110/20-late-failure.svg)

*Figure 27. A002837: `Pred[Var]` matches 41 recorded terms, then returns 41 at input 42 where the sequence requires 43.*

![A misleading zero prefix](figures/OEISMeasurements9110/21-zero-prefix.svg)

*Figure 28. A006983: `Const[0]` passes all twenty training and primary-test terms, but the 21st term is 1.*

## Does mutation or a larger search help?

![Matched mutation and crossover comparisons](figures/OEISMeasurements9110/12-arms.svg)

*Figure 29. On the same 2,048 entries at seed 9101, evolution, no mutation, no crossover and random search give 8, 8, 8 and 9 primary successes: no mutation advantage is demonstrated at this budget.*

![Loss in the matched comparisons](figures/OEISMeasurements9110/13-arm-loss.svg)

*Figure 30. Each method proposes 464 candidates; random search samples depth three while evolution starts at depth two, so equal proposal counts do not imply equal distributions or execution time.*

![Larger search outcome counts](figures/OEISMeasurements9110/14-deep-budget.svg)

*Figure 31. On 1,024 matched entries, increasing proposals from 464 to 6,264 and increasing depth raises training fits from 27 to 56, but primary successes only from five to six.*

![Larger search loss curve](figures/OEISMeasurements9110/15-deep-loss.svg)

*Figure 32. Mean training loss on that same 1,024-entry cohort; both budget and depth change, so their effects cannot be separated here.*

## Measurement and reproduction

The [frozen protocol](OEISCorpusExperiment.md) defines eligibility, search budgets, seeds and controls. Of 393,450 source records, 283,167 qualify. Search sees only eight training terms at their original indices; names, formulas, existing WL code and test terms are withheld. Selection uses rechecked training accuracy, then smaller programs, then lower seeds.

The complete first seed produced 8,626 training fits, 876 primary successes and eighty all-recorded successes; three searches timed out. The headline 9,110/897/91 includes a partially completed second seed, with 283,165 entries having a completed candidate. The four-method comparison uses 2,048 matched entries and excludes the forty pilot IDs. These counts measure this search at its recorded budget, not the language's expressive limit or a speed advantage over WL methods.

Mathematica 15.0.0 computed all statistics and 32 figures. The notebook contains editable graphics and executable Input cells; its closed initialization section imports the fixed data without restarting the search. The compressed records preserve all 9,110 programs, sequences, loss histories, per-term checks and standalone WL functions, plus the matched comparisons. Every WL function agrees with all completed Recursor outputs; “compact” means the shortest verified candidate among the implemented translations, not global minimality.

Recursor revision: `e7786c8b9200a308e495a91e6bb66000d0fa0462`. [OEIS snapshot](https://github.com/WolframInstitute/OEIS/tree/d82309e7f1436b641490aa8abf426c39e0d158a7), data revision: `69c667df437a093151042e2cbec1f1198e70765a`. Exact cutoff: `2026-11-06T07:26:05.809007+00:00`. Report-data SHA-256: `1fd52993f55048d6b2f73503869538bc3797b5f100e125c9df398b1780183096`.

Sequence data are © the OEIS Foundation Inc. and contributors, under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); this report, derived data and figures use the same license. Recursor and reproduction code use MIT. The [report archive](data/OEISMeasurements9110-reproduction.zip) contains its generators; the [experiment archive](OEISCorpusExperiment.zip) contains the frozen search runners. Syntax trees use the documented [rooted layered layout](https://reference.wolfram.com/language/ref/method/LayeredEmbedding.html).
