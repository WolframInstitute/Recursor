# Synthesis and evolution on OEIS sequences

Two measurements made for Recursor 0.3.0 on the pinned OEIS snapshot of the
corpus experiments. The first tests `SynthesizeRecursor` of the paclet on
sequences that were not used to build it. The second repeats the evolutionary
search of the [corpus v1 experiment](OEISCorpusExperiment.md) on the same
sequences and terms: with the language of 0.2.1, with better selection, and
with variation guided by the values the terms require.

| The first 2,000 sequences, eight terms given | Fitted | Predicted |
| --- | ---: | ---: |
| A straight line through the eight terms | 63 | 10 |
| Evolution, paclet 0.1.0 (corpus v1) | 71 | 9 |
| Evolution, paclet 0.2.1 with Quot and Let | 70 | 8 |
| Improved evolution | 96 | 10 |
| Guided evolution | 1,453 | 65 |
| `SynthesizeRecursor` | 385 | 80 |
| Search program of corpus v2 | 1,274 | 120 |

A sequence is fitted when a program reproduces its eight terms and predicted
when the program also reproduces the next twelve. From twenty terms, 248 of
the 252 programs that `SynthesizeRecursor` solved on 3,000 other sequences
reproduce every later term on record. Guided evolution is in the paclet as
`EvolveRecursor[examples, Method -> "Guided"]`.

## What was asked

- Does Solved in `SynthesizeRecursor` mean that a program continues the
  sequence, on sequences in general and not only on the ones used while
  building it?
- Corpus v1 ran evolution before `Quot` and `Let` existed. Do they help it?
- Can the evolutionary search be made much better, and what does it take?

## Data and criteria

The snapshot, the eligibility rule and the 283,167 eligible sequences are
those of corpus v1. Each input is the original OEIS index. A search sees the
first terms only. Names, formulas and later terms are unavailable to it.

- *Fitted*: the program reproduces the terms the search was given.
- *Predicted* (eight terms given): it also reproduces the terms up to the
  twentieth.
- *Complete*: it also reproduces every later recorded term.
- *Solved*: what `SynthesizeRecursor` itself reports. It keeps the last
  quarter of the terms from its search, and reports Solved when its program
  reproduces them and Evidence reaches 24 bits. The measurements below led
  to a third condition, at least four held-out terms; the tables count the
  programs that meet the first two, whatever the number of terms.

Every program is run by `EvaluateRecursor`. Later terms are checked in order
up to the first one missed, with 5,000,000 steps and ten seconds per term.
A budget failure counts as a miss, never as nontermination.

## SynthesizeRecursor from twenty terms

### Samples

Corpus v2 put one sequence in five, by a hash of its identifier, in a
development split. Three random samples were drawn: 300 and then 1,000
sequences of the development split, and 1,000 of the evaluation split. Each
sequence gives its first twenty terms: fifteen to the search, five held out.
Up to thirty later terms check the program.

The method was set on the development samples only: the hold-out, the
evidence measure and its threshold, the costs of composed programs and the
order of the stages. On the first sample, before the evidence measure
existed, 16 of the 40 programs that reproduced all twenty terms failed on
later terms. On the second, a threshold of 16 bits left 6 wrong programs in
108 and a threshold of 24 left 2 in 99. The threshold was fixed at 24. The
evaluation sample was then run once with the finished code. Its numbers are
below. An earlier run of the same sample, before the stages were reordered,
had solved 96 with 89 of 90 right; the three programs lost were searches
over costlier loop terms, one of them wrong.

### Results

| Programs | Sequences | With later terms on record | Reproduce every later term checked | Share |
| --- | ---: | ---: | ---: | ---: |
| Reproduce the fifteen terms of the search | 242 | 236 | 99 | 41.9% |
| …and the five held-out terms | 133 | 127 | 99 | 78.0% |
| …and have 24 bits of evidence: Solved | 93 | 87 | 87 | 100.0% |
| Held-out terms reproduced, evidence short | 40 | 40 | 12 | 30.0% |
| A held-out term missed | 109 | 109 | 0 | 0.0% |

