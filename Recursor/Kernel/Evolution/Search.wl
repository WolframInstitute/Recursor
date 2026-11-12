(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{ScoreRecursor, EvolveRecursor}]

(* ::Section:: *)
(*Usage Messages*)

ScoreRecursor::usage = "ScoreRecursor[program, {{input, output}, ...}] counts exact matches. Evaluations that exhaust a resource limit score zero."
EvolveRecursor::usage = "EvolveRecursor[examples] searches for a closed program matching input-output examples. \
The result records fitness, population and genealogy. Solved means a fit to these examples. \
Method -> \"Guided\" chooses each variation from the values the examples require."

examplesQ::usage = "examplesQ[examples] gives True when examples is a list, not empty, of pairs {input, output} of nonnegative integers."
individualRank::usage = "individualRank[individual] gives {score, -size} of an individual of a search; the individual with the largest is the best."
tournamentWinner::usage = "tournamentWinner[population, size] draws size individuals of the population at random, with repetition, and gives \
the best of them."
individualRecord::usage = "individualRecord[program, parents, generation, search] gives the individual for a program: an association with a \
new \"ID\", the \"Program\", the IDs of its \"Parents\", its \"Generation\", its \"Score\" on the examples and its \"Size\". search holds the \
state of the search: the scores of the programs met in the hash table \"Scores\", and the count of IDs in the counter \"Identifiers\"."
tournamentChild::usage = "tournamentChild[population, generation, search] gives a new individual: a tournament winner, crossed with a second \
winner at the rate \"CrossoverRate\" of search and mutated at the rate \"MutationRate\"."
proposedIndividuals::usage = "proposedIndividuals[state, generation, search] gives the individuals that the \"Proposer\" of search suggests \
for the best program of state: at most \"ProposalCount\" distinct programs within \"MaxNodes\". It gives {} when search has no proposer, when \
the best score has changed within the last \"StagnationPatience\" generations, or when the proposer does not give a list."
tournamentGeneration::usage = "tournamentGeneration[state, search] gives the state of a tournament search one generation after state. A state \
is an association with the keys \"Population\", \"Best\", \"Born\", \"Generation\" and \"Stalled\"."
tournamentEvolution::usage = "tournamentEvolution[examples, settings] runs the tournament search for the examples and gives the result of \
EvolveRecursor. settings is an association of the values of the options. The search adds the examples and its state to it: an empty hash \
table \"Scores\" and a counter \"Identifiers\" at zero."

(* ::Section:: *)
(*Options*)

Options[ScoreRecursor] = {"MaxSteps" -> 10000, "TimeLimit" -> 0.2, "MemoryLimit" -> 67108864}
Options[EvolveRecursor] = Join[{Method -> Automatic}, Options[ScoreRecursor], Options[RandomRecursor], {
	"LibraryCost" -> 6, "PopulationSize" -> 40, "MaxGenerations" -> 30, "EliteCount" -> 2, "TournamentSize" -> 3,
	"CrossoverRate" -> 0.8, "MutationRate" -> 0.3, "InitialDepth" -> 2, "MutationDepth" -> 3,
	"InitialPopulation" -> {}, "RandomSeed" -> Automatic, "StopOnSolve" -> True,
	"Proposer" -> None, "ProposalCount" -> 4, "StagnationPatience" -> 4
}]

(* ::Section:: *)
(*Function Definitions*)

examplesQ[{{_Integer?NonNegative, _Integer?NonNegative} ..}] := True
examplesQ[___] := False

ScoreRecursor[program_?RecursorProgramQ, examples_?examplesQ, OptionsPattern[]] := Enclose @ Module[{
	steps = OptionValue["MaxSteps"], seconds = OptionValue["TimeLimit"], bytes = OptionValue["MemoryLimit"]
},
	ConfirmAssert[recursorBudgetQ[steps, seconds, bytes], "Invalid step, time or memory limit."];
	Total[Function[example, Boole[
		EvaluateRecursor[program, First[example], "MaxSteps" -> steps, "TimeLimit" -> seconds, "MemoryLimit" -> bytes] === Last[example]
	]] /@ examples]
]
ScoreRecursor[___] := invalidArgumentsFailure[ScoreRecursor]

individualRank[individual_Association] := {individual["Score"], -individual["Size"]}

tournamentWinner[population_List, size_Integer] := First @ MaximalBy[RandomChoice[population, size], individualRank]

(* The helpers of the tournament search are at file level, because a function defined inside a Module keeps its
   memory after the call. The state they share is in two data structures of the association search, which are
   freed with it. The order of the random draws is part of the result of a seeded search. *)
