(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{synthesisCost, synthesisFoldTerms, synthesisFolds, synthesisFoldProgram}]

(* ::Section:: *)
(*Usage Messages*)

synthesisCost::usage = "synthesisCost[expression] gives the cost of an expression: one for every node, and the cost of its value for a constant."

$foldCounts::usage = "$foldCounts is the list of the counts a fold may run to, as expressions in Var."

$termInput::usage = "$termInput is the list of the inputs n of the sample pairs (n, i) with i <= n <= 10, on which terms are told apart."

$termIndex::usage = "$termIndex is the list of the indices i of the sample pairs (n, i) with i <= n <= 10, on which terms are told apart."

$noFolds::usage = "$noFolds is the result of synthesisFolds when there is no fold."

synthesisFoldTerms::usage = "synthesisFoldTerms[maximum, maximumConstant, deadline] gives the loop-free terms in Var and Idx by cost, up to the cost maximum, \
one for each distinct list of values on the sample pairs."

synthesisFoldProgram::usage = "synthesisFoldProgram[{kind, count, term}] gives the loop that sums the term (\"Sum\"), multiplies it (\"Product\") or counts its \
zeros (\"Count\") over the indices below count."

segmentTotals::usage = "segmentTotals[matrix, ends] gives the totals of the segments of every row of matrix. ends is the list of the cumulative lengths of \
the segments, starting with zero."

segmentProducts::usage = "segmentProducts[matrix, zeros, counts] gives the products of the segments of every row of matrix. counts gives the lengths of the \
segments and zeros the number of zeros in each segment of each row. A segment with a zero gives zero."

$knownTermValues::usage = "$knownTermValues holds, during a call of termValues, the values of the terms computed so far."

termValue::usage = "termValue[term] gives the values of a term on the pairs of the current call of termValues, from the values of its parts."

termValues::usage = "termValues[bodies, inputs, indices] gives the values of all terms on the pairs of an input and an index, one row per term."

foldRows::usage = "foldRows[count, counts, costs, bodies, indexed, productive, inputs, cap] gives the folds of all terms up to one count as triples {row, cost, \
specification}, term by term: sum, count, product. counts gives the values of count at the inputs."

foldsOfCount::usage = "foldsOfCount[count, costs, bodies, indexed, productive, inputs, cap] gives the folds of all terms up to one count as triples {row, cost, \
specification}. indexed lists the positions of the terms that read Idx, and productive marks the terms whose product is worth taking."

distinctFolds::usage = "distinctFolds[found] gives the distinct rows of the triples {row, cost, specification} with their costs and specifications, each \
row for its cheapest fold."

synthesisFolds::usage = "synthesisFolds[terms, inputs, cap, deadline] gives the values of every fold of the terms at the inputs. terms is a list of pairs \
{cost, term}. It gives an association with the distinct \"Rows\", their \"Costs\" and their \"Specifications\" {kind, count, term}."

(* ::Section:: *)
(*Function Definitions*)

(* Sums, products and counts over a loop index. The step uses the accumulator
   in one fixed way: Add[Acc, f], Mul[Acc, f] or Ifz[f, Succ[Acc], Acc], where
   the term f is a loop-free expression in Var and Idx. Every term is evaluated
   at once on all pairs (n, i) with i below the count at n, so a family of
   loops costs a few array operations instead of one run per loop. *)

synthesisCost[Const[constant_Integer]] := synthesisConstantCost[constant]
synthesisCost[Var | Acc | Idx] := 1
synthesisCost[expression_] := 1 + Total[synthesisCost /@ List @@ expression]

$foldCounts = {Var, Succ[Var], Pred[Var], Monus[Var, Const[2]], Half[Var]}

(* Pairs (n, i) with i <= n <= 10, on which terms are told apart. *)
$termInput = Catenate[Table[ConstantArray[input, input + 1], {input, 0, 10}]]
$termIndex = Catenate[Table[Range[0, input], {input, 0, 10}]]

$noFolds = <|"Rows" -> {}, "Costs" -> {}, "Specifications" -> {}|>

(* Terms by cost, one for each distinct list of values on the sample pairs. *)
synthesisFoldTerms[maximum_Integer, maximumConstant_Integer, deadline : (_Real | _Integer | Infinity)] :=
	synthesisClasses[
		Join[
			{{Var, $termInput}, {Idx, $termIndex}},
			Table[{Const[constant], ConstantArray[constant, Length[$termInput]]}, {constant, 0, maximumConstant}]
		],
		None, maximum, deadline, None, False, None &
	]["Expressions"]

(* A fold costs its term and one more for the choice of its kind and count:
   the rest of the loop is fixed, and the folds of the terms of one cost are
   about as many as the expressions of the next. *)
synthesisFoldProgram[{kind_String, count_, term_}] :=
	With[{loopHead = If[FreeQ[term, Idx], Iter, Rec]},
		Switch[kind,
			"Sum", loopHead[count, Const[0], Add[Acc, term]],
			"Product", loopHead[count, Const[1], Mul[Acc, term]],
			"Count", loopHead[count, Const[0], Ifz[term, Succ[Acc], Acc]]
		]
	]

(* Totals of the segments of every row: matrix[[k]] holds the values of term
   k on all pairs (n, i) laid end to end, and ends are the cumulative counts. *)
segmentTotals[matrix_List, ends_List] :=
	Module[{sums},
		sums = Join[ConstantArray[0, {Length[matrix], 1}], Transpose[Accumulate[Transpose[matrix]]], 2];
		sums[[All, Rest[ends] + 1]] - sums[[All, Most[ends] + 1]]
	]

