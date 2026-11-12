PackageScoped[{synthesisRecurrences, synthesisSolvers, synthesisShiftInput, synthesisStepSeeds, synthesisRecurrenceProgram}]

(* Recurrences are checked against the data itself: a step is evaluated on
   the recorded earlier terms at every position, so no candidate program has
   to be run from its start. Seeds are read from the data. *)

previousTerm[k_] := CGet[Switch[k, 1, Pred[Idx], 2, Pred[Pred[Idx]], _, Monus[Idx, Const[k]]]]

(* Zero exactly when x is at most m. *)
atMost[x_, m_] := Switch[m, 0, x, 1, Pred[x], _, Monus[x, Const[m]]]

shiftInput[program_, 0] := program
shiftInput[program_, shift_] := Let[Monus[Var, Const[shift]], program]
synthesisShiftInput[program_, shift_] := shiftInput[program, shift]

(* CoRec[Var, seeds..., step]. A large offset is subtracted from the input
   first, so the history never runs from zero up to the offset. *)
seededProgram[step_, seeds_, offset_, terms_] := With[{base = If[offset > 4, 0, offset]},
	shiftInput[
		CoRec[Var, Fold[Function[{rest, j}, Ifz[atMost[Idx, base + j], Const[terms[[j + 1]]], rest]], step, Reverse[Range[0, seeds - 1]]]],
		If[offset > 4, offset, 0]
	]
]

stepLag[body_] := Max[Cases[body, synthesisEarlier[k_] :> k, {0, Infinity}], 0]

recurrenceProgram[body_, seeds_, offset_, terms_] := If[stepLag[body] <= 1 && FreeQ[body, synthesisHalved] && seeds === 1,
	Rec[If[offset === 0, Var, Monus[Var, Const[offset]]], Const[First[terms]],
		body /. {Idx -> If[offset === 0, Succ[Idx], Add[Idx, Const[offset + 1]]], synthesisEarlier[1] -> Acc}
	],
	seededProgram[
		body /. {Idx -> If[offset > 4, Add[Idx, Const[offset]], Idx], synthesisEarlier[k_] :> previousTerm[k], synthesisHalved -> CGet[Half[Idx]]},
		seeds, offset, terms
	]
]

synthesisRecurrenceProgram[arguments___] := recurrenceProgram[arguments]

seedCost[terms_, seeds_] := Total[synthesisConstantCost /@ Take[terms, seeds]]

(* Value of a step at zero-based position j, or Missing when it reads a term
   that is not recorded before that position. *)
stepValue[body_, offset_, terms_, j_] := With[{half = Quotient[offset + j, 2] - offset + 1},
	If[stepLag[body] > j || (! FreeQ[body, synthesisHalved] && ! (1 <= half <= j)),
		Missing["Unavailable"],
		synthesisVectorValue[body, <|"Index" -> offset + j, "Earlier" -> Table[terms[[Max[j + 1 - k, 1]]], {k, 3}], "Halved" -> terms[[Clip[half, {1, Length[terms]}]]]|>]
	]
]

(* Seeds a step needs: its lags, and further initial terms it fails to
   reproduce. Exceptional initial terms become extra seeds. *)
stepSeeds[body_, offset_, terms_] := Module[{least, seeds},
	least = Max[stepLag[body], If[FreeQ[body, synthesisHalved], 0, Max[1, offset]], 1];
	seeds = least;
	Do[If[stepValue[body, offset, terms, j] =!= terms[[j + 1]], seeds = j + 1; Break[]], {j, 2, least, -1}];
	seeds
]

synthesisStepSeeds[arguments___] := stepSeeds[arguments]

(* Generic environments appended to every step vector. Without them two
   steps that agree on this sequence alone would be merged, and the one
   needing fewer seeds could be lost. *)
$stepIndex = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 3, 5, 7, 9}
$stepEarlier = {
	{1, 0, 2, 5, 13, 8, 34, 3, 100, 21, 7, 233, 1, 55, 610, 12},
	{0, 1, 1, 3, 8, 5, 21, 2, 60, 13, 4, 144, 4, 34, 377, 9},
	{2, 0, 1, 2, 5, 3, 13, 7, 30, 8, 6, 89, 0, 21, 233, 5}
}
$stepHalved = {3, 1, 0, 4, 2, 9, 1, 6, 17, 2, 11, 40, 7, 0, 5, 28}

