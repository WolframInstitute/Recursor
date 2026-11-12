PackageScoped[{synthesisCost, synthesisFoldTerms, synthesisFolds, synthesisFoldProgram}]

(* Sums, products and counts over a loop index. The step uses the accumulator
   in one fixed way: Add[Acc, f], Mul[Acc, f] or Ifz[f, Succ[Acc], Acc], where
   the term f is a loop-free expression in Var and Idx. Every term is evaluated
   at once on all pairs (n, i) with i below the count at n, so a family of
   loops costs a few array operations instead of one run per loop. *)

synthesisCost[Const[c_]] := synthesisConstantCost[c]
synthesisCost[Var | Acc | Idx] := 1
synthesisCost[e_] := 1 + Total[synthesisCost /@ List @@ e]

$foldCounts = {Var, Succ[Var], Pred[Var], Monus[Var, Const[2]], Half[Var]}

(* Pairs (n, i) with i <= n <= 10, on which terms are told apart. *)
$termInput = Catenate[Table[ConstantArray[n, n + 1], {n, 0, 10}]]
$termIndex = Catenate[Table[Range[0, n], {n, 0, 10}]]

(* Terms by cost, one for each distinct list of values on the sample pairs. *)
synthesisFoldTerms[maximum_Integer, maximumConstant_Integer, deadline_] := synthesisClasses[
	Join[{{Var, $termInput}, {Idx, $termIndex}}, Table[{Const[c], ConstantArray[c, Length[$termInput]]}, {c, 0, maximumConstant}]],
	None, maximum, deadline, None, False, None &
]["Expressions"]

synthesisFoldProgram[{kind_, count_, term_}] := With[{loop = If[FreeQ[term, Idx], Iter, Rec]},
	Switch[kind,
		"Sum", loop[count, Const[0], Add[Acc, term]],
		"Product", loop[count, Const[1], Mul[Acc, term]],
		"Count", loop[count, Const[0], Ifz[term, Succ[Acc], Acc]]
	]
]

(* A fold costs its term and one more for the choice of its kind and count:
   the rest of the loop is fixed, and the folds of the terms of one cost are
   about as many as the expressions of the next. *)
(* Totals of the segments of every row: matrix[[k]] holds the values of term
   k on all pairs (n, i) laid end to end, and ends are the cumulative counts. *)
segmentTotals[matrix_, ends_] := With[{sums = Join[ConstantArray[0, {Length[matrix], 1}], Transpose[Accumulate[Transpose[matrix]]], 2]},
	sums[[All, Rest[ends] + 1]] - sums[[All, Most[ends] + 1]]
]

(* Products of the segments of every row. A segment with a zero is zeroed
   first, so no partial product grows past the product itself. *)
segmentProducts[matrix_, zeros_, counts_] := Module[{segment, factors, slots, last = Length[First[matrix]] + 1},
	segment = Catenate[MapThread[ConstantArray, {Range[Length[counts]], counts}]];
	factors = Join[(1 - Unitize[zeros][[All, segment]]) matrix, ConstantArray[1, {Length[matrix], 1}], 2];
	slots = MapThread[PadRight[Range[#1 + 1, #1 + #2], Max[counts], last] &, {Most[Prepend[Accumulate[counts], 0]], counts}];
	Fold[Times, Table[factors[[All, slots[[All, m]]]], {m, Max[counts]}]]
]

(* The values of all terms on the pairs (n, i), one row per term. A term is
   built from terms of lower cost, so each one costs a single array operation
   on values already known. *)
termValues[bodies_, n_, index_] := Module[{known = <|Var -> n, Idx -> index|>, value, rows},
	value[Const[c_]] := c;
	value[term_] := Lookup[known, Key[term], known[term] = (Head[term] /. $synthesisVectorOperations) @@ (value /@ List @@ term)];
	rows = Developer`ToPackedArray[Replace[value /@ bodies, scalar_Integer :> ConstantArray[scalar, Length[n]], {1}]];
	Remove[value];
	rows
]

(* The folds of all terms for one count, in the order term by term: sum,
   count, product. *)
foldsOfCount[count_, costs_, bodies_, indexed_, productive_, inputs_, cap_] := Module[{
	counts = synthesisVectorValue[count, <|"Input" -> inputs|>], n, index, values, ends, sums, zeros, fits, multiplied, products, keys, rows
},
	If[Total[counts] === 0, Return[{}]];
	n = Catenate[MapThread[ConstantArray, {inputs, counts}]];
	index = Catenate[Range[0, # - 1] & /@ counts];
	values = termValues[bodies, n, index];
	ends = Prepend[Accumulate[counts], 0];
	sums = segmentTotals[values, ends];
	zeros = segmentTotals[1 - Unitize[values], ends];
	(* a product is kept when every segment without a zero stays below the cap *)
	fits = UnitStep[Log[N[cap]] - (Max /@ (segmentTotals[Log[N[Clip[values, {1, Infinity}]]], ends] (1 - Unitize[zeros])))];
	multiplied = Pick[Range[Length[bodies]], fits productive, 1];
	products = If[multiplied === {}, {}, segmentProducts[values[[multiplied]], zeros[[multiplied]], counts]];
	keys = Join[3 indexed, 3 indexed + 1, 3 multiplied + 2];
	rows = Join[sums[[indexed]], zeros[[indexed]], products];
	Transpose[{
		rows,
		Join[costs[[indexed]], costs[[indexed]], costs[[multiplied]]] + 1,
		Join[{"Sum", count, #} & /@ bodies[[indexed]], {"Count", count, #} & /@ bodies[[indexed]], {"Product", count, #} & /@ bodies[[multiplied]]]
	}][[Ordering[keys]]]
]

(* Values of every fold of the terms at the inputs. terms: {{cost, term}, ...}.
   Gives the distinct rows with their costs and specifications {kind, count,
   term}; a row is kept once, for its cheapest fold. *)
synthesisFolds[terms_List, inputs_List, cap_, deadline_] := Module[{
	costs = terms[[All, 1]], bodies = terms[[All, 2]], indexed, productive, found, order, rows, keep,
	none = <|"Rows" -> {}, "Costs" -> {}, "Specifications" -> {}|>
},
	If[terms === {}, Return[none]];
	indexed = Select[Range[Length[bodies]], ! FreeQ[bodies[[#]], Idx] &];
	productive = Boole[! MatchQ[#, Const[0 | 1]]] & /@ bodies;
	found = Catenate[Table[
		If[AbsoluteTime[] > deadline, {}, foldsOfCount[count, costs, bodies, indexed, productive, inputs, cap]],
		{count, $foldCounts}
	]];
	found = Select[found, Max[First[#]] <= cap && ! SameQ @@ First[#] &];
	If[found === {}, Return[none]];
	order = Ordering[found[[All, 2]]];
	rows = found[[order, 1]];
	keep = Values[PositionIndex[rows][[All, 1]]];
	<|"Rows" -> rows[[keep]], "Costs" -> found[[order[[keep]], 2]], "Specifications" -> found[[order[[keep]], 3]]|>
]
