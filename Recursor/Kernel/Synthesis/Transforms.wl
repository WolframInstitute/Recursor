PackageScoped[{synthesisCompositions, synthesisDirect}]

(* Programs built around a closed program P whose values are known on the
   inputs 0 .. M - 1: the n-th number with a property of P, the number of such
   numbers up to n, partial sums, differences and P applied to a simple inner
   function. Each form is found backwards. The examples fix what P must be on
   some inputs, and every stored class is tested against that in a few array
   operations. A class is rows[[k]], with cost costs[[k]] and program
   build[k]. *)

rowsEqual[matrix_, vector_] := Flatten[Position[matrix, vector, {1}, Heads -> False]]

(* The cheapest few of the matching classes, with the program each one gives. *)
cheapest[indices_List, totals_List, make_, method_String, limit_ : 2] := Map[
	<|"Program" -> make[indices[[#]]], "Cost" -> totals[[#]], "Method" -> method|> &,
	Take[Ordering[totals], UpTo[limit]]
]

(* Classes equal to the values, or equal after scaling and shifting. *)
synthesisDirect[rows_, costs_, build_, columns_List, values_List, method_String] := Module[{
	part, exact, found = {}, differences = Differences[values], pivot, step, valid, scale, shift, good
},
	If[rows === {}, Return[{}]];
	part = rows[[All, columns]];
	exact = rowsEqual[part, values];
	If[exact =!= {}, found = cheapest[exact, costs[[exact]], build, method]];
	pivot = First[FirstPosition[differences, _?(# =!= 0 &), {0}, {1}, Heads -> False]];
	If[pivot > 0,
		step = part[[All, pivot + 1]] - part[[All, pivot]];
		valid = Pick[Range[Length[part]], Unitize[step] (1 - Unitize[Mod[differences[[pivot]], step + (1 - Unitize[step])]]), 1];
		If[valid =!= {},
			scale = Quotient[differences[[pivot]], step[[valid]]];
			shift = First[values] - scale part[[valid, 1]];
			good = Pick[Range[Length[valid]],
				MapThread[
					Function[{row, c1, c0}, c1 row + c0 === values && ! (c1 === 1 && c0 === 0) && (c1 > 0 || c0 > 0)],
					{part[[valid]], scale, shift}
				]
			];
			If[good =!= {},
				found = Join[found, cheapest[good,
					costs[[valid[[good]]]] + MapThread[synthesisAffineCost, {scale[[good]], shift[[good]]}],
					Function[at, synthesisAffineProgram[build[valid[[at]]], scale[[at]], shift[[at]]]], method]]
			]
		]
	];
	found
]

(* A test that is zero exactly when the value of a program has the property. *)
distance[c_] := Add[Monus[Var, Const[c]], Monus[Const[c], Var]]
propertyTest["Equal", 0, program_] := program
propertyTest["Equal", c_, program_] := Let[program, distance[c]]
propertyTest["AtMost", 0, program_] := program
propertyTest["AtMost", c_, program_] := Monus[program, Const[c]]
propertyTest["AtLeast", c_, program_] := Monus[Const[c], program]
propertyTest["Unequal", 0, program_] := Ifz[program, Const[1], Const[0]]
propertyTest["Unequal", c_, program_] := Let[program, Ifz[distance[c], Const[1], Const[0]]]

(* Costs count what the search chose: one for the kind of property, with a
   constant up to three, and one for the form built around the program. *)
propertyCost[_, c_] := synthesisConstantCost[c]

(* Classes that separate two sets of inputs by a property of their value:
   {index, kind, constant} for every class and kind that does. inside and
   outside are the values of each class on the two sets. *)
separations[inside_, outside_] := Module[{count = Length[inside], low, high, least, most, pick},
	low = Min /@ inside; high = Max /@ inside; least = Min /@ outside; most = Max /@ outside;
	pick[flags_, kind_, constants_] := With[{at = Pick[Range[count], flags, 1]}, Transpose[{at, ConstantArray[kind, Length[at]], constants[[at]]}]];
	Join[
		pick[(1 - Unitize[high - low]) (1 - Unitize[Total /@ (1 - Unitize[outside - low])]), "Equal", low],
		pick[UnitStep[least - high - 1], "AtMost", high],
		pick[UnitStep[low - most - 1], "AtLeast", low],
		pick[(1 - Unitize[most - least]) (1 - Unitize[Total /@ (1 - Unitize[inside - least])]), "Unequal", least]
	]
]

(* The j-th number, from the start, whose value under the test is zero. *)
searchProgram[test_, start_, offset_] := synthesisShiftInput[
	Pred[Iter[Succ[Var], Const[start], Succ[WhileLoop[Acc, Let[Acc, test], Succ[Acc]]]]],
	offset
]

shiftCost[0 | 1] := 0
shiftCost[offset_] := synthesisConstantCost[offset]

searches[rows_, costs_, build_, offset_, values_] := Module[{top = Max[values], found = {}},
	Do[
		With[{rest = Complement[Range[start, top], values]},
			If[rest =!= {},
				With[{hits = separations[rows[[All, values + 1]], rows[[All, rest + 1]]]},
					If[hits =!= {},
						found = Join[found, cheapest[hits,
							(costs[[#[[1]]]] + propertyCost[#[[2]], #[[3]]] & /@ hits) + 1 + shiftCost[start] + shiftCost[offset],
							Function[hit, searchProgram[propertyTest[hit[[2]], hit[[3]], build[hit[[1]]]], start, offset]], "Search"]]
					]
				]
			]
		],
		{start, DeleteDuplicates[{0, 1, First[values]}]}
	];
	found
]

(* The number of k <= n whose value under the test is zero. *)
countingProgram[test_] := Rec[Succ[Var], Const[0], Ifz[Let[Idx, test], Succ[Acc], Acc]]

holds["Equal", values_, c_] := 1 - Unitize[values - c]
holds["AtMost", values_, c_] := UnitStep[c - values]
holds["AtLeast", values_, c_] := UnitStep[values - c]
holds["Unequal", values_, c_] := Unitize[values - c]

countings[rows_, costs_, build_, inputs_, values_] := Module[{steps = Differences[values], rising, level, hits},
	rising = Pick[Rest[inputs], steps, 1];
	level = Pick[Rest[inputs], steps, 0];
	If[rising === {} || level === {}, Return[{}]];
	hits = separations[rows[[All, rising + 1]], rows[[All, level + 1]]];
	hits = Select[hits, Total[holds[#[[2]], rows[[#[[1]], ;; First[inputs] + 1]], #[[3]]]] === First[values] &];
	If[hits === {}, {},
		cheapest[hits, (costs[[#[[1]]]] + propertyCost[#[[2]], #[[3]]] & /@ hits) + 1,
			Function[hit, countingProgram[propertyTest[hit[[2]], hit[[3]], build[hit[[1]]]]]], "Counting"]
	]
]

(* Inner functions of the input worth composing with: loop-free, not the
   input itself, with values inside the stored range. *)
innerFunctions[inputs_, limit_, maximumConstant_, deadline_] := Module[{classes},
	classes = synthesisClasses[
		Join[{{Var, inputs}}, Table[{Const[c], ConstantArray[c, Length[inputs]]}, {c, 0, maximumConstant}]],
		None, 4, deadline, None, False, None &
	];
	Catenate[KeyValueMap[
		Function[{cost, expressions},
			MapThread[
				If[! FreeQ[#1, Var] && #2 =!= inputs && ! SameQ @@ #2 && Max[#2] < limit, {cost, #1, #2}, Nothing] &,
				{expressions, classes["Vectors"][cost]}
			]
		],
		classes["Expressions"]
	]]
]

synthesisCompositions[rows_, costs_, build_, inputs_List, values_List, maximumConstant_Integer, deadline_] := Module[{
	limit, columns = inputs + 1, consecutive, found = {}, sums, steps = Differences[values]
},
	If[rows === {}, Return[{}]];
	limit = Length[First[rows]];
	If[Max[inputs] >= limit, Return[{}]];
	consecutive = inputs === Range[First[inputs], Last[inputs]];
	If[consecutive && Length[values] >= 4 && Min[steps] > 0 && Max[values] < limit,
		found = Join[found, searches[rows, costs, build, First[inputs], values]]
	];
	If[consecutive && Length[values] >= 4 && Min[steps] >= 0 && Max[steps] === 1,
		found = Join[found, countings[rows, costs, build, inputs, values]]
	];
	If[AbsoluteTime[] > deadline, Return[found]];
	sums = Transpose[Accumulate[Transpose[rows]]];
	found = Join[found,
		synthesisDirect[sums, costs + 1, Function[k, Rec[Succ[Var], Const[0], Add[Acc, Let[Idx, build[k]]]]], columns, values, "PartialSum"],
		synthesisDirect[Join[ConstantArray[0, {Length[rows], 1}], sums, 2], costs + 1,
			Function[k, Rec[Var, Const[0], Add[Acc, Let[Idx, build[k]]]]], columns, values, "PartialSum"]
	];
	If[Max[inputs] + 1 < limit,
		With[{hits = rowsEqual[Ramp[rows[[All, columns + 1]] - rows[[All, columns]]], values]},
			If[hits =!= {},
				found = Join[found, cheapest[hits, costs[[hits]] + 1, Function[k, With[{p = build[k]}, Monus[Let[Succ[Var], p], p]]], "Difference"]]
			]
		]
	];
	Do[
		If[AbsoluteTime[] > deadline, Break[]];
		With[{hits = rowsEqual[rows[[All, inner[[3]] + 1]], values]},
			If[hits =!= {},
				found = Join[found, cheapest[hits, costs[[hits]] + inner[[1]] + 1, Function[k, Let[inner[[2]], build[k]]], "Composition", 1]]
			]
		],
		{inner, innerFunctions[inputs, limit, maximumConstant, deadline]}
	];
	found
]
