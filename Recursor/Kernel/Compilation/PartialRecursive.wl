(* Structural translation of mathlib Nat.Partrec.Code. The corresponding
   compiler and simulation theorem are in Assets/Lean/Universality.lean. *)

partialCodeQ["Zero" | "Successor" | "Left" | "Right"] := True
partialCodeQ[{"Pair" | "Compose" | "Recurse", first_, second_}] := partialCodeQ[first] && partialCodeQ[second]
partialCodeQ[{"Search", body_}] := partialCodeQ[body]
partialCodeQ[_] := False

(* Translated functions read their argument from Idx. This bounded application
   retains the new argument until its final iteration, then binds Idx to it.
   The argument is strict even when the body ignores it. *)
partialCall[body_, argument_] := Rec[Succ[argument], argument, Ifz[Monus[Acc, Idx], body, Acc]]

partialPair[first_, second_] := Ifz[Monus[Succ[first], second],
	Add[Mul[second, second], first], Add[Add[Mul[first, first], first], second]
]

partialSqrt[] := WhileLoop[Const[0], Ifz[Monus[Mul[Succ[Acc], Succ[Acc]], Idx], Const[1], Const[0]], Succ[Acc]]

partialUnpair[right : (True | False)] := With[{remainder = Monus[Idx, Mul[Acc, Acc]]},
	Iter[Const[1], partialSqrt[], Ifz[Monus[Succ[remainder], Acc],
		If[right, Acc, remainder], If[right, Monus[remainder, Acc], Acc]
	]]
]

partialCompile["Zero"] := Const[0]
partialCompile["Successor"] := Succ[Idx]
partialCompile["Left"] := partialUnpair[False]
partialCompile["Right"] := partialUnpair[True]
partialCompile[{"Pair", first_, second_}] := partialPair[partialCompile[first], partialCompile[second]]
partialCompile[{"Compose", first_, second_}] := partialCall[partialCompile[first], partialCompile[second]]
partialCompile[{"Recurse", base_, body_}] := With[{
	index = partialCall[partialUnpair[False], Acc],
	value = partialCall[partialUnpair[True], Acc],
	parameter = partialCall[partialUnpair[False], Idx]
},
	partialCall[partialUnpair[True], Iter[
		partialCall[partialUnpair[True], Idx],
		partialPair[Const[0], partialCall[partialCompile[base], parameter]],
		partialPair[Succ[index], partialCall[partialCompile[body], partialPair[parameter, partialPair[index, value]]]]
	]]
]
partialCompile[{"Search", body_}] := WhileLoop[
	partialCall[partialUnpair[True], Idx],
	partialCall[partialCompile[body], partialPair[partialCall[partialUnpair[False], Idx], Acc]],
	Succ[Acc]
]

ToRecursor[code_?partialCodeQ, "PartialRecursive"] := partialCall[partialCompile[code], Var]
