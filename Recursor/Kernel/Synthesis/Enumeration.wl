(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{synthesisConstantCost, synthesisClasses, synthesisVectorValue, synthesisVectorFunction, $synthesisVectorOperations, synthesisOffer, synthesisEarlier,
	synthesisHalved, synthesisAffineProgram, synthesisAffineCost, synthesisExpressionQ}]

(* ::Section:: *)
(*Usage Messages*)

synthesisConstantCost::usage = "synthesisConstantCost[constant] gives the cost of an integer constant: one node up to three, and one more for every further two bits."

synthesisExpressionQ::usage = "synthesisExpressionQ[expression] gives True when expression is a variable, a node of the language or a placeholder of a recurrence step. \
It looks at the head only, so it costs the same for every expression."

synthesisEarlier::usage = "synthesisEarlier[lag] stands in a recurrence step for the term lag positions before the current one."

synthesisHalved::usage = "synthesisHalved stands in a recurrence step for the term at half the current index."

totalRemainder::usage = "totalRemainder[dividend, divisor] gives the remainder of integers or arrays of integers, and dividend where divisor is zero."

totalQuotient::usage = "totalQuotient[dividend, divisor] gives the quotient of integers or arrays of integers, and zero where divisor is zero."

synthesisVectorValue::usage = "synthesisVectorValue[expression, environment] gives the values of a loop-free expression on arrays of inputs. environment is an \
association that gives the arrays under \"Input\", \"Accumulator\", \"Index\", \"Earlier\" and \"Halved\", as far as the expression reads them."

$synthesisVectorOperations::usage = "$synthesisVectorOperations is the list of rules that replace the operations of the language by functions of arrays."

synthesisVectorFunction::usage = "synthesisVectorFunction[expression] gives a loop-free expression in Var, Acc and Idx as one function of their arrays."

synthesisOffer::usage = "synthesisOffer[best, candidate] gives the cheaper of two candidates, and best when they cost the same. best may be None."

synthesisAffineProgram::usage = "synthesisAffineProgram[program, scale, shift] gives a program for scale times program plus shift, with truncated subtraction \
for a negative constant."

synthesisAffineCost::usage = "synthesisAffineCost[scale, shift] gives the cost that scaling by scale and shifting by shift add to a program."

affineProgram::usage = "affineProgram[program, scale, shift] gives a program for scale times program plus shift, with truncated subtraction for a negative constant."

affineCost::usage = "affineCost[scale, shift] gives the cost that scaling by scale and shifting by shift add to a program."

$leafPattern::usage = "$leafPattern is the pattern of the leaves of a loop body: Var, Acc, Idx and constants."

bodyShape::usage = "bodyShape[body] gives {function, leaves} for a loop body: its operations as one function of its leaves, which are numbered in reading \
order, and the leaves themselves."

loopGroupValues::usage = "loopGroupValues[step, leaves, counts, bases, inputs, width, cap, steps] runs the loop bodies of one shape on every loop at once, \
for at most the given number of steps. step is the function of the shape and leaves holds, for each of its leaves, the leaf of every body. It gives \
{values, steps}: the final values as bodies x loops x width, and the number of steps that the loops still running at the end needed."

loopValues::usage = "loopValues[bodies, counts, bases, inputs, width, cap] runs every loop body on every loop. counts, bases and inputs are the loops laid end to \
end, width values each. A loop whose values pass cap stops and is marked with cap + 1. It gives the final values as bodies x loops x width."

loopPrograms::usage = "loopPrograms[positions, countExpressions, baseExpressions, bodies] gives the loops at the given positions of the family of all counts, \
bases and bodies, numbered count by count, base by base and body by body. A body without Idx gives Iter, and any other gives Rec."

$classExpressions::usage = "$classExpressions holds, during a call of synthesisClasses, the stored expressions by cost."

$classVectors::usage = "$classVectors holds, during a call of synthesisClasses, the vectors of values of the stored expressions by cost."

$classSeen::usage = "$classSeen holds, during a call of synthesisClasses, True for every vector of values that has a stored expression."

$classConditions::usage = "$classConditions holds, during a call of synthesisClasses, the pairs {vector, expression} by cost that serve as conditions of Ifz."

$classPatterns::usage = "$classPatterns holds, during a call of synthesisClasses, True for every zero pattern that has a condition."

$classBest::usage = "$classBest holds, during a call of synthesisClasses, the cheapest candidate met so far, or None."

