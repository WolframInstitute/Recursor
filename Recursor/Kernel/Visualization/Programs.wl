(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{RecursorProgramTree, RecursorEvolutionPlot, RecursorGenealogyGraph}]

(* ::Section:: *)
(*Usage Messages*)

RecursorProgramTree::usage = "RecursorProgramTree[p] draws the syntax tree of a Recursor expression."
RecursorEvolutionPlot::usage = "RecursorEvolutionPlot[result] plots best fitness by generation for a EvolveRecursor result."
RecursorGenealogyGraph::usage = "RecursorGenealogyGraph[result] draws parent-child edges recorded by EvolveRecursor."

nodeLabel::usage = "nodeLabel[expression] gives the name shown in the box of a syntax node: the digits of a constant, and otherwise the \
name of the node's head."
nodeKind::usage = "nodeKind[expression] gives the kind of a syntax node as a position in $nodeColors: 1 for a loop, 2 for arithmetic, \
3 for choice and binding, and 4 for an input or a constant."
$nodeColors::usage = "$nodeColors lists the colors of the four kinds of syntax node, in the order nodeKind gives."
nodeStyle::usage = "nodeStyle[kind] gives the face and the edge of the box of a syntax node of the given kind."
$boxHeight::usage = "$boxHeight is the height of the box of a syntax node, in units of the label height."
$levelHeight::usage = "$levelHeight is the distance between two levels of a syntax tree, in units of the label height."
$margin::usage = "$margin is the space around a box and around the tree, in units of the label height."
$labelSize::usage = "$labelSize is the width of one unit of the tree design in printer's points."
$widthLimit::usage = "$widthLimit is the greatest width of a syntax tree picture in printer's points."
boxWidth::usage = "boxWidth[name] gives the width of the box that holds a name, in units of the label height."
subtreeWidths::usage = "subtreeWidths[paths, children, boxWidths] gives the width of the subtree at each path: the width of its root box with \
its margin, or the total width of its children when that is greater."
subtreeLefts::usage = "subtreeLefts[paths, children, widths] gives the left edge of the subtree at each path, with the children of a node \
side by side and centered under it. The paths list each node before its children."
subtreeCenters::usage = "subtreeCenters[paths, children, widths, lefts] gives the horizontal center of the node at each path: the middle of \
its subtree for a leaf, and otherwise the middle of its first and last child."
treeDesign::usage = "treeDesign[sites] gives the options with which RecursorProgramTree draws its own design for the sites of a program: \
coordinates, labels, shapes, styles, plot range and image size."

(* ::Section:: *)
(*Options*)

Options[RecursorProgramTree] = Join[{VertexLabels -> Automatic}, FilterRules[Options[TreeGraph], Except[VertexLabels]]]
Options[RecursorGenealogyGraph] = Join[{VertexLabels -> "Name"}, FilterRules[Options[Graph], Except[VertexLabels]]]
Options[RecursorEvolutionPlot] = Join[
	{Frame -> True, Axes -> False, FrameLabel -> {"Generation", "Exact matches"}},
	FilterRules[Options[ListLinePlot], Except[Frame | Axes | FrameLabel]]
]

(* ::Section:: *)
(*Function Definitions*)

nodeLabel[Const[value_Integer]] := ToString[value]
nodeLabel[atom : Var | Acc | Idx] := SymbolName[atom]
nodeLabel[expression_] := SymbolName[Head[expression]]

(* Syntax nodes are of four kinds: loops, arithmetic, choice and binding, and inputs and constants. *)
nodeKind[_Const | Var | Acc | Idx] := 4
nodeKind[_Rec | _Iter | _CoRec | _WhileLoop] := 1
nodeKind[_Ifz | _Let | _CGet] := 3
nodeKind[_] := 2

$nodeColors = {StandardBlue, StandardOrange, StandardGreen, StandardYellow}

nodeStyle[kind_Integer] := With[{color = $nodeColors[[kind]]},
	Directive[FaceForm[LightDarkSwitched[Blend[{White, color}, 0.2], Blend[{Black, color}, 0.45]]], EdgeForm[Directive[color, AbsoluteThickness[1]]]]
]

(* The design measures in units of the label height. A box is as wide as its name; a subtree is as
   wide as its root box or its children; a node sits over the middle of its first and last child.
   The picture is as wide as its tree, up to a limit, so names have one size in every tree. *)
$boxHeight = 1.8
$levelHeight = 3.1
$margin = 0.6
$labelSize = 11.5
$widthLimit = 600

boxWidth[name_String] := 0.56 StringLength[name] + 1.

(* Children have longer paths than their parent, so the deepest paths come first. *)
subtreeWidths[paths_List, children_Association, boxWidths_Association] := Fold[
	Function[{known, path},
		Append[known, path -> Max[boxWidths[path] + $margin, Total[Map[known, Lookup[children, Key[path], {}]]]]]
	],
	<||>,
	ReverseSortBy[paths, Length]
]

subtreeLefts[paths_List, children_Association, widths_Association] := Fold[
	Function[{known, path},
		Module[{below = Lookup[children, Key[path], {}], childWidths, offset},
			childWidths = Map[widths, below];
			offset = known[path] + (widths[path] - Total[childWidths]) / 2;
			Join[known, AssociationThread[below, Most[FoldList[Plus, offset, childWidths]]]]
		]
	],
	<|{} -> 0|>,
	paths
]