Nothing found: 758 sequences. Later terms checked per solved program: median 10, at most 30.

| Evidence at least | Programs | With later terms | Reproduce every one | Share |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 119 | 113 | 96 | 85.0% |
| 8 | 106 | 100 | 93 | 93.0% |
| 16 | 98 | 92 | 90 | 97.8% |
| 24 | 93 | 87 | 87 | 100.0% |
| 32 | 88 | 82 | 82 | 100.0% |
| 40 | 85 | 79 | 79 | 100.0% |

| Method | Solved | With later terms | Reproduce every one |
| --- | ---: | ---: | ---: |
| LinearRecurrence | 49 | 43 | 43 |
| Holonomic | 14 | 14 | 14 |
| Recurrence | 9 | 9 | 9 |
| Polynomial | 8 | 8 | 8 |
| ClosedForm | 6 | 6 | 6 |
| Hypergeometric | 3 | 3 | 3 |
| Affine | 3 | 3 | 3 |
| Periodic | 1 | 1 | 1 |

The search program of corpus v2 validated 111 of these sequences from twenty terms; SynthesizeRecursor solved 79 of them and 14 others.
Seconds per sequence: median 7.7, mean 7.5, largest 10.0.

Fitting is weak evidence. Of the programs that reproduce the fifteen terms of
the search, 58% fail later. The five held-out terms remove most of those, and
22% of the programs that pass them still fail. The evidence threshold removes
the rest in this sample: the programs it rejects are right three times in
ten, the programs it accepts were right every time. A sample of 87 cannot
show that a rate is zero. With 87 of 87, the one-sided 95% bound on the rate
of wrong solved programs is 3.4%.

A second sample bears that out. On the first 2,000 sequences of corpus v1's
random order, which were not used to set the method either, 161 of the 165
solved programs with later terms on record reproduce every one. Three of the
four that fail are lines their sequences follow for a long time: the
identity for twenty terms of A358121, 2n for thirty-three terms of the
Beatty sequence A379511, 8n - 2 for forty-seven terms of A189785. Together
the two samples give 248 of 252, or 98%.

### How many terms

The first 1,000 sequences of corpus v1's order, with the first 8, 12, 16 or 20
terms given. Solved here means the held-out terms reproduced and 24 bits of
evidence.

| Terms given | Held out | Fitted | Every later term | Solved | Solved with later terms | …that reproduce every one |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 8 | 2 | 195 | 41 | 21 | 21 | 16 |
| 12 | 3 | 135 | 65 | 41 | 41 | 38 |
| 16 | 4 | 131 | 88 | 65 | 65 | 62 |
| 20 | 5 | 142 | 111 | 95 | 88 | 85 |

Evidence in bits does not replace terms. From eight terms a quarter of the
programs with 24 bits of evidence fail, and a threshold of 48 bits leaves
that share where it was: the failures are sequences that follow a simple
rule exactly for their first terms and then leave it, most of them at the
very next term. The share that continue rises with the terms given. Solved
therefore requires four held-out terms, which the default hold-out gives
from sixteen examples on.

### Compared with the search program of corpus v2

The search program of corpus v2 is native code that enumerates once for the
whole corpus and learns a library over several rounds.
`SynthesizeRecursor` is Wolfram Language, sees one sequence, and stops after
twenty seconds. From twenty terms it solves 79 of the 111 sequences of the
sample that the search program validated, and 14 that it did not. From eight
terms it predicts 80 of the first 2,000 sequences where the search program
predicts 120.

## Evolution

### Protocol

The protocol is that of corpus v1: the sequences in its fixed random order,
eight training terms, seeds 9101 to 9103, population 24, twenty generations,
464 programs per run, at most sixty nodes, 2,000 steps and one second per
evaluation. One of the three runs is chosen by training terms reproduced,
then by size, then by seed, never by later terms. A prefix of the order is a
uniform sample of the corpus.

