(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{synthesisRecurrences, synthesisSolvers, synthesisShiftInput, synthesisStepSeeds, synthesisRecurrenceProgram}]

(* ::Section:: *)
(*Usage Messages*)

previousTerm::usage = "previousTerm[lag] gives the expression that reads, in the step of CoRec, the term lag positions before the current one."

atMost::usage = "atMost[value, bound] gives an expression that is zero exactly when value is at most bound."

shiftInput::usage = "shiftInput[program, shift] gives program with shift subtracted from its input first, and program itself for a shift of zero."

synthesisShiftInput::usage = "synthesisShiftInput[program, shift] gives program with shift subtracted from its input first, and program itself for a shift of zero."

seededProgram::usage = "seededProgram[step, seeds, offset, terms] gives CoRec with the first seeds terms as constants and step for every later term. offset is \
the input of the first term."

stepLag::usage = "stepLag[body] gives the largest lag of an earlier term that the recurrence step body reads, or zero."

recurrenceProgram::usage = "recurrenceProgram[body, seeds, offset, terms] gives the program of a recurrence step with its seeds read from terms. A step that reads \
only the term before it and needs one seed becomes Rec, and any other CoRec."

synthesisRecurrenceProgram::usage = "synthesisRecurrenceProgram[body, seeds, offset, terms] gives the program of a recurrence step with its seeds read from terms."

seedCost::usage = "seedCost[terms, seeds] gives the cost of the first seeds terms as constants."

stepValue::usage = "stepValue[body, offset, terms, position] gives the value of a recurrence step at a zero-based position, or Missing[\"Unavailable\"] when it \
reads a term that is not recorded before that position."

stepSeeds::usage = "stepSeeds[body, offset, terms] gives the number of seeds a recurrence step needs: its lags, and further initial terms it fails to reproduce."

synthesisStepSeeds::usage = "synthesisStepSeeds[body, offset, terms] gives the number of seeds a recurrence step needs."

$stepIndex::usage = "$stepIndex is the list of generic indices appended to the vector of every recurrence step."

$stepEarlier::usage = "$stepEarlier is the list of generic earlier terms, for the lags one to three, appended to the vector of every recurrence step."

$stepHalved::usage = "$stepHalved is the list of generic terms at half the index appended to the vector of every recurrence step."

recurrenceCandidate::usage = "recurrenceCandidate[body, cost, offset, terms] gives the candidate of a recurrence step that matches the terms, or None when the \
step reads no earlier term or needs too many seeds."

synthesisRecurrences::usage = "synthesisRecurrences[offset, terms, maximum, maximumConstant, deadline] gives the candidates whose recurrence step, enumerated \
up to the cost maximum, reproduces the terms. offset is the input of the first term."

$noPositiveTerm::usage = "$noPositiveTerm is the Failure that signedSum gives when nothing is added."

signedSum::usage = "signedSum[positive, negative] gives the sum of the expressions in positive less the sum of those in negative, with truncated \
subtraction. It gives a Failure when positive is empty."

scaledTerm::usage = "scaledTerm[coefficient, term] gives term times the absolute value of coefficient."

indexPower::usage = "indexPower[exponent] gives Idx to the given positive power as a product."

constantTail::usage = "constantTail[offset, terms] gives the candidate for terms that are constant after a short prefix, or an empty list."

constantStepsQ::usage = "constantStepsQ[terms, period] gives True when every term exceeds the term period positions before it by the same nonnegative amount."

periodicIncrement::usage = "periodicIncrement[offset, terms] gives the candidate for terms with a(i) = a(i - period) + increment, or an empty list."

binomialTerm::usage = "binomialTerm[order] gives the expression for the binomial coefficient of the input over order."

vanishingDegreeQ::usage = "vanishingDegreeQ[terms, degree] gives True when the differences of the terms of the given degree do not start with zero and those \
of the next degree are all zero."

newtonSummand::usage = "newtonSummand[coefficient, order] gives the summand of a Newton form without its sign: a constant for the order zero, and a scaled \
binomial term otherwise."

newtonPolynomial::usage = "newtonPolynomial[offset, terms] gives the candidate for terms that are a polynomial of the input, in Newton form, or an empty list."

recurrenceShapes::usage = "recurrenceShapes[length] gives the shapes of the recurrences with polynomial coefficients that length terms can confirm, simplest \
first. A shape is an association with the keys \"Order\", \"Degree\", \"Constant\" and \"Skip\"."

