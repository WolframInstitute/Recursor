PackageExported[SynthesizeRecursor]

PackageScoped[synthesisLoopBodies]

SynthesizeRecursor::usage = "SynthesizeRecursor[examples] finds a closed program from input-output examples and checks it on examples it was not shown. \
It enumerates programs up to observational equivalence, checks recurrences against the data, solves for constants exactly, \
and composes sums, products, counts and searches. \
SynthesizeRecursor[terms] uses the inputs 0, 1, 2, …. Solved means the program found from the first examples also reproduces at least four held-out ones \
and the examples hold enough evidence."

Options[SynthesizeRecursor] = {Method -> Automatic, "MaxCost" -> 8, "MaxConstant" -> 3, "MaxLoopBody" -> 4, "MaxFoldTerm" -> 5,
	"HoldOut" -> Automatic, "RequiredEvidence" -> 24, "TimeLimit" -> 20}

$synthesisFamilies = {"Enumeration", "Recurrence", "Solving", "Composition"}

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

synthesisLoopBodies[arguments___] := loopBodies[arguments]

(* Examples kept from the search: the last quarter, and one of fewer than eight. *)
heldOutCount[Automatic, count_] := Which[count < 2, 0, count < 8, 1, True, Quotient[count, 4]]
heldOutCount[k_Integer, count_] := Min[k, Max[count - 1, 0]]

reproducesQ[program_, {input_, value_}] := EvaluateRecursor[program, input, "MaxSteps" -> 1000000, "TimeLimit" -> 5] === value

(* Evidence, in bits: the information in the examples less the information in
   the program. A value is coded by its distance from the one before; a unit
   of cost stands for one choice among the expressions of the next level,
   which grow about fivefold. A program that says about as much as its
   examples can fit them by chance. *)
$bitsPerCost = 2.5

(* Solved needs this many held-out examples. Sequences often follow a simple
   rule for their first terms and then leave it, which no amount of evidence
   in those terms can show. On OEIS samples the share of solved programs that
   continue their sequence was 76% from eight terms, 93% from twelve, 95% from
   sixteen and 98% from twenty. *)
$requiredHeldOut = 4
exampleBits[values_List] := Total[Log2[2. + Abs[Differences[Prepend[values, 0]]]]]

(* Inputs on which the values of composed programs are kept. *)
$rangeLimit = 128

(* Sums, products and counts over a loop index, alone and inside searches,
   counting functions, partial sums, differences and compositions. Inside
   those forms a term costs one less than alone: they need its values on a
   long range of inputs, and each further unit of cost multiplies the terms. *)
