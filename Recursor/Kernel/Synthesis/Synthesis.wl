PackageExported[SynthesizeRecursor]

SynthesizeRecursor::usage = "SynthesizeRecursor[examples] finds the cheapest closed program that matches input-output examples. \
It enumerates programs up to observational equivalence, checks recurrences against the data and solves for constants exactly. \
SynthesizeRecursor[terms] uses the inputs 0, 1, 2, …. Solved means a fit to these examples."

Options[SynthesizeRecursor] = {Method -> Automatic, "MaxCost" -> 8, "MaxConstant" -> 3, "MaxLoopBody" -> 4, "TimeLimit" -> 20}

$synthesisFamilies = {"Enumeration", "Recurrence", "Solving"}

synthesisExamplesQ[data_List] := data =!= {} && MatchQ[data, {{_Integer?NonNegative, _Integer?NonNegative}..}]
synthesisExamplesQ[_] := False

(* Sample environments on which loop bodies are told apart. *)
$bodyInput = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 5, 7, 9}
$bodyIndex = {0, 0, 1, 2, 0, 3, 5, 1, 6, 4, 9, 7, 3, 4, 2, 8}
$bodyAccumulator = {0, 1, 3, 2, 7, 12, 5, 24, 1, 64, 10, 120, 0, 31, 100, 720}

loopBodies[maximum_, maximumConstant_, deadline_] := Map[
	Select[#, ! FreeQ[#, Acc] &] &,
	synthesisClasses[
		Join[{{Var, $bodyInput}, {Acc, $bodyAccumulator}, {Idx, $bodyIndex}}, Table[{Const[c], ConstantArray[c, 16]}, {c, 0, maximumConstant}]],
		None, maximum, deadline, None, False, None &
	]["Expressions"]
]

reproducesQ[program_, data_] := RecursorProgramQ[program] &&
	AllTrue[data, EvaluateRecursor[program, First[#], "MaxSteps" -> 1000000, "TimeLimit" -> 5] === Last[#] &]

SynthesizeRecursor[terms : {__Integer?NonNegative}, opts : OptionsPattern[]] :=
	SynthesizeRecursor[Transpose[{Range[0, Length[terms] - 1], terms}], opts]

SynthesizeRecursor[examples_?synthesisExamplesQ, OptionsPattern[]] := Enclose @ Module[{
	method = OptionValue[Method], maximum = OptionValue["MaxCost"], maximumConstant = OptionValue["MaxConstant"],
	loopBody = OptionValue["MaxLoopBody"], seconds = OptionValue["TimeLimit"],
	data = Union[examples], inputs, values, families, deadline, consecutive, candidates = {}, enumerated = 0, bound, closed, chosen
},
	families = Replace[method, {Automatic | All -> $synthesisFamilies, name_String :> {name}}];
	ConfirmAssert[ListQ[families] && SubsetQ[$synthesisFamilies, families], "Method must be Automatic or a subset of Enumeration, Recurrence and Solving."];
	ConfirmAssert[MatchQ[maximum, _Integer?Positive] && MatchQ[maximumConstant, _Integer?NonNegative] && MatchQ[loopBody, _Integer?NonNegative],
		"MaxCost, MaxConstant and MaxLoopBody must be nonnegative integers, with MaxCost positive."];
	ConfirmAssert[MatchQ[seconds, _?Positive | Infinity], "TimeLimit must be positive or Infinity."];
	inputs = data[[All, 1]];
	values = data[[All, 2]];
	deadline = AbsoluteTime[] + seconds;
	consecutive = inputs === Range[First[inputs], Last[inputs]];
	If[DuplicateFreeQ[inputs],
		If[SameQ @@ values,
			AppendTo[candidates, <|"Program" -> Const[First[values]], "Cost" -> synthesisConstantCost[First[values]], "Method" -> "Constant"|>]
		];
		If[consecutive && MemberQ[families, "Solving"], candidates = Join[candidates, synthesisSolvers[First[inputs], values]]];
		If[consecutive && MemberQ[families, "Recurrence"],
			With[{found = synthesisRecurrences[First[inputs], values, Max[maximum - 3, 1], maximumConstant, deadline]},
				If[found =!= None, AppendTo[candidates, found]]
			]
		];
		If[MemberQ[families, "Enumeration"],
			bound = Min[maximum, Min[Lookup[candidates, "Cost", {}], Infinity] - 1];
			If[bound >= 1,
				closed = synthesisClasses[
					Join[{{Var, inputs}}, Table[{Const[c], ConstantArray[c, Length[inputs]]}, {c, 0, maximumConstant}]],
					values, bound, deadline,
					If[loopBody > 0, <|"Bodies" -> loopBodies[loopBody, maximumConstant, deadline], "Inputs" -> inputs, "MaxBody" -> loopBody|>, None],
					Length[inputs] > 1, Function[{expression, cost}, <|"Cost" -> cost, "Expression" -> expression, "Method" -> "ClosedForm"|>]
				];
				enumerated = closed["Candidates"];
				If[closed["Best"] =!= None,
					AppendTo[candidates, <|"Program" -> closed["Best"]["Expression"], "Cost" -> closed["Best"]["Cost"], "Method" -> closed["Best"]["Method"]|>]
				]
			]
		]
	];
	(* Ordering is stable, so equal costs keep the order solved, recurrence, enumerated. *)
	chosen = SelectFirst[candidates[[Ordering[Lookup[candidates, "Cost", {}]]]], reproducesQ[#["Program"], data] &, None];
	If[chosen === None,
		<|"Program" -> Missing["NotFound"], "Solved" -> False, "Candidates" -> enumerated|>,
		<|"Program" -> chosen["Program"], "Solved" -> True, "Cost" -> chosen["Cost"], "Nodes" -> RecursorNodeCount[chosen["Program"]],
			"Method" -> chosen["Method"], "Candidates" -> enumerated|>
	]
]
