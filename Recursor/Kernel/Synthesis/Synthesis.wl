(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[SynthesizeRecursor]

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[synthesisLoopBodies]

(* ::Section:: *)
(*Usage Messages*)

SynthesizeRecursor::usage = "SynthesizeRecursor[examples] finds a closed program from input-output examples and checks it on examples it was not \
shown. It enumerates programs up to observational equivalence, checks recurrences against the data, solves for constants exactly, \
and composes sums, products, counts and searches. Solved means the program found from the first examples also reproduces at least four held-out \
ones and the examples hold enough evidence.\n\
SynthesizeRecursor[terms] uses the inputs 0, 1, 2 and so on."

$synthesisFamilies::usage = "$synthesisFamilies is the list of the families of programs that Method can name."

synthesisExamplesQ::usage = "synthesisExamplesQ[data] gives True when data is a nonempty list of pairs of natural numbers."

$bodyInput::usage = "$bodyInput is the list of sample inputs on which loop bodies are told apart."

$bodyIndex::usage = "$bodyIndex is the list of sample indices on which loop bodies are told apart."

$bodyAccumulator::usage = "$bodyAccumulator is the list of sample accumulator values on which loop bodies are told apart."

loopBodies::usage = "loopBodies[maximum, maximumConstant, deadline] gives the loop bodies that read Acc by cost, up to the cost maximum, one for each distinct \
list of values on the sample environments."

synthesisLoopBodies::usage = "synthesisLoopBodies[maximum, maximumConstant, deadline] gives the loop bodies that read Acc by cost, up to the cost maximum."

heldOutCount::usage = "heldOutCount[holdOut, count] gives the number of examples kept from the search out of count examples. For holdOut Automatic it is the \
last quarter, and one of fewer than eight."

reproducesQ::usage = "reproducesQ[program, {input, value}] gives True when program gives value on input."

$bitsPerCost::usage = "$bitsPerCost is the number of bits of information that one unit of cost stands for."

$requiredHeldOut::usage = "$requiredHeldOut is the number of held-out examples a solved program needs."

exampleBits::usage = "exampleBits[values] gives the information in the values in bits, each value coded by its distance from the one before."

$rangeLimit::usage = "$rangeLimit is the largest number of inputs on which the values of composed programs are kept."

rangeCompositions::usage = "rangeCompositions[inputs, values, terms, limit, cap, maximum, maximumConstant, foldTerm, deadline] gives the candidates built \
around closed forms and folds whose values are kept on the inputs below limit. terms is the list of pairs {cost, term} of the fold terms."

compositionCandidates::usage = "compositionCandidates[inputs, values, maximum, maximumConstant, foldTerm, deadline] gives the candidates that are sums, \
products and counts over a loop index, alone and inside searches, counting functions, partial sums, differences and compositions."

$emptySearch::usage = "$emptySearch is the state of a search before any candidate is tried: an association with the accepted candidate or None \
(\"Accepted\"), the candidates that fit the training examples only (\"Unconfirmed\"), the number of enumerated \"Candidates\" and the cost enumerated to \
(\"EnumeratedTo\")."

considerCandidate::usage = "considerCandidate[search, candidate, problem] gives the state of the search after trying one candidate. A candidate that \
reproduces the training examples is accepted when it also reproduces every held-out example, and is kept as unconfirmed otherwise."

considerCandidates::usage = "considerCandidates[search, candidates, problem] gives the state of the search after trying the twelve cheapest candidates, from \
the cheapest."

enumerateClosedForms::usage = "enumerateClosedForms[search, limit, problem] gives the state of the search after enumerating closed forms up to the cost limit, \
or up to less than the cost of the accepted candidate."

searchFamilies::usage = "searchFamilies[problem] gives the state of the search after trying the families of programs that the problem names. problem is an \
association with the examples and the settings of the search."

describeCandidate::usage = "describeCandidate[candidate, matches, search, problem] gives the result of SynthesizeRecursor for a candidate that reproduces \
matches of the held-out examples."

searchResult::usage = "searchResult[search, problem] gives the result of SynthesizeRecursor for a finished search."

(* ::Section:: *)
(*Function Definitions*)

Options[SynthesizeRecursor] = {Method -> Automatic, "MaxCost" -> 8, "MaxConstant" -> 3, "MaxLoopBody" -> 4, "MaxFoldTerm" -> 5,
	"HoldOut" -> Automatic, "RequiredEvidence" -> 24, "TimeLimit" -> 20}

$synthesisFamilies = {"Enumeration", "Recurrence", "Solving", "Composition"}

synthesisExamplesQ[data_List] := data =!= {} && MatchQ[data, {{_Integer?NonNegative, _Integer?NonNegative}..}]
synthesisExamplesQ[___] := False

(* Sample environments on which loop bodies are told apart. *)
$bodyInput = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 5, 7, 9}
$bodyIndex = {0, 0, 1, 2, 0, 3, 5, 1, 6, 4, 9, 7, 3, 4, 2, 8}
$bodyAccumulator = {0, 1, 3, 2, 7, 12, 5, 24, 1, 64, 10, 120, 0, 31, 100, 720}

