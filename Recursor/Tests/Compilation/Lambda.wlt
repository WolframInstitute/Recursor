Needs["WolframInstitute`Recursor`"]

closedLambda[index_Integer, depth_] :=
	1 <= index <= depth

closedLambda[\[FormalLambda][body_], depth_] :=
	closedLambda[body, depth + 1]

closedLambda[head_[argument_], depth_] :=
	closedLambda[head, depth] && closedLambda[argument, depth]

closedLambda[_, _] :=
	False

VerificationTest[AllTrue[Values[RecursorExamples[]], closedLambda[CompileRecursor[#], 0]&], True, TestID -> "compiled-examples-are-closed-lambda-terms"
	]

VerificationTest[CompileRecursor[Var], \[FormalLambda][1], TestID -> "compile-input-is-identity"]

VerificationTest[NormalizeRecursor[Const[2]], \[FormalLambda][\[FormalLambda][\[FormalLambda][2[2[1]]]]], TestID -> "normalize-constant-function"
	]

VerificationTest[Table[EvaluateRecursor[program, n, Method -> "Lambda", "MaxSteps" -> 500000], {program, {Var, Const[2], Succ[Var], Pred[
	Var], Half[Var], Add[Var, Var], Mul[Var, Var], Monus[Const[2], Var], Rem[Var, Const[2]], Rem[Var, Const[0]]}}, {n, 0, 3}], Table[EvaluateRecursor[
	program, n], {program, {Var, Const[2], Succ[Var], Pred[Var], Half[Var], Add[Var, Var], Mul[Var, Var], Monus[Const[2], Var], Rem[Var, Const[
	2]], Rem[Var, Const[0]]}}, {n, 0, 3}], TestID -> "interpreter-compiler-arithmetic-agreement"]

VerificationTest[Table[EvaluateRecursor[program, n, Method -> "Lambda", "MaxSteps" -> 1000000, "TimeLimit" -> 20], {program, Lookup[RecursorExamples[
	], {"Countdown", "Factorial", "Fibonacci", "PopulationCount", "PowerOfTwo"}]}, {n, 0, 3}], Table[EvaluateRecursor[program, n], {program,
	 Lookup[RecursorExamples[], {"Countdown", "Factorial", "Fibonacci", "PopulationCount", "PowerOfTwo"}]}, {n, 0, 3}], TestID -> "interpreter-compiler-recurrence-agreement"
	]

VerificationTest[EvaluateRecursor[Ifz[Const[0], Const[7], RecursorExamples["Nonterminating"]], 0, Method -> "Lambda"], 7, TestID -> "compiler-lazy-branch"
	]

VerificationTest[AllTrue[{Mul[Const[0], RecursorExamples["Nonterminating"]], Monus[Const[0], RecursorExamples["Nonterminating"]], Ifz[Succ[
	RecursorExamples["Nonterminating"]], Const[1], Const[2]], WhileLoop[RecursorExamples["Nonterminating"], Const[0], Const[0]], Iter[Const[
	1], RecursorExamples["Nonterminating"], Const[0]]}, FailureQ[EvaluateRecursor[#, 0, Method -> "Lambda", "MaxSteps" -> 1000]]&], True, TestID
	 -> "compiler-preserves-strict-divergence"]

VerificationTest[EvaluateRecursor[Rec[Const[2], Const[10], Add[Acc, Iter[Const[1], Const[3], Add[Acc, Idx]]]], 0, Method -> "Lambda", "MaxSteps"
	 -> 1000000], 17, TestID -> "compiler-nested-binders"]

VerificationTest[EvaluateRecursor[CoRec[Const[1], CoRec[Const[0], CGet[Const[0]]]], 0, Method -> "Lambda"], 0, TestID -> "compiler-history-shadowing"
	]

VerificationTest[EvaluateRecursor[RecursorExamples["Nonterminating"], 0, Method -> "Lambda", "MaxSteps" -> 1000]["Tag"], "StepLimit", TestID
	 -> "lambda-fixed-point-divergence-bounded"]
VerificationTest[
	FailureQ[NormalizeRecursor[Var, "TimeLimit" -> 0]],
	True,
	TestID -> "normalization-rejects-invalid-resource-options"
]

VerificationTest[Table[EvaluateRecursor[program, n, Method -> "Lambda", "MaxSteps" -> 2000000, "TimeLimit" -> 30], {program, {Quot[Var, Const[2]], Quot[Var,
	Const[3]], Quot[Var, Const[0]], Quot[Const[7], Var], Let[Succ[Var], Mul[Var, Var]], Let[Const[2], Let[Succ[Var], Mul[Var, Var]]], Add[Let[
	Const[5], Var], Var]}}, {n, 0, 4}], Table[EvaluateRecursor[program, n], {program, {Quot[Var, Const[2]], Quot[Var, Const[3]], Quot[Var, Const[
	0]], Quot[Const[7], Var], Let[Succ[Var], Mul[Var, Var]], Let[Const[2], Let[Succ[Var], Mul[Var, Var]]], Add[Let[Const[5], Var], Var]}}, {n, 0,
	4}], TestID -> "interpreter-compiler-quotient-and-let-agreement"]

VerificationTest[Table[EvaluateRecursor[Rec[Var, Const[0], Add[Acc, Let[Idx, Mul[Var, Var]]]], n, Method -> "Lambda", "MaxSteps" -> 5000000, "TimeLimit"
	 -> 60], {n, 0, 4}], {0, 0, 1, 5, 14}, TestID -> "compiler-let-inherits-loop-bindings"]

VerificationTest[AllTrue[{Let[RecursorExamples["Nonterminating"], Const[1]], Quot[Const[0], RecursorExamples["Nonterminating"]], Quot[RecursorExamples[
	"Nonterminating"], Const[0]]}, FailureQ[EvaluateRecursor[#, 0, Method -> "Lambda", "MaxSteps" -> 1000]]&], True, TestID -> "compiler-keeps-let-and-quotient-strict"
	]

VerificationTest[EvaluateRecursor[RecursorExamples["Prime"], 2, Method -> "Lambda", "MaxSteps" -> 10000000, "TimeLimit" -> 120], 5, TestID -> "compiler-prime-search-through-let"]