The first step was to repeat corpus v1 itself. With its own source, the rerun
gives the recorded program in all 900 runs of the first 300 sequences. The
arms then change one thing at a time.

- **Evolution, 0.2.1.** The same search with the paclet source of 0.2.1, whose
  random programs, mutations and crossovers also use `Quot` and `Let`.
- **Improved evolution.** Selection from the program synthesis literature.
  Every term is a test that a program passes or fails. Parents are chosen by
  lexicase selection: the tests are taken in a random order and the programs
  that fail one are dropped, so a program that alone gets one term right
  survives. The population holds one individual per distinct list of values.
  Variation is by small additions and deletions, with crossover now and then.
  Half of the first population are simple fixed programs. A program whose
  values match after a scale and a shift is completed with them.
- **Guided evolution.** Variation that uses what the terms require. A library
  holds the distinct functions of small cost on the training inputs, one
  program each, enumerated once per sequence. A variation picks a node of a
  parent and runs the program backwards: the terms and the values of the rest
  of the program give, for each training input, the interval in which the
  value of the node must lie for the program to be right there. The library
  program inside most intervals replaces the node. A parent can also be given
  an operation with a missing operand, or be joined to a second parent under
  a missing condition; the missing part is found the same way. Half of the
  budget evolves closed programs. The other half evolves the step of a
  recurrence, which is right at a position when it gives the recorded term
  from the recorded earlier terms. Of the programs left by lexicase selection
  the smallest is taken, so a search that already fits goes on to shrink.
  This is semantic backpropagation with a library, as in the random desired
  operator of the genetic programming literature.

The guided arm was tuned on sequences 20,001 to 20,300 of the order, which no
reported arm uses: the size of its library, the recurrence half and the rule
that picks one of three runs. Its library is built by the class enumeration
of `SynthesizeRecursor`. The proposal count does not include that
enumeration; the seconds per sequence do.

### Results

**Eight terms, the first 2,000 sequences**

| Search | Fitted | Predicted | Complete | Seconds per sequence |
| --- | ---: | ---: | ---: | ---: |
| A straight line through the eight terms | 63 | 10 | — | — |
| Evolution, paclet 0.1.0 (the record of corpus v1) | 71 | 9 | 3 | — |
| Evolution, paclet 0.2.1 (with Quot and Let) | 70 | 8 | 2 | 3.5 |
| Improved evolution | 96 | 10 | 3 | 4.8 |
| Guided evolution | 1,453 | 65 | 55 | 4.5 |
| SynthesizeRecursor | 385 | 80 | 71 | 3.9 |
| Search program of corpus v2 | 1,274 | 120 | 100 | — |

SynthesizeRecursor marked 34 of them Solved; 26 of those are predicted and 26 complete.

| Predicted by | Sequences |
| --- | ---: |
| Guided evolution and SynthesizeRecursor | 52 |
| Guided evolution only | 13 |
| SynthesizeRecursor only | 28 |
| Guided evolution, not the search program of corpus v2 | 5 |
| Any of the three | 130 |

Share of fitted programs that predict: evolution 0.2.1 11%; improved 10%; guided 4%; SynthesizeRecursor 21%; search program of corpus v2 9%.

**Each arm against corpus v1 on its own sequences**

| Arm | Sequences | Fitted | v1 fitted | Only this arm | Only v1 | p | Predicted | v1 predicted | Only this arm | Only v1 | p |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Evolution, paclet 0.2.1 (with Quot and Let) | 5,000 | 179 | 184 | 13 | 18 | 0.47 | 21 | 23 | 2 | 4 | 0.69 |
| Improved evolution | 5,000 | 245 | 184 | 73 | 12 | < 0.001 | 29 | 23 | 7 | 1 | 0.07 |
| Improved evolution, five times the budget | 600 | 47 | 20 | 27 | 0 | < 0.001 | 4 | 3 | 1 | 0 | 1 |
| Guided evolution | 2,000 | 1,453 | 71 | 1,382 | 0 | < 0.001 | 65 | 9 | 56 | 0 | < 0.001 |

