# OEIS corpus experiment v2

This study repeats the [corpus v1 experiment](OEISCorpusExperiment.md) on the
same pinned OEIS snapshot with a different search. Corpus v1 evolved 464
candidate programs per sequence. Corpus v2 enumerates programs once for the
whole corpus, checks recurrences against the data and solves for constants.
It uses two additions to the language, `Quot` and `Let`.

These are checkpoint results after 4 completed rounds per protocol,
exported 2026-11-10 04:01 UTC. The campaign keeps running; later rounds add
sequences.

| Of 283,167 eligible sequences | Corpus v1 | Corpus v2 |
| --- | ---: | ---: |
| Eight terms predict the next twelve | 876 | 19,919 |
| …and every later recorded term | 130 | 17,033 |
| A program reproduces the first twenty terms | not measured | 60,199 |
| …and every later recorded term | not measured | 33,506 |

The first row is the v1 criterion. Corpus v2 passes it for 7.03% of the corpus,
22.7 times the v1 count and 14.9 times the straight-line baseline of 1,341.

## What changed

**Language.** `Quot[a, b]` is the integer quotient. `Let[value, body]`
evaluates a body with a new input, so a closed program can be applied inside
another. Sums and products of a subprogram, the n-th number with a property
and compositions are then ordinary programs. Both constructs are in the
interpreter, the lambda compiler and the Lean models.

**Search.** Four mechanisms replace evolution.

- *One enumeration for all sequences.* Programs are listed by increasing
  cost. Two programs with the same values on the inputs 0 to 11 (0 to 23
  for twenty training terms) count as one, and only the cheapest is kept.
  Each kept program is looked up against every training window at once.
  Levels contain arithmetic, conditionals, bounded loops, compositions
  through `Let`, and transforms of earlier programs: partial sums and
  products, differences, the n-th number with a property and counts.
- *Recurrences checked against the data.* A step a(i) = F(i, a(i-1),
  a(i-2), a(i-3), a(⌊i/2⌋)) is evaluated on the recorded earlier terms at
  each training position. No candidate is run from its start. Initial
  terms are read from the data; extra initial terms absorb exceptions.
- *Exact solving.* Linear algebra modulo a prime finds integer
  coefficients of recurrences with polynomial coefficients, periodic
  increments, polynomials and constant tails. Spare training terms must
  confirm each solution.
- *A library.* Subprograms shared by the selected programs of several
  windows, and recurrences found for single windows, become building
  blocks of the next round. Odd rounds search deeper without the library;
  even rounds search with it.

**Cost and selection.** Each window keeps the cheapest program found. Cost
counts the syntax nodes the search chose. A constant up to three costs one
node and every further two bits cost one more, so initial terms and solved
constants pay for what they say. A window that has a program keeps it in
later rounds.

**Two protocols.** P8 is the v1 protocol: search sees eight terms and the
next twelve are the test. P20 gives search the first twenty terms and tests
every later recorded term. Eight terms often admit a cheaper explanation
than the intended one; twenty terms rarely do.

**Isolation.** The search program reads a file that holds training terms
only. Wolfram kernels then evaluate every proposed program with
`EvaluateRecursor` and compare it with the recorded terms. Validation
outcomes never choose programs, build the library or set parameters.

## Data and criteria

The snapshot, the eligibility rule and the 283,167 eligible sequences are those
of corpus v1. Each input is the original OEIS index. A sequence counts in
P8 when its program reproduces the eight training terms and the next twelve.
It counts as represented in P20 when its program reproduces the first twenty
terms, and as validated when the program also reproduces every later
recorded term. Sequences that share a training window share a program and
are checked separately; they are not independent evidence.

## Results

### From eight terms

178,624 sequences have a program that reproduces their training terms, from
120,685 distinct training windows and 119,609 distinct programs.
19,919 pass the twelve-term test and 17,033 of the 176,811 with later terms reproduce
every recorded term.

| Method | Reproduce training terms | Pass the twelve-term test | Share |
| --- | ---: | ---: | ---: |
| Linear | 7,447 | 5,884 | 79.01% |
| Closed | 52,850 | 5,169 | 9.78% |
| Recurrence | 89,063 | 2,670 | 3.00% |
| Affine | 12,973 | 2,272 | 17.51% |
| Polynomial | 1,757 | 1,630 | 92.77% |
| Periodic | 5,609 | 885 | 15.78% |
| Hypergeometric | 715 | 628 | 87.83% |
| Constant | 3,919 | 462 | 11.79% |
| Tail | 4,291 | 319 | 7.43% |

| Round | Library blocks | Search (s) | Validation (s) | Programs proposed | Reproduce training terms | Pass the twelve-term test |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | none | 43 | 500 | 101,793 | 158,092 | 18,467 |
| 2 | 2,000 | 113 | 315 | 5,486 | 6,091 | 817 |
| 3 | none | 130 | 53 | 12,225 | 13,156 | 297 |
| 4 | 2,000 | 152 | 155 | 1,181 | 1,285 | 338 |

### From twenty terms

60,199 sequences have a program that reproduces their training terms, from
55,489 distinct training windows and 55,145 distinct programs.
33,506 of the 58,959 with later recorded terms reproduce every one of them.

| Method | Reproduce training terms | Reproduce every later term | Share |
| --- | ---: | ---: | ---: |
| Linear | 14,964 | 13,547 | 90.53% |
| Closed | 15,339 | 5,370 | 35.01% |
| Holonomic | 4,020 | 3,837 | 95.45% |
| Recurrence | 14,305 | 3,351 | 23.43% |
| Affine | 3,552 | 2,339 | 65.85% |
| Polynomial | 2,232 | 2,164 | 96.95% |
| Periodic | 3,818 | 1,777 | 46.54% |
| Hypergeometric | 796 | 762 | 95.73% |
| Tail | 711 | 326 | 45.85% |
| Constant | 462 | 33 | 7.14% |

