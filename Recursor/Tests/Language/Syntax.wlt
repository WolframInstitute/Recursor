Needs["WolframInstitute`Recursor`"]

VerificationTest[RecursorProgramQ /@ Values[RecursorExamples[]], ConstantArray[True, 11], TestID -> "example-programs-closed"]

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

VerificationTest[Lookup[$RecursorGrammar, {"Quot", "Let"}], {2, 2}, TestID -> "grammar-lists-quotient-and-let"]

VerificationTest[RecursorExpressionQ /@ {Quot[Var, Const[2]], Let[Var, Var], Quot[Var], Let[Var], Let[Var, Var, Var]}, {True, True, False, False,
	False}, TestID -> "quotient-and-let-arities"]

VerificationTest[RecursorProgramQ /@ {Let[Succ[Var], Mul[Var, Var]], Let[Var, Acc], Let[Idx, Var], Let[Var, CGet[Var]]}, {True, False, False, False},
	TestID -> "let-binds-only-the-input"]

VerificationTest[RecursorFreeVariables[Let[Acc, Idx]], {Acc, Idx}, TestID -> "let-keeps-enclosing-bindings-free"]

VerificationTest[RecursorProgramQ[Rec[Var, Const[0], Add[Acc, Let[Idx, Mul[Var, Var]]]]], True, TestID -> "let-inherits-loop-bindings"]

VerificationTest[Lookup[RecursorSites[Iter[Var, Const[0], Let[Acc, Var]]], "Bindings"], {{}, {}, {}, {Acc}, {Acc}, {Acc}}, TestID -> "let-sites-add-no-bindings"]

VerificationTest[ParseRecursor["Let[Quot[Var, Const[3]], Succ[Var]]"], Let[Quot[Var, Const[3]], Succ[Var]], TestID -> "parser-reads-quotient-and-let"]

VerificationTest[FailureQ[ParseRecursor["Let[Var, Acc]"]], True, TestID -> "parser-rejects-unbound-accumulator-under-let"]
