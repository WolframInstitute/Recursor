Needs["WolframInstitute`Recursor`"]

pairs[terms_] :=
	Transpose[{Range[0, Length[terms] - 1], terms}]

guided[terms_, options___] :=
	EvolveRecursor[pairs[terms], Method -> "Guided", options, "RandomSeed" -> 7, "PopulationSize" -> 24, "MaxGenerations" -> 20]

(* every backward rule against the interpreter: a value inside the interval gives a result inside the wanted one *)
backward[head_, k_, complete_] :=
	Module[{needed = WolframInstitute`Recursor`Evolution`Guided`Private`needed, arity = Switch[head, Succ | Pred | Half, 1, Ifz, 3, _, 2]},
		BlockRandom[
			SeedRandom[11];
			And @@ Table[
				With[{others = RandomInteger[{0, 9}, arity - 1], lo = RandomInteger[{0, 12}], width = RandomChoice[{0, 0, 1, 3, 50}]},
					With[{need = needed[head, k, {{lo}, {lo + width}}, List /@ others]},
						With[{inside = Select[Range[0, 40], need[[1, 1]] <= # <= need[[2, 1]]&], good = Select[Range[0, 40], lo <= EvaluateRecursor[head @@ (Const /@ Insert[others, #, k]), 0] <= lo + width&]},
							SubsetQ[good, inside] && (! complete || SubsetQ[inside, good])
						]
					]
				],
				{120}
			]
		]
	]

VerificationTest[
	backward[#1, #2, True]& @@@ {{Succ, 1}, {Pred, 1}, {Half, 1}, {Add, 1}, {Add, 2}, {Mul, 1}, {Mul, 2}, {Monus, 1}, {Monus, 2}, {Quot, 1}, {Ifz, 1}, {Ifz, 2}, {Ifz, 3}},
	ConstantArray[True, 13],
	TestID -> "backward-rules-are-exact"
]

VerificationTest[
	backward[#1, #2, False]& @@@ {{Quot, 2}, {Rem, 1}, {Rem, 2}},
	{True, True, True},
	TestID -> "partial-backward-rules-are-sound"
]

VerificationTest[
	With[{result = guided[Table[n (n + 1)/2, {n, 0, 7}]]},
		{result["Solved"], result["Program"]}
	],
	{True, Half[Mul[Var, Succ[Var]]]},
	TestID -> "guided-finds-a-closed-program"
]

VerificationTest[
	With[{result = guided[Fibonacci[Range[0, 7]], "StopOnSolve" -> False]},
		{result["Solved"], Table[EvaluateRecursor[result["Program"], n], {n, 8, 15}]}
	],
	{True, Fibonacci[Range[8, 15]]},
	TestID -> "guided-finds-a-recurrence"
]

VerificationTest[
	With[{result = guided[2^Range[0, 7] - 1, "StopOnSolve" -> False]},
		{Sort[Keys[result]], result["Generations"], Length[result["FitnessHistory"]], Length[result["Population"]] <= 24,
			AllTrue[result["Genealogy"], RecursorProgramQ[#["Program"]]&], DuplicateFreeQ[result["Genealogy"][[All, "ID"]]],
			SubsetQ[result["Genealogy"][[All, "ID"]], Catenate[result["Genealogy"][[All, "Parents"]]]], OrderedQ[result["FitnessHistory"]]}
	],
	{Sort[{"Program", "Solved", "Fitness", "MaxFitness", "Generations", "FitnessHistory", "Population", "Genealogy"}], 20, 21, True, True, True, True, True},
	TestID -> "guided-result-has-the-shape-of-a-search"
]

VerificationTest[
	guided[{3, 7, 13, 21, 31, 43, 57, 73}] === guided[{3, 7, 13, 21, 31, 43, 57, 73}],
	True,
	TestID -> "guided-seeded-search-reproducible"
]

VerificationTest[
	With[{result = EvolveRecursor[{{0, 1}, {2, 5}, {5, 26}, {9, 82}}, Method -> "Guided", "RandomSeed" -> 1]},
		{result["Solved"], result["Program"]}
	],
	{True, Succ[Mul[Var, Var]]},
	TestID -> "guided-accepts-inputs-with-gaps"
]

VerificationTest[
	With[{result = EvolveRecursor[pairs[{3, 4, 7, 12, 19, 28}], Method -> "Guided", "InitialPopulation" -> {Add[Mul[Var, Var], Const[3]]}, "RandomSeed" -> 2, "MaxGenerations" -> 0]},
		{result["Solved"], result["Generations"]}
	],
	{True, 0},
	TestID -> "guided-uses-seed-programs"
]

VerificationTest[
	FailureQ /@ {EvolveRecursor[{{0, 0}}, Method -> "Other"], EvolveRecursor[{{0, 0}}, Method -> "Guided", "LibraryCost" -> 0]},
	{True, True},
	TestID -> "guided-rejects-invalid-options"
]

VerificationTest[
	With[{before = Length[Names["WolframInstitute`Recursor`*`*$*"]]},
		Do[guided[Fibonacci[Range[0, 7]] + k], {k, 3}];
		Length[Names["WolframInstitute`Recursor`*`*$*"]] - before
	],
	0,
	TestID -> "guided-search-leaves-nothing-behind"
]

VerificationTest[
	With[{result = EvolveRecursor[Table[{n, Prime[n]}, {n, 1, 20}], Method -> "Guided", "StopOnSolve" -> False, "RandomSeed" -> 1, "MaxSteps" -> 2000, "TimeLimit" -> 1]},
		{Last[result["FitnessHistory"]] === result["Fitness"], RecursorNodeCount[result["Program"]] <= 60}
	],
	{True, True},
	TestID -> "guided-history-counts-only-programs-it-may-return"
]