$classMatches::usage = "$classMatches holds, during a call of synthesisClasses, the cheapest few of the candidates met so far."

$classCandidates::usage = "$classCandidates holds, during a call of synthesisClasses, the number of rows of values tested so far."

$classGoal::usage = "$classGoal holds, during a call of synthesisClasses, the vector of values to find, or None."

$classWidth::usage = "$classWidth holds, during a call of synthesisClasses, the length of the goal, or zero without a goal."

$classCap::usage = "$classCap holds, during a call of synthesisClasses, the largest value a stored vector may have."

$classDifferences::usage = "$classDifferences holds, during a call of synthesisClasses, the differences of the goal."

$classPivot::usage = "$classPivot holds, during a call of synthesisClasses, the first position at which the goal changes, or zero when rows are not scaled \
and shifted."

$classJudge::usage = "$classJudge holds, during a call of synthesisClasses, the function that gives the candidate of an expression and a cost, or None."

$classLoops::usage = "$classLoops holds, during a call of synthesisClasses, the loop bodies by cost with the inputs they are run on, or None."

classOffer::usage = "classOffer[candidate] records a candidate: it becomes the best one when it is cheaper, and joins the cheapest few."

classConsider::usage = "classConsider[expression, cost] asks the judge for the candidate of an expression that matches the goal, and records it unless it is None."

classClosure::usage = "classClosure[cost, rows, made] records, as \"Affine\" candidates, the expressions in made whose rows become the goal after a scale and a shift."

classRecordConditions::usage = "classRecordConditions[cost, newRows, made] stores the first row of every new zero pattern, with its expression, as a condition."

classStore::usage = "classStore[cost, rows, keep, build] stores the rows at the positions keep that no stored expression has yet, with the expressions that \
build gives for their positions."

classAdmit::usage = "classAdmit[cost, rows, build] takes in the rows of values of new expressions of one cost. build gives the expressions at a list of \
positions. Rows equal to the goal go to the judge, and one expression is stored for each new row."

classUnary::usage = "classUnary[cost] takes in Succ, Pred and Half of the expressions that cost one less."

classPairs::usage = "classPairs[cost, leftCost, rightCost] takes in the sums, products, truncated differences, remainders and quotients of the stored \
expressions of two costs."

classTernary::usage = "classTernary[cost, testCost, zeroCost, positiveCost] takes in Ifz of the conditions and the stored expressions of the given costs."

classLoopFamily::usage = "classLoopFamily[cost, countCost, baseCost] takes in the loops whose count and base are stored expressions of the given costs and whose \
body has the rest of the cost."

classLoops::usage = "classLoops[cost] takes in Iter and Rec of the given cost, for counts and bases that cost one or two."

classLevel::usage = "classLevel[cost] takes in every expression of the given cost that is built from stored expressions."

classComplete::usage = "classComplete[head, picked, partners, swapQ, made, levels] judges head of two stored expressions for the cheapest pairs. partners gives \
for each picked class the class that completes it, or zero. swapQ says whether the partner comes first."

classJoin::usage = "classJoin[] judges sums, products and truncated differences of two stored expressions that give the goal."

synthesisClasses::usage = "synthesisClasses[leaves, goal, maximum, deadline, loops, affineQ, judge] enumerates expressions up to the cost maximum and keeps one \
for each distinct vector of values. leaves is a list of pairs {expression, vector}, goal a vector or None, loops None or an association with the loop \
bodies by cost, and judge a function of an expression and a cost that gives a candidate or None. It gives an association with the cheapest candidate \
(\"Best\"), the cheapest few (\"Matches\"), the stored \"Expressions\" and \"Vectors\" by cost and the number of \"Candidates\"."

(* ::Section:: *)
(*Function Definitions*)

(* Bottom-up enumeration up to observational equivalence. One program is kept
   for each distinct vector of values on the observed inputs, so a level holds
   the distinct functions of one cost rather than every syntax tree. *)

(* Constants 0..3 cost one node; every further two bits cost one more. *)
synthesisConstantCost[constant_Integer] := If[Abs[constant] <= 3, 1, 1 + Ceiling[(BitLength[Abs[constant]] - 2) / 2]]

(* A test of the head alone: the search builds its expressions itself, and a recurrence step holds placeholders
   that RecursorExpressionQ does not know. *)
