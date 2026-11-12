PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{}], input, "MaxSteps" -> 1000000], {input, 0, 4}],
	Range[0, 4],
	TestID -> "empty-counter-program-is-identity"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{{1, 0, {2}}}], input, "MaxSteps" -> 1000000], {input, 0, 3}],
	Range[1, 4],
	TestID -> "counter-increment"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{{1, 1, {2}, {2}}}], input, "MaxSteps" -> 1000000], {input, 0, 4}],
	{0, 0, 1, 2, 3},
	TestID -> "counter-decrement-and-zero-branch"
]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[{{1, 1, {1}, {2}}}], input, "MaxSteps" -> 1000000], {input, 0, 4}],
	{0, 0, 0, 0, 0},
	TestID -> "counter-unbounded-control-loop"
]

VerificationTest[
	Table[
		EvaluateRecursor[ToRecursor[{{1, 1, {2}, {3}}, {2, 0, {1}}, {2, 1, {4}, {5}}, {1, 0, {3}}}], input, "MaxSteps" -> 1000000],
		{input, 0, 3}
	],
	Range[0, 3],
	TestID -> "two-counters-transfer-and-restore"
]

VerificationTest[
	EvaluateRecursor[ToRecursor[{{1, 0, {1}}}], 0, "MaxSteps" -> 500]["Tag"],
	"StepLimit",
	TestID -> "translated-nonhalting-machine"
]

VerificationTest[
	RecursorProgramQ[ToRecursor[{{3, 0, {2}}, {3, 1, {3}, {3}}}]],
	True,
	TestID -> "arbitrary-register-index"
]

VerificationTest[
	Quiet[
		Map[Function[instructions, ToRecursor[instructions]["Tag"]], {{{0, 0, {2}}}, {{1, 0, {3}}}, {{1, 1, {2}}}, {{1, 2, {2}}}}],
		{ToRecursor::args}
	],
	ConstantArray["InvalidArguments", 4],
	TestID -> "invalid-counter-instructions-fail"
]

VerificationTest[
	ToRecursor[{{0, 0, {2}}}]["Tag"],
	"InvalidArguments",
	{ToRecursor::args},
	TestID -> "torecursor-invalid-arguments"
]

VerificationTest[
	ToRecursor[]["Tag"],
	"InvalidArguments",
	{ToRecursor::args},
	TestID -> "torecursor-no-arguments"
]
