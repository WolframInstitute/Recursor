---
Template: TechNote
Name: MeasuringOEISSequenceDiscovery
Title: Measuring OEIS Sequence Discovery
Description: Measure training fits, error curves and held-out predictions on pinned OEIS sequence data
Context: WolframInstitute`Recursor`
Paclet: WolframInstitute/Recursor
URI: WolframInstitute/Recursor/tutorial/MeasuringOEISSequenceDiscovery
Keywords: [OEIS, sequence discovery, generalization, computational essay]
RelatedGuides: [Evolution, Recursor, Visualization]
RelatedTutorials: [EvolutionaryExperiments, EvolvingPrograms, HaltingAndBudgets]
---

## A fixed sequence benchmark

How often does the current search discover a program that matches a sequence
and predicts later terms? This pilot uses
[WolframInstitute/OEIS](https://github.com/WolframInstitute/OEIS/tree/d82309e7f1436b641490aa8abf426c39e0d158a7)
and the raw sequence revision pinned by that repository. Its parser verified
the terms and offsets in the packaged dataset. Generated formulas and program
definitions are excluded from the search inputs.

The sample contains 32 eligible sequences selected by a fixed hash ordering
of A-numbers, plus eight named controls: natural numbers starting at zero,
squares, triangular numbers, powers of two, Fibonacci numbers, binary digit
sums, factorials and cubes. Controls are reported separately. Eligibility
requires the nonn keyword, a nonnegative starting index, at least 20 recorded
terms, no negative recorded terms, and neither the dead nor full keyword.
This sample covers the stated subset of the pinned snapshot, not all OEIS
entries. Forty-three candidate IDs were examined to obtain the 32 samples.

Every sequence has three runs, with seeds 9101, 9102 and 9103. Each run trains
on the first eight terms and checks the final selected program on the next
twelve. Input indices retain the OEIS offset. Names, formulas, test terms and
the paclet's named example programs are not supplied to the search.

Locate the packaged data and recorded results:

```wl
oeisDirectory = PacletObject["WolframInstitute/Recursor"]["AssetLocation", "OEISBenchmark"];
```

Load the frozen cohort:

```wl
cohort = Import[FileNameJoin[{oeisDirectory, "Cohort.json"}], "RawJSON"];
```

Load the recorded runs:

```wl
recorded = Import[FileNameJoin[{oeisDirectory, "Results.json"}], "RawJSON"];
```

Group runs by their sampling cohort:

```wl
groups = GroupBy[recorded["Trials"], #["Cohort"] &];
```

## Exact fits and later terms

A training fit matches all eight training terms. A successful held-out
prediction here means the same selected program also matches all twelve test
terms. Both conditions are required; a program can match a constant test
tail while failing on the training prefix.

Compare the fractions of runs meeting these two criteria:

```wl
BarChart[Table[100 {Count[Lookup[group, "TrainingExact"], True], Count[Map[#1["TrainingExact"] && #1["TestExact"] &, group], True]}/Length[group], {group, Values[groups]}], ChartLabels -> {Keys[groups], None}, ChartLegends -> {"Training fit", "Training and test fit"}, AxesLabel -> {None, "Runs (%)"}]
```

The recorded results are finite observations under this search budget. Exact
agreement on these terms does not prove equality for all indices. Repeated
seeds on one sequence are also not independent sequence samples.

## Training-error curves

Fitness counts exact matching terms, so the plotted loss is
1 - fitness/8. It is a fraction of mismatches, not a numerical distance
between terms. The curves show the best fitness found so far, averaged over
runs within each cohort; improvement does not imply that the whole population
improved or that unseen terms became more accurate.

Compute the mean training loss in each cohort:

```wl
trainingLoss = Map[1 - Mean[Lookup[#, "FitnessHistory"]]/8 &, groups];
```

Plot all 20 generations, including the initial population at generation zero:

```wl
ListLinePlot[Values[trainingLoss], DataRange -> {0, 20}, PlotLegends -> Keys[trainingLoss], AxesLabel -> {"Generation", "Training mismatch fraction"}, PlotRange -> {0, 1}]
```

Each run has population 24, two elites, tournament size 3, crossover
probability 0.8 and mutation probability 0.3. Initial depth is 2, replacement
depth is 3, maximum program size is 60 nodes and generated constants are
0 through 3. Unbounded loops are permitted. StopOnSolve is False, so every
curve spans the same generations. There are 464 candidate proposals per run;
repeated programs share a cached training score within that run.

Mutation selects a syntax-tree node uniformly, including the root, and grows
a replacement from the grammar while respecting the available bindings.
Before exhausting its depth or size budget, the generator chooses a leaf
with probability 0.3; otherwise it chooses uniformly among eligible operators.
These rules are fixed design choices, not a learned mutation policy.

Each input evaluation has budgets of 2000 syntax visits, 0.1 seconds and
64 MiB of additional memory. Exhaustion counts as a mismatch during search.
These resource limits restrict the experiment, not the language.

## Generalization and incomplete evaluations

Partial agreement on later terms remains informative even without a full fit.
Compare the distributions of the final programs' test agreement, normalizing
within cohorts of different sizes:

```wl
Histogram[Map[Lookup[#, "TestMatches"]/12 &, Values[groups]], {-1/24, 25/24, 1/12}, "Probability", ChartLegends -> Keys[groups], AxesLabel -> {"Held-out agreement fraction", "Fraction of runs"}]
```

Every test evaluation retains its input, expected term, returned integer or
failure status, and exact-match flag. A resource failure has no integer value;
it is not silently converted to zero or called nonterminating.

Count completed and budget-limited test evaluations:

```wl
testStatuses = Counts[Lookup[Flatten[Lookup[recorded["Trials"], "TestChecks"], 1], "Status"]];
```

Show those diagnostic counts:

```wl
BarChart[Values[testStatuses], ChartLabels -> Keys[testStatuses], AxesLabel -> {None, "Test evaluations"}]
```

For a structural illustration, select the recorded run with the most training
matches, then test matches, then syntax nodes. This is a post-experiment
illustration; test terms were never used to choose a program during a run:

```wl
illustration = First[MaximalBy[recorded["Trials"], {#["TrainingMatches"], #["TestMatches"], #["Nodes"]} &]];
```

Inspect its program tree:

```wl
RecursorProgramTree[ParseRecursor[illustration["Program"]], PlotLabel -> Row[{illustration["ID"], ", seed ", illustration["Seed"]}]]
```

## Repeat the experiment

The figures above use saved results and need no network access. The following
definitions reproduce a trial using the packaged terms and recorded settings.
The full set of searches is an explicit computation, disabled during ordinary
documentation builds. Timing and resource-limit outcomes can vary with the
machine and Wolfram version; source revisions are recorded in the data.

Read the exact search settings:

```wl
protocol = cohort["Protocol"];
```

Convert those settings to options:

```wl
searchOptions = Normal[protocol["SearchOptions"]];
```

Use the same evaluator budgets for the final checks:

```wl
evaluationOptions = FilterRules[searchOptions, Options[EvaluateRecursor]];
```

Construct indexed examples without resetting the original offset:

```wl
sequenceExamples[entry_] := Transpose[{Range[entry["Offset"], entry["Offset"] + Length[entry["Terms"]] - 1], entry["Terms"]}]
```

Keep failures distinct from returned numbers when checking a program:

```wl
checkExamples[program_, examples_] := Map[Function[example, With[{value = EvaluateRecursor[program, First[example], Sequence @@ evaluationOptions]}, <|"Input" -> First[example], "Expected" -> Last[example], "Value" -> If[IntegerQ[value], value, Null], "Status" -> Which[IntegerQ[value], "Completed", FailureQ[value], First[value], True, "Unevaluated"], "Match" -> SameQ[value, Last[example]]|>]], examples]
```

Run one search and record its training history and independent final checks:

```wl
runTrial[entry_, seed_] := Module[{examples, measurement, result, training, heldout, programs, messages},
	examples = sequenceExamples[entry];
	measurement = Block[{$MessageList = {}}, With[{
		timing = AbsoluteTiming[EvolveRecursor[Take[examples, protocol["TrainingTerms"]], Sequence @@ searchOptions, "RandomSeed" -> seed]]
	}, messages = ToString[#, InputForm] & /@ $MessageList; timing]];
	result = Last[measurement];
	If[! AssociationQ[result], Return[<|"ID" -> entry["ID"], "Seed" -> seed, "Status" -> "SearchFailure", "Result" -> ToString[result, InputForm]|>]];
	training = checkExamples[result["Program"], Take[examples, protocol["TrainingTerms"]]];
	heldout = checkExamples[result["Program"], Drop[examples, protocol["TrainingTerms"]]];
	programs = Lookup[result["Genealogy"], "Program"];
	<|"ID" -> entry["ID"], "Cohort" -> entry["Cohort"], "Seed" -> seed, "Status" -> "Completed",
		"Program" -> FormatRecursor[result["Program"]], "Nodes" -> RecursorNodeCount[result["Program"]],
		"SearchSeconds" -> First[measurement], "CandidateProposals" -> Length[programs],
		"DistinctCandidates" -> Length[DeleteDuplicates[programs]], "Generations" -> result["Generations"],
		"FitnessHistory" -> result["FitnessHistory"], "SearchFitness" -> result["Fitness"], "Messages" -> messages,
		"TrainingMatches" -> Count[Lookup[training, "Match"], True], "TestMatches" -> Count[Lookup[heldout, "Match"], True],
		"TrainingExact" -> AllTrue[training, TrueQ[#["Match"]] &], "TestExact" -> AllTrue[heldout, TrueQ[#["Match"]] &],
		"TrainingChecks" -> training, "TestChecks" -> heldout|>
]
```

Run the same 120 trials explicitly:

```wl
#| eval: false
repeatedTrials = Flatten[Table[runTrial[entry, seed], {entry, cohort["Sequences"]}, {seed, protocol["SearchSeeds"]}], 1];
```

This pilot measures the current combination of mutation, crossover and
selection. It does not isolate mutation's causal contribution or compare
search efficiency with random search or sequence-fitting built-ins. Those
comparisons require additional experimental arms with matched budgets.

Sequence data are copyright the OEIS Foundation and contributors, licensed
under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
The packaged NOTICE and per-entry source links preserve attribution and
identify the selected and truncated data. The source repository's
[benchmark notes](https://github.com/WolframInstitute/Recursor/blob/main/docs/notes/OEISBenchmark.md)
describe acquisition, selection and the recorded results.