compositionCandidates[inputs_, values_, maximum_, maximumConstant_, foldTerm_, deadline_] := Module[{
	cap = Max[2^40, 16 Max[values]], terms, deep, limit, range, closed, wide, rows, costs, expressions, found
},
	terms = Catenate[KeyValueMap[Function[{cost, list}, {cost, #} & /@ list], KeySort[synthesisFoldTerms[foldTerm, maximumConstant, deadline]]]];
	deep = synthesisFolds[terms, inputs, cap, deadline];
	found = synthesisDirect[deep["Rows"], deep["Costs"], Function[k, synthesisFoldProgram[deep["Specifications"][[k]]]], Range[Length[inputs]], values, "Fold"];
	If[AbsoluteTime[] > deadline, Return[found]];
	limit = Min[$rangeLimit, Max[2 Max[inputs] + 3, If[Min[Differences[values]] > 0, Max[values] + 2, 0]]];
	If[Max[inputs] >= limit, Return[found]];
	range = Range[0, limit - 1];
	closed = synthesisClasses[
		Join[{{Var, range}}, Table[{Const[c], ConstantArray[c, limit]}, {c, 0, maximumConstant}]],
		None, Min[maximum, 5], deadline, None, False, None &
	];
	wide = synthesisFolds[Select[terms, First[#] < foldTerm &], range, cap, deadline];
	rows = Join[Catenate[Values[KeySort[closed["Vectors"]]]], wide["Rows"]];
	costs = Join[Catenate[KeyValueMap[ConstantArray[#1, Length[#2]] &, KeySort[closed["Vectors"]]]], wide["Costs"]];
	expressions = Catenate[Values[KeySort[closed["Expressions"]]]];
	Join[found, synthesisCompositions[rows, costs,
		Function[k, If[k <= Length[expressions], expressions[[k]], synthesisFoldProgram[wide["Specifications"][[k - Length[expressions]]]]]],
		inputs, values, maximumConstant, deadline]]
]

SynthesizeRecursor[terms : {__Integer?NonNegative}, opts : OptionsPattern[]] :=
	SynthesizeRecursor[Transpose[{Range[0, Length[terms] - 1], terms}], opts]

SynthesizeRecursor[examples_?synthesisExamplesQ, OptionsPattern[]] := Enclose @ Module[{
	method = OptionValue[Method], maximum = OptionValue["MaxCost"], maximumConstant = OptionValue["MaxConstant"],
	loopBody = OptionValue["MaxLoopBody"], foldTerm = OptionValue["MaxFoldTerm"], holdOut = OptionValue["HoldOut"],
	required = OptionValue["RequiredEvidence"], seconds = OptionValue["TimeLimit"],
	data = Union[examples], training, heldOut, inputs, values, families, deadline, consecutive, enumerated = 0, bound, closed,
	accepted = None, unconfirmed = {}, information, consider, describe, enumerate, enumeratedTo = 0
},
	families = Replace[method, {Automatic | All -> $synthesisFamilies, name_String :> {name}}];
	ConfirmAssert[ListQ[families] && SubsetQ[$synthesisFamilies, families], "Method must be Automatic or a subset of Enumeration, Recurrence, Solving and Composition."];
	ConfirmAssert[MatchQ[maximum, _Integer?Positive] && AllTrue[{maximumConstant, loopBody, foldTerm}, MatchQ[#, _Integer?NonNegative] &],
		"MaxCost, MaxConstant, MaxLoopBody and MaxFoldTerm must be nonnegative integers, with MaxCost positive."];
	ConfirmAssert[MatchQ[holdOut, Automatic | _Integer?NonNegative], "HoldOut must be Automatic or a nonnegative integer."];
	ConfirmAssert[MatchQ[required, _?NumericQ] && Element[required, Reals], "RequiredEvidence must be a real number."];
	ConfirmAssert[MatchQ[seconds, _?Positive | Infinity], "TimeLimit must be positive or Infinity."];
	{training, heldOut} = TakeDrop[data, Length[data] - heldOutCount[holdOut, Length[data]]];
	inputs = training[[All, 1]];
	values = training[[All, 2]];
	deadline = AbsoluteTime[] + seconds;
	consecutive = inputs === Range[First[inputs], Last[inputs]];
	information = exampleBits[data[[All, 2]]];
	(* Candidates are tried from the cheapest. One that reproduces the training
	   examples is accepted when it also reproduces every held-out example;
	   a cheaper program is then the only one that could replace it. *)
	consider[candidates_List] := Do[
		If[accepted =!= None && candidate["Cost"] >= accepted["Cost"], Break[]];
		If[RecursorProgramQ[candidate["Program"]] && AllTrue[training, reproducesQ[candidate["Program"], #] &],
			With[{matches = Count[heldOut, _?(reproducesQ[candidate["Program"], #] &)]},
				If[heldOut =!= {} && matches === Length[heldOut],
					accepted = candidate,
					AppendTo[unconfirmed, Append[candidate, "HeldOutMatches" -> matches]]
				]
			]
		],
		{candidate, Take[SortBy[candidates, #["Cost"] &], UpTo[12]]}
	];
	If[DuplicateFreeQ[inputs],
		If[SameQ @@ values,
			consider[{<|"Program" -> Const[First[values]], "Cost" -> synthesisConstantCost[First[values]], "Method" -> "Constant"|>}]
		];
		If[consecutive && MemberQ[families, "Solving"], consider[synthesisSolvers[First[inputs], values]]];
		If[consecutive && MemberQ[families, "Recurrence"],
			consider[synthesisRecurrences[First[inputs], values, Max[maximum - 3, 1], maximumConstant, deadline]]
		];
		(* Closed forms are enumerated to cost six, then programs are composed, then
		   enumeration goes on to the full cost if nothing cheaper is accepted:
		   the deep levels take most of the time and a composed program often
		   makes them unnecessary. *)
		enumerate[limit_] := (
			bound = Min[limit, If[accepted === None, Infinity, accepted["Cost"] - 1]];
			If[bound >= 1 && bound > enumeratedTo,
				closed = synthesisClasses[
					Join[{{Var, inputs}}, Table[{Const[c], ConstantArray[c, Length[inputs]]}, {c, 0, maximumConstant}]],
					values, bound, deadline,
					If[loopBody > 0, <|"Bodies" -> loopBodies[loopBody, maximumConstant, deadline], "Inputs" -> inputs, "MaxBody" -> loopBody|>, None],
					Length[inputs] > 1, Function[{expression, cost}, <|"Cost" -> cost, "Expression" -> expression, "Method" -> "ClosedForm"|>]
				];
				enumerated = closed["Candidates"];
				enumeratedTo = bound;
				consider[<|"Program" -> #["Expression"], "Cost" -> #["Cost"], "Method" -> #["Method"]|> & /@ closed["Matches"]]
			]
		);
		If[MemberQ[families, "Enumeration"], enumerate[Min[maximum, 6]]];
		(* an accepted program with evidence enough ends the search; one without may give way to a cheaper composed program *)
		If[(accepted === None || information - $bitsPerCost accepted["Cost"] < required) &&
			MemberQ[families, "Composition"] && Length[inputs] > 2 && AbsoluteTime[] < deadline,
			consider[compositionCandidates[inputs, values, maximum, maximumConstant, foldTerm, deadline]]
		];
		If[MemberQ[families, "Enumeration"] && AbsoluteTime[] < deadline, enumerate[maximum]]
	];
	describe[candidate_, matches_] := With[{evidence = N[Round[information - $bitsPerCost candidate["Cost"], 1/10]]},
		<|"Program" -> candidate["Program"], "Solved" -> matches === Length[heldOut] && Length[heldOut] >= $requiredHeldOut && evidence >= required,
			"Cost" -> candidate["Cost"], "Nodes" -> RecursorNodeCount[candidate["Program"]], "Method" -> candidate["Method"], "Candidates" -> enumerated,
			"TrainingExamples" -> Length[training], "HeldOutExamples" -> Length[heldOut], "HeldOutMatches" -> matches, "Evidence" -> evidence|>
	];
	(* the local functions are cleared so that nothing of the search outlives the call *)
	With[{result = Which[
			accepted =!= None, describe[accepted, Length[heldOut]],
			unconfirmed =!= {}, With[{fit = First[SortBy[unconfirmed, #["Cost"] &]]}, describe[fit, fit["HeldOutMatches"]]],
			True, <|"Program" -> Missing["NotFound"], "Solved" -> False, "Candidates" -> enumerated,
				"TrainingExamples" -> Length[training], "HeldOutExamples" -> Length[heldOut]|>
		]},
		Remove[consider, describe, enumerate];
		closed = unconfirmed = Null;
		result
	]
]
