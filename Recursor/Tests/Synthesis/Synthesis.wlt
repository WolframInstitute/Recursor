Needs["WolframInstitute`Recursor`"]

reproduces[result_, examples_] :=
	result["Solved"] && RecursorProgramQ[result["Program"]] && AllTrue[examples, EvaluateRecursor[result["Program"], First[#]] === Last[#]&]

pairs[terms_] :=
	Transpose[{Range[0, Length[terms] - 1], terms}]

VerificationTest[SynthesizeRecursor[Range[0, 9]^2]["Program"], Mul[Var, Var], TestID -> "enumeration-finds-square"]

VerificationTest[SynthesizeRecursor[Fibonacci[Range[0, 11]]]["Program"], RecursorExamples["Fibonacci"], TestID -> "recurrence-finds-fibonacci-example"]

VerificationTest[SynthesizeRecursor[Range[0, 9]!]["Program"], RecursorExamples["Factorial"], TestID -> "solver-finds-factorial-example"]

VerificationTest[SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]]["Program"], RecursorExamples["PopulationCount"], TestID -> "recurrence-finds-population-count-example"
	]

VerificationTest[Lookup[SynthesizeRecursor[#, "MaxCost" -> 6], "Method"]& /@ {ConstantArray[7, 8], Range[0, 9]^2, Fibonacci[Range[0, 11]], LinearRecurrence[{10,
	-1}, {0, 2}, 10], CatalanNumber[Range[0, 11]], Table[2 n^3 - 5 n^2 + 7 n + 3, {n, 0, 9}], {1, 2, 4, 8, 9, 11, 15, 16, 18, 22, 23, 25}, {7, 3, 5, 5, 5, 5,
	5, 5}}, {"Constant", "ClosedForm", "Recurrence", "LinearRecurrence", "Hypergeometric", "Polynomial", "Periodic", "ConstantTail"}, TestID -> "methods-by-sequence-family"
	]

VerificationTest[AllTrue[{Range[0, 9]^2, Fibonacci[Range[0, 11]], Range[0, 9]!, 2^Range[0, 9] + 1, Table[n^2 + 41, {n, 0, 9}], Table[Quotient[n^2, 3], {n,
	0, 11}], {7, 3, 5, 5, 5, 5, 5, 5}, Accumulate[Range[0, 9]^2]}, reproduces[SynthesizeRecursor[#], pairs[#]]&], True, TestID -> "synthesized-programs-reproduce-their-examples"
	]

VerificationTest[AllTrue[{CatalanNumber[Range[0, 11]], LinearRecurrence[{10, -1}, {0, 2}, 10], Table[2 n^3 - 5 n^2 + 7 n + 3, {n, 0, 9}], {1, 2, 4, 8, 9, 11,
	15, 16, 18, 22, 23, 25}}, reproduces[SynthesizeRecursor[#, "MaxCost" -> 6], pairs[#]]&], True, TestID -> "solved-programs-reproduce-their-examples"]

VerificationTest[
	With[{examples = Table[{n, n! + 1}, {n, 1, 9}]},
		reproduces[SynthesizeRecursor[examples], examples]
	],
	True,
	TestID -> "examples-with-offset"
]

VerificationTest[
	With[{examples = {{0, 1}, {2, 5}, {5, 26}, {9, 82}}},
		reproduces[SynthesizeRecursor[examples], examples]
	],
	True,
	TestID -> "examples-with-gaps-use-enumeration"
]

VerificationTest[SynthesizeRecursor[Table[n^2 + 41, {n, 0, 9}], Method -> "Enumeration"]["Method"], "Affine", TestID -> "affine-closure-supplies-large-constants"
	]

VerificationTest[SynthesizeRecursor[Table[5 n + 3, {n, 0, 9}]]["Program"], Add[Mul[Const[5], Var], Const[3]], TestID -> "affine-closure-of-the-input"]

VerificationTest[KeyTake[SynthesizeRecursor[{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8}, "MaxCost" -> 6], {"Program", "Solved"}], <|"Program" -> Missing["NotFound"],
	"Solved" -> False|>, TestID -> "unexplained-data-is-not-solved"]

VerificationTest[SynthesizeRecursor[{{0, 1}, {0, 2}}]["Solved"], False, TestID -> "contradictory-examples-are-not-solved"]

VerificationTest[SynthesizeRecursor[{{3, 9}, {3, 9}, {4, 16}, {5, 25}}]["Program"], Mul[Var, Var], TestID -> "repeated-examples-are-merged"]

VerificationTest[SynthesizeRecursor[Fibonacci[Range[0, 11]], Method -> "Enumeration", "MaxCost" -> 6]["Solved"], False, TestID -> "method-restricts-the-search"
	]

VerificationTest[SynthesizeRecursor[Fibonacci[Range[0, 11]], Method -> {"Solving"}]["Method"], "LinearRecurrence", TestID -> "method-accepts-a-list"]

VerificationTest[SynthesizeRecursor[{0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89}]["Cost"] <= SynthesizeRecursor[{0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89}, Method ->
	"Solving"]["Cost"], True, TestID -> "automatic-method-keeps-the-cheapest-candidate"]

VerificationTest[SynthesizeRecursor[2^Range[0, 9], "MaxLoopBody" -> 0, Method -> "Enumeration", "MaxCost" -> 7]["Solved"], False, TestID -> "loop-bodies-can-be-disabled"
	]

VerificationTest[RecursorProgramQ[SynthesizeRecursor[2^Range[0, 9], Method -> "Enumeration", "MaxCost" -> 7]["Program"]], True, TestID -> "enumeration-builds-bounded-loops"
	]

VerificationTest[FailureQ /@ {SynthesizeRecursor[{1, 2, 3}, Method -> "Guessing"], SynthesizeRecursor[{1, 2, 3}, "MaxCost" -> 0], SynthesizeRecursor[{1, 2,
	3}, "MaxConstant" -> -1], SynthesizeRecursor[{1, 2, 3}, "TimeLimit" -> 0]}, {True, True, True, True}, TestID -> "invalid-options-fail"]

VerificationTest[Head /@ {SynthesizeRecursor[{}], SynthesizeRecursor[{-1, 2}], SynthesizeRecursor[{{0, 1.5}}], SynthesizeRecursor[7]}, {SynthesizeRecursor,
	SynthesizeRecursor, SynthesizeRecursor, SynthesizeRecursor}, TestID -> "wrong-shapes-stay-unevaluated"]

VerificationTest[
	With[{result = SynthesizeRecursor[Range[0, 9]^2]},
		{result["Cost"], result["Nodes"], IntegerQ[result["Candidates"]]}
	],
	{3, 3, True},
	TestID -> "result-records-cost-nodes-and-candidates"
]
