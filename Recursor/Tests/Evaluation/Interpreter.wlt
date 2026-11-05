Needs["WolframInstitute`Recursor`"]

VerificationTest[Table[EvaluateRecursor[RecursorExamples["Factorial"], n], {n, 0, 7}], Factorial[Range[0, 7]], TestID -> "factorial-original-recursion"
	]

VerificationTest[Table[EvaluateRecursor[RecursorExamples["Fibonacci"], n], {n, 0, 12}], Fibonacci[Range[0, 12]], TestID -> "fibonacci-course-recursion"
	]

VerificationTest[Table[EvaluateRecursor[RecursorExamples["PopulationCount"], n], {n, 0, 20}], DigitCount[Range[0, 20], 2, 1], TestID ->
	"population-count"]

VerificationTest[Table[EvaluateRecursor[RecursorExamples["PowerOfTwo"], n], {n, 0, 10}], 2 ^ Range[0, 10], TestID -> "bounded-iteration"
	]

VerificationTest[EvaluateRecursor[CoRec[Const[3], Add[CGet[Idx], CGet[Succ[Idx]]]], 0], 0, TestID -> "history-current-and-future-zero"]

VerificationTest[EvaluateRecursor[Rec[Const[2], Const[10], Add[Acc, Iter[Const[1], Const[3], Add[Acc, Idx]]]], 0], 17, TestID -> "nested-index-inheritance-and-acc-shadowing"
	]

VerificationTest[EvaluateRecursor[Iter[Const[1], Const[9], CoRec[Const[2], Acc]], 0], 9, TestID -> "course-inherits-accumulator"]

VerificationTest[EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 5000, "MaxSteps" -> 20003], 0, TestID -> "while-long-run-no-host-stack-growth"
	]

VerificationTest[EvaluateRecursor[WhileLoop[Var, Const[0], RecursorExamples["Nonterminating"]], 9], 9, TestID -> "while-zero-iterations"
	]

VerificationTest[EvaluateRecursor[Ifz[Const[0], Const[7], RecursorExamples["Nonterminating"]], 0], 7, TestID -> "lazy-unselected-branch"
	]

VerificationTest[EvaluateRecursor[WhileLoop[Const[0], Const[1], Acc], 0, "MaxSteps" -> 10]["Tag"], "StepLimit", TestID -> "nontermination-is-step-limit"
	]

VerificationTest[FailureQ[EvaluateRecursor[Mul[Const[0], RecursorExamples["Nonterminating"]], 0, "MaxSteps" -> 20]], True, TestID -> "multiplication-strict-even-at-zero"
	]

VerificationTest[FailureQ[EvaluateRecursor[Iter[Const[0], RecursorExamples["Nonterminating"], Const[1]], 0, "MaxSteps" -> 20]], True, TestID
	 -> "zero-iteration-base-is-strict"]

VerificationTest[EvaluateRecursor[Const[3], 0, "MaxSteps" -> 0]["Tag"], "StepLimit", TestID -> "zero-step-budget"]

VerificationTest[EvaluateRecursor[Const[3], 0, "MaxSteps" -> 1], 3, TestID -> "one-step-budget"]

VerificationTest[
	Table[EvaluateRecursor[Rem[Const[a], Const[b]], 0], {a, 0, 6}, {b, 0, 4}],
	Table[
		If[b === 0,
			a,
			Mod[a, b]
		],
		{a, 0, 6},
		{b, 0, 4}
	],
	TestID -> "remainder-including-zero-divisor"
]

VerificationTest[Head[EvaluateRecursor[Acc, 0]], EvaluateRecursor, TestID -> "open-program-not-evaluated"]

VerificationTest[Head[EvaluateRecursor[Var, -1]], EvaluateRecursor, TestID -> "negative-input-not-evaluated"]

VerificationTest[FailureQ[EvaluateRecursor[Var, 0, "MaxSteps" -> -1]], True, TestID -> "invalid-evaluation-option"]

VerificationTest[EvaluateRecursor[WhileLoop[Const[0], Const[1], Acc], 0, "MaxSteps" -> Infinity, "TimeLimit" -> 0.05]["Tag"], "TimeLimit",
	 TestID -> "time-limit-independent-of-step-limit"]

VerificationTest[EvaluateRecursor[WhileLoop[Var, Acc, Pred[Acc]], 20, "MaxSteps" -> Infinity, "TimeLimit" -> Infinity, "MemoryLimit" ->
	Infinity], 0, TestID -> "unbounded-mode-terminating-program"]

VerificationTest[
	EvaluateRecursor[Iter[Const[10^30], Const[7], Succ[Acc]], 0, "MaxSteps" -> 10]["Tag"],
	"StepLimit", TestID -> "iteration-count-beyond-machine-integer-obeys-budget"
]

VerificationTest[
	EvaluateRecursor[Rec[Const[10^30], Const[7], Succ[Acc]], 0, "MaxSteps" -> 10]["Tag"],
	"StepLimit", TestID -> "recursion-count-beyond-machine-integer-obeys-budget"
]

VerificationTest[
	EvaluateRecursor[CoRec[Const[10^30], Const[7]], 0, "MaxSteps" -> 10]["Tag"],
	"StepLimit", TestID -> "history-count-beyond-machine-integer-obeys-budget"
]