recurrenceRow::usage = "recurrenceRow[index, position, terms, shape] gives the row of the linear system of a recurrence shape for the term at a zero-based \
position, which has the given index."

polynomialValue::usage = "polynomialValue[coefficients, index] gives the value of the polynomial whose coefficients are given by exponent."

earlierSummand::usage = "earlierSummand[coefficient, lag, exponent] gives the summand of a recurrence, without its sign, for the earlier term at lag times \
the index to the exponent."

indexSummand::usage = "indexSummand[coefficient, exponent] gives the summand of a polynomial in the index without its sign."

summandCost::usage = "summandCost[coefficient, exponent] gives the cost of a summand with the given coefficient and power of the index, and zero for no summand."

recurrenceFromVector::usage = "recurrenceFromVector[nullVector, offset, terms, shape] gives the candidate of the recurrence whose coefficients are the null \
vector of the linear system of a shape, or an empty list when the recurrence cannot be solved for its latest term."

polynomialRecurrence::usage = "polynomialRecurrence[offset, terms, shape] gives the candidate of the recurrence of the given shape that the terms satisfy, or \
an empty list."

synthesisSolvers::usage = "synthesisSolvers[offset, terms] gives the candidates found by solving for constants exactly: a constant tail, a periodic increment, \
a polynomial and recurrences with polynomial coefficients."

(* ::Section:: *)
(*Function Definitions*)

(* Recurrences are checked against the data itself: a step is evaluated on
   the recorded earlier terms at every position, so no candidate program has
   to be run from its start. Seeds are read from the data. *)

previousTerm[lag_Integer] := CGet[Switch[lag, 1, Pred[Idx], 2, Pred[Pred[Idx]], _, Monus[Idx, Const[lag]]]]

(* Zero exactly when value is at most bound. *)
atMost[value_?synthesisExpressionQ, bound_Integer] := Switch[bound, 0, value, 1, Pred[value], _, Monus[value, Const[bound]]]

shiftInput[program_?synthesisExpressionQ, 0] := program
shiftInput[program_?synthesisExpressionQ, shift_Integer] := Let[Monus[Var, Const[shift]], program]
synthesisShiftInput[program_?synthesisExpressionQ, shift_Integer] := shiftInput[program, shift]

(* CoRec[Var, seeds..., step]. A large offset is subtracted from the input
   first, so the history never runs from zero up to the offset. *)
seededProgram[step_?synthesisExpressionQ, seeds_Integer, offset_Integer, terms_List] :=
	With[{base = If[offset > 4, 0, offset]},
		shiftInput[
			CoRec[Var, Fold[Function[{rest, position}, Ifz[atMost[Idx, base + position], Const[terms[[position + 1]]], rest]], step, Reverse[Range[0, seeds - 1]]]],
			If[offset > 4, offset, 0]
		]
	]

stepLag[body_?synthesisExpressionQ] := Max[Cases[body, synthesisEarlier[lag_] :> lag, {0, Infinity}], 0]

recurrenceProgram[body_?synthesisExpressionQ, seeds_Integer, offset_Integer, terms_List] :=
	If[stepLag[body] <= 1 && FreeQ[body, synthesisHalved] && seeds === 1,
		Rec[
			If[offset === 0, Var, Monus[Var, Const[offset]]],
			Const[First[terms]],
			body /. {Idx -> If[offset === 0, Succ[Idx], Add[Idx, Const[offset + 1]]], synthesisEarlier[1] -> Acc}
		],
		seededProgram[
			body /. {Idx -> If[offset > 4, Add[Idx, Const[offset]], Idx], synthesisEarlier[lag_] :> previousTerm[lag], synthesisHalved -> CGet[Half[Idx]]},
			seeds, offset, terms
		]
	]

synthesisRecurrenceProgram[body_?synthesisExpressionQ, seeds_Integer, offset_Integer, terms_List] := recurrenceProgram[body, seeds, offset, terms]

seedCost[terms_List, seeds_Integer] := Total[synthesisConstantCost /@ Take[terms, seeds]]

(* Value of a step at a zero-based position, or Missing when it reads a term
   that is not recorded before that position. *)
stepValue[body_?synthesisExpressionQ, offset_Integer, terms_List, position_Integer] :=
	With[{half = Quotient[offset + position, 2] - offset + 1},
		If[stepLag[body] > position || (! FreeQ[body, synthesisHalved] && ! (1 <= half <= position)),
			Missing["Unavailable"],
			synthesisVectorValue[
				body,
				<|
					"Index" -> offset + position,
					"Earlier" -> Table[terms[[Max[position + 1 - lag, 1]]], {lag, 3}],
					"Halved" -> terms[[Clip[half, {1, Length[terms]}]]]
				|>
			]
		]
	]

