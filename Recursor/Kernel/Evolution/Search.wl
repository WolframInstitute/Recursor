PackageExported[{ScoreRecursor, EvolveRecursor}]

ScoreRecursor::usage = "ScoreRecursor[p, {{input, output}, ...}] counts exact matches. Evaluations that exhaust a resource limit score zero."
EvolveRecursor::usage = "EvolveRecursor[examples] searches for a closed program matching input-output examples. \
The result records fitness, population and genealogy. Solved means a fit to these examples."

Options[ScoreRecursor] = {"MaxSteps" -> 10000, "TimeLimit" -> 0.2, "MemoryLimit" -> 67108864}
Options[EvolveRecursor] = Join[Options[ScoreRecursor], Options[RandomRecursor], {
	"PopulationSize" -> 40, "MaxGenerations" -> 30, "EliteCount" -> 2, "TournamentSize" -> 3,
	"CrossoverRate" -> 0.8, "MutationRate" -> 0.3, "InitialDepth" -> 2, "MutationDepth" -> 3,
	"InitialPopulation" -> {}, "RandomSeed" -> Automatic, "StopOnSolve" -> True,
	"Proposer" -> None, "ProposalCount" -> 4, "StagnationPatience" -> 4
}]

examplesQ[data_List] := data =!= {} && MatchQ[data, {{_Integer?NonNegative, _Integer?NonNegative}..}]
examplesQ[_] := False

ScoreRecursor[program_?RecursorProgramQ, examples_?examplesQ, OptionsPattern[]] := Enclose @ Module[{
	steps = OptionValue["MaxSteps"], seconds = OptionValue["TimeLimit"], bytes = OptionValue["MemoryLimit"]
},
	ConfirmAssert[recursorBudgetQ[steps, seconds, bytes], "Invalid step, time or memory limit."];
	Total[Function[example, Boole[
		EvaluateRecursor[program, First[example], "MaxSteps" -> steps, "TimeLimit" -> seconds, "MemoryLimit" -> bytes] === Last[example]
	]] /@ examples]
]

rank[individual_] := {individual["Score"], -individual["Size"]}
tournament[population_, size_] := First @ MaximalBy[RandomChoice[population, size], rank]