| Round | Library blocks | Search (s) | Validation (s) | Programs proposed | Reproduce training terms | Reproduce every later term |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | none | 87 | 417 | 48,979 | 53,117 | 32,374 |
| 2 | 2,000 | 173 | 729 | 1,677 | 1,959 | 745 |
| 3 | none | 406 | 40 | 4,456 | 4,674 | 203 |
| 4 | 2,000 | 87 | 239 | 385 | 449 | 184 |

The columns after the proposals count sequences; several sequences can
share a training window and its program. Linear, Hypergeometric and
Holonomic are recurrences with solved coefficients; Recurrence is an
enumerated step; Closed is an enumerated program without solved constants;
Affine adds a solved scale and shift. Polynomial, Periodic and Tail are
solved polynomials, periodic increments and constant tails. Solved
constants almost always hold on later terms. Enumerated fits to eight
terms often do not: many windows have a cheap explanation that is not the
sequence's rule.

The search program and the reference interpreter never returned different
values. Of 176,182 proposals over all rounds, 176,174 reproduced their
training terms when the interpreter evaluated them. The other 8, for
5 training windows, reached the step limit of the interpreter
on a training term. They are not counted, and their windows stay open for
later rounds.

### Development and evaluation splits

One sequence in five, chosen by a hash of its identifier, was used for
diagnostics while the method was built. The other four fifths were not.

| Split | Sequences | P8 held-out test | P20 every later term |
| --- | ---: | ---: | ---: |
| Evaluation | 226,390 | 15,899 (7.02%) | 26,741 (11.81%) |
| Development | 56,777 | 4,020 (7.08%) | 6,765 (11.92%) |

Before the split existed, the first prototypes were scored by aggregate
held-out counts over the whole corpus, to decide whether enumeration, loops
and recurrences were worth building. No per-sequence outcome outside the
development split was inspected and no parameter was tuned on it.

## Programs worth reading

- **Primes from eight terms (A000040).** The selected program returns the
  n-th m + 1 such that m + 1 divides m! + 1. That is Wilson's theorem, so
  the program is exact. It reproduces all 58 recorded terms.
- **Primes from twenty terms.** The selected program tests m by iterating
  x → 2x mod m + 1. It is Fermat's test in base 2. It reproduces
  all 58 recorded terms and the first 68 primes, then returns
  341 = 11 × 31. Agreement on every recorded term is evidence, not proof.
- **Number of divisors (A000005).** The difference of two sums of
  quotients, the identity tau(n) = D(n) - D(n-1). It reproduces
  all 104 recorded terms.
- **Nonprime numbers (A018252).** The numbers m that divide the product of
  ⌈k/2⌉ for k up to m. It reproduces all 65 recorded terms.
- **Flavius Josephus's sieve (A000960).** A program of 12 nodes carries the
  index n - 1 back through the sieving steps, j → j + ⌊j/d⌋ for d = n, …, 1.
  It reproduces all 51 recorded terms.
- **Sum of divisors (A000203).** Found with the library: sigma(n) = S(n) -
  S(n-1), where S(m) is m² minus the remainders of m by the numbers below
  it. It reproduces all 70 recorded terms.
- **Prime gaps (A001223).** The difference of two copies of a third prime
  program, which tests m by trial division. The recorded gaps reach past
  341, where Fermat's test in base 2 fails. It reproduces
  all 97 recorded terms.
- **Primorial numbers (A002110).** The product of the first n primes, each
  computed by the Wilson program that round 1 found for the primes. It
  reproduces all 20 recorded terms.
- **Catalan, Motzkin, Apéry and Baxter numbers.** Recurrences with polynomial
  coefficients, recovered with their coefficients (A000108, A001006, A005258, A001181).

## Limits

- Sequences defined through decimal digits, tables read by rows and
  digits of constants are almost untouched. Eight or twenty terms of a
  digit-based sequence often do not reach a second digit.
- The search program keeps machine integers. A sequence whose training
  terms exceed 2^62 is out of reach, and a program whose intermediate
  values overflow is not proposed. The reference interpreter has no such
  limit.
- From eight terms, the cheapest program is often not the sequence's
  rule. The prime-counting function agrees with ⌊(n+1)/2⌋ mod n on its
  first eight terms.
- A validation budget failure is recorded with its tag and counts as not
  reproduced. It never establishes nontermination.
- Cost is the search's own measure, not `RecursorNodeCount`. Both are
  recorded.

## Reproducibility

The experiment is in `build/oeis-corpus-v2`. [The experiment archive](OEISCorpusExperimentV2.zip)
holds its code: the search program in Rust, the controller, the validation
worker, the dashboard, the protocol and the notebook builder. Its README
gives the commands. `python3 run.py start` launches the campaign and a
dashboard at http://127.0.0.1:8765/; no supervision is needed.

`results.sqlite3` records the program of every training window and the
checks of every sequence. [The exported measurements](data/OEISCorpusV2.json.gz)
are the numbers in this note and in the notebook. The code hash at export
was `a2e83f3b669cec11d92428a2a4c4a1ee0dfe6a9ab26873c36e73553b38ba276a`.

OEIS data are copyright the OEIS Foundation Inc. and contributors, under
CC BY-SA 4.0. The experiment code follows Recursor's MIT license.
