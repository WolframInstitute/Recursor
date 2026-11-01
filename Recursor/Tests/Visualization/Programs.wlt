Needs["WolframInstitute`Recursor`"]

VerificationTest[VertexCount[RecursorProgramTree[Var]], 1, TestID -> "tree-single-leaf"]

VerificationTest[
	With[{graph = RecursorProgramTree[WhileLoop[Var, Acc, Pred[Acc]]]},
		{VertexCount[graph], EdgeCount[graph]}
	],
	{5, 4},
	TestID -> "tree-contains-every-node"
]

VerificationTest[
	With[{result = EvolveRecursor[{{0, 7}}, "PopulationSize" -> 3, "EliteCount" -> 1, "MaxGenerations" -> 1, "RandomSeed" -> 15, "StopOnSolve"
		 -> False]},
		GraphQ[RecursorGenealogyGraph[result]]
	],
	True,
	TestID -> "genealogy-graph"
]