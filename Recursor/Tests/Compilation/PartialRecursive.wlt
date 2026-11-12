PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor["Successor", "PartialRecursive"], input], {input, 0, 6}],
	Range[1, 7],
	TestID -> "partialrecursive-successor"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor["Zero", "PartialRecursive"], input], {input, 0, 6}],
	ConstantArray[0, 7],
	TestID -> "partialrecursive-zero"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[code, "PartialRecursive"], input], {code, {"Left", "Right"}}, {input, 0, 8}],
	{{0, 0, 1, 1, 0, 1, 2, 2, 2}, {0, 1, 0, 1, 2, 2, 0, 1, 2}},
	TestID -> "partialrecursive-unpair-square-boundaries"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{"Pair", "Left", "Right"}, "PartialRecursive"], input], {input, 0, 8}],
	Range[0, 8],
	TestID -> "partialrecursive-pair-unpair-identity"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{"Compose", "Successor", "Successor"}, "PartialRecursive"], input], {input, 0, 6}],
	Range[2, 8],
	TestID -> "partialrecursive-composition"
]

VerificationTest[
	Table[
		EvaluateRecursor[
			ToRecursor[{"Recurse", {"Pair", "Left", "Right"}, {"Compose", "Successor", {"Compose", "Right", "Right"}}}, "PartialRecursive"],
			input
		],
		{input, 0, 8}
	],
	{0, 1, 1, 2, 2, 3, 2, 3, 4},
	TestID -> "partialrecursive-primitive-addition"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{"Search", "Left"}, "PartialRecursive"], input], {input, {0, 1, 4, 9}}],
	Range[0, 3],
	TestID -> "partialrecursive-search-respects-start"
]

VerificationTest[
	EvaluateRecursor[ToRecursor[{"Pair", "Zero", {"Search", "Successor"}}, "PartialRecursive"], 0, "MaxSteps" -> 500]["Tag"],
	"StepLimit",
	TestID -> "partialrecursive-pair-forces-both-results"
]

VerificationTest[
	EvaluateRecursor[ToRecursor[{"Recurse", {"Search", "Successor"}, "Zero"}, "PartialRecursive"], 0, "MaxSteps" -> 500]["Tag"],
	"StepLimit",
	TestID -> "partialrecursive-zero-recursion-forces-base"
]

VerificationTest[
	Map[
		Function[code, RecursorProgramQ[ToRecursor[code, "PartialRecursive"]]],
		{
			"Zero", "Successor", "Left", "Right", {"Pair", "Left", "Right"}, {"Compose", "Left", "Right"},
			{"Recurse", "Zero", "Successor"}, {"Search", "Right"}
		}
	],
	ConstantArray[True, 8],
	TestID -> "partialrecursive-all-constructors-closed"
]

VerificationTest[
	ToRecursor[{"Pair", "Left"}, "PartialRecursive"]["Tag"],
	"InvalidArguments",
	{ToRecursor::args},
	TestID -> "partialrecursive-incomplete-code-fails"
]

VerificationTest[
	ToRecursor["Unknown", "PartialRecursive"]["Tag"],
	"InvalidArguments",
	{ToRecursor::args},
	TestID -> "partialrecursive-unknown-code-fails"
]

VerificationTest[
	ToRecursor["Zero", "Unknown"]["Tag"],
	"InvalidArguments",
	{ToRecursor::args},
	TestID -> "partialrecursive-unknown-kind-fails"
]