(* Seeds a step needs: its lags, and further initial terms it fails to
   reproduce. Exceptional initial terms become extra seeds. *)
stepSeeds[body_?synthesisExpressionQ, offset_Integer, terms_List] :=
	Module[{least, exceptional},
		least = Max[stepLag[body], If[FreeQ[body, synthesisHalved], 0, Max[1, offset]], 1];
		exceptional = SelectFirst[Range[2, least, -1], Function[position, stepValue[body, offset, terms, position] =!= terms[[position + 1]]], None];
		If[exceptional === None, least, exceptional + 1]
	]

synthesisStepSeeds[body_?synthesisExpressionQ, offset_Integer, terms_List] := stepSeeds[body, offset, terms]

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

(* A step must reproduce more terms than it takes as seeds, by two at least:
   otherwise the seeds explain the data and the step explains little. *)
recurrenceCandidate[body_?synthesisExpressionQ, cost_Integer, offset_Integer, terms_List] :=
	If[FreeQ[body, synthesisEarlier | synthesisHalved],
		None,
		With[{seeds = stepSeeds[body, offset, terms]},
			If[Length[terms] - seeds < seeds + 2,
				None,
				<|"Cost" -> cost + seedCost[terms, seeds] + 1, "Expression" -> body, "Seeds" -> seeds|>
			]
		]
	]

