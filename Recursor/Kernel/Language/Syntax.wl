PackageExported[{
	Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot,
	Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let,
	RecursorExpressionQ, RecursorProgramQ, RecursorFreeVariables,
	RecursorNodeCount, RecursorSites, ReplaceRecursorPart, FormatRecursor, $RecursorGrammar
}]

PackageScoped[{recursorChildren, recursorBindings, recursorRebuild, recursorSubtree}]

Var::usage = "Var denotes the input natural number of a Recursor program, or the value bound by the nearest enclosing Let."
Acc::usage = "Acc denotes the nearest enclosing accumulator, bound by Iter, Rec or WhileLoop."
Idx::usage = "Idx denotes the nearest enclosing index, bound by Rec or CoRec."
Const::usage = "Const[n] denotes the nonnegative integer n."
Succ::usage = "Succ[e] adds one to the value of e."
Pred::usage = "Pred[e] subtracts one, stopping at zero."
Half::usage = "Half[e] gives the integer quotient of e by two."
Add::usage = "Add[a, b] adds two natural numbers."
Mul::usage = "Mul[a, b] multiplies two natural numbers. Both arguments are evaluated."
Monus::usage = "Monus[a, b] gives Max[a - b, 0]. Both arguments are evaluated."
Rem::usage = "Rem[a, b] gives the remainder of a divided by b, or a when b is zero."
Quot::usage = "Quot[a, b] gives the integer quotient of a by b, or zero when b is zero. Both arguments are evaluated."
Ifz::usage = "Ifz[c, z, p] evaluates z when c is zero and p otherwise. Only the selected branch is evaluated."
Iter::usage = "Iter[count, base, step] applies step count times, binding Acc to the running value."
Rec::usage = "Rec[count, base, step] iterates with Acc and the zero-based index Idx bound in step."
CoRec::usage = "CoRec[count, step] computes indices zero through count, binding Idx and CGet in step. It does not bind Acc."
CGet::usage = "CGet[j] reads an earlier value in the nearest enclosing CoRec. Uncomputed indices give zero."
WhileLoop::usage = "WhileLoop[base, condition, step] starts at base and repeats step while condition is nonzero. Acc is bound in condition and step."
Let::usage = "Let[value, body] evaluates body with Var bound to value. Acc, Idx and CGet keep their enclosing bindings."
RecursorExpressionQ::usage = "RecursorExpressionQ[e] tests the syntax of a Recursor expression, including exact arities and natural-number constants."
RecursorProgramQ::usage = "RecursorProgramQ[p] tests whether p is a well-formed Recursor program with no unbound Acc, Idx or CGet."
RecursorFreeVariables::usage = "RecursorFreeVariables[e] lists the unbound accumulator, index and history symbols in e. Var is the program input."
RecursorNodeCount::usage = "RecursorNodeCount[e] counts syntax nodes, treating Const[n] as one node."
RecursorSites::usage = "RecursorSites[e] lists associations containing each subtree's Path, Expression and available Bindings."
ReplaceRecursorPart::usage = "ReplaceRecursorPart[p, path, e] replaces a subtree when e fits the bindings at path and the resulting program is closed."
FormatRecursor::usage = "FormatRecursor[e] gives portable Recursor source text without Wolfram context prefixes."
$RecursorGrammar::usage = "$RecursorGrammar gives each syntax head's arity. Var, Acc and Idx are atoms."

$RecursorGrammar = <|
	"Acc" -> 0, "Add" -> 2, "CGet" -> 1, "CoRec" -> 2, "Const" -> 1,
	"Half" -> 1, "Idx" -> 0, "Ifz" -> 3, "Iter" -> 3, "Let" -> 2,
	"Monus" -> 2, "Mul" -> 2, "Pred" -> 1, "Quot" -> 2, "Rec" -> 3,
	"Rem" -> 2, "Succ" -> 1, "Var" -> 0, "WhileLoop" -> 3
|>

RecursorExpressionQ[Var | Acc | Idx] := True
RecursorExpressionQ[Const[n_Integer?NonNegative]] := True
RecursorExpressionQ[e : (Succ | Pred | Half | CGet | Add | Mul | Monus | Rem | Quot | CoRec | Let | Ifz | Iter | Rec | WhileLoop)[___]] :=
	Length[e] === Lookup[$RecursorGrammar, SymbolName[Head[e]]] && AllTrue[List @@ e, RecursorExpressionQ]
RecursorExpressionQ[___] := False

RecursorProgramQ[e_] := RecursorExpressionQ[e] && RecursorFreeVariables[e] === {}
RecursorProgramQ[___] := False

recursorChildren[Var | Acc | Idx | Const[_]] := {}
recursorChildren[e_] := List @@ e

recursorBindings[_Iter, 3] := {Acc}
recursorBindings[_Rec, 3] := {Acc, Idx}
recursorBindings[_CoRec, 2] := {Idx, CGet}
recursorBindings[_WhileLoop, 2 | 3] := {Acc}
recursorBindings[_, _Integer] := {}

recursorRebuild[e_, {}] := e
recursorRebuild[e_, children_List] := Head[e] @@ children

freeVariables[Acc] := {Acc}
freeVariables[Idx] := {Idx}
freeVariables[CGet[e_]] := Union[{CGet}, freeVariables[e]]
freeVariables[e_] := Union @@ MapIndexed[
	Function[{child, position}, Complement[freeVariables[child], recursorBindings[e, First[position]]]],
	recursorChildren[e]
]

RecursorFreeVariables[e_?RecursorExpressionQ] := freeVariables[e]
RecursorNodeCount[e_?RecursorExpressionQ] := 1 + Total[RecursorNodeCount /@ recursorChildren[e]]

sites[e_, path_, bindings_] := Prepend[
	Catenate @ MapIndexed[
		Function[{child, position}, sites[child, Append[path, First[position]], Union[bindings, recursorBindings[e, First[position]]]]],
		recursorChildren[e]
	],
	<|"Path" -> path, "Expression" -> e, "Bindings" -> bindings|>
]

RecursorSites[e_?RecursorExpressionQ] := sites[e, {}, {}]

recursorSubtree[e_, {}] := e
recursorSubtree[e_, path_List] := recursorSubtree[Extract[recursorChildren[e], {First[path]}], Rest[path]]

replaceSubtree[_, {}, replacement_] := replacement
replaceSubtree[e_, path_List, replacement_] := recursorRebuild[e,
	MapIndexed[
		Function[{child, position}, If[First[position] === First[path], replaceSubtree[child, Rest[path], replacement], child]],
		recursorChildren[e]
	]
]

replacementFitsQ[program_, path_, replacement_] := With[{
	site = SelectFirst[RecursorSites[program], Lookup[#, "Path"] === path &, Missing["Path"]]
},
	AssociationQ[site] && Complement[RecursorFreeVariables[replacement], site["Bindings"]] === {}
]

ReplaceRecursorPart[program_?RecursorProgramQ, path : {___Integer}, replacement_?RecursorExpressionQ] :=
	replaceSubtree[program, path, replacement] /; replacementFitsQ[program, path, replacement]

FormatRecursor[e : Var | Acc | Idx] := SymbolName[e]
FormatRecursor[Const[n_Integer?NonNegative]] := "Const[" <> IntegerString[n] <> "]"
FormatRecursor[e_?RecursorExpressionQ] := SymbolName[Head[e]] <> "[" <> StringRiffle[FormatRecursor /@ recursorChildren[e], ", "] <> "]"

Protect[Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let]
