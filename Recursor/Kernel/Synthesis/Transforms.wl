(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{synthesisCompositions, synthesisDirect}]

(* ::Section:: *)
(*Usage Messages*)

rowsEqual::usage = "rowsEqual[matrix, vector] gives the positions of the rows of matrix that are equal to vector."

cheapest::usage = "cheapest[indices, totals, make, method] gives the two cheapest of the matching classes as candidates. totals gives the cost of each \
class in indices, and make the program of a class.\n\
cheapest[indices, totals, make, method, limit] gives the limit cheapest."

affineMatches::usage = "affineMatches[part, costs, build, values, method, pivot] gives candidates for the classes whose rows in part become the values after a \
scale and a shift. pivot is the first position at which the values change."

synthesisDirect::usage = "synthesisDirect[rows, costs, build, columns, values, method] gives candidates for the classes whose rows are equal to the values at \
the given columns, or equal after scaling and shifting. A class is a row with its cost in costs and the program build gives for its position."

distance::usage = "distance[constant] gives an expression in Var that is zero exactly when Var equals constant."

propertyTest::usage = "propertyTest[kind, constant, program] gives an expression that is zero exactly when the value of program has a property. kind is \
\"Equal\", \"AtMost\", \"AtLeast\" or \"Unequal\", each with respect to constant."

propertyCost::usage = "propertyCost[kind, constant] gives the cost of a property of the given kind with the given constant."

separationHits::usage = "separationHits[flags, kind, constants] gives {index, kind, constant} for every class that flags marks with one."

separations::usage = "separations[inside, outside] gives the classes that separate two sets of inputs by a property of their value, as triples {index, kind, \
constant}. inside and outside are the values of each class on the two sets."

searchProgram::usage = "searchProgram[test, start, offset] gives a program for the n-th number, from start, at which test is zero. offset is the input of \
the first example."

shiftCost::usage = "shiftCost[offset] gives the cost of a start or an offset: nothing for zero and one, and the cost of the constant otherwise."

hitCost::usage = "hitCost[costs, {index, kind, constant}] gives the cost of a class together with a property of its value."

hitTest::usage = "hitTest[build, {index, kind, constant}] gives the expression that is zero exactly when the value of a class has a property."

searchesFrom::usage = "searchesFrom[rows, costs, build, offset, values, start] gives candidates for the values as the numbers, from start, at which a class \
has a property."

searches::usage = "searches[rows, costs, build, offset, values] gives candidates for increasing values as the numbers at which a class has a property."

countingProgram::usage = "countingProgram[test] gives a program for the number of k <= n at which test is zero."

holds::usage = "holds[kind, values, constant] gives one where a value has the property of the given kind with respect to constant, and zero elsewhere."

countedFromStartQ::usage = "countedFromStartQ[rows, {index, kind, constant}, firstInput, firstValue] gives True when the class has the property at exactly \
firstValue of the inputs up to firstInput."

countings::usage = "countings[rows, costs, build, inputs, values] gives candidates for the values as the number of inputs up to n at which a class has a property."

innerFunctions::usage = "innerFunctions[inputs, limit, maximumConstant, deadline] gives the inner functions of the input worth composing with, as triples \
{cost, expression, values}: loop-free, not the input itself, with values below limit."

compositionForms::usage = "compositionForms[rows, costs, build, inputs, values, maximumConstant, deadline] gives the candidates of synthesisCompositions for \
classes whose rows cover the inputs."

partialSumCandidates::usage = "partialSumCandidates[rows, costs, build, columns, values] gives candidates for the values as sums of a class over the inputs up to n, with or \
without n itself."

differenceCandidates::usage = "differenceCandidates[rows, costs, build, columns, values] gives candidates for the values as the truncated differences of a class at consecutive inputs."

innerCompositions::usage = "innerCompositions[rows, costs, build, values, {cost, expression, inputs}] gives candidates for the values as a class applied to an \
inner function with the given cost and values."