individualRecord[program_?RecursorProgramQ, parents_List, generation_Integer, search_Association] := Module[{score},
	score = search["Scores"]["Lookup", program];
	If[MissingQ[score],
		score = ScoreRecursor[program, search["Examples"], Sequence @@ search["ScoreOptions"]];
		search["Scores"]["Insert", program -> score]
	];
	<|
		"ID" -> search["Identifiers"]["Increment"] + 1, "Program" -> program, "Parents" -> parents, "Generation" -> generation,
		"Score" -> score, "Size" -> RecursorNodeCount[program]
	|>
]

tournamentChild[population_List, generation_Integer, search_Association] := Module[{left, right, child, parents},
	left = tournamentWinner[population, search["TournamentSize"]];
	parents = {left["ID"]};
	child = left["Program"];
	If[RandomReal[] < search["CrossoverRate"],
		right = tournamentWinner[population, search["TournamentSize"]];
		parents = DeleteDuplicates[{left["ID"], right["ID"]}];
		child = CrossoverRecursor[child, right["Program"], "MaxNodes" -> search["MaxNodes"]]
	];
	If[RandomReal[] < search["MutationRate"], child = MutateRecursor[child, search["MutationDepth"], Sequence @@ search["RandomOptions"]]];
	individualRecord[child, parents, generation, search]
]

