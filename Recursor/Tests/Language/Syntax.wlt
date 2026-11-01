Needs["WolframInstitute`Recursor`"]

VerificationTest[RecursorProgramQ /@ Values[RecursorExamples[]], ConstantArray[True, 7], TestID -> "example-programs-closed"]

VerificationTest[RecursorExpressionQ /@ {Acc, Idx, CGet[Const[0]]}, {True, True, True}, TestID -> "open-expressions-well-formed"]

VerificationTest[RecursorProgramQ /@ {Acc, Idx, CGet[Const[0]]}, {False, False, False}, TestID -> "open-expressions-not-programs"]

VerificationTest[RecursorExpressionQ /@ {Const[-1], Const[1.5], Const[1, 2], Succ[], Add[Var], WhileLoop[Var, Acc], Var[1], 7}, ConstantArray[
	False, 8], TestID -> "syntax-exact-arities-and-types"]

VerificationTest[RecursorProgramQ[CoRec[Var, Acc]], False, TestID -> "course-recursion-does-not-bind-accumulator"]

VerificationTest[RecursorProgramQ[Iter[Var, Const[0], CoRec[Var, Acc]]], True, TestID -> "course-recursion-inherits-outer-accumulator"]

VerificationTest[RecursorProgramQ[WhileLoop[Acc, Const[0], Acc]], False, TestID -> "while-base-outside-binder"]

VerificationTest[RecursorProgramQ[WhileLoop[Const[0], Idx, Acc]], False, TestID -> "while-does-not-bind-index"]

VerificationTest[RecursorFreeVariables[Rec[Var, Const[0], Add[Acc, CGet[Idx]]]], {CGet}, TestID -> "scope-removes-only-own-bindings"]

VerificationTest[RecursorNodeCount[Const[1000000]], 1, TestID -> "constant-is-single-node"]

VerificationTest[RecursorNodeCount[WhileLoop[Var, Acc, Pred[Acc]]], 5, TestID -> "while-node-count"]

VerificationTest[Lookup[RecursorSites[WhileLoop[Var, Acc, Pred[Acc]]], "Bindings"], {{}, {}, {Acc}, {Acc}, {Acc}}, TestID -> "while-sites-bind-both-children"
	]

VerificationTest[ReplaceRecursorPart[WhileLoop[Var, Acc, Pred[Acc]], {3}, Half[Acc]], WhileLoop[Var, Acc, Half[Acc]], TestID -> "scope-correct-replacement"
	]

VerificationTest[Head[ReplaceRecursorPart[Var, {}, Acc]], ReplaceRecursorPart, TestID -> "reject-free-replacement"]

VerificationTest[Head[ReplaceRecursorPart[Var, {1}, Const[0]]], ReplaceRecursorPart, TestID -> "reject-path-inside-leaf"]

VerificationTest[ParseRecursor /@ (FormatRecursor /@ Values[RecursorExamples[]]), Values[RecursorExamples[]], TestID -> "source-round-trip"
	]

VerificationTest[And @@ (FailureQ[ParseRecursor[#]]& /@ {"", "Acc", "Const[-1]", "Const[1+1]", "Add[Var]", "Var;Quit[]", "Global`Var", "Const[1 2]",
	 "Var[]", "WhileLoop[Var,Idx,Acc]"}), True, TestID -> "parser-rejects-outside-grammar"]

VerificationTest[
	Block[{probe = 0},
		ParseRecursor["(probe=1;Var)"];
		probe
	],
	0,
	TestID -> "parser-does-not-evaluate-source"
]

VerificationTest[FailureQ[ParseRecursor["Succ[Succ[Var]]", "MaxNodes" -> 2]], True, TestID -> "parser-node-limit"]

VerificationTest[FailureQ[ParseRecursor["Succ[Succ[Var]]", "MaxDepth" -> 2]], True, TestID -> "parser-depth-limit"]

VerificationTest[RecursorProgramQ[Nest[Succ, Var, 70]], True, TestID -> "language-has-no-sixty-node-limit"]