subtreeCenters[paths_List, children_Association, widths_Association, lefts_Association] := Fold[
	Function[{known, path},
		Module[{below = Lookup[children, Key[path], {}]},
			Append[known, path -> If[below === {}, lefts[path] + widths[path] / 2, (known[First[below]] + known[Last[below]]) / 2]]
		]
	],
	<||>,
	ReverseSortBy[paths, Length]
]

treeDesign[sites_List] := Module[{paths, expressions, names, vertices, children, widths, lefts, centers, width, depth, halfSizes},
	paths = Lookup[sites, "Path"];
	expressions = Lookup[sites, "Expression"];
	names = nodeLabel /@ expressions;
	vertices = Range[Length[sites]];
	children = GroupBy[Rest[paths], Most];
	widths = subtreeWidths[paths, children, AssociationThread[paths, boxWidth /@ names]];
	lefts = subtreeLefts[paths, children, widths];
	centers = subtreeCenters[paths, children, widths, lefts];
	width = widths[{}] + 2 $margin;
	depth = Max[Length /@ paths];
	halfSizes = AssociationThread[vertices, Map[Function[name, {boxWidth[name], $boxHeight} / 2], names]];
	{
		VertexCoordinates -> Map[Function[path, {centers[path], -$levelHeight Length[path]}], paths],
		VertexLabels -> Thread[vertices -> Map[Function[name, Placed[name, Center]], names]],
		VertexLabelStyle -> Directive[FontSize -> Scaled[0.95 / width]],
		VertexShapeFunction -> With[{half = halfSizes},
			Function[{position, vertex, size}, Rectangle[position - half[vertex], position + half[vertex], RoundingRadius -> 0.35]]
		],
		VertexStyle -> Thread[vertices -> Map[Function[expression, nodeStyle[nodeKind[expression]]], expressions]],
		EdgeShapeFunction -> "Line",
		EdgeStyle -> StandardGray,
		PlotRange -> {{-$margin, widths[{}] + $margin}, {-$levelHeight depth - $boxHeight / 2 - $margin, $boxHeight / 2 + $margin}},
		PlotRangePadding -> None,
		ImageSize -> Min[$widthLimit, $labelSize width]
	}
]

(* The design draws the tree when the caller leaves its labels, shapes, layout and root Automatic.
   A value other than TreeGraph's own default for any other option replaces that part of the design. *)
RecursorProgramTree[program_?RecursorExpressionQ, opts : OptionsPattern[]] := Module[{sites, indices, edges, design},
	sites = RecursorSites[program];
	indices = AssociationThread[Lookup[sites, "Path"], Range[Length[sites]]];
	edges = Function[site, DirectedEdge[Lookup[indices, Key[Most[site["Path"]]]], Lookup[indices, Key[site["Path"]]]]] /@ Rest[sites];
	design = If[AllTrue[{VertexLabels, VertexShapeFunction, GraphLayout, VertexCoordinates, GraphRoot}, OptionValue[#] === Automatic &],
		Select[treeDesign[sites], First[#] === VertexLabels || OptionValue[First[#]] === OptionValue[TreeGraph, {}, First[#]] &],
		{VertexLabels -> Replace[OptionValue[VertexLabels], Automatic :> Thread[Range[Length[sites]] -> (nodeLabel /@ Lookup[sites, "Expression"])]]}
	];
	With[{constructor = If[edges === {}, Graph, TreeGraph]},
		constructor[Range[Length[sites]], edges,
			GraphRoot -> Replace[OptionValue[GraphRoot], Automatic -> 1],
			FilterRules[Flatten[{design, FilterRules[Flatten[{opts, Options[RecursorProgramTree]}], Except[Alternatives @@ First /@ design]]}], Options[constructor]]
		]
	]
]
RecursorProgramTree[___] := invalidArgumentsFailure[RecursorProgramTree]

(* The frame and its labels are options of the plot itself, so SetOptions and explicit options replace them. *)
RecursorEvolutionPlot[result_Association, opts : OptionsPattern[]] := ListLinePlot[
	result["FitnessHistory"],
	DataRange -> Replace[OptionValue[DataRange], Automatic -> {0, result["Generations"]}],
	Frame -> OptionValue[Frame],
	Axes -> OptionValue[Axes],
	FrameLabel -> OptionValue[FrameLabel],
	FilterRules[Flatten[{opts, Options[RecursorEvolutionPlot]}], Options[ListLinePlot]]
] /; KeyExistsQ[result, "FitnessHistory"] && KeyExistsQ[result, "Generations"]
RecursorEvolutionPlot[___] := invalidArgumentsFailure[RecursorEvolutionPlot]

RecursorGenealogyGraph[result_Association, opts : OptionsPattern[]] := With[{records = result["Genealogy"]},
	Graph[
		Lookup[records, "ID"],
		Catenate[Function[record, DirectedEdge[#, record["ID"]] & /@ record["Parents"]] /@ records],
		FilterRules[Flatten[{opts, Options[RecursorGenealogyGraph]}], Options[Graph]]
	]
] /; KeyExistsQ[result, "Genealogy"]
RecursorGenealogyGraph[___] := invalidArgumentsFailure[RecursorGenealogyGraph]