EvolveRecursor[examples_?examplesQ, opts : OptionsPattern[]] := Enclose @ Module[{
	populationSize = OptionValue["PopulationSize"], generations = OptionValue["MaxGenerations"], elites = OptionValue["EliteCount"],
	tournamentSize = OptionValue["TournamentSize"], crossoverRate = OptionValue["CrossoverRate"], mutationRate = OptionValue["MutationRate"],
	initialDepth = OptionValue["InitialDepth"], mutationDepth = OptionValue["MutationDepth"], seeds = OptionValue["InitialPopulation"],
	maximumNodes = OptionValue["MaxNodes"], seed = OptionValue["RandomSeed"], stop = TrueQ[OptionValue["StopOnSolve"]],
	proposer = OptionValue["Proposer"], proposalCount = OptionValue["ProposalCount"], patience = OptionValue["StagnationPatience"],
	randomOptions, scoreOptions, score, record, next, breed, run, nextIdentifier = 0
},
	ConfirmAssert[MatchQ[populationSize, _Integer?Positive] && MatchQ[generations, _Integer?NonNegative], "PopulationSize and MaxGenerations are invalid."];
	ConfirmAssert[MatchQ[elites, _Integer?NonNegative] && elites <= populationSize, "EliteCount must lie between zero and PopulationSize."];
	ConfirmAssert[MatchQ[tournamentSize, _Integer?Positive], "TournamentSize must be positive."];
	ConfirmAssert[AllTrue[{crossoverRate, mutationRate}, NumericQ[#] && 0 <= # <= 1 &], "Rates must lie between zero and one."];
	ConfirmAssert[MatchQ[initialDepth, _Integer?NonNegative] && MatchQ[mutationDepth, _Integer?NonNegative], "Depths must be nonnegative integers."];
	ConfirmAssert[generationOptionsQ[OptionValue["MaxConstant"], maximumNodes, OptionValue["IncludeWhile"]], "Invalid generation options."];
	ConfirmAssert[recursorBudgetQ[OptionValue["MaxSteps"], OptionValue["TimeLimit"], OptionValue["MemoryLimit"]], "Invalid step, time or memory limit."];
	ConfirmAssert[BooleanQ[OptionValue["StopOnSolve"]], "StopOnSolve must be True or False."];
	ConfirmAssert[ListQ[seeds] && AllTrue[seeds, RecursorProgramQ[#] && RecursorNodeCount[#] <= maximumNodes &], "InitialPopulation contains invalid or oversized programs."];
	ConfirmAssert[MatchQ[proposalCount, _Integer?NonNegative] && MatchQ[patience, _Integer?NonNegative], "ProposalCount and StagnationPatience must be nonnegative integers."];
	randomOptions = FilterRules[Flatten[{opts}], Options[RandomRecursor]];
	scoreOptions = FilterRules[Flatten[{opts}], Options[ScoreRecursor]];
	score[program_] := score[program] = ScoreRecursor[program, examples, Sequence @@ scoreOptions];
	record[program_, parents_, generation_] := <|
		"ID" -> ++nextIdentifier, "Program" -> program, "Parents" -> parents, "Generation" -> generation,
		"Score" -> score[program], "Size" -> RecursorNodeCount[program]
	|>;
	breed[population_, generation_] := Module[{left, right, child, parents},
		left = tournament[population, tournamentSize];
		parents = {left["ID"]};
		child = left["Program"];
		If[RandomReal[] < crossoverRate,
			right = tournament[population, tournamentSize];
			parents = DeleteDuplicates[{left["ID"], right["ID"]}];
			child = CrossoverRecursor[child, right["Program"], "MaxNodes" -> maximumNodes]
		];
		If[RandomReal[] < mutationRate, child = MutateRecursor[child, mutationDepth, Sequence @@ randomOptions]];
		record[child, parents, generation]
	];
	next[state_] := Module[{population, children, proposals = {}, texts, generation, best, stalled},
		generation = state["Generation"] + 1;
		children = Table[breed[state["Population"], generation], {populationSize - elites}];
		If[proposer =!= None && state["Stalled"] >= patience,
			texts = proposer[state["Best"]["Program"], examples, proposalCount];
			If[ListQ[texts],
				proposals = Replace[texts, text_String :> ParseRecursor[text, "MaxNodes" -> maximumNodes], {1}];
				proposals = Take[DeleteDuplicates @ Select[proposals, RecursorProgramQ[#] && RecursorNodeCount[#] <= maximumNodes &], UpTo[proposalCount]];
				proposals = record[#, {state["Best"]["ID"]}, generation] & /@ proposals
			]
		];
		population = Take[ReverseSortBy[Join[Take[ReverseSortBy[state["Population"], rank], elites], children, proposals], rank], populationSize];
		best = First @ MaximalBy[{state["Best"], First[population]}, rank];
		stalled = If[rank[best] === rank[state["Best"]], state["Stalled"] + 1, 0];
		<|"Population" -> population, "Best" -> best, "Born" -> Join[children, proposals], "Generation" -> generation, "Stalled" -> stalled|>
	];
	run[] := Module[{initial, first, states, last},
		initial = Take[Join[seeds, Table[RandomRecursor[initialDepth, Sequence @@ randomOptions], {Max[populationSize - Length[seeds], 0]}]], populationSize];
		initial = record[#, {}, 0] & /@ initial;
		first = <|"Population" -> initial, "Best" -> First @ MaximalBy[initial, rank], "Born" -> initial, "Generation" -> 0, "Stalled" -> 0|>;
		states = NestWhileList[next, first, ! (stop && #["Best"]["Score"] === Length[examples]) &, 1, generations];
		last = Last[states];
		<|
			"Program" -> last["Best"]["Program"], "Solved" -> (last["Best"]["Score"] === Length[examples]),
			"Fitness" -> last["Best"]["Score"], "MaxFitness" -> Length[examples], "Generations" -> last["Generation"],
			"FitnessHistory" -> (#["Best"]["Score"] & /@ states), "Population" -> last["Population"],
			"Genealogy" -> Catenate[Lookup[states, "Born"]]
		|>
	];
	If[seed === Automatic, run[], BlockRandom[SeedRandom[seed]; run[]]]
]