synthesisRecurrences[offset_Integer, terms_List, maximum_Integer, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)] :=
	Module[{positions, leaves, found},
		If[Length[terms] < 6,
			{},
			positions = Range[3, Length[terms] - 1];
			leaves = Join[
				{{Idx, Join[offset + positions, $stepIndex]}},
				Table[{synthesisEarlier[lag], Join[terms[[positions + 1 - lag]], $stepEarlier[[lag]]]}, {lag, 3}],
				If[offset <= 1, {{synthesisHalved, Join[terms[[Quotient[offset + positions, 2] - offset + 1]], $stepHalved]}}, {}],
				Table[{Const[constant], ConstantArray[constant, Length[positions] + 16]}, {constant, 0, maximumConstant}]
			];
			found = synthesisClasses[
				leaves, terms[[positions + 1]], maximum, deadline, None, False,
				Function[{body, cost}, recurrenceCandidate[body, cost, offset, terms]]
			]["Matches"];
			Map[<|"Program" -> recurrenceProgram[#["Expression"], #["Seeds"], offset, terms], "Cost" -> #["Cost"], "Method" -> "Recurrence"|> &, found]
		]
	]

$noPositiveTerm = Failure["NoPositiveTerm", <|"MessageTemplate" -> "A truncated difference needs a term that is added."|>]

signedSum[{}, _List] := $noPositiveTerm
signedSum[positive_List, {}] := Fold[Add, positive]
signedSum[positive_List, negative_List] := Monus[Fold[Add, positive], Fold[Add, negative]]

scaledTerm[coefficient_Integer, term_?synthesisExpressionQ] := If[Abs[coefficient] === 1, term, Mul[Const[Abs[coefficient]], term]]

indexPower[exponent_Integer] := Fold[Mul, ConstantArray[Idx, exponent]]

constantTail[offset_Integer, terms_List] :=
	Module[{tail, prefix},
		tail = Last[terms];
		prefix = Length[terms] - LengthWhile[Reverse[terms], # === tail &];
		If[0 < prefix <= Length[terms] - 3,
			{<|
				"Program" -> Fold[
					Function[{rest, position}, Ifz[atMost[Var, offset + position], Const[terms[[position + 1]]], rest]],
					Const[tail],
					Reverse[Range[0, prefix - 1]]
				],
				"Cost" -> synthesisConstantCost[tail] + seedCost[terms, prefix] + 1,
				"Method" -> "ConstantTail"
			|>},
			{}
		]
	]

constantStepsQ[terms_List, period_Integer] :=
	Module[{steps},
		steps = Drop[terms, period] - Drop[terms, -period];
		SameQ @@ steps && First[steps] >= 0
	]
constantStepsQ[___] := False

(* a(i) = a(i-k) + m: periodic sequences and residue-class lists. *)
periodicIncrement[offset_Integer, terms_List] :=
	Module[{period, increment},
		period = SelectFirst[Range[2, Length[terms] - 3], constantStepsQ[terms, #] &, None];
		If[period === None,
			{},
			increment = terms[[period + 1]] - First[terms];
			{<|
				"Program" -> seededProgram[If[increment === 0, previousTerm[period], Add[previousTerm[period], Const[increment]]], period, offset, terms],
				"Cost" -> If[increment === 0, 1, 2 + synthesisConstantCost[increment]] + seedCost[terms, period] + 1,
				"Method" -> "Periodic"
			|>}
		]
	]

binomialTerm[1] := Var
binomialTerm[order_Integer] := Quot[Fold[Mul, Table[Nest[Pred, Var, back], {back, 0, order - 1}]], Const[order!]]

vanishingDegreeQ[terms_List, degree_Integer] := AllTrue[Differences[terms, degree + 1], # === 0 &] && First[Differences[terms, degree]] =!= 0
vanishingDegreeQ[___] := False

newtonSummand[coefficient_Integer, 0] := Const[Abs[coefficient]]
newtonSummand[coefficient_Integer, order_Integer] := scaledTerm[coefficient, binomialTerm[order]]

(* Newton form sum_j c_j Binomial[n - offset, j], confirmed by at least two
   vanishing higher differences. *)
newtonPolynomial[offset_Integer, terms_List] :=
	Module[{degree, coefficients, orders, summands, body, cost},
		degree = SelectFirst[Range[2, Min[7, Length[terms] - 3]], vanishingDegreeQ[terms, #] &, None];
		If[degree === None,
			{},
			coefficients = Table[First[Differences[terms, order]], {order, 0, degree}];
			orders = Select[Range[0, degree], coefficients[[# + 1]] =!= 0 &];
			summands = Map[Function[order, {coefficients[[order + 1]], newtonSummand[coefficients[[order + 1]], order]}], orders];
			body = signedSum[Cases[summands, {_?Positive, summand_} :> summand], Cases[summands, {_?Negative, summand_} :> summand]];
			cost = 1 + Total[Map[Function[order, synthesisConstantCost[coefficients[[order + 1]]] + order], orders]];
			If[FailureQ[body],
				{},
				{<|"Program" -> shiftInput[body, offset], "Cost" -> cost + If[offset === 0, 0, 2 + synthesisConstantCost[offset]], "Method" -> "Polynomial"|>}
			]
		]
	]

recurrenceShapes[length_Integer] :=
	SortBy[
		Select[
			Flatten[
				Table[
					<|"Order" -> order, "Degree" -> degree, "Constant" -> constantQ, "Skip" -> skip|>,
					{order, 1, 9}, {degree, 0, 5}, {constantQ, {False, True}}, {skip, 0, 2}
				]
			],
			And[
				! #Constant || #Degree === 0,
				#Order + #Skip <= length - 3,
				length - #Order - #Skip >= (#Order + 1) (#Degree + 1) + Boole[#Constant] + 1
			] &
		],
		{(#Order + 1) (#Degree + 1) + Boole[#Constant] + #Skip &, #Order &, #Degree &, #Skip &}
	]

(* The row holds the coefficients of a(i-order) .. a(i-1) by falling degree, the constant, then those of a(i). *)
recurrenceRow[index_Integer, position_Integer, terms_List, shape_Association] :=
	Join[
		Flatten[Table[index ^ exponent terms[[position + 1 - lag]], {lag, shape["Order"], 1, -1}, {exponent, shape["Degree"], 0, -1}]],
		If[shape["Constant"], {1}, {}],
		Table[index ^ exponent terms[[position + 1]], {exponent, shape["Degree"], 0, -1}]
	]

polynomialValue[coefficients_Association, index_Integer] := Total[KeyValueMap[Function[{exponent, coefficient}, coefficient index ^ exponent], coefficients]]

earlierSummand[coefficient_Integer, lag_Integer, 0] := scaledTerm[coefficient, synthesisEarlier[lag]]
earlierSummand[coefficient_Integer, lag_Integer, exponent_Integer] := scaledTerm[coefficient, Mul[indexPower[exponent], synthesisEarlier[lag]]]

indexSummand[coefficient_Integer, 0] := Const[Abs[coefficient]]
indexSummand[coefficient_Integer, exponent_Integer] := scaledTerm[coefficient, indexPower[exponent]]

summandCost[0, _Integer] := 0
summandCost[coefficient_Integer, exponent_Integer] := synthesisConstantCost[coefficient] + exponent + 1

(* The recurrence is solved for a(i): the earlier terms and the constant go
   to the other side, and the sum is divided by the coefficient of a(i)
   unless that is one. The coefficient of a(i) must be positive at every
   position, so the vector is taken with the sign that makes it so. *)
recurrenceFromVector[nullVector_List, offset_Integer, terms_List, shape_Association] :=
	Module[{
		order, degree, seeds, exponents, vector, earlierPart, constantPart, leadingPart, leading, constant, summands, positive, negative, numerator,
		divisorSummands, cost, body
	},
		order = shape["Order"];
		degree = shape["Degree"];
		seeds = order + shape["Skip"];
		exponents = Range[degree, 0, -1];
		vector = nullVector (LCM @@ Denominator[nullVector]);
		vector = vector / (GCD @@ vector);
		If[polynomialValue[AssociationThread[exponents, Take[vector, -(degree + 1)]], offset + seeds] < 0, vector = -vector];
		{earlierPart, constantPart, leadingPart} = TakeList[vector, {order (degree + 1), Boole[shape["Constant"]], degree + 1}];
		leading = AssociationThread[exponents, leadingPart];
		constant = First[constantPart, 0];
		(* the summands of the other side, as {coefficient, lag, exponent}, lag by lag and by rising exponent *)
		summands = Catenate[Table[{-earlierPart[[(order - lag) (degree + 1) + degree - exponent + 1]], lag, exponent}, {lag, 1, order}, {exponent, 0, degree}]];
		summands = Select[summands, First[#] =!= 0 &];
		Which[
			! AllTrue[Range[offset + seeds, offset + Length[terms] - 1], polynomialValue[leading, #] > 0 &],
				{},
			summands === {},
				{},
			True,
				positive = Cases[summands, {coefficient_?Positive, lag_, exponent_} :> earlierSummand[coefficient, lag, exponent]];
				negative = Cases[summands, {coefficient_?Negative, lag_, exponent_} :> earlierSummand[coefficient, lag, exponent]];
				positive = If[constant < 0, Append[positive, Const[-constant]], positive];
				negative = If[constant > 0, Append[negative, Const[constant]], negative];
				numerator = signedSum[positive, negative];
				cost = 1 + seedCost[terms, seeds] + Total[summandCost[First[#], Last[#]] & /@ summands] + If[constant === 0, 0, synthesisConstantCost[constant] + 1];
				If[FailureQ[numerator],
					{},
					body = If[leading[0] === 1 && AllTrue[Range[1, degree], leading[#] === 0 &],
						numerator,
						divisorSummands = Reverse[KeyValueMap[List, leading]];
						cost += Total[KeyValueMap[Function[{exponent, coefficient}, summandCost[coefficient, exponent]], leading]];
						Quot[
							numerator,
							signedSum[
								Cases[divisorSummands, {exponent_, coefficient_?Positive} :> indexSummand[coefficient, exponent]],
								Cases[divisorSummands, {exponent_, coefficient_?Negative} :> indexSummand[coefficient, exponent]]
							]
						]
					];
					{<|
						"Program" -> recurrenceProgram[body, seeds, offset, terms],
						"Cost" -> cost,
						"Method" -> Which[degree === 0, "LinearRecurrence", order === 1, "Hypergeometric", True, "Holonomic"]
					|>}
				]
		]
	]

(* sum_k p_k(i) a(i-k) + c = 0 with polynomial coefficients. Degree zero is a
   linear recurrence with constant coefficients; order one is hypergeometric.
   The null space is exact, and at least two spare equations confirm it. *)
polynomialRecurrence[offset_Integer, terms_List, shape_Association] :=
	Module[{seeds, rows, null},
		seeds = shape["Order"] + shape["Skip"];
		rows = Table[recurrenceRow[offset + position, position, terms, shape], {position, seeds, Length[terms] - 1}];
		null = NullSpace[rows];
		If[Length[null] =!= 1, {}, recurrenceFromVector[First[null], offset, terms, shape]]
	]

synthesisSolvers[offset_Integer, terms_List] :=
	If[Length[terms] < 5,
		{},
		Join[
			constantTail[offset, terms],
			periodicIncrement[offset, terms],
			newtonPolynomial[offset, terms],
			Catenate[polynomialRecurrence[offset, terms, #] & /@ recurrenceShapes[Length[terms]]]
		]
	]
