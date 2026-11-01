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

RecursorProgramTree[program_?RecursorExpressionQ, opts : OptionsPattern[]] := Module[{sites, indices, edges},
	sites = RecursorSites[program];
	indices = AssociationThread[Lookup[sites, "Path"], Range[Length[sites]]];
	edges = Function[site, DirectedEdge[Lookup[indices, Key[Most[site["Path"]]]], Lookup[indices, Key[site["Path"]]]]] /@ Rest[sites];
	With[{constructor = If[edges === {}, Graph, TreeGraph]},
		constructor[Range[Length[sites]], edges,
			VertexLabels -> Replace[OptionValue[VertexLabels], Automatic :> Thread[Range[Length[sites]] -> (label /@ Lookup[sites, "Expression"])]],
			GraphRoot -> Replace[OptionValue[GraphRoot], Automatic -> 1],
			FilterRules[Flatten[{opts, Options[RecursorProgramTree]}], Options[constructor]]
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