synthesisRecurrences[offset_Integer, terms_List, maximum_Integer, maximumConstant_Integer, deadline_] := Module[{
	length = Length[terms], positions, leaves, found
},
	If[length < 6, Return[{}]];
	positions = Range[3, length - 1];
	leaves = Join[
		{{Idx, Join[offset + positions, $stepIndex]}},
		Table[{synthesisEarlier[k], Join[terms[[positions + 1 - k]], $stepEarlier[[k]]]}, {k, 3}],
		If[offset <= 1, {{synthesisHalved, Join[terms[[Quotient[offset + positions, 2] - offset + 1]], $stepHalved]}}, {}],
		Table[{Const[c], ConstantArray[c, Length[positions] + 16]}, {c, 0, maximumConstant}]
	];
	(* A step must reproduce more terms than it takes as seeds, by two at least:
	   otherwise the seeds explain the data and the step explains little. *)
	found = synthesisClasses[leaves, terms[[positions + 1]], maximum, deadline, None, False,
		Function[{body, cost},
			If[FreeQ[body, synthesisEarlier | synthesisHalved], None,
				With[{seeds = stepSeeds[body, offset, terms]},
					If[length - seeds < seeds + 2, None,
						<|"Cost" -> cost + seedCost[terms, seeds] + 1, "Expression" -> body, "Seeds" -> seeds|>
					]
				]
			]
		]
	]["Matches"];
	Map[<|"Program" -> recurrenceProgram[#["Expression"], #["Seeds"], offset, terms], "Cost" -> #["Cost"], "Method" -> "Recurrence"|> &, found]
]

signedSum[{}, _] := $Failed
signedSum[positive_List, {}] := Fold[Add, positive]
signedSum[positive_List, negative_List] := Monus[Fold[Add, positive], Fold[Add, negative]]

scaledTerm[c_, x_] := If[Abs[c] === 1, x, Mul[Const[Abs[c]], x]]

indexPower[e_] := Fold[Mul, ConstantArray[Idx, e]]

constantTail[offset_, terms_] := With[{last = Last[terms], prefix = Length[terms] - LengthWhile[Reverse[terms], # === Last[terms] &]},
	If[0 < prefix <= Length[terms] - 3,
		{<|"Program" -> Fold[Function[{rest, j}, Ifz[atMost[Var, offset + j], Const[terms[[j + 1]]], rest]], Const[last], Reverse[Range[0, prefix - 1]]],
			"Cost" -> synthesisConstantCost[last] + seedCost[terms, prefix] + 1, "Method" -> "ConstantTail"|>},
		{}
	]
]

(* a(i) = a(i-k) + m: periodic sequences and residue-class lists. *)
periodicIncrement[offset_, terms_] := With[{k = SelectFirst[Range[2, Length[terms] - 3],
	With[{steps = Drop[terms, #] - Drop[terms, -#]}, SameQ @@ steps && First[steps] >= 0] &, None]},
	If[k === None, {},
		With[{m = terms[[k + 1]] - terms[[1]]},
			{<|"Program" -> seededProgram[If[m === 0, previousTerm[k], Add[previousTerm[k], Const[m]]], k, offset, terms],
				"Cost" -> If[m === 0, 1, 2 + synthesisConstantCost[m]] + seedCost[terms, k] + 1, "Method" -> "Periodic"|>}
		]
	]
]

binomialTerm[1] := Var
binomialTerm[j_] := Quot[Fold[Mul, Table[Nest[Pred, Var, back], {back, 0, j - 1}]], Const[j!]]

(* Newton form sum_j c_j Binomial[n - offset, j], confirmed by at least two
   vanishing higher differences. *)
newtonPolynomial[offset_, terms_] := With[{degree = SelectFirst[Range[2, Min[7, Length[terms] - 3]],
	AllTrue[Differences[terms, # + 1], # === 0 &] && First[Differences[terms, #]] =!= 0 &, None]},
	If[degree === None, {},
		Module[{coefficients = Table[First[Differences[terms, j]], {j, 0, degree}], parts, body},
			parts = Table[If[coefficients[[j + 1]] === 0, Nothing,
				{coefficients[[j + 1]], If[j === 0, Const[Abs[coefficients[[1]]]], scaledTerm[coefficients[[j + 1]], binomialTerm[j]]]}], {j, 0, degree}];
			body = signedSum[Cases[parts, {c_ /; c > 0, x_} :> x], Cases[parts, {c_ /; c < 0, x_} :> x]];
			If[body === $Failed, {},
				{<|"Program" -> shiftInput[body, offset],
					"Cost" -> 1 + Sum[If[coefficients[[j + 1]] === 0, 0, synthesisConstantCost[coefficients[[j + 1]]] + j], {j, 0, degree}] +
						If[offset === 0, 0, 2 + synthesisConstantCost[offset]],
					"Method" -> "Polynomial"|>}
			]
		]
	]
]

recurrenceShapes[length_] := SortBy[
	Select[
		Flatten[Table[<|"Order" -> r, "Degree" -> d, "Constant" -> c, "Skip" -> s|>, {r, 1, 9}, {d, 0, 5}, {c, {False, True}}, {s, 0, 2}]],
		(! #Constant || #Degree === 0) && #Order + #Skip <= length - 3 &&
			length - #Order - #Skip >= (#Order + 1) (#Degree + 1) + Boole[#Constant] + 1 &
	],
	{(#Order + 1) (#Degree + 1) + Boole[#Constant] + #Skip &, #Order &, #Degree &, #Skip &}
]

(* sum_k p_k(i) a(i-k) + c = 0 with polynomial coefficients. Degree zero is a
   linear recurrence with constant coefficients; order one is hypergeometric.
   The null space is exact, and at least two spare equations confirm it. *)
polynomialRecurrence[offset_, terms_, shape_] := Module[{
	r = shape["Order"], d = shape["Degree"], seeds, rows, null, vector, parts, coefficient, constant = 0, leading, positive = {}, negative = {},
	cost, numerator, denominator, body
},
	seeds = r + shape["Skip"];
	rows = Table[
		With[{i = offset + j},
			Join[
				Flatten[Table[i^e terms[[j + 1 - k]], {k, r, 1, -1}, {e, d, 0, -1}]],
				If[shape["Constant"], {1}, {}],
				Table[i^e terms[[j + 1]], {e, d, 0, -1}]
			]
		],
		{j, seeds, Length[terms] - 1}
	];
	null = NullSpace[rows];
	If[Length[null] =!= 1, Return[{}]];
	vector = First[null] (LCM @@ Denominator[First[null]]);
	vector = vector / (GCD @@ vector);
	(* the vector holds the coefficients of a(i-r) .. a(i-1) by falling degree, the constant, then those of a(i) *)
	parts = TakeList[vector, {r (d + 1), Boole[shape["Constant"]], d + 1}];
	coefficient = Association[MapThread[#1 -> AssociationThread[Range[d, 0, -1], #2] &, {Range[r, 1, -1], Partition[parts[[1]], d + 1]}]];
	If[shape["Constant"], constant = First[parts[[2]]]];
	coefficient[0] = AssociationThread[Range[d, 0, -1], parts[[3]]];
	leading = Function[i, Sum[coefficient[0][e] i^e, {e, 0, d}]];
	If[leading[offset + seeds] < 0, coefficient = Map[-# &, coefficient, {2}]; constant = -constant];
	If[! AllTrue[Range[offset + seeds, offset + Length[terms] - 1], leading[#] > 0 &], Return[{}]];
	cost = 1 + seedCost[terms, seeds];
	Do[
		With[{c = -coefficient[k][e]},
			If[c =!= 0,
				cost += synthesisConstantCost[c] + e + 1;
				With[{term = scaledTerm[c, If[e === 0, synthesisEarlier[k], Mul[indexPower[e], synthesisEarlier[k]]]]},
					If[c > 0, AppendTo[positive, term], AppendTo[negative, term]]
				]
			]
		],
		{k, 1, r}, {e, 0, d}
	];
	If[positive === {} && negative === {}, Return[{}]];
	If[constant =!= 0,
		cost += synthesisConstantCost[constant] + 1;
		If[constant < 0, AppendTo[positive, Const[-constant]], AppendTo[negative, Const[constant]]]
	];
	numerator = signedSum[positive, negative];
	If[numerator === $Failed, Return[{}]];
	body = If[coefficient[0][0] === 1 && AllTrue[Range[1, d], coefficient[0][#] === 0 &],
		numerator,
		denominator = signedSum[
			Table[With[{c = coefficient[0][e]}, If[c > 0, If[e === 0, Const[c], scaledTerm[c, indexPower[e]]], Nothing]], {e, 0, d}],
			Table[With[{c = coefficient[0][e]}, If[c < 0, If[e === 0, Const[-c], scaledTerm[c, indexPower[e]]], Nothing]], {e, 0, d}]
		];
		cost += Sum[If[coefficient[0][e] === 0, 0, synthesisConstantCost[coefficient[0][e]] + e + 1], {e, 0, d}];
		Quot[numerator, denominator]
	];
	{<|"Program" -> recurrenceProgram[body, seeds, offset, terms], "Cost" -> cost,
		"Method" -> Which[d === 0, "LinearRecurrence", r === 1, "Hypergeometric", True, "Holonomic"]|>}
]

synthesisSolvers[offset_Integer, terms_List] := If[Length[terms] < 5, {},
	Join[
		constantTail[offset, terms],
		periodicIncrement[offset, terms],
		newtonPolynomial[offset, terms],
		Catenate[polynomialRecurrence[offset, terms, #] & /@ recurrenceShapes[Length[terms]]]
	]
]
