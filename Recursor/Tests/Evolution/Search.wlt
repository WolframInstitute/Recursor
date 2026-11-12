PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

VerificationTest[
	BlockRandom[
		SeedRandom[92];
		AllTrue[Table[RandomRecursor[4], {100}], RecursorProgramQ[#] && RecursorNodeCount[#] <= 60&]
	],
	True,
	TestID -> "random-programs-closed-and-size-bounded"
]

VerificationTest[
	BlockRandom[
		SeedRandom[93];
		AllTrue[Table[RandomRecursor[4, "IncludeWhile" -> False], {50}], FreeQ[#, _WhileLoop]&]
	],
	True,
	TestID -> "bounded-language-generation"
]

VerificationTest[
	BlockRandom[
		SeedRandom[94];
		AllTrue[Table[RandomRecursor[8, "MaxNodes" -> 1], {30}], RecursorNodeCount[#] === 1&]
	],
	True,
	TestID -> "one-node-generation-bound"
]

VerificationTest[
	BlockRandom[
		SeedRandom[95];
		MemberQ[Flatten[Table[RandomRecursor[3], {80}]], _WhileLoop, Infinity]
	],
	True,
	TestID -> "generator-can-produce-while"
]

VerificationTest[
	BlockRandom[
		SeedRandom[96];
		AllTrue[NestList[MutateRecursor, RecursorExamples["Fibonacci"], 100], RecursorProgramQ[#] && RecursorNodeCount[#] <= 60&]
	],
	True,
	TestID -> "mutation-preserves-scope-and-size"
]

VerificationTest[
	BlockRandom[
		SeedRandom[97];
		AllTrue[Table[CrossoverRecursor[RecursorExamples["Factorial"], RecursorExamples["Fibonacci"]], {100}], RecursorProgramQ]
	],
	True,
	TestID -> "crossover-preserves-scope"
]

VerificationTest[
	SimplifyRecursor[Mul[Const[0], WhileLoop[Const[0], Const[1], Acc]]],
	Mul[Const[0], WhileLoop[Const[0], Const[1], Acc]],
	TestID -> "simplification-retains-divergent-multiplicand"
]

VerificationTest[
	SimplifyRecursor[Monus[WhileLoop[Var, Const[1], Acc], WhileLoop[Var, Const[1], Acc]]],
	Monus[WhileLoop[Var, Const[1], Acc], WhileLoop[Var, Const[1], Acc]],
	TestID -> "simplification-retains-divergent-self-subtraction"
]

VerificationTest[SimplifyRecursor[Add[Mul[Const[3], Const[4]], Pred[Const[0]]]], Const[12], TestID -> "constant-folding"]

VerificationTest[SimplifyRecursor[Ifz[Const[0], Var, WhileLoop[Var, Const[1], Acc]]], Var, TestID -> "simplification-may-drop-unselected-branch"]

VerificationTest[ScoreRecursor[Mul[Var, Var], {{0, 0}, {2, 4}, {3, 8}}], 2, TestID -> "exact-match-score"]

VerificationTest[ScoreRecursor[RecursorExamples["Nonterminating"], {{0, 0}, {1, 1}}, "MaxSteps" -> 20], 0, TestID -> "nonterminating-program-scores-zero"]

VerificationTest[
	Module[{result = EvolveRecursor[{{0, 0}, {1, 1}, {2, 4}}, "PopulationSize" -> 4, "InitialPopulation" -> {Mul[Var, Var]}, "RandomSeed" -> 8]},
		{result["Solved"], result["Generations"], result["Program"], Length[result["Population"]]}
	],
	{True, 0, Mul[Var, Var], 4},
	TestID -> "seeded-solution-at-generation-zero"
]

VerificationTest[
	Module[{result = EvolveRecursor[{{0, 11}, {1, 12}}, "PopulationSize" -> 5, "MaxGenerations" -> 3, "StopOnSolve" -> False, "RandomSeed" -> 10]},
		{
			result["Generations"], Length[result["Population"]], Length[result["FitnessHistory"]],
			AllTrue[result["Population"], RecursorProgramQ[#["Program"]]&]
		}
	],
	{3, 5, 4, True},
	TestID -> "evolution-keeps-population-size"
]

VerificationTest[
	SameQ[
		EvolveRecursor[{{0, 11}, {1, 12}}, "PopulationSize" -> 4, "MaxGenerations" -> 2, "RandomSeed" -> 12],
		EvolveRecursor[{{0, 11}, {1, 12}}, "PopulationSize" -> 4, "MaxGenerations" -> 2, "RandomSeed" -> 12]
	],
	True,
	TestID -> "seeded-search-reproducible"
]

VerificationTest[
	Module[{proposer, result},
		proposer = Function[{program, examples, count}, {"Quit[]", "Add[Var,Const[7]]", "Acc"}];
		result = EvolveRecursor[
			{{0, 7}, {1, 8}},
			"PopulationSize" -> 3, "EliteCount" -> 1, "MaxGenerations" -> 1, "StagnationPatience" -> 0, "RandomSeed" -> 3, "Proposer" -> proposer
		];
		{result["Solved"], result["Program"], Length[result["Population"]]}
	],
	{True, Add[Var, Const[7]], 3},
	TestID -> "proposal-callback-parsed-and-filtered"
]

VerificationTest[FailureQ[EvolveRecursor[{{0, 0}}, "PopulationSize" -> 0]], True, TestID -> "invalid-population-size"]

VerificationTest[FailureQ[EvolveRecursor[{{0, 0}}, "InitialPopulation" -> {Acc}]], True, TestID -> "invalid-seed-rejected"]

VerificationTest[
	BlockRandom[
		SeedRandom[103];
		Module[{programs = Table[RandomRecursor[2, "MaxConstant" -> 1, "IncludeWhile" -> False], {12}]},
			AllTrue[
				Tuples[{programs, Range[0, 2]}],
				Function[pair, EvaluateRecursor[First[pair], Last[pair], Method -> "Lambda", "MaxSteps" -> 500000] === EvaluateRecursor[First[pair], Last[pair]]]
			]
		]
	],
	True,
	TestID -> "random-small-programs-compiler-agreement"
]

VerificationTest[
	ScoreRecursor[WhileLoop[Var, Acc, Pred[Acc]], {{4000, 0}}, "TimeLimit" -> Infinity],
	0,
	TestID -> "score-enforces-default-step-limit"
]

VerificationTest[
	ScoreRecursor[WhileLoop[Var, Acc, Pred[Acc]], {{4000, 0}}, "MaxSteps" -> 13000, "TimeLimit" -> Infinity],
	1,
	TestID -> "score-explicit-step-limit"
]

VerificationTest[
	FailureQ[ScoreRecursor[Var, {{0, 0}}, "MaxSteps" -> -1]],
	True,
	TestID -> "score-rejects-invalid-resource-options"
]

VerificationTest[
	FailureQ[EvolveRecursor[{{0, 0}}, "TimeLimit" -> 0]],
	True,
	TestID -> "evolution-rejects-invalid-resource-options"
]

VerificationTest[
	SimplifyRecursor /@ {
		Quot[Const[7], Const[2]], Quot[Const[7], Const[0]], Quot[Var, Const[1]], Quot[Var, Const[0]],
		Let[Succ[Var], Var], Let[Var, Half[Var]], Let[Const[5], Const[2]]
	},
	{Const[3], Const[0], Var, Const[0], Succ[Var], Half[Var], Const[2]},
	TestID -> "simplification-of-quotient-and-let"
]

VerificationTest[
	SimplifyRecursor[Let[WhileLoop[Const[0], Const[1], Acc], Const[2]]],
	Let[WhileLoop[Const[0], Const[1], Acc], Const[2]],
	TestID -> "simplification-retains-divergent-let-value"
]

VerificationTest[
	SimplifyRecursor[Quot[WhileLoop[Const[0], Const[1], Acc], Const[0]]],
	Quot[WhileLoop[Const[0], Const[1], Acc], Const[0]],
	TestID -> "simplification-retains-divergent-dividend"
]

VerificationTest[
	BlockRandom[
		SeedRandom[98];
		With[{programs = Table[RandomRecursor[4], {300}]}, {AllTrue[programs, RecursorProgramQ], ! FreeQ[programs, _Let], ! FreeQ[programs, _Quot]}]
	],
	{True, True, True},
	TestID -> "generator-produces-closed-let-and-quotient"
]

VerificationTest[
	BlockRandom[
		SeedRandom[99];
		Module[{programs = Table[RandomRecursor[4, "IncludeWhile" -> False], {40}]},
			AllTrue[programs, Function[program, AllTrue[Range[0, 3], EvaluateRecursor[SimplifyRecursor[program], #, "MaxSteps" -> 200000] === EvaluateRecursor[program, #, "MaxSteps" -> 200000]&]]]
		]
	],
	True,
	TestID -> "simplification-preserves-values-with-new-syntax"
]

VerificationTest[
	BlockRandom[
		SeedRandom[5];
		{RandomRecursor[], MutateRecursor[Succ[Var]], RandomRecursor["MaxNodes" -> 1, "MaxConstant" -> 0]}
	],
	BlockRandom[
		SeedRandom[5];
		{RandomRecursor[3], MutateRecursor[Succ[Var], 3], RandomRecursor[3, "MaxNodes" -> 1, "MaxConstant" -> 0]}
	],
	TestID -> "default-depth-is-three"
]

VerificationTest[
	Module[{examples = Table[{n, n ^ 2 + 1}, {n, 0, 5}], result},
		result = EvolveRecursor[examples, "PopulationSize" -> 12, "MaxGenerations" -> 6, "StopOnSolve" -> False, "RandomSeed" -> 21];
		{
			Lookup[result["Genealogy"], "ID"] === Range[Length[result["Genealogy"]]],
			AllTrue[result["Genealogy"], #["Score"] === ScoreRecursor[#["Program"], examples]&],
			SubsetQ[Lookup[result["Genealogy"], "ID"], Catenate[Lookup[result["Genealogy"], "Parents"]]],
			OrderedQ[result["FitnessHistory"]]
		}
	],
	{True, True, True, True},
	TestID -> "genealogy-ids-scores-and-parents"
]

VerificationTest[
	Module[{before = Length[Names["WolframInstitute`Recursor`*`*$*"]]},
		Scan[Function[seed, EvolveRecursor[{{0, 1}, {1, 2}, {2, 5}}, "PopulationSize" -> 6, "MaxGenerations" -> 3, "RandomSeed" -> seed]], Range[3]];
		Length[Names["WolframInstitute`Recursor`*`*$*"]] - before
	],
	0,
	TestID -> "search-leaves-nothing-behind"
]

VerificationTest[RandomRecursor[-1]["Tag"], "InvalidArguments", {RandomRecursor::args}, TestID -> "random-catch-all"]

VerificationTest[MutateRecursor[Acc]["Tag"], "InvalidArguments", {MutateRecursor::args}, TestID -> "mutate-catch-all"]

VerificationTest[CrossoverRecursor[Var]["Tag"], "InvalidArguments", {CrossoverRecursor::args}, TestID -> "crossover-catch-all"]

VerificationTest[SimplifyRecursor[Acc]["Tag"], "InvalidArguments", {SimplifyRecursor::args}, TestID -> "simplify-catch-all"]

VerificationTest[ScoreRecursor[Var, {}]["Tag"], "InvalidArguments", {ScoreRecursor::args}, TestID -> "score-catch-all"]

VerificationTest[EvolveRecursor[{{0, -1}}]["Tag"], "InvalidArguments", {EvolveRecursor::args}, TestID -> "evolve-catch-all"]