synthesisExpressionQ[Var | Acc | Idx | synthesisHalved] := True
synthesisExpressionQ[(Const | Succ | Pred | Half | CGet | Add | Mul | Monus | Rem | Quot | CoRec | Let | Ifz | Iter | Rec | WhileLoop | synthesisEarlier)[___]] := True
synthesisExpressionQ[___] := False

totalRemainder[dividend : (_Integer | _List), divisor : (_Integer | _List)] := Mod[dividend, divisor + (1 - Unitize[divisor]) (dividend + 1)]
totalQuotient[dividend : (_Integer | _List), divisor : (_Integer | _List)] := Quotient[dividend, divisor + (1 - Unitize[divisor]) (dividend + 1)]

(* Value of a loop-free expression on arrays of inputs. Both branches of Ifz
   are evaluated, which is sound because loop-free expressions are total. *)
synthesisVectorValue[Var, environment_Association] := environment["Input"]
synthesisVectorValue[Acc, environment_Association] := environment["Accumulator"]
synthesisVectorValue[Idx, environment_Association] := environment["Index"]
synthesisVectorValue[Const[constant_Integer], _Association] := constant
(* Placeholders in recurrence steps: a(i-k) and a(floor(i/2)). *)
synthesisVectorValue[synthesisEarlier[lag_Integer], environment_Association] := environment["Earlier"][[lag]]
synthesisVectorValue[synthesisHalved, environment_Association] := environment["Halved"]
synthesisVectorValue[Succ[operand_], environment_Association] := synthesisVectorValue[operand, environment] + 1
synthesisVectorValue[Pred[operand_], environment_Association] := Ramp[synthesisVectorValue[operand, environment] - 1]
synthesisVectorValue[Half[operand_], environment_Association] := Quotient[synthesisVectorValue[operand, environment], 2]
synthesisVectorValue[Add[left_, right_], environment_Association] := synthesisVectorValue[left, environment] + synthesisVectorValue[right, environment]
synthesisVectorValue[Mul[left_, right_], environment_Association] := synthesisVectorValue[left, environment] synthesisVectorValue[right, environment]
synthesisVectorValue[Monus[left_, right_], environment_Association] := Ramp[synthesisVectorValue[left, environment] - synthesisVectorValue[right, environment]]
synthesisVectorValue[Rem[left_, right_], environment_Association] :=
	totalRemainder[synthesisVectorValue[left, environment], synthesisVectorValue[right, environment]]
synthesisVectorValue[Quot[left_, right_], environment_Association] :=
	totalQuotient[synthesisVectorValue[left, environment], synthesisVectorValue[right, environment]]
synthesisVectorValue[Ifz[condition_, whenZero_, whenPositive_], environment_Association] :=
	With[{nonzero = Unitize[synthesisVectorValue[condition, environment]]},
		(1 - nonzero) synthesisVectorValue[whenZero, environment] + nonzero synthesisVectorValue[whenPositive, environment]
	]

(* A loop-free expression in Var, Acc and Idx as one function of their arrays.
   The expression is translated once to array arithmetic, so a loop that
   applies it many times pays for the arithmetic only. *)
