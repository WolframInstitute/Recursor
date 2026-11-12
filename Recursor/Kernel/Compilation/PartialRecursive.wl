(* ::Package:: *)

(* Structural translation of mathlib Nat.Partrec.Code. The corresponding
   compiler and simulation theorem are in Assets/Lean/Universality.lean. *)

(* ::Section:: *)
(*Usage Messages*)

partialCodeQ::usage = "partialCodeQ[code] gives True when code is a partial-recursive code: \"Zero\", \"Successor\", \"Left\", \"Right\", \
{\"Pair\", code1, code2}, {\"Compose\", code1, code2}, {\"Recurse\", code1, code2} or {\"Search\", code1}, and False otherwise."

syntaxNodeQ::usage = "syntaxNodeQ[expression] gives True when expression is Var, Acc, Idx or has the head of a Recursor syntax node, and False \
otherwise. It does not look inside, so that building a program from parts stays linear in its size."

partialCall::usage = "partialCall[body, argument] gives a Recursor expression that evaluates body with Idx bound to the value of argument. \
The argument is evaluated even when body ignores it."

partialPair::usage = "partialPair[left, right] gives a Recursor expression for the pairing function of mathlib, Nat.pair, at the values of left and right."

partialSquareRoot::usage = "partialSquareRoot[] gives a Recursor expression for the integer square root of Idx."

partialUnpair::usage = "partialUnpair[rightQ] gives a Recursor expression for one component of the pair that Idx encodes: the right one when rightQ \
is True and the left one when it is False."

partialCompile::usage = "partialCompile[code] gives a Recursor expression that reads its argument from Idx and has the value of the \
partial-recursive code at that argument."

(* ::Section:: *)
(*Function Definitions*)

partialCodeQ["Zero" | "Successor" | "Left" | "Right"] := True
partialCodeQ[{"Pair" | "Compose" | "Recurse", firstCode_, secondCode_}] := partialCodeQ[firstCode] && partialCodeQ[secondCode]
partialCodeQ[{"Search", body_}] := partialCodeQ[body]
partialCodeQ[___] := False

syntaxNodeQ[Var | Acc | Idx] := True
syntaxNodeQ[_Const | _Succ | _Pred | _Half | _Add | _Mul | _Monus | _Rem | _Quot | _Ifz | _Iter | _Rec | _CoRec | _CGet | _WhileLoop | _Let] := True
syntaxNodeQ[___] := False

(* Translated functions read their argument from Idx. This bounded application
   retains the new argument until its final iteration, then binds Idx to it.
   The argument is strict even when the body ignores it. *)
partialCall[body_?syntaxNodeQ, argument_?syntaxNodeQ] := Rec[Succ[argument], argument, Ifz[Monus[Acc, Idx], body, Acc]]

partialPair[left_?syntaxNodeQ, right_?syntaxNodeQ] := Ifz[Monus[Succ[left], right],
	Add[Mul[right, right], left], Add[Add[Mul[left, left], left], right]
]

partialSquareRoot[] := WhileLoop[Const[0], Ifz[Monus[Mul[Succ[Acc], Succ[Acc]], Idx], Const[1], Const[0]], Succ[Acc]]

partialUnpair[rightQ : (True | False)] := With[{excess = Monus[Idx, Mul[Acc, Acc]]},
	Iter[Const[1], partialSquareRoot[], Ifz[Monus[Succ[excess], Acc],
		If[rightQ, Acc, excess], If[rightQ, Monus[excess, Acc], Acc]
	]]
]

partialCompile["Zero"] := Const[0]
partialCompile["Successor"] := Succ[Idx]
partialCompile["Left"] := partialUnpair[False]
partialCompile["Right"] := partialUnpair[True]
partialCompile[{"Pair", firstCode_, secondCode_}] := partialPair[partialCompile[firstCode], partialCompile[secondCode]]
partialCompile[{"Compose", outerCode_, innerCode_}] := partialCall[partialCompile[outerCode], partialCompile[innerCode]]
partialCompile[{"Recurse", base_, body_}] :=
	Module[{index, value, parameter},
		index = partialCall[partialUnpair[False], Acc];
		value = partialCall[partialUnpair[True], Acc];
		parameter = partialCall[partialUnpair[False], Idx];
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

ToRecursor[partialCode_?partialCodeQ, "PartialRecursive"] := partialCall[partialCompile[partialCode], Var]

(* The same catch-all ends CounterMachines.wl; whichever file loads last, it stays the least specific definition. *)
ToRecursor[___] := invalidArgumentsFailure[ToRecursor]