proposedIndividuals[state_Association, generation_Integer, search_Association] := Module[{texts, proposals},
	If[search["Proposer"] === None || state["Stalled"] < search["StagnationPatience"],
		{},
		texts = search["Proposer"][state["Best"]["Program"], search["Examples"], search["ProposalCount"]];
		If[!ListQ[texts],
			{},
			proposals = Replace[texts, text_String :> ParseRecursor[text, "MaxNodes" -> search["MaxNodes"]], {1}];
			proposals = Select[proposals, RecursorProgramQ[#] && RecursorNodeCount[#] <= search["MaxNodes"] &];
			proposals = Take[DeleteDuplicates[proposals], UpTo[search["ProposalCount"]]];
			Map[individualRecord[#, {state["Best"]["ID"]}, generation, search] &, proposals]
		]
	]
]

tournamentGeneration[state_Association, search_Association] := Module[{generation, children, proposals, elites, population, best, stalled},
	generation = state["Generation"] + 1;
	children = Table[tournamentChild[state["Population"], generation, search], {search["PopulationSize"] - search["EliteCount"]}];
	proposals = proposedIndividuals[state, generation, search];
	elites = Take[ReverseSortBy[state["Population"], individualRank], search["EliteCount"]];
	population = Take[ReverseSortBy[Join[elites, children, proposals], individualRank], search["PopulationSize"]];
	best = First @ MaximalBy[{state["Best"], First[population]}, individualRank];
	stalled = If[individualRank[best] === individualRank[state["Best"]], state["Stalled"] + 1, 0];
	<|"Population" -> population, "Best" -> best, "Born" -> Join[children, proposals], "Generation" -> generation, "Stalled" -> stalled|>
]

tournamentEvolution[examples_List, settings_Association] := Module[{search, maximumFitness, randomCount, programs, initial, initialState, states, final},
	search = Join[settings, <|"Examples" -> examples, "Scores" -> CreateDataStructure["HashTable"], "Identifiers" -> CreateDataStructure["Counter", 0]|>];
	maximumFitness = Length[examples];
	randomCount = Max[search["PopulationSize"] - Length[search["InitialPopulation"]], 0];
	programs = Join[search["InitialPopulation"], Table[RandomRecursor[search["InitialDepth"], Sequence @@ search["RandomOptions"]], {randomCount}]];
	initial = Map[individualRecord[#, {}, 0, search] &, Take[programs, search["PopulationSize"]]];
	initialState = <|"Population" -> initial, "Best" -> First @ MaximalBy[initial, individualRank], "Born" -> initial, "Generation" -> 0, "Stalled" -> 0|>;
	states = NestWhileList[
		Function[state, tournamentGeneration[state, search]],
		initialState,
		Function[state, !(search["StopOnSolve"] && state["Best"]["Score"] === maximumFitness)],
		1,
		search["MaxGenerations"]
	];
	final = Last[states];
	<|
		"Program" -> final["Best"]["Program"], "Solved" -> (final["Best"]["Score"] === maximumFitness),
		"Fitness" -> final["Best"]["Score"], "MaxFitness" -> maximumFitness, "Generations" -> final["Generation"],
		"FitnessHistory" -> Map[Function[state, state["Best"]["Score"]], states], "Population" -> final["Population"],
		"Genealogy" -> Catenate[Lookup[states, "Born"]]
	|>
]

EvolveRecursor[examples_?examplesQ, opts : OptionsPattern[]] := Enclose @ Module[{
	populationSize = OptionValue["PopulationSize"], generations = OptionValue["MaxGenerations"], elites = OptionValue["EliteCount"],
	tournamentSize = OptionValue["TournamentSize"], crossoverRate = OptionValue["CrossoverRate"], mutationRate = OptionValue["MutationRate"],
	initialDepth = OptionValue["InitialDepth"], mutationDepth = OptionValue["MutationDepth"], seeds = OptionValue["InitialPopulation"],
	maximumNodes = OptionValue["MaxNodes"], seed = OptionValue["RandomSeed"], stop = TrueQ[OptionValue["StopOnSolve"]],
	proposer = OptionValue["Proposer"], proposalCount = OptionValue["ProposalCount"], patience = OptionValue["StagnationPatience"],
	method = Replace[OptionValue[Method], Automatic -> "Tournament"], libraryCost = OptionValue["LibraryCost"],
	randomOptions, scoreOptions, settings, evolution
},
	ConfirmAssert[MatchQ[method, "Tournament" | "Guided"], "Method must be Automatic, \"Tournament\" or \"Guided\"."];
	ConfirmAssert[MatchQ[libraryCost, _Integer?Positive], "LibraryCost must be a positive integer."];
	ConfirmAssert[MatchQ[populationSize, _Integer?Positive] && MatchQ[generations, _Integer?NonNegative], "PopulationSize and MaxGenerations are invalid."];
	ConfirmAssert[MatchQ[elites, _Integer?NonNegative] && elites <= populationSize, "EliteCount must lie between zero and PopulationSize."];
	ConfirmAssert[MatchQ[tournamentSize, _Integer?Positive], "TournamentSize must be positive."];
	ConfirmAssert[AllTrue[{crossoverRate, mutationRate}, NumericQ[#] && 0 <= # <= 1 &], "Rates must lie between zero and one."];
	ConfirmAssert[MatchQ[initialDepth, _Integer?NonNegative] && MatchQ[mutationDepth, _Integer?NonNegative], "Depths must be nonnegative integers."];
	ConfirmAssert[generationOptionsQ[OptionValue["MaxConstant"], maximumNodes, OptionValue["IncludeWhile"]], "Invalid generation options."];
	ConfirmAssert[recursorBudgetQ[OptionValue["MaxSteps"], OptionValue["TimeLimit"], OptionValue["MemoryLimit"]], "Invalid step, time or memory limit."];
	ConfirmAssert[BooleanQ[OptionValue["StopOnSolve"]], "StopOnSolve must be True or False."];
	ConfirmAssert[
		ListQ[seeds] && AllTrue[seeds, RecursorProgramQ[#] && RecursorNodeCount[#] <= maximumNodes &],
		"InitialPopulation contains invalid or oversized programs."
	];
	ConfirmAssert[
		MatchQ[proposalCount, _Integer?NonNegative] && MatchQ[patience, _Integer?NonNegative],
		"ProposalCount and StagnationPatience must be nonnegative integers."
	];
	randomOptions = FilterRules[Flatten[{opts}], Options[RandomRecursor]];
	scoreOptions = FilterRules[Flatten[{opts}], Options[ScoreRecursor]];
	(* the guided search has variation of its own; it shares the budget, the seeds and the scoring limits *)
	settings = If[method === "Guided",
		<|
			"PopulationSize" -> populationSize, "MaxGenerations" -> generations, "EliteCount" -> elites,
			"MaxNodes" -> maximumNodes, "MaxConstant" -> OptionValue["MaxConstant"], "LibraryCost" -> libraryCost, "StopOnSolve" -> stop,
			"InitialPopulation" -> seeds, "ScoreOptions" -> Join[scoreOptions, Options[ScoreRecursor]]
		|>,
		<|
			"PopulationSize" -> populationSize, "MaxGenerations" -> generations, "EliteCount" -> elites,
			"TournamentSize" -> tournamentSize, "CrossoverRate" -> crossoverRate, "MutationRate" -> mutationRate,
			"InitialDepth" -> initialDepth, "MutationDepth" -> mutationDepth, "InitialPopulation" -> seeds, "MaxNodes" -> maximumNodes,
			"StopOnSolve" -> stop, "Proposer" -> proposer, "ProposalCount" -> proposalCount, "StagnationPatience" -> patience,
			"RandomOptions" -> randomOptions, "ScoreOptions" -> scoreOptions
		|>
	];
	evolution = If[method === "Guided", guidedEvolution, tournamentEvolution];
	If[seed === Automatic,
		evolution[examples, settings],
		BlockRandom[
			SeedRandom[seed];
			evolution[examples, settings]
		]
	]
]
EvolveRecursor[___] := invalidArgumentsFailure[EvolveRecursor]
