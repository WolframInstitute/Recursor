Needs["WolframInstitute`Recursor`"]

VerificationTest[Table[EvaluateRecursor[ToRecursor["Successor", "PartialRecursive"], n], {n, 0, 6}], Range[1, 7], TestID -> "partialrecursive-successor"]

VerificationTest[Table[EvaluateRecursor[ToRecursor["Zero", "PartialRecursive"], n], {n, 0, 6}], ConstantArray[0, 7], TestID -> "partialrecursive-zero"]

VerificationTest[
	Table[EvaluateRecursor[ToRecursor[code, "PartialRecursive"], n], {code, {"Left", "Right"}}, {n, 0, 8}],
	{{0, 0, 1, 1, 0, 1, 2, 2, 2}, {0, 1, 0, 1, 2, 2, 0, 1, 2}}, TestID -> "partialrecursive-unpair-square-boundaries"
]

VerificationTest[Table[EvaluateRecursor[ToRecursor[{"Pair", "Left", "Right"}, "PartialRecursive"], n], {n, 0, 8}], Range[0, 8], TestID -> "partialrecursive-pair-unpair-identity"]

VerificationTest[Table[EvaluateRecursor[ToRecursor[{"Compose", "Successor", "Successor"}, "PartialRecursive"], n], {n, 0, 6}], Range[2, 8], TestID -> "partialrecursive-composition"]

VerificationTest[
	With[{code = {"Recurse", {"Pair", "Left", "Right"}, {"Compose", "Successor", {"Compose", "Right", "Right"}}}},
		Table[EvaluateRecursor[ToRecursor[code, "PartialRecursive"], n], {n, 0, 8}]
	], {0, 1, 1, 2, 2, 3, 2, 3, 4}, TestID -> "partialrecursive-primitive-addition"
]

VerificationTest[Table[EvaluateRecursor[ToRecursor[{"Search", "Left"}, "PartialRecursive"], n], {n, {0, 1, 4, 9}}], Range[0, 3], TestID -> "partialrecursive-search-respects-start"]

VerificationTest[
	EvaluateRecursor[ToRecursor[{"Pair", "Zero", {"Search", "Successor"}}, "PartialRecursive"], 0, "MaxSteps" -> 500]["Tag"],
	"StepLimit", TestID -> "partialrecursive-pair-forces-both-results"
]

VerificationTest[
	EvaluateRecursor[ToRecursor[{"Recurse", {"Search", "Successor"}, "Zero"}, "PartialRecursive"], 0, "MaxSteps" -> 500]["Tag"],
	"StepLimit", TestID -> "partialrecursive-zero-recursion-forces-base"
]

VerificationTest[
	RecursorProgramQ /@ (ToRecursor[#, "PartialRecursive"] & /@ {"Zero", "Successor", "Left", "Right", {"Pair", "Left", "Right"}, {"Compose", "Left", "Right"}, {"Recurse", "Zero", "Successor"}, {"Search", "Right"}}),
	ConstantArray[True, 8], TestID -> "partialrecursive-all-constructors-closed"
]

VerificationTest[Head /@ {ToRecursor[{"Pair", "Left"}, "PartialRecursive"], ToRecursor["Unknown", "PartialRecursive"]}, {ToRecursor, ToRecursor}, TestID -> "partialrecursive-invalid-code-unmatched"]