(* Products of the segments of every row. A segment with a zero is zeroed
   first, so no partial product grows past the product itself. *)
segmentProducts[matrix_List, zeros_List, counts_List] :=
	Module[{segment, factors, columns, padding},
		padding = Length[First[matrix]] + 1;
		segment = Catenate[MapThread[ConstantArray, {Range[Length[counts]], counts}]];
		factors = Join[(1 - Unitize[zeros][[All, segment]]) matrix, ConstantArray[1, {Length[matrix], 1}], 2];
		columns = MapThread[PadRight[Range[#1 + 1, #1 + #2], Max[counts], padding] &, {Most[Prepend[Accumulate[counts], 0]], counts}];
		Fold[Times, Table[factors[[All, columns[[All, place]]]], {place, Max[counts]}]]
	]

(* A term is built from terms of lower cost, so each one costs a single array
   operation on values already known. The known values are a file-level value
   that termValues sets with Block for the time of one call: a function
   defined inside a Module would keep them alive after the call. *)
termValue[Const[constant_Integer]] := constant
termValue[term_] :=
	Lookup[$knownTermValues, Key[term], $knownTermValues[term] = Apply[Replace[Head[term], $synthesisVectorOperations], termValue /@ List @@ term]]

(* The values of all terms on the pairs (n, i), one row per term. *)
termValues[bodies_List, inputs_List, indices_List] :=
	Block[{$knownTermValues = <|Var -> inputs, Idx -> indices|>},
		(* allow QualifiedSymbol: packing has no System function, and the rows are used as one packed matrix *)
		Developer`ToPackedArray[Replace[termValue /@ bodies, scalar_Integer :> ConstantArray[scalar, Length[inputs]], {1}]]
	]

(* The folds of all terms for one count, in the order term by term: sum,
   count, product. *)
foldRows[count_?synthesisExpressionQ, counts_List, costs_List, bodies_List, indexed_List, productive_List, inputs_List, cap_Integer] :=
	Module[{pairInputs, pairIndices, values, ends, sums, zeros, fits, multiplied, products, keys, rows, specifications},
		pairInputs = Catenate[MapThread[ConstantArray, {inputs, counts}]];
		pairIndices = Catenate[Range[0, # - 1] & /@ counts];
		values = termValues[bodies, pairInputs, pairIndices];
		ends = Prepend[Accumulate[counts], 0];
		sums = segmentTotals[values, ends];
		zeros = segmentTotals[1 - Unitize[values], ends];
		(* a product is kept when every segment without a zero stays below the cap *)
		fits = UnitStep[Log[N[cap]] - (Max /@ (segmentTotals[Log[N[Clip[values, {1, Infinity}]]], ends] (1 - Unitize[zeros])))];
		multiplied = Pick[Range[Length[bodies]], fits productive, 1];
		products = If[multiplied === {}, {}, segmentProducts[values[[multiplied]], zeros[[multiplied]], counts]];
		keys = Join[3 indexed, 3 indexed + 1, 3 multiplied + 2];
		rows = Join[sums[[indexed]], zeros[[indexed]], products];
		specifications = Join[
			{"Sum", count, #} & /@ bodies[[indexed]],
			{"Count", count, #} & /@ bodies[[indexed]],
			{"Product", count, #} & /@ bodies[[multiplied]]
		];
		Transpose[{rows, Join[costs[[indexed]], costs[[indexed]], costs[[multiplied]]] + 1, specifications}][[Ordering[keys]]]
	]

foldsOfCount[count_?synthesisExpressionQ, costs_List, bodies_List, indexed_List, productive_List, inputs_List, cap_Integer] :=
	Module[{counts},
		counts = synthesisVectorValue[count, <|"Input" -> inputs|>];
		If[Total[counts] === 0, {}, foldRows[count, counts, costs, bodies, indexed, productive, inputs, cap]]
	]

distinctFolds[found_List] :=
	Module[{order, rows, keep},
		order = Ordering[found[[All, 2]]];
		rows = found[[order, 1]];
		keep = Values[PositionIndex[rows][[All, 1]]];
		<|"Rows" -> rows[[keep]], "Costs" -> found[[order[[keep]], 2]], "Specifications" -> found[[order[[keep]], 3]]|>
	]

(* Values of every fold of the terms at the inputs. terms: {{cost, term}, ...}.
   Gives the distinct rows with their costs and specifications {kind, count,
   term}; a row is kept once, for its cheapest fold. *)
synthesisFolds[{}, _List, _Integer, _Real | _Integer | Infinity] := $noFolds
synthesisFolds[terms_List, inputs_List, cap_Integer, deadline : (_Real | _Integer | Infinity)] :=
	Module[{costs, bodies, indexed, productive, found},
		costs = terms[[All, 1]];
		bodies = terms[[All, 2]];
		indexed = Select[Range[Length[bodies]], ! FreeQ[bodies[[#]], Idx] &];
		productive = Boole[! MatchQ[#, Const[0 | 1]]] & /@ bodies;
		found = Catenate[Table[
			If[AbsoluteTime[] > deadline, {}, foldsOfCount[count, costs, bodies, indexed, productive, inputs, cap]],
			{count, $foldCounts}
		]];
		found = Select[found, Max[First[#]] <= cap && ! SameQ @@ First[#] &];
		If[found === {}, $noFolds, distinctFolds[found]]
	]
