PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

VerificationTest[VertexCount[RecursorProgramTree[Var]], 1, TestID -> "tree-single-leaf"]

VerificationTest[
	Module[{graph = RecursorProgramTree[WhileLoop[Var, Acc, Pred[Acc]]]},
		{VertexCount[graph], EdgeCount[graph]}
	],
	{5, 4},
	TestID -> "tree-contains-every-node"
]

VerificationTest[
	Module[{result},
		result = EvolveRecursor[{{0, 7}}, "PopulationSize" -> 3, "EliteCount" -> 1, "MaxGenerations" -> 1, "RandomSeed" -> 15, "StopOnSolve" -> False];
		GraphQ[RecursorGenealogyGraph[result]]
	],
	True,
	TestID -> "genealogy-graph"
]

visualizationResult = <|
	"FitnessHistory" -> {2, 4, 5}, "Generations" -> 2, "MaxFitness" -> 20,
	"Genealogy" -> {<|"ID" -> 1, "Parents" -> {}|>, <|"ID" -> 2, "Parents" -> {1}|>, <|"ID" -> 3, "Parents" -> {1, 2}|>}
|>;

(* the plot that RecursorEvolutionPlot[visualizationResult] must equal in its presentation: framed, with frame labels *)
framedReferencePlot = ListLinePlot[{2, 4, 5}, DataRange -> {0, 2}, Frame -> True, Axes -> False, FrameLabel -> {"Generation", "Exact matches"}];

visualizationOptionValues[native_, options_List, names_] := OptionValue[native, FilterRules[options, Options[native]], names]

VerificationTest[
	Map[
		Function[root,
			Module[{graph = RecursorProgramTree[RecursorExamples["Factorial"], GraphRoot -> root]},
				First[Ordering[Last /@ (VertexCoordinates /. AbsoluteOptions[graph, VertexCoordinates]), -1]]
			]
		],
		{Automatic, 4}
	],
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
		FilterRules[Options[RecursorEvolutionPlot], Except[Frame | Axes | FrameLabel]] === FilterRules[Options[ListLinePlot], Except[Frame | Axes | FrameLabel]]
	], True, TestID -> "visualizations-inherit-native-presentation-defaults"
]

VerificationTest[
	OptionValue[RecursorEvolutionPlot, {Frame, Axes, FrameLabel}],
	{True, False, {"Generation", "Exact matches"}},
	TestID -> "evolution-plot-declares-its-frame"
]

VerificationTest[
	visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult]], {Frame, Axes, FrameLabel}],
	visualizationOptionValues[Graphics, Options[framedReferencePlot], {Frame, Axes, FrameLabel}],
	TestID -> "evolution-plot-is-framed-and-labeled"
]

VerificationTest[
	SameQ[
		visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult, Frame -> False, Axes -> True]], {Frame, Axes}],
		visualizationOptionValues[Graphics, Options[ListLinePlot[{2, 4, 5}, DataRange -> {0, 2}, Frame -> False, Axes -> True]], {Frame, Axes}]
	],
	True,
	TestID -> "evolution-plot-frame-is-replaceable"
]

VerificationTest[
	Module[{graphOptions = {ImageSize, AspectRatio, ImagePadding, EdgeStyle, VertexStyle, GraphLayout}, plotOptions = {ImageSize, AspectRatio, ImagePadding, PlotRange},
			treeOptions = {AspectRatio, ImagePadding, GraphLayout}},
		And[
			(* the syntax tree has a design of its own; what the design leaves alone stays native *)
			SameQ[
				visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Const[3], Var]]], treeOptions],
				visualizationOptionValues[TreeGraph, Options[TreeGraph[Range[3], {1 -> 2, 1 -> 3}]], treeOptions]
			],
			SameQ[
				visualizationOptionValues[Graph, Options[RecursorGenealogyGraph[visualizationResult]], graphOptions],
				visualizationOptionValues[Graph, Options[Graph[Range[3], {1 -> 2, 1 -> 3, 2 -> 3}]], graphOptions]
			],
			SameQ[
				visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult]], plotOptions],
				visualizationOptionValues[Graphics, Options[framedReferencePlot], plotOptions]
			]
		]
	], True, TestID -> "rendered-objects-have-no-hidden-presentation-overrides"
]

VerificationTest[
	{
		Sort[Cases[Options[RecursorProgramTree[Mul[Const[3], Var]], VertexLabels], Placed[value_String, Center] :> value, Infinity]],
		SameQ[
			visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Var, VertexLabels -> None]], VertexLabels],
			visualizationOptionValues[Graph, Options[Graph[{1}, {}, VertexLabels -> None]], VertexLabels]
		]
	}, {{"3", "Mul", "Var"}, True}, TestID -> "syntax-labels-are-automatic-and-overridable"
]

VerificationTest[
	Module[{options = Options[RecursorProgramTree[Mul[Const[3], Var]]]},
		{
			MatchQ[Flatten[{visualizationOptionValues[TreeGraph, options, VertexShapeFunction]}], {_Function}],
			Flatten[{visualizationOptionValues[TreeGraph, options, EdgeShapeFunction]}],
			Length[visualizationOptionValues[TreeGraph, options, VertexStyle]],
			NumericQ[visualizationOptionValues[TreeGraph, options, ImageSize]]
		}
	],
	{True, {"Line"}, 3, True}, TestID -> "syntax-tree-design-resolves-automatic-options"
]

