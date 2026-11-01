PackageExported[ToRecursor]

ToRecursor::usage = "ToRecursor[instructions] translates increment/decrement-jump instructions to a closed Recursor program. \
Input initializes register 1; output is its final value. ToRecursor[code, \"PartialRecursive\"] translates a partial-recursive code."

instructionQ[{register_Integer?Positive, 0, {target_Integer?Positive}}, halt_] := target <= halt
instructionQ[{register_Integer?Positive, 1, {positive_Integer?Positive}, {zero_Integer?Positive}}, halt_] := Max[positive, zero] <= halt
instructionQ[_, _] := False
machineQ[instructions_List] := AllTrue[instructions, instructionQ[#, Length[instructions] + 1] &]
machineQ[_] := False

(* Quotient and prime valuation are macros in the original bounded language. *)
quotient[expression_, divisor_Integer?Positive] := Rec[expression, Const[0],
	Ifz[Rem[Succ[Idx], Const[divisor]], Succ[Acc], Acc]
]
power[base_Integer?Positive, exponent_] := Iter[exponent, Const[1], Mul[Const[base], Acc]]

increment[{register_, 0, {target_}}, radix_] := Add[Mul[Const[radix * Prime[register]], quotient[Acc, radix]], Const[target]]
increment[{register_, 1, {positive_}, {zero_}}, radix_] := With[{payload = quotient[Acc, radix], prime = Prime[register]},
	Ifz[Rem[payload, Const[prime]],
		Add[Mul[Const[radix], quotient[payload, prime]], Const[positive]],
		Add[Mul[Const[radix], payload], Const[zero]]
	]
]

dispatch[instructions_, radix_] := Fold[
	Function[{otherwise, entry}, With[{address = First[entry], instruction = Last[entry], counter = Rem[Acc, Const[radix]]},
		Ifz[Add[Monus[counter, Const[address]], Monus[Const[address], counter]], increment[instruction, radix], otherwise]
	]],
	Acc,
	Reverse @ MapIndexed[{First[#2], #1} &, instructions]
]

ToRecursor[instructions_?machineQ] := With[{
	halt = Length[instructions] + 1, radix = Length[instructions] + 2
}, {
	finalState = WhileLoop[
		Add[Mul[Const[radix], power[2, Var]], Const[1]],
		Monus[Const[halt], Rem[Acc, Const[radix]]],
		dispatch[instructions, radix]
	]
},
	(* Save the final payload at history index zero so the output decoder cannot
	   capture its accumulator or repeat the simulated machine. *)
	CoRec[Const[1], Ifz[Idx,
		quotient[finalState, radix],
		Rec[CGet[Const[0]], Const[0], Ifz[Rem[CGet[Const[0]], power[2, Succ[Idx]]], Succ[Idx], Acc]]
	]]
]
