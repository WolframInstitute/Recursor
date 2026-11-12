(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{
	Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot,
	Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let,
	RecursorExpressionQ, RecursorProgramQ, RecursorFreeVariables,
	RecursorNodeCount, RecursorSites, ReplaceRecursorPart, FormatRecursor, $RecursorGrammar
}]

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{recursorChildren, recursorBindings, recursorRebuild, recursorSubtree}]

(* ::Section:: *)
(*Usage Messages*)

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
ReplaceRecursorPart::usage = "ReplaceRecursorPart[p, path, e] replaces a subtree when e fits the bindings at path and the resulting program is \
closed."
FormatRecursor::usage = "FormatRecursor[e] gives portable Recursor source text without Wolfram context prefixes."
$RecursorGrammar::usage = "$RecursorGrammar gives each syntax head's arity. Var, Acc and Idx are atoms."

$syntaxNode::usage = "$syntaxNode is the pattern of a value that can be a syntax node: a symbol or an expression with arguments. \
Helpers that run after RecursorExpressionQ take their expressions with it, without testing the syntax again."
recursorChildren::usage = "recursorChildren[expression] lists the subexpressions of a syntax node. An atom and a constant have none."
recursorBindings::usage = "recursorBindings[expression, position] lists the symbols among Acc, Idx and CGet that the syntax node binds in \
its child at position."
recursorRebuild::usage = "recursorRebuild[expression, children] gives the syntax node with the head of expression and the given children. \
With no children it gives expression itself."
recursorSubtree::usage = "recursorSubtree[expression, path] gives the subexpression at path, a list of child positions from the root."
freeVariables::usage = "freeVariables[expression] lists the symbols among Acc, Idx and CGet that are unbound in expression, which is \
taken to be well formed."
subtreeSites::usage = "subtreeSites[expression, path, bindings] lists the sites of expression and of its subexpressions, where expression \
is at path and has the given bindings available."
replaceSubtree::usage = "replaceSubtree[expression, path, replacement] gives expression with the subexpression at path replaced."
replacementFitsQ::usage = "replacementFitsQ[program, path, replacement] gives True when program has a subexpression at path and every \
unbound symbol of replacement is bound there."

(* ::Section:: *)
(*Function Definitions*)

(* The syntax nodes Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, CGet,
   WhileLoop and Let are data. They have no definitions and no catch-all, so that a program stays unevaluated. *)

$RecursorGrammar = <|
	"Acc" -> 0, "Add" -> 2, "CGet" -> 1, "CoRec" -> 2, "Const" -> 1,
	"Half" -> 1, "Idx" -> 0, "Ifz" -> 3, "Iter" -> 3, "Let" -> 2,
	"Monus" -> 2, "Mul" -> 2, "Pred" -> 1, "Quot" -> 2, "Rec" -> 3,
	"Rem" -> 2, "Succ" -> 1, "Var" -> 0, "WhileLoop" -> 3
|>

$syntaxNode = _Symbol | _[___]

RecursorExpressionQ[Var | Acc | Idx] := True
RecursorExpressionQ[Const[_Integer?NonNegative]] := True
RecursorExpressionQ[expression : (Succ | Pred | Half | CGet | Add | Mul | Monus | Rem | Quot | CoRec | Let | Ifz | Iter | Rec | WhileLoop)[___]] :=
	Length[expression] === Lookup[$RecursorGrammar, SymbolName[Head[expression]]] && AllTrue[List @@ expression, RecursorExpressionQ]
RecursorExpressionQ[___] := False

RecursorProgramQ[expression_?RecursorExpressionQ] := freeVariables[expression] === {}
RecursorProgramQ[___] := False

recursorChildren[Var | Acc | Idx | Const[_]] := {}
recursorChildren[expression_] := List @@ expression

recursorBindings[_Iter, 3] := {Acc}
recursorBindings[_Rec, 3] := {Acc, Idx}
recursorBindings[_CoRec, 2] := {Idx, CGet}
recursorBindings[_WhileLoop, 2 | 3] := {Acc}
recursorBindings[_, _Integer] := {}

recursorRebuild[expression : $syntaxNode, {}] := expression
recursorRebuild[expression : $syntaxNode, children_List] := Head[expression] @@ children

freeVariables[Acc] := {Acc}
freeVariables[Idx] := {Idx}
freeVariables[CGet[index_]] := Union[{CGet}, freeVariables[index]]
freeVariables[expression_] := Union @@ MapIndexed[
	Function[{child, position}, Complement[freeVariables[child], recursorBindings[expression, First[position]]]],
	recursorChildren[expression]
]

RecursorFreeVariables[expression_?RecursorExpressionQ] := freeVariables[expression]
RecursorFreeVariables[___] := invalidArgumentsFailure[RecursorFreeVariables]

RecursorNodeCount[expression_?RecursorExpressionQ] := 1 + Total[RecursorNodeCount /@ recursorChildren[expression]]
RecursorNodeCount[___] := invalidArgumentsFailure[RecursorNodeCount]

subtreeSites[expression : $syntaxNode, path_List, bindings_List] := Prepend[
	Catenate @ MapIndexed[
		Function[{child, position}, subtreeSites[child, Append[path, First[position]], Union[bindings, recursorBindings[expression, First[position]]]]],
		recursorChildren[expression]
	],
	<|"Path" -> path, "Expression" -> expression, "Bindings" -> bindings|>
]

RecursorSites[expression_?RecursorExpressionQ] := subtreeSites[expression, {}, {}]
RecursorSites[___] := invalidArgumentsFailure[RecursorSites]

recursorSubtree[expression : $syntaxNode, {}] := expression
recursorSubtree[expression : $syntaxNode, path_List] := recursorSubtree[Extract[recursorChildren[expression], {First[path]}], Rest[path]]

replaceSubtree[$syntaxNode, {}, replacement : $syntaxNode] := replacement
replaceSubtree[expression : $syntaxNode, path_List, replacement : $syntaxNode] := recursorRebuild[expression,
	MapIndexed[
		Function[{child, position}, If[First[position] === First[path], replaceSubtree[child, Rest[path], replacement], child]],
		recursorChildren[expression]
	]
]

replacementFitsQ[program : $syntaxNode, path_List, replacement : $syntaxNode] := Module[{site},
	site = SelectFirst[subtreeSites[program, {}, {}], Function[candidate, candidate["Path"] === path], Missing["Path"]];
	AssociationQ[site] && Complement[freeVariables[replacement], site["Bindings"]] === {}
]

(* A replacement that does not fit, or a path outside the program, is an invalid call: it reaches the catch-all. *)
ReplaceRecursorPart[program_?RecursorProgramQ, path : {___Integer}, replacement_?RecursorExpressionQ] :=
	replaceSubtree[program, path, replacement] /; replacementFitsQ[program, path, replacement]
ReplaceRecursorPart[___] := invalidArgumentsFailure[ReplaceRecursorPart]

FormatRecursor[atom : Var | Acc | Idx] := SymbolName[atom]
FormatRecursor[Const[value_Integer?NonNegative]] := "Const[" <> IntegerString[value] <> "]"
FormatRecursor[expression_?RecursorExpressionQ] :=
	SymbolName[Head[expression]] <> "[" <> StringRiffle[FormatRecursor /@ recursorChildren[expression], ", "] <> "]"
FormatRecursor[___] := invalidArgumentsFailure[FormatRecursor]

Protect[Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let]
