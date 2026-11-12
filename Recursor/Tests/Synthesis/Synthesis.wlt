PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

reproduces[result_, examples_] :=
	RecursorProgramQ[result["Program"]] && AllTrue[examples, EvaluateRecursor[result["Program"], First[#], "MaxSteps" -> 5000000] === Last[#] &]

from[first_, terms_] :=
	Transpose[{Range[first, first + Length[terms] - 1], terms}]

pairs[terms_] :=
	Transpose[{Range[0, Length[terms] - 1], terms}]

VerificationTest[SynthesizeRecursor[Range[0, 9] ^ 2]["Program"], Mul[Var, Var], TestID -> "enumeration-finds-square"]

VerificationTest[SynthesizeRecursor[Fibonacci[Range[0, 11]]]["Program"], RecursorExamples["Fibonacci"], TestID -> "recurrence-finds-fibonacci-example"]

VerificationTest[SynthesizeRecursor[Range[0, 9]!]["Program"], RecursorExamples["Factorial"], TestID -> "solver-finds-factorial-example"]

VerificationTest[
	SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]]["Program"],
	RecursorExamples["PopulationCount"],
	TestID -> "recurrence-finds-population-count-example"
]

VerificationTest[
	Map[
		Lookup[SynthesizeRecursor[#, "MaxCost" -> 6, "TimeLimit" -> 120], "Method"] &,
		{
			ConstantArray[7, 8],
			Range[0, 9] ^ 2,
			Fibonacci[Range[0, 11]],
			LinearRecurrence[{10, -1}, {0, 2}, 10],
			CatalanNumber[Range[0, 11]],
			Table[2 n ^ 3 - 5 n ^ 2 + 7 n + 3, {n, 0, 9}],
			{1, 2, 4, 8, 9, 11, 15, 16, 18, 22, 23, 25},
			{7, 3, 5, 5, 5, 5, 5, 5}
		}
	],
	{"Constant", "ClosedForm", "Recurrence", "LinearRecurrence", "Hypergeometric", "Polynomial", "Periodic", "ConstantTail"},
	TestID -> "methods-by-sequence-family"
]

VerificationTest[
	AllTrue[
		{
			Range[0, 9] ^ 2,
			Fibonacci[Range[0, 11]],
			Range[0, 9]!,
			2 ^ Range[0, 9] + 1,
			Table[n ^ 2 + 41, {n, 0, 9}],
			Table[Quotient[n ^ 2, 3], {n, 0, 11}],
			{7, 3, 5, 5, 5, 5, 5, 5},
			Accumulate[Range[0, 9] ^ 2]
		},
		reproduces[SynthesizeRecursor[#, "TimeLimit" -> 120], pairs[#]] &
	],
	True,
	TestID -> "synthesized-programs-reproduce-their-examples"
]

VerificationTest[
	AllTrue[
		{
			CatalanNumber[Range[0, 11]],
			LinearRecurrence[{10, -1}, {0, 2}, 10],
			Table[2 n ^ 3 - 5 n ^ 2 + 7 n + 3, {n, 0, 9}],
			{1, 2, 4, 8, 9, 11, 15, 16, 18, 22, 23, 25}
		},
		reproduces[SynthesizeRecursor[#, "MaxCost" -> 6, "TimeLimit" -> 120], pairs[#]] &
	],
	True,
	TestID -> "solved-programs-reproduce-their-examples"
]

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

VerificationTest[
	SynthesizeRecursor[Table[n ^ 2 + 41, {n, 0, 9}], Method -> "Enumeration"]["Method"],
	"Affine",
	TestID -> "affine-closure-supplies-large-constants"
]

VerificationTest[SynthesizeRecursor[Table[5 n + 3, {n, 0, 9}]]["Program"], Add[Mul[Const[5], Var], Const[3]], TestID -> "affine-closure-of-the-input"]

VerificationTest[
	KeyTake[SynthesizeRecursor[{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8}, "MaxCost" -> 6], {"Program", "Solved"}],
	<|"Program" -> Missing["NotFound"], "Solved" -> False|>,
	TestID -> "unexplained-data-is-not-solved"
]

VerificationTest[SynthesizeRecursor[{{0, 1}, {0, 2}}]["Solved"], False, TestID -> "contradictory-examples-are-not-solved"]

VerificationTest[SynthesizeRecursor[{{3, 9}, {3, 9}, {4, 16}, {5, 25}}]["Program"], Mul[Var, Var], TestID -> "repeated-examples-are-merged"]

VerificationTest[
	SynthesizeRecursor[Fibonacci[Range[0, 11]], Method -> "Enumeration", "MaxCost" -> 6]["Solved"],
	False,
	TestID -> "method-restricts-the-search"
]

VerificationTest[SynthesizeRecursor[Fibonacci[Range[0, 11]], Method -> {"Solving"}]["Method"], "LinearRecurrence", TestID -> "method-accepts-a-list"]

VerificationTest[
	Module[{terms, automaticCost, solvingCost},
		terms = {0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89};
		automaticCost = SynthesizeRecursor[terms]["Cost"];
		solvingCost = SynthesizeRecursor[terms, Method -> "Solving"]["Cost"];
		automaticCost <= solvingCost
	],
	True,
	TestID -> "automatic-method-keeps-the-cheapest-candidate"
]

VerificationTest[
	SynthesizeRecursor[2 ^ Range[0, 9], "MaxLoopBody" -> 0, Method -> "Enumeration", "MaxCost" -> 7]["Solved"],
	False,
	TestID -> "loop-bodies-can-be-disabled"
]

VerificationTest[
	RecursorProgramQ[SynthesizeRecursor[2 ^ Range[0, 9], Method -> "Enumeration", "MaxCost" -> 7]["Program"]],
	True,
	TestID -> "enumeration-builds-bounded-loops"
]

VerificationTest[
	Map[
		FailureQ,
		{
			SynthesizeRecursor[{1, 2, 3}, Method -> "Guessing"],
			SynthesizeRecursor[{1, 2, 3}, "MaxCost" -> 0],
			SynthesizeRecursor[{1, 2, 3}, "MaxConstant" -> -1],
			SynthesizeRecursor[{1, 2, 3}, "TimeLimit" -> 0]
		}
	],
	{True, True, True, True},
	TestID -> "invalid-options-fail"
]

VerificationTest[
	SynthesizeRecursor[7]["Tag"],
	"InvalidArguments",
	{SynthesizeRecursor::args},
	TestID -> "invalid-arguments-fail"
]

VerificationTest[
	Map[Function[failure, failure["Tag"]], {SynthesizeRecursor[{}], SynthesizeRecursor[{-1, 2}]}],
	{"InvalidArguments", "InvalidArguments"},
	{SynthesizeRecursor::args, SynthesizeRecursor::args},
	TestID -> "wrong-shapes-fail"
]

VerificationTest[
	SynthesizeRecursor[{{0, 1.5}}]["Tag"],
	"InvalidArguments",
	{SynthesizeRecursor::args},
	TestID -> "examples-that-are-not-natural-numbers-fail"
]

VerificationTest[
	With[{result = SynthesizeRecursor[Range[0, 9] ^ 2]},
		{result["Cost"], result["Nodes"], IntegerQ[result["Candidates"]]}
	],
	{3, 3, True},
	TestID -> "result-records-cost-nodes-and-candidates"
]

VerificationTest[
	KeyTake[SynthesizeRecursor[Range[0, 15] ^ 2], {"Program", "Solved", "TrainingExamples", "HeldOutExamples", "HeldOutMatches"}],
	<|"Program" -> Mul[Var, Var], "Solved" -> True, "TrainingExamples" -> 12, "HeldOutExamples" -> 4, "HeldOutMatches" -> 4|>,
	TestID -> "solved-programs-predict-held-out-examples"
]

VerificationTest[
	With[{result = SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1]]},
		{result["Program"], result["Solved"], result["HeldOutMatches"] === result["HeldOutExamples"], result["Evidence"] < 24}
	],
	{RecursorExamples["PopulationCount"], False, True, True},
	TestID -> "thin-evidence-is-not-solved"
]

VerificationTest[
	With[{result = SynthesizeRecursor[DigitCount[Range[0, 47], 2, 1]]}, {result["Program"], result["Solved"]}],
	{RecursorExamples["PopulationCount"], True},
	TestID -> "more-terms-give-evidence"
]

VerificationTest[
	KeyTake[SynthesizeRecursor[Join[Range[0, 11] ^ 2, {150, 170, 190, 215}], "TimeLimit" -> 120], {"Program", "Solved", "HeldOutMatches"}],
	<|"Program" -> Mul[Var, Var], "Solved" -> False, "HeldOutMatches" -> 0|>,
	TestID -> "a-failed-held-out-example-is-not-solved"
]

VerificationTest[
	{
		KeyTake[SynthesizeRecursor[Range[0, 15] ^ 2, "HoldOut" -> 0, "TimeLimit" -> 120], {"Solved", "TrainingExamples", "HeldOutExamples"}],
		KeyTake[SynthesizeRecursor[Range[0, 15] ^ 2, "HoldOut" -> 8], {"Solved", "TrainingExamples", "HeldOutExamples"}]
	},
	{<|"Solved" -> False, "TrainingExamples" -> 16, "HeldOutExamples" -> 0|>, <|"Solved" -> True, "TrainingExamples" -> 8, "HeldOutExamples" -> 8|>},
	TestID -> "hold-out-sets-the-examples-kept-from-the-search"
]

VerificationTest[
	SynthesizeRecursor[DigitCount[Range[0, 15], 2, 1], "RequiredEvidence" -> 0]["Solved"],
	True,
	TestID -> "required-evidence-is-an-option"
]

VerificationTest[
	Module[{result},
		result = SynthesizeRecursor[from[1, DivisorSigma[0, Range[30]]], "TimeLimit" -> 120];
		{result["Method"], result["Solved"], reproduces[result, from[31, DivisorSigma[0, Range[31, 60]]]]}
	],
	{"Fold", True, True},
	TestID -> "folds-count-over-a-loop-index"
]

VerificationTest[
	Module[{result},
		result = SynthesizeRecursor[from[1, Prime[Range[30]]], "TimeLimit" -> 120];
		{result["Method"], result["Solved"], reproduces[result, from[31, Prime[Range[31, 40]]]]}
	],
	{"Search", True, True},
	TestID -> "searches-find-the-numbers-with-a-property"
]

VerificationTest[
	Module[{result},
		result = SynthesizeRecursor[from[1, PrimePi[Range[40]]], "TimeLimit" -> 120];
		{result["Method"], result["Solved"], reproduces[result, from[41, PrimePi[Range[41, 60]]]]}
	],
	{"Counting", True, True},
	TestID -> "counting-functions-count-the-numbers-with-a-property"
]

VerificationTest[
	Module[{result},
		result = SynthesizeRecursor[DivisorSigma[0, 2 Range[0, 39] + 1], "TimeLimit" -> 120];
		{result["Method"], result["Solved"], reproduces[result, from[40, DivisorSigma[0, 2 Range[40, 55] + 1]]]}
	],
	{"Composition", True, True},
	TestID -> "compositions-apply-a-program-to-a-function-of-the-input"
]

VerificationTest[
	Module[{result},
		result = SynthesizeRecursor[Subfactorial[Range[0, 15]], "TimeLimit" -> 120];
		{result["Method"], result["Solved"], reproduces[result, from[16, Subfactorial[Range[16, 19]]]]}
	],
	{"Recurrence", True, True},
	TestID -> "joined-steps-reach-past-the-enumerated-cost"
]

VerificationTest[
	{
		SynthesizeRecursor[from[1, DivisorSigma[0, Range[30]]], Method -> "Composition", "TimeLimit" -> 120]["Method"],
		MissingQ[SynthesizeRecursor[from[1, Prime[Range[30]]], Method -> "Enumeration"]["Program"]]
	},
	{"Fold", True},
	TestID -> "composition-is-a-method-of-its-own"
]

VerificationTest[
	FailureQ /@ {SynthesizeRecursor[Range[0, 9] ^ 2, "HoldOut" -> -1], SynthesizeRecursor[Range[0, 9] ^ 2, "RequiredEvidence" -> "much"],
		SynthesizeRecursor[Range[0, 9] ^ 2, Method -> "Guessing"]},
	{True, True, True},
	TestID -> "invalid-hold-out-evidence-and-method-fail"
]

VerificationTest[
	Module[{before},
		before = Length[Names["WolframInstitute`Recursor`*`*$*"]];
		Scan[Function[shift, SynthesizeRecursor[Prime[Range[16]] + shift, "TimeLimit" -> 120]], Range[3]];
		Length[Names["WolframInstitute`Recursor`*`*$*"]] - before
	],
	0,
	TestID -> "a-search-leaves-nothing-behind"
]

VerificationTest[
	KeyTake[SynthesizeRecursor[Range[0, 11] ^ 3, "TimeLimit" -> 120], {"Program", "Solved", "HeldOutExamples", "HeldOutMatches"}],
	<|"Program" -> Mul[Var, Mul[Var, Var]], "Solved" -> False, "HeldOutExamples" -> 3, "HeldOutMatches" -> 3|>,
	TestID -> "fewer-than-four-held-out-examples-are-not-solved"
]

VerificationTest[
	SynthesizeRecursor[Range[0, 11] ^ 3, "HoldOut" -> 4, "TimeLimit" -> 120]["Solved"],
	True,
	TestID -> "four-held-out-examples-can-be-asked-for"
]