loopBodies[maximum_Integer, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)] :=
	Map[
		Function[bodies, Select[bodies, ! FreeQ[#, Acc] &]],
		synthesisClasses[
			Join[
				{{Var, $bodyInput}, {Acc, $bodyAccumulator}, {Idx, $bodyIndex}},
				Table[{Const[constant], ConstantArray[constant, 16]}, {constant, 0, maximumConstant}]
			],
			None, maximum, deadline, None, False, None &
		]["Expressions"]
	]

synthesisLoopBodies[maximum_Integer, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)] := loopBodies[maximum, maximumConstant, deadline]

(* Examples kept from the search: the last quarter, and one of fewer than eight. *)
heldOutCount[Automatic, count_Integer] := Which[count < 2, 0, count < 8, 1, True, Quotient[count, 4]]
heldOutCount[requested_Integer, count_Integer] := Min[requested, Max[count - 1, 0]]

reproducesQ[program_?synthesisExpressionQ, {input_Integer, value_Integer}] := EvaluateRecursor[program, input, "MaxSteps" -> 1000000, "TimeLimit" -> 5] === value
reproducesQ[___] := False

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

(* Closed forms and folds on a long range of inputs, inside searches,
   counting functions, partial sums, differences and compositions. Inside
   those forms a term costs one less than alone: they need its values on a
   long range of inputs, and each further unit of cost multiplies the terms. *)
rangeCompositions[
	inputs_List, values_List, terms_List, limit_Integer, cap_Integer, maximum_Integer, maximumConstant_Integer, foldTerm_Integer,
	deadline : (_Real | _Integer | Infinity)
] :=
	Module[{range, closed, wide, rows, costs, expressions},
		range = Range[0, limit - 1];
		closed = synthesisClasses[
			Join[{{Var, range}}, Table[{Const[constant], ConstantArray[constant, limit]}, {constant, 0, maximumConstant}]],
			None, Min[maximum, 5], deadline, None, False, None &
		];
		wide = synthesisFolds[Select[terms, First[#] < foldTerm &], range, cap, deadline];
		rows = Join[Catenate[Values[KeySort[closed["Vectors"]]]], wide["Rows"]];
		costs = Join[Catenate[KeyValueMap[ConstantArray[#1, Length[#2]] &, KeySort[closed["Vectors"]]]], wide["Costs"]];
		expressions = Catenate[Values[KeySort[closed["Expressions"]]]];
		synthesisCompositions[
			rows, costs,
			Function[position,
				If[position <= Length[expressions], expressions[[position]], synthesisFoldProgram[wide["Specifications"][[position - Length[expressions]]]]]
			],
			inputs, values, maximumConstant, deadline
		]
	]

(* Sums, products and counts over a loop index, alone and inside searches,
   counting functions, partial sums, differences and compositions. *)
compositionCandidates[
	inputs_List, values_List, maximum_Integer, maximumConstant_Integer, foldTerm_Integer, deadline : (_Real | _Integer | Infinity)
] :=
	Module[{cap, terms, deep, found, limit},
		cap = Max[2 ^ 40, 16 Max[values]];
		terms = Catenate[KeyValueMap[Function[{cost, list}, {cost, #} & /@ list], KeySort[synthesisFoldTerms[foldTerm, maximumConstant, deadline]]]];
		deep = synthesisFolds[terms, inputs, cap, deadline];
		found = synthesisDirect[
			deep["Rows"], deep["Costs"], Function[position, synthesisFoldProgram[deep["Specifications"][[position]]]], Range[Length[inputs]], values, "Fold"
		];
		limit = Min[$rangeLimit, Max[2 Max[inputs] + 3, If[Min[Differences[values]] > 0, Max[values] + 2, 0]]];
		If[AbsoluteTime[] > deadline || Max[inputs] >= limit,
			found,
			Join[found, rangeCompositions[inputs, values, terms, limit, cap, maximum, maximumConstant, foldTerm, deadline]]
		]
	]

(* The state of a search is passed from step to step as an association. *)
$emptySearch = <|"Accepted" -> None, "Unconfirmed" -> {}, "Candidates" -> 0, "EnumeratedTo" -> 0|>

(* A candidate that reproduces the training examples is accepted when it also
   reproduces every held-out example; a cheaper program is then the only one
   that could replace it. *)
considerCandidate[search_Association, candidate_Association, problem_Association] :=
	Module[{program, matches},
		program = candidate["Program"];
		Which[
			search["Accepted"] =!= None && candidate["Cost"] >= search["Accepted"]["Cost"],
				search,
			! (RecursorProgramQ[program] && AllTrue[problem["Training"], reproducesQ[program, #] &]),
				search,
			True,
				matches = Count[problem["HeldOut"], _?(reproducesQ[program, #] &)];
				If[problem["HeldOut"] =!= {} && matches === Length[problem["HeldOut"]],
					<|search, "Accepted" -> candidate|>,
					<|search, "Unconfirmed" -> Append[search["Unconfirmed"], Append[candidate, "HeldOutMatches" -> matches]]|>
				]
		]
	]

(* Candidates are tried from the cheapest. *)
considerCandidates[search_Association, candidates_List, problem_Association] :=
	Fold[
		Function[{current, candidate}, considerCandidate[current, candidate, problem]],
		search,
		Take[SortBy[candidates, #["Cost"] &], UpTo[12]]
	]

enumerateClosedForms[search_Association, limit_Integer, problem_Association] :=
	Module[{bound, inputs, loopBody, closed},
		bound = Min[limit, If[search["Accepted"] === None, Infinity, search["Accepted"]["Cost"] - 1]];
		If[bound >= 1 && bound > search["EnumeratedTo"],
			inputs = problem["Inputs"];
			loopBody = problem["MaxLoopBody"];
			closed = synthesisClasses[
				Join[{{Var, inputs}}, Table[{Const[constant], ConstantArray[constant, Length[inputs]]}, {constant, 0, problem["MaxConstant"]}]],
				problem["Values"], bound, problem["Deadline"],
				If[loopBody > 0,
					<|"Bodies" -> loopBodies[loopBody, problem["MaxConstant"], problem["Deadline"]], "Inputs" -> inputs, "MaxBody" -> loopBody|>,
					None
				],
				Length[inputs] > 1,
				Function[{expression, cost}, <|"Cost" -> cost, "Expression" -> expression, "Method" -> "ClosedForm"|>]
			];
			considerCandidates[
				<|search, "Candidates" -> closed["Candidates"], "EnumeratedTo" -> bound|>,
				<|"Program" -> #["Expression"], "Cost" -> #["Cost"], "Method" -> #["Method"]|> & /@ closed["Matches"],
				problem
			],
			search
		]
	]

(* Closed forms are enumerated to cost six, then programs are composed, then
   enumeration goes on to the full cost if nothing cheaper is accepted:
   the deep levels take most of the time and a composed program often
   makes them unnecessary. *)
searchFamilies[problem_Association] :=
	Module[{
		inputs, values, families, maximum, maximumConstant, deadline, consecutive, afterConstant, afterSolving, afterRecurrences, afterClosedForms,
		evidence, afterCompositions
	},
		{inputs, values, families, maximum, maximumConstant, deadline} = Lookup[problem, {"Inputs", "Values", "Families", "MaxCost", "MaxConstant", "Deadline"}];
		consecutive = inputs === Range[First[inputs], Last[inputs]];
		afterConstant = If[SameQ @@ values,
			considerCandidates[
				$emptySearch,
				{<|"Program" -> Const[First[values]], "Cost" -> synthesisConstantCost[First[values]], "Method" -> "Constant"|>},
				problem
			],
			$emptySearch
		];
		afterSolving = If[consecutive && MemberQ[families, "Solving"],
			considerCandidates[afterConstant, synthesisSolvers[First[inputs], values], problem],
			afterConstant
		];
		afterRecurrences = If[consecutive && MemberQ[families, "Recurrence"],
			considerCandidates[afterSolving, synthesisRecurrences[First[inputs], values, Max[maximum - 3, 1], maximumConstant, deadline], problem],
			afterSolving
		];
		afterClosedForms = If[MemberQ[families, "Enumeration"], enumerateClosedForms[afterRecurrences, Min[maximum, 6], problem], afterRecurrences];
		(* an accepted program with evidence enough ends the search; one without may give way to a cheaper composed program *)
		evidence = If[afterClosedForms["Accepted"] === None, -Infinity, problem["Information"] - $bitsPerCost afterClosedForms["Accepted"]["Cost"]];
		afterCompositions = If[
			evidence < problem["RequiredEvidence"] && MemberQ[families, "Composition"] && Length[inputs] > 2 && AbsoluteTime[] < deadline,
			considerCandidates[afterClosedForms, compositionCandidates[inputs, values, maximum, maximumConstant, problem["MaxFoldTerm"], deadline], problem],
			afterClosedForms
		];
		If[MemberQ[families, "Enumeration"] && AbsoluteTime[] < deadline, enumerateClosedForms[afterCompositions, maximum, problem], afterCompositions]
	]

describeCandidate[candidate_Association, matches_Integer, search_Association, problem_Association] :=
	Module[{evidence, heldOutLength},
		evidence = N[Round[problem["Information"] - $bitsPerCost candidate["Cost"], 1 / 10]];
		heldOutLength = Length[problem["HeldOut"]];
		<|
			"Program" -> candidate["Program"],
			"Solved" -> matches === heldOutLength && heldOutLength >= $requiredHeldOut && evidence >= problem["RequiredEvidence"],
			"Cost" -> candidate["Cost"],
			"Nodes" -> RecursorNodeCount[candidate["Program"]],
			"Method" -> candidate["Method"],
			"Candidates" -> search["Candidates"],
			"TrainingExamples" -> Length[problem["Training"]],
			"HeldOutExamples" -> heldOutLength,
			"HeldOutMatches" -> matches,
			"Evidence" -> evidence
		|>
	]

searchResult[search_Association, problem_Association] :=
	Module[{fit},
		Which[
			search["Accepted"] =!= None,
				describeCandidate[search["Accepted"], Length[problem["HeldOut"]], search, problem],
			search["Unconfirmed"] =!= {},
				fit = First[SortBy[search["Unconfirmed"], #["Cost"] &]];
				describeCandidate[fit, fit["HeldOutMatches"], search, problem],
			True,
				<|
					"Program" -> Missing["NotFound"],
					"Solved" -> False,
					"Candidates" -> search["Candidates"],
					"TrainingExamples" -> Length[problem["Training"]],
					"HeldOutExamples" -> Length[problem["HeldOut"]]
				|>
		]
	]

SynthesizeRecursor[terms : {__Integer?NonNegative}, opts : OptionsPattern[]] :=
	SynthesizeRecursor[Transpose[{Range[0, Length[terms] - 1], terms}], opts]

SynthesizeRecursor[examples_?synthesisExamplesQ, opts : OptionsPattern[]] :=
	Enclose @ Module[{method, maximum, maximumConstant, loopBody, foldTerm, holdOut, required, seconds, families, data, training, heldOut, problem},
		method = OptionValue[Method];
		maximum = OptionValue["MaxCost"];
		maximumConstant = OptionValue["MaxConstant"];
		loopBody = OptionValue["MaxLoopBody"];
		foldTerm = OptionValue["MaxFoldTerm"];
		holdOut = OptionValue["HoldOut"];
		required = OptionValue["RequiredEvidence"];
		seconds = OptionValue["TimeLimit"];
		families = Replace[method, {Automatic | All -> $synthesisFamilies, name_String :> {name}}];
		ConfirmAssert[
			ListQ[families] && SubsetQ[$synthesisFamilies, families],
			"Method must be Automatic or a subset of Enumeration, Recurrence, Solving and Composition."
		];
		ConfirmAssert[
			MatchQ[maximum, _Integer?Positive] && AllTrue[{maximumConstant, loopBody, foldTerm}, MatchQ[#, _Integer?NonNegative] &],
			"MaxCost, MaxConstant, MaxLoopBody and MaxFoldTerm must be nonnegative integers, with MaxCost positive."
		];
		ConfirmAssert[MatchQ[holdOut, Automatic | _Integer?NonNegative], "HoldOut must be Automatic or a nonnegative integer."];
		ConfirmAssert[MatchQ[required, _?NumericQ] && Element[required, Reals], "RequiredEvidence must be a real number."];
		ConfirmAssert[MatchQ[seconds, _?Positive | Infinity], "TimeLimit must be positive or Infinity."];
		data = Union[examples];
		{training, heldOut} = TakeDrop[data, Length[data] - heldOutCount[holdOut, Length[data]]];
		problem = <|
			"Training" -> training,
			"HeldOut" -> heldOut,
			"Inputs" -> training[[All, 1]],
			"Values" -> training[[All, 2]],
			"Families" -> families,
			"MaxCost" -> maximum,
			"MaxConstant" -> maximumConstant,
			"MaxLoopBody" -> loopBody,
			"MaxFoldTerm" -> foldTerm,
			"RequiredEvidence" -> required,
			"Deadline" -> AbsoluteTime[] + seconds,
			"Information" -> exampleBits[data[[All, 2]]]
		|>;
		searchResult[If[DuplicateFreeQ[problem["Inputs"]], searchFamilies[problem], $emptySearch], problem]
	]

SynthesizeRecursor[___] := invalidArgumentsFailure[SynthesizeRecursor]