(* the design colors the four kinds of node with Standard colors and draws the lines between them in the Standard gray *)
VerificationTest[
	Module[{options = Options[RecursorProgramTree[Rec[Var, Const[1], Ifz[Idx, Acc, Succ[Acc]]]]], styles},
		styles = Association[visualizationOptionValues[TreeGraph, options, VertexStyle]];
		{
			Map[Function[vertex, FirstCase[styles[vertex], EdgeForm[Directive[color_, _]] :> color, None, {0, Infinity}]], {1, 2, 4, 7}],
			AllTrue[Values[styles], MatchQ[Directive[FaceForm[_LightDarkSwitched], _EdgeForm]]],
			Flatten[{visualizationOptionValues[TreeGraph, options, EdgeStyle]}]
		}
	],
	{{StandardBlue, StandardYellow, StandardGreen, StandardOrange}, True, {StandardGray}},
	TestID -> "syntax-tree-design-uses-standard-colors"
]

VerificationTest[
	Module[{width},
		width = Function[program, visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[program]], ImageSize]];
		{
			width[Var] < width[Mul[Var, Var]] < width[Add[Mul[Var, Var], Mul[Var, Var]]],
			width[Nest[Add[#, #] &, Var, 7]] == width[Nest[Add[#, #] &, Var, 8]]
		}
	],
	{True, True}, TestID -> "syntax-tree-width-follows-the-tree-up-to-a-limit"
]

VerificationTest[
	Module[{graph = RecursorProgramTree[RecursorExamples["Prime"]], coordinates, widths, levels, apartQ},
		coordinates = VertexCoordinates /. AbsoluteOptions[graph, VertexCoordinates];
		widths = Cases[Options[graph, VertexLabels], Placed[name_String, Center] :> 0.56 StringLength[name] + 1., Infinity];
		(* each box is {{x, y}, width}: a level holds the boxes with one y, from left to right *)
		levels = GatherBy[SortBy[Transpose[{coordinates, widths}], First], Function[box, Last[First[box]]]];
		apartQ = Function[pair,
			Replace[pair, {{{leftCenter_, _}, leftWidth_}, {{rightCenter_, _}, rightWidth_}} :> rightCenter - leftCenter >= (leftWidth + rightWidth) / 2]
		];
		{Length[widths] === VertexCount[graph], AllTrue[levels, Function[level, AllTrue[Partition[level, 2, 1], apartQ]]]}
	],
	{True, True}, TestID -> "syntax-tree-boxes-on-a-level-do-not-overlap"
]

VerificationTest[
	{
		Flatten[visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Var, Var], VertexStyle -> Red, EdgeStyle -> Blue, ImageSize -> 200]], {VertexStyle, EdgeStyle, ImageSize}]],
		(* a layout, a root, labels or shapes of the caller's choosing give the native drawing *)
		Map[Flatten[visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Var, Var], #]], {VertexShapeFunction, VertexStyle, ImageSize}]] &,
			{GraphLayout -> "RadialEmbedding", GraphRoot -> 2, VertexLabels -> "Name", VertexShapeFunction -> "Square"}]
	},
	{{Red, Blue, 200}, {{Automatic, Automatic, Automatic}, {Automatic, Automatic, Automatic}, {Automatic, Automatic, Automatic}, {"Square", Automatic, Automatic}}},
	TestID -> "syntax-tree-design-parts-are-replaceable"
]

VerificationTest[
	Module[{options = {ImageSize -> Small, AspectRatio -> 1, GraphLayout -> "CircularEmbedding", VertexLabels -> None}},
		And[
			SameQ[
				visualizationOptionValues[TreeGraph, Options[RecursorProgramTree[Mul[Const[3], Var], options]], First /@ options],
				visualizationOptionValues[TreeGraph, Options[TreeGraph[Range[3], {1 -> 2, 1 -> 3}, options]], First /@ options]
			],
			SameQ[
				visualizationOptionValues[Graph, Options[RecursorGenealogyGraph[visualizationResult, options]], First /@ options],
				visualizationOptionValues[Graph, Options[Graph[Range[3], {1 -> 2, 1 -> 3, 2 -> 3}, options]], First /@ options]
			]
		]
	], True, TestID -> "graph-options-override-native-defaults"
]

VerificationTest[
	MapThread[Function[{function, argument, native}, Module[{defaults = Options[function]},
		WithCleanup[
			SetOptions[function, ImageSize -> Small, AspectRatio -> 1];
			{
				visualizationOptionValues[native, Options[function[argument]], {ImageSize, AspectRatio}],
				visualizationOptionValues[native, Options[function[argument, ImageSize -> Large, AspectRatio -> 1 / 2]], {ImageSize, AspectRatio}]
			},
			Options[function] = defaults
		]
	]], {{RecursorProgramTree, RecursorGenealogyGraph, RecursorEvolutionPlot}, {Var, visualizationResult, visualizationResult}, {TreeGraph, Graph, Graphics}}],
	ConstantArray[{{Small, 1}, {Large, 1 / 2}}, 3], TestID -> "visualization-setoptions-and-explicit-precedence"
]

VerificationTest[
	SameQ[
		visualizationOptionValues[Graphics, Options[RecursorEvolutionPlot[visualizationResult, DataRange -> {10, 12}, PlotRange -> All]], PlotRange],
		visualizationOptionValues[Graphics, Options[ListLinePlot[{2, 4, 5}, DataRange -> {10, 12}, PlotRange -> All]], PlotRange]
	],
	True, TestID -> "evolution-coordinate-and-range-options-are-forwarded"
]

VerificationTest[RecursorProgramTree[Succ[]]["Tag"], "InvalidArguments", {RecursorProgramTree::args}, TestID -> "program-tree-catch-all"]

VerificationTest[RecursorEvolutionPlot[<|"Generations" -> 2|>]["Tag"], "InvalidArguments", {RecursorEvolutionPlot::args}, TestID -> "evolution-plot-catch-all"]

VerificationTest[RecursorGenealogyGraph[{}]["Tag"], "InvalidArguments", {RecursorGenealogyGraph::args}, TestID -> "genealogy-graph-catch-all"]
