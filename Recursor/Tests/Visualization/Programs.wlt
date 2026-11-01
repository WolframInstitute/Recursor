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

visualizationResult = <|
	"FitnessHistory" -> {2, 4, 5}, "Generations" -> 2, "MaxFitness" -> 20,
	"Genealogy" -> {<|"ID" -> 1, "Parents" -> {}|>, <|"ID" -> 2, "Parents" -> {1}|>, <|"ID" -> 3, "Parents" -> {1, 2}|>}
|>;

visualizationOptionValues[native_, options_List, names_] := OptionValue[native, FilterRules[options, Options[native]], names]

VerificationTest[
	Map[Function[root, With[{graph = RecursorProgramTree[RecursorExamples["Factorial"], GraphRoot -> root]},
		First[Ordering[Last /@ (VertexCoordinates /. AbsoluteOptions[graph, VertexCoordinates]), -1]]
	]], {Automatic, 4}],
	{1, 4}, TestID -> "syntax-tree-root-is-the-program-root-unless-overridden"
]

VerificationTest[
	Module[{graph = RecursorProgramTree[Add[Mul[Var, Var], Mul[Var, Var]]], coordinates, edges},
		coordinates = AssociationThread[VertexList[graph], VertexCoordinates /. AbsoluteOptions[graph, VertexCoordinates]];
		edges = EdgeList[graph];
		{VertexList[graph], edges, AllTrue[edges, Last[coordinates[First[#]]] > Last[coordinates[Last[#]]] &]}
	],
	{Range[7], {1 \[DirectedEdge] 2, 2 \[DirectedEdge] 3, 2 \[DirectedEdge] 4, 1 \[DirectedEdge] 5, 5 \[DirectedEdge] 6, 5 \[DirectedEdge] 7}, True},
	TestID -> "repeated-subexpressions-keep-distinct-directed-paths-below-root"
]

VerificationTest[
	And[
		FilterRules[Options[RecursorProgramTree], Except[VertexLabels]] === FilterRules[Options[TreeGraph], Except[VertexLabels]],
		FilterRules[Options[RecursorGenealogyGraph], Except[VertexLabels]] === FilterRules[Options[Graph], Except[VertexLabels]],
		FilterRules[Options[RecursorEvolutionPlot], Except[AxesLabel]] === FilterRules[Options[ListLinePlot], Except[AxesLabel]]
	], True, TestID -> "visualizations-inherit-native-presentation-defaults"
]

VerificationTest[
	Module[{graphOptions = {ImageSize, AspectRatio, ImagePadding, EdgeStyle, VertexStyle, GraphLayout}, plotOptions = {ImageSize, AspectRatio, ImagePadding, PlotRange}},
		And[
			visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Const[3], Var]]], graphOptions] ===
				visualizationOptionValues[TreeGraph, Options[TreeGraph[Range[3], {1 -> 2, 1 -> 3}]], graphOptions],
			visualizationOptionValues[Graph, Options[RecursorGenealogyGraph[visualizationResult]], graphOptions] ===
				visualizationOptionValues[Graph, Options[Graph[Range[3], {1 -> 2, 1 -> 3, 2 -> 3}]], graphOptions],
			visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult]], plotOptions] ===
				visualizationOptionValues[Graphics, Options[ListLinePlot[{2, 4, 5}, DataRange -> {0, 2}, AxesLabel -> {"Generation", "Exact matches"}]], plotOptions]
		]
	], True, TestID -> "rendered-objects-have-no-hidden-presentation-overrides"
]

VerificationTest[
	{
		Sort[Cases[Options[RecursorProgramTree[Mul[Const[3], Var]], VertexLabels], Rule[_, value_String] :> value, Infinity]],
		visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Var, VertexLabels -> None]], VertexLabels] ===
			visualizationOptionValues[Graph, Options[Graph[{1}, {}, VertexLabels -> None]], VertexLabels]
	}, {{"3", "Mul", "Var"}, True}, TestID -> "syntax-labels-are-automatic-and-overridable"
]

VerificationTest[
	Module[{options = {ImageSize -> Small, AspectRatio -> 1, GraphLayout -> "CircularEmbedding", VertexLabels -> None}},
		And[
			visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Const[3], Var], options]], First /@ options] ===
				visualizationOptionValues[TreeGraph, Options[TreeGraph[Range[3], {1 -> 2, 1 -> 3}, options]], First /@ options],
			visualizationOptionValues[Graph, Options[RecursorGenealogyGraph[visualizationResult, options]], First /@ options] ===
				visualizationOptionValues[Graph, Options[Graph[Range[3], {1 -> 2, 1 -> 3, 2 -> 3}, options]], First /@ options]
		]
	], True, TestID -> "graph-options-override-native-defaults"
]

VerificationTest[
	MapThread[Function[{function, argument, native}, Module[{defaults = Options[function]},
		WithCleanup[
			SetOptions[function, ImageSize -> Small, AspectRatio -> 1];
			{
				visualizationOptionValues[native, Options[function[argument]], {ImageSize, AspectRatio}],
				visualizationOptionValues[native, Options[function[argument, ImageSize -> Large, AspectRatio -> 1/2]], {ImageSize, AspectRatio}]
			},
			Options[function] = defaults
		]
	]], {{RecursorProgramTree, RecursorGenealogyGraph, RecursorEvolutionPlot}, {Var, visualizationResult, visualizationResult}, {TreeGraph, Graph, Graphics}}],
	ConstantArray[{{Small, 1}, {Large, 1/2}}, 3], TestID -> "visualization-setoptions-and-explicit-precedence"
]

VerificationTest[
	visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult, DataRange -> {10, 12}, PlotRange -> All]], PlotRange] ===
		visualizationOptionValues[Graphics, Options[ListLinePlot[{2, 4, 5}, DataRange -> {10, 12}, PlotRange -> All]], PlotRange],
	True, TestID -> "evolution-coordinate-and-range-options-are-forwarded"
]