**Budget, the first 600 sequences**

| Search | Fitted | Predicted | Complete | Seconds per sequence |
| --- | ---: | ---: | ---: | ---: |
| Improved evolution | 25 | 4 | 0 | 4.8 |
| Improved evolution, five times the budget | 47 | 4 | 0 | 20.1 |

**Twenty terms, the first 1,200 sequences**

| Search | Fitted | Every later term | Seconds per sequence |
| --- | ---: | ---: | ---: |
| Improved evolution, twenty terms | 6 | 2 | 15.0 |
| SynthesizeRecursor, twenty terms | 176 | 136 | 7.3 |
| Search program of corpus v2 | 259 | 147 | — |

SynthesizeRecursor marked 116 of them Solved. 107 of those have later terms on record, and 104 reproduce every one.

Only this arm and Only v1 count the sequences that one search reaches and the
other does not; p is the exact sign test on those. Later terms of every
fitted program were checked again with a generous evaluation budget, which
changed no outcome of corpus v1.

### Readings

- **The language additions do not help blind evolution.** With `Quot` and
  `Let` the search of corpus v1 fits 179 of 5,000 sequences where it fitted
  184, and predicts 21 where it predicted 23. Both differences are noise. A
  larger language is a larger space for the same 464 samples.
- **Better selection fits more and predicts no more.** Improved evolution
  fits a third more sequences than corpus v1 (245 against 184 of 5,000). It
  predicts 29 against 23, a difference that chance produces seven times in a
  hundred, and a straight line through the eight terms predicts 25.
- **More terms make blind evolution worse.** With twenty training terms
  improved evolution fits 6 of 1,200 sequences. Every further term is one
  more test that a blind proposal must pass at once. `SynthesizeRecursor`
  fits 176 of the same sequences, and 136 of those continue through every
  recorded term.
- **A larger budget buys fits, not predictions.** Five times the proposals
  fit 47 of the first 600 sequences where the standard budget fits 25. Both
  predict 4, and the longer search takes four times as long.
- **Guidance changes the order of magnitude.** With the same 464 proposals,
  guided evolution fits 1,453 of 2,000 sequences where corpus v1 fitted 71,
  and predicts 65 where it predicted 9. No sequence predicted by corpus v1 is
  lost. 39 of the 65 predicted programs are recurrences.
- **Fitting is not predicting.** Guided evolution fits almost anything, and
  4% of its fits predict. The share falls with size: 10% of its fits of 8 to
  15 nodes predict, 1% of those above 40. `SynthesizeRecursor` fits a
  quarter as many sequences and predicts more of them, 21% of its fits: it
  takes the cheapest program and tests it on terms it did not see.
- **The two searches differ in what they find.** Of the 93 sequences that
  guided evolution or `SynthesizeRecursor` predicts, 52 are predicted by
  both, 13 by guided evolution only and 28 by `SynthesizeRecursor` only.
  Five of the guided predictions are not made by the search program of
  corpus v2 either.

### Programs worth reading

- **Two coordination sequences (A301688, A315036).** Guided evolution finds
  closed programs of 20 and 19 nodes: linear growth with a correction that
  depends on the input modulo three, or on its parity. Each reproduces every
  recorded term, 57 and 50 of them. Neither deterministic search finds them:
  they are deeper than enumeration reaches, and no recurrence of the forms
  searched fits.
- **A product recurrence (A123151).** a(n) = (n(n-1)/2 + n + 1) a(n-3), found
  as a step of 11 nodes with three initial terms.
