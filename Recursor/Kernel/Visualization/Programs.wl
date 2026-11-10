PackageExported[{RecursorProgramTree, RecursorEvolutionPlot, RecursorGenealogyGraph}]

RecursorProgramTree::usage = "RecursorProgramTree[p] draws the syntax tree of a Recursor expression."
RecursorEvolutionPlot::usage = "RecursorEvolutionPlot[result] plots best fitness by generation for a EvolveRecursor result."
RecursorGenealogyGraph::usage = "RecursorGenealogyGraph[result] draws parent-child edges recorded by EvolveRecursor."

Options[RecursorProgramTree] = Join[{VertexLabels -> Automatic}, FilterRules[Options[TreeGraph], Except[VertexLabels]]]
Options[RecursorGenealogyGraph] = Join[{VertexLabels -> "Name"}, FilterRules[Options[Graph], Except[VertexLabels]]]
Options[RecursorEvolutionPlot] = Join[{AxesLabel -> {"Generation", "Exact matches"}}, FilterRules[Options[ListLinePlot], Except[AxesLabel]]]

label[Const[n_]] := ToString[n]
label[e : Var | Acc | Idx] := SymbolName[e]
label[e_] := SymbolName[Head[e]]

(* Syntax nodes are of four kinds: loops, arithmetic, choice and binding, and inputs and constants. *)
nodeKind[_Const | Var | Acc | Idx] := 4
nodeKind[e_] := Switch[Head[e], Rec | Iter | CoRec | WhileLoop, 1, Ifz | Let | CGet, 3, _, 2]
$nodeColors = {RGBColor["#2a78d6"], RGBColor["#eb6834"], RGBColor["#1baf7a"], RGBColor["#eda100"]}
nodeStyle[e_] := With[{color = $nodeColors[[nodeKind[e]]]},
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
boxWidth[e_] := 0.56 StringLength[label[e]] + 1.

treeDesign[sites_List, indices_Association] := Module[{paths = Lookup[sites, "Path"], expression, children, measure, place, coordinates = <||>, width, depth},
	expression[path_] := sites[[indices[path], "Expression"]];
	children = GroupBy[Rest[paths], Most];
	measure[path_] := measure[path] = Max[boxWidth[expression[path]] + $margin, Total[measure /@ Lookup[children, Key[path], {}]]];
	place[path_, left_] := Module[{below = Lookup[children, Key[path], {}], offset, centers, center},
		offset = left + (measure[path] - Total[measure /@ below])/2;
		centers = Table[With[{x = place[child, offset]}, offset += measure[child]; x], {child, below}];
		center = If[below === {}, left + measure[path]/2, (First[centers] + Last[centers])/2];
		coordinates[indices[path]] = {center, -$levelHeight Length[path]};
		center
	];
	place[{}, 0];
	width = measure[{}] + 2 $margin;
	depth = Max[Length /@ paths];
	{
		VertexCoordinates -> Lookup[coordinates, Range[Length[sites]]],
		VertexLabels -> Thread[Range[Length[sites]] -> (Placed[label[#], Center] & /@ Lookup[sites, "Expression"])],
		VertexLabelStyle -> Directive[FontSize -> Scaled[0.95/width]],
		VertexShapeFunction -> With[{half = Association[MapIndexed[First[#2] -> {boxWidth[#1], $boxHeight}/2 &, Lookup[sites, "Expression"]]]},
			Function[{position, vertex, size}, Rectangle[position - half[vertex], position + half[vertex], RoundingRadius -> 0.35]]],
		VertexStyle -> Thread[Range[Length[sites]] -> (nodeStyle /@ Lookup[sites, "Expression"])],
		EdgeShapeFunction -> "Line",
		EdgeStyle -> GrayLevel[0.6],
		PlotRange -> {{-$margin, measure[{}] + $margin}, {-$levelHeight depth - $boxHeight/2 - $margin, $boxHeight/2 + $margin}},
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
		Select[treeDesign[sites, indices], First[#] === VertexLabels || OptionValue[First[#]] === OptionValue[TreeGraph, {}, First[#]] &],
		{VertexLabels -> Replace[OptionValue[VertexLabels], Automatic :> Thread[Range[Length[sites]] -> (label /@ Lookup[sites, "Expression"])]]}
	];
	With[{constructor = If[edges === {}, Graph, TreeGraph]},
		constructor[Range[Length[sites]], edges,
			GraphRoot -> Replace[OptionValue[GraphRoot], Automatic -> 1],
			FilterRules[Flatten[{design, FilterRules[Flatten[{opts, Options[RecursorProgramTree]}], Except[Alternatives @@ First /@ design]]}], Options[constructor]]
		]
	]
]

RecursorEvolutionPlot[result_Association, opts : OptionsPattern[]] := ListLinePlot[
	result["FitnessHistory"], DataRange -> Replace[OptionValue[DataRange], Automatic -> {0, result["Generations"]}],
	FilterRules[Flatten[{opts, Options[RecursorEvolutionPlot]}], Options[ListLinePlot]]
] /; KeyExistsQ[result, "FitnessHistory"] && KeyExistsQ[result, "Generations"]

RecursorGenealogyGraph[result_Association, opts : OptionsPattern[]] := With[{records = result["Genealogy"]},
	Graph[Lookup[records, "ID"], Catenate[
		Function[record, DirectedEdge[#, record["ID"]] & /@ record["Parents"]] /@ records
	], FilterRules[Flatten[{opts, Options[RecursorGenealogyGraph]}], Options[Graph]]]
] /; KeyExistsQ[result, "Genealogy"]