$synthesisVectorOperations = {Succ -> (# + 1 &), Pred -> (Ramp[# - 1] &), Half -> (Quotient[#, 2] &), Add -> Plus, Mul -> Times, Monus -> (Ramp[#1 - #2] &),
	Rem -> totalRemainder, Quot -> totalQuotient, Ifz -> (With[{nonzero = Unitize[#1]}, (1 - nonzero) #2 + nonzero #3] &)}

synthesisVectorFunction[expression_?synthesisExpressionQ] := synthesisVectorFunction[expression] = Function @@ {
	expression /. {Var -> Slot[1], Acc -> Slot[2], Idx -> Slot[3], Const[constant_] :> constant} /. $synthesisVectorOperations
}

(* Keep the cheaper of two candidates; ties keep the earlier one. *)
synthesisOffer[None, candidate_Association] := candidate
synthesisOffer[best_Association, candidate_Association] := If[candidate["Cost"] < best["Cost"], candidate, best]

(* scale program + shift with truncated subtraction for negative constants. *)
synthesisAffineProgram[program_?synthesisExpressionQ, scale_Integer, shift_Integer] := affineProgram[program, scale, shift]
synthesisAffineCost[scale_Integer, shift_Integer] := affineCost[scale, shift]

affineProgram[program_?synthesisExpressionQ, scale_Integer, shift_Integer] :=
	Module[{scaled},
		scaled = If[Abs[scale] === 1, program, Mul[Const[Abs[scale]], program]];
		Which[
			scale > 0 && shift > 0, Add[scaled, Const[shift]],
			scale > 0 && shift < 0, Monus[scaled, Const[-shift]],
			scale > 0, scaled,
			True, Monus[Const[shift], scaled]
		]
	]

affineCost[scale_Integer, shift_Integer] := If[Abs[scale] === 1, 0, 1 + synthesisConstantCost[scale]] + If[shift === 0, 0, 1 + synthesisConstantCost[shift]]

$leafPattern = Var | Acc | Idx | _Const

(* The shape of a loop body: its operations as one function of its leaves,
   which are numbered in reading order, and the leaves themselves. Bodies of
   one shape differ only in which of Var, Acc, Idx or a constant each leaf is. *)
bodyShape[body_?synthesisExpressionQ] := bodyShape[body] =
	Module[{count = 0, leaves, template},
		leaves = Cases[body, $leafPattern, {0, Infinity}];
		template = body /. $leafPattern :> Slot[++count];
		{Function @@ {template /. $synthesisVectorOperations}, leaves}
	]

(* All bodies of one shape advance together: a leaf is a matrix with one row
   per body, so a step of the group costs the arithmetic of one body. A loop
   whose values pass the cap stops and is marked with cap + 1, which keeps the
   arrays machine integers. The step function changes the arrays in place:
   passing them through as a state would copy them at every step. When loops
   stop at the cap, the number of steps falls to what the loops still running
   need. *)
loopGroupValues[step_Function, leaves_List, counts_List, bases_List, inputs_List, width_Integer, cap_Integer, steps_Integer] :=
	Module[{size, length, fixed, onAccumulator, onIndex, accumulator, live, top, running, over},
		size = Length[First[leaves]];
		length = Length[counts];
		(* each leaf as a fixed part plus the accumulator or the index where the body reads them *)
		fixed = Map[Replace[#, {Var -> inputs, Const[constant_] :> ConstantArray[constant, length], _ -> ConstantArray[0, length]}] &, leaves, {2}];
		onAccumulator = Map[Boole[# === Acc] &, leaves, {2}];
		onIndex = Map[Boole[# === Idx] &, leaves, {2}];
		accumulator = ConstantArray[bases, size];
		live = ConstantArray[counts, size];
		top = steps;
		NestWhile[
			Function[time,
				running = UnitStep[live - time - 1];
				accumulator += running (step @@ MapThread[#1 + #2 accumulator + #3 time &, {fixed, onAccumulator, onIndex}] - accumulator);
				If[Max[accumulator] > cap,
					over = Unitize[Total[ArrayReshape[UnitStep[accumulator - cap - 1], {size, Quotient[length, width], width}], {3}]];
					over = ArrayReshape[Transpose[ConstantArray[over, width], {3, 1, 2}], {size, length}];
					live = (1 - over) live;
					(* allow QualifiedSymbol: packing has no System function, and unpacked arrays would slow every later step *)
					accumulator = Developer`ToPackedArray[(1 - over) accumulator + over (cap + 1)];
					top = Max[live]
				];
				time + 1
			],
			0,
			Function[time, time < top]
		];
		{Partition[#, width] & /@ accumulator, top}
	]

(* Loop bodies run for many loops at once. counts, bases and inputs are the
   loops laid end to end, width values each. Gives the values as
   bodies x loops x width. The number of steps is carried from one group of
   bodies to the next: a group whose loops stop at the cap lowers it for the
   groups after it. *)
loopValues[bodies_List, counts_List, bases_List, inputs_List, width_Integer, cap_Integer] :=
	Module[{shapes, groups, values},
		shapes = bodyShape /@ bodies;
		groups = GroupBy[Range[Length[bodies]], Function[position, First[shapes[[position]]]]];
		values = FoldPairList[
			Function[{steps, group}, loopGroupValues[First[group], Transpose[shapes[[Last[group], 2]]], counts, bases, inputs, width, cap, steps]],
			Max[counts],
			Transpose[{Keys[groups], Values[groups]}]
		];
		(* the groups hold the bodies in another order; the ordering of their positions puts the values back *)
		Catenate[values][[Ordering[Catenate[Values[groups]]]]]
	]

loopPrograms[positions_List, countExpressions_List, baseExpressions_List, bodies_List] :=
	Module[{baseCount, bodyCount},
		baseCount = Length[baseExpressions];
		bodyCount = Length[bodies];
		MapThread[
			Function[{count, base, body}, If[FreeQ[body, Idx], Iter, Rec][count, base, body]],
			{
				countExpressions[[Quotient[positions - 1, baseCount bodyCount] + 1]],
				baseExpressions[[Mod[Quotient[positions - 1, bodyCount], baseCount] + 1]],
				bodies[[Mod[positions - 1, bodyCount] + 1]]
			}
		]
	]

(* The tables of a search are file-level values that synthesisClasses sets
   with Block for the time of one call. Functions defined inside a Module
   would refer to one another and to the tables, and keep all of them alive
   after the call. *)

classOffer[candidate_Association] := (
	$classBest = synthesisOffer[$classBest, candidate];
	$classMatches = Append[$classMatches, candidate];
	If[Length[$classMatches] > 48, $classMatches = Take[SortBy[$classMatches, #["Cost"] &], 16]]
)

classConsider[expression_?synthesisExpressionQ, cost_Integer] := Replace[$classJudge[expression, cost], candidate : Except[None] :> classOffer[candidate]]

(* rows that become the goal after a scale and a shift, all tested at once *)
classClosure[cost_Integer, rows_List, made_List] :=
	Module[{change, step, valid, scales, shifts, reproducing, changing, natural, good},
		If[Length[First[rows]] === $classWidth,
			change = $classDifferences[[$classPivot]];
			step = rows[[All, $classPivot + 1]] - rows[[All, $classPivot]];
			valid = Pick[Range[Length[rows]], Unitize[step] (1 - Unitize[Mod[change, step + (1 - Unitize[step])]]), 1];
			If[valid =!= {},
				scales = Quotient[change, step[[valid]]];
				shifts = First[$classGoal] - scales rows[[valid, 1]];
				reproducing = 1 - Unitize[Total[Unitize[Transpose[scales (rows[[valid, 2 ;;]] - rows[[valid, ;; -2]])] - $classDifferences]]];
				changing = 1 - (1 - Unitize[scales - 1]) (1 - Unitize[shifts]);
				natural = Unitize[UnitStep[scales - 1] + UnitStep[shifts - 1]];
				good = Pick[Range[Length[valid]], reproducing changing natural, 1];
				Scan[
					Function[position,
						classOffer[<|
							"Cost" -> cost + affineCost[scales[[position]], shifts[[position]]],
							"Expression" -> affineProgram[made[[valid[[position]]]], scales[[position]], shifts[[position]]],
							"Method" -> "Affine"
						|>]
					],
					good
				]
			]
		]
	]

(* Only the zero pattern of a condition matters, so the first row of every
   new zero pattern serves as a condition. *)
classRecordConditions[cost_Integer, newRows_List, made_List] :=
	Module[{zeroKeys, mixed, novel},
		zeroKeys = Unitize[newRows];
		mixed = Pick[Range[Length[newRows]], Unitize[Total[zeroKeys, {2}]] Unitize[Total[1 - zeroKeys, {2}]], 1];
		novel = Select[DeleteDuplicatesBy[mixed, zeroKeys[[#]] &], ! KeyExistsQ[$classPatterns, zeroKeys[[#]]] &];
		If[novel =!= {},
			AssociateTo[$classPatterns, Thread[zeroKeys[[novel]] -> True]];
			$classConditions[cost] = Join[Lookup[$classConditions, cost, {}], Transpose[{newRows[[novel]], made[[novel]]}]]
		]
	]

classStore[cost_Integer, rows_List, keep_List, build_Function] :=
	Module[{earliest, unseen, indices, newRows, made},
		earliest = AssociationThread[Reverse[rows[[keep]]], Reverse[keep]];
		unseen = KeySelect[earliest, ! KeyExistsQ[$classSeen, #] &];
		If[Length[unseen] > 0,
			indices = Sort[Values[unseen]];
			newRows = rows[[indices]];
			made = build[indices];
			AssociateTo[$classSeen, Thread[newRows -> True]];
			$classExpressions[cost] = Join[Lookup[$classExpressions, cost, {}], made];
			$classVectors[cost] = Join[Lookup[$classVectors, cost, {}], newRows];
			classRecordConditions[cost, newRows, made];
			If[$classGoal =!= None && $classPivot > 0, classClosure[cost, newRows, made]]
		]
	]

(* Every matching candidate is judged, also one whose class is already
   stored, because equal values on the observed positions need not mean equal
   total cost. *)
classAdmit[cost_Integer, rows_List, build_Function] :=
	Module[{keep, matching},
		$classCandidates += Length[rows];
		keep = If[rows === {}, {}, Pick[Range[Length[rows]], UnitStep[$classCap - (Max /@ rows)], 1]];
		If[keep =!= {} && $classGoal =!= None,
			matching = Flatten[Position[rows[[keep, ;; $classWidth]], $classGoal, {1}]];
			Scan[Function[position, classConsider[First[build[{keep[[position]]}]], cost]], matching]
		];
		If[keep =!= {}, classStore[cost, rows, keep, build]]
	]

classUnary[cost_Integer] :=
	Module[{rows, made},
		rows = Lookup[$classVectors, cost - 1, {}];
		made = Lookup[$classExpressions, cost - 1, {}];
		If[rows =!= {},
			classAdmit[cost, rows + 1, Succ /@ made[[#]] &];
			classAdmit[cost, Ramp[rows - 1], Pred /@ made[[#]] &];
			classAdmit[cost, Quotient[rows, 2], Half /@ made[[#]] &]
		]
	]

(* Sums and products are taken once for each unordered pair. *)
classPairs[cost_Integer, leftCost_Integer, rightCost_Integer] :=
	Module[{leftRows, rightRows, leftMade, rightMade, leftCount, rightCount, leftIndex, rightIndex, leftValues, rightValues, upper},
		leftRows = Lookup[$classVectors, leftCost, {}];
		rightRows = Lookup[$classVectors, rightCost, {}];
		If[leftRows =!= {} && rightRows =!= {},
			leftMade = $classExpressions[leftCost];
			rightMade = $classExpressions[rightCost];
			leftCount = Length[leftRows];
			rightCount = Length[rightRows];
			leftIndex = Flatten[Transpose[ConstantArray[Range[leftCount], rightCount]]];
			rightIndex = Flatten[ConstantArray[Range[rightCount], leftCount]];
			leftValues = leftRows[[leftIndex]];
			rightValues = rightRows[[rightIndex]];
			upper = If[leftCost === rightCost, Pick[Range[leftCount rightCount], UnitStep[rightIndex - leftIndex], 1], Range[leftCount rightCount]];
			classAdmit[cost, (leftValues + rightValues)[[upper]],
				Function[positions, MapThread[Add, {leftMade[[leftIndex[[upper[[positions]]]]]], rightMade[[rightIndex[[upper[[positions]]]]]]}]]];
			classAdmit[cost, (leftValues rightValues)[[upper]],
				Function[positions, MapThread[Mul, {leftMade[[leftIndex[[upper[[positions]]]]]], rightMade[[rightIndex[[upper[[positions]]]]]]}]]];
			classAdmit[cost, Ramp[leftValues - rightValues], Function[positions, MapThread[Monus, {leftMade[[leftIndex[[positions]]]], rightMade[[rightIndex[[positions]]]]}]]];
			classAdmit[cost, totalRemainder[leftValues, rightValues],
				Function[positions, MapThread[Rem, {leftMade[[leftIndex[[positions]]]], rightMade[[rightIndex[[positions]]]]}]]];
			classAdmit[cost, totalQuotient[leftValues, rightValues],
				Function[positions, MapThread[Quot, {leftMade[[leftIndex[[positions]]]], rightMade[[rightIndex[[positions]]]]}]]];
			If[leftCost =!= rightCost,
				classAdmit[cost, Ramp[rightValues - leftValues],
					Function[positions, MapThread[Monus, {rightMade[[rightIndex[[positions]]]], leftMade[[leftIndex[[positions]]]]}]]];
				classAdmit[cost, totalRemainder[rightValues, leftValues],
					Function[positions, MapThread[Rem, {rightMade[[rightIndex[[positions]]]], leftMade[[leftIndex[[positions]]]]}]]];
				classAdmit[cost, totalQuotient[rightValues, leftValues],
					Function[positions, MapThread[Quot, {rightMade[[rightIndex[[positions]]]], leftMade[[leftIndex[[positions]]]]}]]]
			]
		]
	]

(* Only the zero pattern of a condition matters, so one condition per
   pattern is enough. *)
classTernary[cost_Integer, testCost_Integer, zeroCost_Integer, positiveCost_Integer] :=
	Module[{tests, zeroRows, positiveRows, zeroMade, positiveMade, zeroCount, positiveCount, zeroIndex, positiveIndex, distinct, zeroValues, positiveValues},
		tests = Lookup[$classConditions, testCost, {}];
		zeroRows = Lookup[$classVectors, zeroCost, {}];
		positiveRows = Lookup[$classVectors, positiveCost, {}];
		If[tests =!= {} && zeroRows =!= {} && positiveRows =!= {},
			zeroMade = $classExpressions[zeroCost];
			positiveMade = $classExpressions[positiveCost];
			zeroCount = Length[zeroRows];
			positiveCount = Length[positiveRows];
			zeroIndex = Flatten[Transpose[ConstantArray[Range[zeroCount], positiveCount]]];
			positiveIndex = Flatten[ConstantArray[Range[positiveCount], zeroCount]];
			distinct = If[zeroCost === positiveCost,
				Pick[Range[zeroCount positiveCount], Unitize[zeroIndex - positiveIndex], 1],
				Range[zeroCount positiveCount]
			];
			If[distinct =!= {},
				zeroValues = Transpose[zeroRows[[zeroIndex[[distinct]]]]];
				positiveValues = Transpose[positiveRows[[positiveIndex[[distinct]]]]];
				Scan[
					Apply[
						Function[{vector, condition},
							With[{nonzero = Unitize[vector]},
								classAdmit[cost, Transpose[(1 - nonzero) zeroValues + nonzero positiveValues],
									Function[positions,
										MapThread[Ifz[condition, #1, #2] &, {zeroMade[[zeroIndex[[distinct[[positions]]]]]], positiveMade[[positiveIndex[[distinct[[positions]]]]]]}]
									]
								]
							]
						]
					],
					tests
				]
			]
		]
	]

(* Iter[count, base, step] and Rec[count, base, step]: count and base are
   stored classes, step a loop body that reads Acc. Every count, base and
   body: the loops of one body are run together. *)
classLoopFamily[cost_Integer, countCost_Integer, baseCost_Integer] :=
	Module[{bodyCost, counts, bases, bodies, pick, inputs, allCounts, allBases, allInputs, countExpressions, baseExpressions},
		bodyCost = cost - 1 - countCost - baseCost;
		If[1 <= bodyCost <= $classLoops["MaxBody"],
			counts = Lookup[$classVectors, countCost, {}];
			bases = Lookup[$classVectors, baseCost, {}];
			bodies = Lookup[$classLoops["Bodies"], bodyCost, {}];
			inputs = $classLoops["Inputs"];
			pick = Select[Range[Length[counts]], ! SameQ @@ counts[[#]] && Max[counts[[#]]] <= 64 &];
			If[Length[pick] Length[bases] Length[bodies] > 0,
				allCounts = Flatten[counts[[Flatten[Transpose[ConstantArray[pick, Length[bases]]]]]]];
				allBases = Flatten[ConstantArray[bases, Length[pick]]];
				allInputs = Flatten[ConstantArray[inputs, Length[pick] Length[bases]]];
				countExpressions = $classExpressions[countCost][[pick]];
				baseExpressions = $classExpressions[baseCost];
				classAdmit[cost,
					Flatten[Transpose[loopValues[bodies, allCounts, allBases, allInputs, Length[inputs], $classCap]], 1],
					Function[positions, loopPrograms[positions, countExpressions, baseExpressions, bodies]]
				]
			]
		]
	]

classLoops[cost_Integer] := Scan[Apply[Function[{countCost, baseCost}, classLoopFamily[cost, countCost, baseCost]]], Tuples[{1, 2}, 2]]

classLevel[cost_Integer] := (
	classUnary[cost];
	Scan[Function[leftCost, classPairs[cost, leftCost, cost - 1 - leftCost]], Range[1, Quotient[cost - 1, 2]]];
	Scan[
		Function[testCost,
			Scan[Function[zeroCost, classTernary[cost, testCost, zeroCost, cost - 1 - testCost - zeroCost]], Range[1, cost - 2 - testCost]]
		],
		Range[1, cost - 3]
	];
	If[$classLoops =!= None, classLoops[cost]]
)

(* partners[[k]] is the stored class that completes the k-th picked row, or zero *)
classComplete[head_Symbol, picked_List, partners_List, swapQ : (True | False), made_List, levels_List] :=
	Module[{found},
		found = Pick[Transpose[{picked, partners}], Unitize[partners], 1];
		Scan[
			Apply[
				Function[{first, second},
					classConsider[If[swapQ, head[made[[second]], made[[first]]], head[made[[first]], made[[second]]]], levels[[first]] + levels[[second]] + 1]
				]
			],
			Take[SortBy[found, Function[pair, Total[levels[[pair]]]]], UpTo[64]]
		]
	]

(* Two stored classes joined at the root. The goal fixes one operand once
   the other is chosen, so a lookup replaces the product of all pairs and a
   match may cost up to twice the enumerated maximum. *)
classJoin[] :=
	Module[{costs, rows, made, levels, count, index, target, missing, excess, picked, exact},
		costs = Sort[Keys[$classVectors]];
		rows = Join @@ Map[Function[cost, $classVectors[cost][[All, ;; $classWidth]]], costs];
		made = Join @@ Map[$classExpressions, costs];
		levels = Join @@ Map[Function[cost, ConstantArray[cost, Length[$classVectors[cost]]]], costs];
		count = Length[rows];
		index = Association[Reverse[Thread[rows -> Range[count]]]];
		target = ConstantArray[$classGoal, count];
		missing = target - rows;
		picked = Pick[Range[count], UnitStep[Min /@ missing], 1];
		If[picked =!= {}, classComplete[Add, picked, Lookup[index, missing[[picked]], 0], False, made, levels]];
		picked = Pick[Range[count], Unitize[Min /@ rows], 1];
		If[picked =!= {},
			exact = Pick[picked, Unitize[Total /@ Mod[target[[picked]], rows[[picked]]]], 0];
			If[exact =!= {}, classComplete[Mul, exact, Lookup[index, Quotient[target[[exact]], rows[[exact]]], 0], False, made, levels]]
		];
		If[Min[$classGoal] > 0,
			classComplete[Monus, Range[count], Lookup[index, target + rows, 0], True, made, levels];
			excess = rows - target;
			picked = Pick[Range[count], UnitStep[Min /@ excess], 1];
			If[picked =!= {}, classComplete[Monus, picked, Lookup[index, excess[[picked]], 0], False, made, levels]]
		]
	]

(* leaves: {{expression, vector}, ...}. goal: a vector, or None to enumerate
   only. loops: None, or bodies by cost with the inputs they are run on.
   judge[expression, cost] gives the candidate for an expression that matches
   the goal, or None to reject it. Leaf vectors may be longer than the goal:
   the extra columns only keep classes apart.
   Returns the cheapest candidate, the cheapest few of all candidates met,
   and the stored expressions and vectors by cost. *)
synthesisClasses[
	leaves_List, goal : (_List | None), maximum_Integer, deadline : (_Real | _Integer | Infinity), loops : (_Association | None), affineQ : (True | False),
	judge_Function
] :=
	Block[{
		$classExpressions = <||>, $classVectors = <||>, $classSeen = <||>, $classConditions = <||>, $classPatterns = <||>, $classBest = None,
		$classMatches = {}, $classCandidates = 0, $classGoal = goal, $classJudge = judge, $classLoops = loops, $classWidth, $classCap,
		$classDifferences, $classPivot
	},
		$classWidth = If[goal === None, 0, Length[goal]];
		$classCap = If[goal === None, 2 ^ 40, Max[2 ^ 40, 16 Max[goal]]];
		$classDifferences = If[goal === None, {}, Differences[goal]];
		$classPivot = If[affineQ, First[FirstPosition[$classDifferences, _?(# =!= 0 &), {0}, {1}, Heads -> False]], 0];
		classAdmit[1, leaves[[All, 2]], leaves[[#, 1]] &];
		NestWhile[
			Function[cost,
				classLevel[cost];
				cost + 1
			],
			2,
			Function[cost, cost <= maximum && ! (($classBest =!= None && cost >= $classBest["Cost"]) || AbsoluteTime[] > deadline)]
		];
		If[goal =!= None && $classBest === None && $classWidth > 1 && AbsoluteTime[] <= deadline, classJoin[]];
		<|
			"Best" -> $classBest,
			"Matches" -> Take[DeleteDuplicatesBy[SortBy[$classMatches, #["Cost"] &], #["Expression"] &], UpTo[12]],
			"Expressions" -> $classExpressions,
			"Vectors" -> $classVectors,
			"Candidates" -> $classCandidates
		|>
	]
