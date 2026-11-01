PackageExported[{RecursorProgramTree, RecursorEvolutionPlot, RecursorGenealogyGraph}]

RecursorProgramTree::usage = "RecursorProgramTree[p] draws the syntax tree of a Recursor expression."
RecursorEvolutionPlot::usage = "RecursorEvolutionPlot[result] plots best fitness by generation for a EvolveRecursor result."
RecursorGenealogyGraph::usage = "RecursorGenealogyGraph[result] draws parent-child edges recorded by EvolveRecursor."

Options[RecursorProgramTree] = Options[Graph]
Options[RecursorGenealogyGraph] = Options[Graph]
Options[RecursorEvolutionPlot] = Options[ListLinePlot]

label[Const[n_]] := ToString[n]
label[e : Var | Acc | Idx] := SymbolName[e]
label[e_] := SymbolName[Head[e]]

RecursorProgramTree[program_?RecursorExpressionQ, opts : OptionsPattern[]] := Module[{sites, indices, edges},
	sites = RecursorSites[program];
	indices = AssociationThread[Lookup[sites, "Path"], Range[Length[sites]]];
	edges = Function[site, DirectedEdge[Lookup[indices, Key[Most[site["Path"]]]], Lookup[indices, Key[site["Path"]]]]] /@ Rest[sites];
	Graph[Range[Length[sites]], edges, opts,
		VertexLabels -> Thread[Range[Length[sites]] -> (label /@ Lookup[sites, "Expression"])],
		GraphLayout -> "LayeredDigraphEmbedding", ImagePadding -> 25,
		ImageSize -> {480, 360}, AspectRatio -> 3/4,
		EdgeStyle -> LightDarkSwitched[RGBColor[0.50, 0.61, 0.74], RGBColor[0.55, 0.67, 0.83]],
		VertexStyle -> LightDarkSwitched[RGBColor[0.27, 0.48, 0.68], RGBColor[0.50, 0.72, 0.88]]
	]
]

RecursorEvolutionPlot[result_Association, opts : OptionsPattern[]] := ListLinePlot[
	result["FitnessHistory"], opts, DataRange -> {0, result["Generations"]},
	PlotRange -> {0, Lookup[result, "MaxFitness", Max[1, Max[result["FitnessHistory"]]]]},
	AxesLabel -> {"Generation", "Exact matches"}, PlotMarkers -> Automatic, ImageSize -> {520, 340}
] /; KeyExistsQ[result, "FitnessHistory"] && KeyExistsQ[result, "Generations"]

RecursorGenealogyGraph[result_Association, opts : OptionsPattern[]] := With[{records = result["Genealogy"]},
	Graph[Lookup[records, "ID"], Catenate[
		Function[record, DirectedEdge[#, record["ID"]] & /@ record["Parents"]] /@ records
	], opts, GraphLayout -> "LayeredDigraphEmbedding", VertexLabels -> "Name",
		EdgeStyle -> LightDarkSwitched[RGBColor[0.50, 0.61, 0.74], RGBColor[0.55, 0.67, 0.83]],
		ImageSize -> {520, 360}, AspectRatio -> 2/3]
] /; KeyExistsQ[result, "Genealogy"]