synthesisCompositions::usage = "synthesisCompositions[rows, costs, build, inputs, values, maximumConstant, deadline] gives candidates built around a class: \
searches, counting functions, partial sums, differences and compositions. rows holds the values of each class on the inputs 0, 1, 2 and so on."

(* ::Section:: *)
(*Function Definitions*)

(* Programs built around a closed program P whose values are known on the
   inputs 0 .. M - 1: the n-th number with a property of P, the number of such
   numbers up to n, partial sums, differences and P applied to a simple inner
   function. Each form is found backwards. The examples fix what P must be on
   some inputs, and every stored class is tested against that in a few array
   operations. A class is rows[[k]], with cost costs[[k]] and program
   build[k]. *)

rowsEqual[matrix_List, vector_List] := Flatten[Position[matrix, vector, {1}, Heads -> False]]

(* The cheapest few of the matching classes, with the program each one gives. *)
cheapest[indices_List, totals_List, make_Function, method_String, limit_Integer] :=
	Map[
		<|"Program" -> make[indices[[#]]], "Cost" -> totals[[#]], "Method" -> method|> &,
		Take[Ordering[totals], UpTo[limit]]
	]
cheapest[indices_List, totals_List, make_Function, method_String] := cheapest[indices, totals, make, method, 2]

affineMatches[part_List, costs_List, build_Function, values_List, method_String, pivot_Integer] :=
	Module[{change, step, valid, scale, shift, good},
		change = Differences[values][[pivot]];
		step = part[[All, pivot + 1]] - part[[All, pivot]];
		valid = Pick[Range[Length[part]], Unitize[step] (1 - Unitize[Mod[change, step + (1 - Unitize[step])]]), 1];
		If[valid === {},
			{},
			scale = Quotient[change, step[[valid]]];
			shift = First[values] - scale part[[valid, 1]];
			good = Pick[
				Range[Length[valid]],
				MapThread[
					Function[{row, rowScale, rowShift}, rowScale row + rowShift === values && ! (rowScale === 1 && rowShift === 0) && (rowScale > 0 || rowShift > 0)],
					{part[[valid]], scale, shift}
				]
			];
			If[good === {},
				{},
				cheapest[
					good,
					costs[[valid[[good]]]] + MapThread[synthesisAffineCost, {scale[[good]], shift[[good]]}],
					Function[position, synthesisAffineProgram[build[valid[[position]]], scale[[position]], shift[[position]]]],
					method
				]
			]
		]
	]

(* Classes equal to the values, or equal after scaling and shifting. *)
synthesisDirect[{}, _List, _Function, _List, _List, _String] := {}
synthesisDirect[rows_List, costs_List, build_Function, columns_List, values_List, method_String] :=
	Module[{part, exact, pivot},
		part = rows[[All, columns]];
		exact = rowsEqual[part, values];
		pivot = First[FirstPosition[Differences[values], _?(# =!= 0 &), {0}, {1}, Heads -> False]];
		Join[
			If[exact =!= {}, cheapest[exact, costs[[exact]], build, method], {}],
			If[pivot > 0, affineMatches[part, costs, build, values, method, pivot], {}]
		]
	]

(* A test that is zero exactly when the value of a program has the property. *)
distance[constant_Integer] := Add[Monus[Var, Const[constant]], Monus[Const[constant], Var]]

propertyTest["Equal", 0, program_?synthesisExpressionQ] := program
propertyTest["Equal", constant_Integer, program_?synthesisExpressionQ] := Let[program, distance[constant]]
propertyTest["AtMost", 0, program_?synthesisExpressionQ] := program
propertyTest["AtMost", constant_Integer, program_?synthesisExpressionQ] := Monus[program, Const[constant]]
propertyTest["AtLeast", constant_Integer, program_?synthesisExpressionQ] := Monus[Const[constant], program]
propertyTest["Unequal", 0, program_?synthesisExpressionQ] := Ifz[program, Const[1], Const[0]]
propertyTest["Unequal", constant_Integer, program_?synthesisExpressionQ] := Let[program, Ifz[distance[constant], Const[1], Const[0]]]

(* Costs count what the search chose: one for the kind of property, with a
   constant up to three, and one for the form built around the program. *)
propertyCost[_String, constant_Integer] := synthesisConstantCost[constant]

separationHits[flags_List, kind_String, constants_List] :=
	Module[{marked},
		marked = Pick[Range[Length[flags]], flags, 1];
		Transpose[{marked, ConstantArray[kind, Length[marked]], constants[[marked]]}]
	]

(* Classes that separate two sets of inputs by a property of their value:
   {index, kind, constant} for every class and kind that does. inside and
   outside are the values of each class on the two sets. *)
separations[inside_List, outside_List] :=
	Module[{low, high, least, most},
		low = Min /@ inside;
		high = Max /@ inside;
		least = Min /@ outside;
		most = Max /@ outside;
		Join[
			separationHits[(1 - Unitize[high - low]) (1 - Unitize[Total /@ (1 - Unitize[outside - low])]), "Equal", low],
			separationHits[UnitStep[least - high - 1], "AtMost", high],
			separationHits[UnitStep[low - most - 1], "AtLeast", low],
			separationHits[(1 - Unitize[most - least]) (1 - Unitize[Total /@ (1 - Unitize[inside - least])]), "Unequal", least]
		]
	]

(* The j-th number, from the start, whose value under the test is zero. *)
searchProgram[test_?synthesisExpressionQ, start_Integer, offset_Integer] :=
	synthesisShiftInput[
		Pred[Iter[Succ[Var], Const[start], Succ[WhileLoop[Acc, Let[Acc, test], Succ[Acc]]]]],
		offset
	]

shiftCost[0 | 1] := 0
shiftCost[offset_Integer] := synthesisConstantCost[offset]

hitCost[costs_List, {index_Integer, kind_String, constant_Integer}] := costs[[index]] + propertyCost[kind, constant]

hitTest[build_Function, {index_Integer, kind_String, constant_Integer}] := propertyTest[kind, constant, build[index]]

searchesFrom[rows_List, costs_List, build_Function, offset_Integer, values_List, start_Integer] :=
	Module[{others, hits},
		others = Complement[Range[start, Max[values]], values];
		hits = If[others === {}, {}, separations[rows[[All, values + 1]], rows[[All, others + 1]]]];
		If[hits === {},
			{},
			cheapest[
				hits,
				Map[Function[hit, hitCost[costs, hit]], hits] + 1 + shiftCost[start] + shiftCost[offset],
				Function[hit, searchProgram[hitTest[build, hit], start, offset]],
				"Search"
			]
		]
	]

searches[rows_List, costs_List, build_Function, offset_Integer, values_List] :=
	Catenate[Map[Function[start, searchesFrom[rows, costs, build, offset, values, start]], DeleteDuplicates[{0, 1, First[values]}]]]

(* The number of k <= n whose value under the test is zero. *)
countingProgram[test_?synthesisExpressionQ] := Rec[Succ[Var], Const[0], Ifz[Let[Idx, test], Succ[Acc], Acc]]

holds["Equal", values_List, constant_Integer] := 1 - Unitize[values - constant]
holds["AtMost", values_List, constant_Integer] := UnitStep[constant - values]
holds["AtLeast", values_List, constant_Integer] := UnitStep[values - constant]
holds["Unequal", values_List, constant_Integer] := Unitize[values - constant]

countedFromStartQ[rows_List, {index_Integer, kind_String, constant_Integer}, firstInput_Integer, firstValue_Integer] :=
	Total[holds[kind, rows[[index, ;; firstInput + 1]], constant]] === firstValue
countedFromStartQ[___] := False

countings[rows_List, costs_List, build_Function, inputs_List, values_List] :=
	Module[{steps, rising, level, hits},
		steps = Differences[values];
		rising = Pick[Rest[inputs], steps, 1];
		level = Pick[Rest[inputs], steps, 0];
		hits = If[rising === {} || level === {}, {}, separations[rows[[All, rising + 1]], rows[[All, level + 1]]]];
		hits = Select[hits, countedFromStartQ[rows, #, First[inputs], First[values]] &];
		If[hits === {},
			{},
			cheapest[hits, Map[Function[hit, hitCost[costs, hit]], hits] + 1, Function[hit, countingProgram[hitTest[build, hit]]], "Counting"]
		]
	]

(* Inner functions of the input worth composing with: loop-free, not the
   input itself, with values inside the stored range. *)
innerFunctions[inputs_List, limit_Integer, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)] :=
	Module[{classes},
		classes = synthesisClasses[
			Join[{{Var, inputs}}, Table[{Const[constant], ConstantArray[constant, Length[inputs]]}, {constant, 0, maximumConstant}]],
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

partialSumCandidates[rows_List, costs_List, build_Function, columns_List, values_List] :=
	Module[{sums},
		sums = Transpose[Accumulate[Transpose[rows]]];
		Join[
			synthesisDirect[sums, costs + 1, Function[position, Rec[Succ[Var], Const[0], Add[Acc, Let[Idx, build[position]]]]], columns, values, "PartialSum"],
			synthesisDirect[
				Join[ConstantArray[0, {Length[rows], 1}], sums, 2], costs + 1,
				Function[position, Rec[Var, Const[0], Add[Acc, Let[Idx, build[position]]]]], columns, values, "PartialSum"
			]
		]
	]

differenceCandidates[rows_List, costs_List, build_Function, columns_List, values_List] :=
	Module[{hits},
		hits = rowsEqual[Ramp[rows[[All, columns + 1]] - rows[[All, columns]]], values];
		If[hits === {},
			{},
			cheapest[hits, costs[[hits]] + 1, Function[position, With[{program = build[position]}, Monus[Let[Succ[Var], program], program]]], "Difference"]
		]
	]

innerCompositions[rows_List, costs_List, build_Function, values_List, {cost_Integer, expression_?synthesisExpressionQ, inputs_List}] :=
	Module[{hits},
		hits = rowsEqual[rows[[All, inputs + 1]], values];
		If[hits === {}, {}, cheapest[hits, costs[[hits]] + cost + 1, Function[position, Let[expression, build[position]]], "Composition", 1]]
	]

compositionForms[
	rows_List, costs_List, build_Function, inputs_List, values_List, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)
] :=
	Module[{limit, columns, consecutive, steps, found},
		limit = Length[First[rows]];
		columns = inputs + 1;
		steps = Differences[values];
		consecutive = inputs === Range[First[inputs], Last[inputs]];
		found = Join[
			If[consecutive && Length[values] >= 4 && Min[steps] > 0 && Max[values] < limit, searches[rows, costs, build, First[inputs], values], {}],
			If[consecutive && Length[values] >= 4 && Min[steps] >= 0 && Max[steps] === 1, countings[rows, costs, build, inputs, values], {}]
		];
		If[AbsoluteTime[] > deadline,
			found,
			Join[
				found,
				partialSumCandidates[rows, costs, build, columns, values],
				If[Max[inputs] + 1 < limit, differenceCandidates[rows, costs, build, columns, values], {}],
				Catenate[
					Map[
						Function[inner, If[AbsoluteTime[] > deadline, {}, innerCompositions[rows, costs, build, values, inner]]],
						innerFunctions[inputs, limit, maximumConstant, deadline]
					]
				]
			]
		]
	]

synthesisCompositions[
	rows_List, costs_List, build_Function, inputs_List, values_List, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)
] :=
	If[rows === {} || Max[inputs] >= Length[First[rows]],
		{},
		compositionForms[rows, costs, build, inputs, values, maximumConstant, deadline]
	]