- **Eight terms that mislead (A324809, A364428, A160936, A043455).** The
  number of endofunctions with at most nine preimages per point is n^n up to
  the tenth term. The ribbon tilings of an 8 × n strip are n! up to 8!. The
  product n · reversal(n-1) · reversal(n+1) is n³ - n while n + 1 has one
  digit. The numbers with three zeros in base 9 are the multiples of 729 at
  first. Each of these was marked Solved from eight terms. No search can tell
  from the terms it has; only more terms can.

## What the comparison says

Selection was not what held evolution back. What it lacked was a way to use
the terms when it changes a program. Random variation samples 464 programs
out of a space that enumeration, with one program per behaviour, covers by
the hundred thousand. Variation that asks "what must this part be" searches
that space instead of sampling it, and each proposal then costs a lookup.

What decides prediction is a different thing: how much the terms say beyond
what the program says. Every search here fits more sequences than it
predicts, and the gap is widest for the search that fits most. The evidence
rule of `SynthesizeRecursor` is the part that carries over. Guided evolution
has no such rule yet, and its fits should be read as candidates.

`EvolveRecursor` now has the guided variation as a method, with a library
from the enumeration that `SynthesizeRecursor` already performs. Two
directions remain.

- Judge evolved programs as synthesized ones are judged: hold terms out and
  report Evidence, so that a fit and a solved program are told apart.
- Use evolution where enumeration ends. The two coordination sequences show
  the place: compositions of twenty nodes around parts the library holds.
  A library learned across sequences, as in corpus v2, would deepen both
  searches.

## Limits

- Eight terms are the protocol of corpus v1, kept for comparison. They are
  too few to establish a rule, for any search.
- Later terms are a finite check. A program that reproduces thirty later
  terms can fail on the next.
- The samples are small beside the corpus. The 2,000 sequences of the main
  table give 65 and 80 predictions; differences of a few sequences between
  arms are noise. The paired tests above say which differences are not.
- `SynthesizeRecursor` stops at a time limit, so its results depend on the
  machine. The measurements ran with nine or ten kernels on a 14-core
  machine and stayed well inside the limit: the slowest sequence took ten
  seconds of twenty.
- The guided arm of the experiment reads internal functions of the paclet
  source. The guided method of the paclet is the same search behind
  `EvolveRecursor`: on sixty tuning sequences each fitted 44, and they
  predicted three and two.

## What the runs cost

The first run of the twenty-term synthesis arm ended with the machine: nine
kernels had grown to 6.6 GB each where 36 GB were installed.
`SynthesizeRecursor` kept about fifty megabytes after every call, because
its local functions referred to one another and to its tables and were never
freed. They are now removed when a search ends, and memory stays flat over
repeated calls. The search was also rewritten as array arithmetic: loop
bodies of one shape run together, the terms of sums and products are
evaluated from values already known, and segment totals are matrix
operations. A call takes about two seconds where it took five, with the
same result on every sequence compared. The measurements made before the
rewrite stand: no search in them came near its time limit, and a search that
finishes is deterministic. The runner now starts fresh kernels every
thousand sequences.

## Reproducibility

The experiment code is in `build/synth` and `build/oeis-evolution-v2`.
[The archive](OEISSynthesisAndEvolution.zip) holds it with the notebook
sources and a README that gives the commands. It needs the snapshot and the
result databases of the corpus experiments, which their own archives
rebuild. [The exported measurements](data/OEISSynthesisAndEvolution.json.gz)
hold the outcome of every sequence in every arm, the fitted programs, and
the sampled measurement of `SynthesizeRecursor`; the notebook reads them.

The methods come from the literature on program synthesis by genetic
programming: lexicase selection (Helmuth, Spector and Matheson 2015; Helmuth
and Spector 2020), uniform mutation by addition and deletion (Helmuth,
McPhee and Spector 2018), running programs backwards and the random desired
operator (Wieloch and Krawiec 2013), and semantic backpropagation with a
library (Pawlak, Wieloch and Krawiec 2015).

OEIS data are copyright the OEIS Foundation Inc. and contributors, under
CC BY-SA 4.0. The experiment code follows Recursor's MIT license.
