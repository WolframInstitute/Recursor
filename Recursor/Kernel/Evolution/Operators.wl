(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{RandomRecursor, MutateRecursor, CrossoverRecursor, SimplifyRecursor}]

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[generationOptionsQ]

(* ::Section:: *)
(*Usage Messages*)

RandomRecursor::usage = "RandomRecursor[depth] generates a closed program with maximum syntax depth depth. MaxNodes bounds search size; IncludeWhile \
controls unbounded loops.\n\
RandomRecursor[] uses the depth 3."
MutateRecursor::usage = "MutateRecursor[program, depth] replaces a random subtree with a scope-correct expression of at most depth levels.\n\
MutateRecursor[program] uses the depth 3."
CrossoverRecursor::usage = "CrossoverRecursor[left, right] replaces a subtree of left by a scope-compatible subtree of right, subject to MaxNodes."
SimplifyRecursor::usage = "SimplifyRecursor[program] simplifies a program while preserving its value and possible nontermination."

generationOptionsQ::usage = "generationOptionsQ[maximumConstant, maximumNodes, includeWhile] gives True when the three values are valid settings \
of the options \"MaxConstant\", \"MaxNodes\" and \"IncludeWhile\": a nonnegative integer, a positive integer or Infinity, and True or False."
generate::usage = "generate[depth, bindings, maximumConstant, includeWhile, budget] gives a random expression of at most depth levels and budget \
nodes whose free variables are among bindings. Its constants are at most maximumConstant, and it has a WhileLoop only when includeWhile is True."

(* ::Section:: *)
(*Options*)

Options[RandomRecursor] = {"MaxConstant" -> 3, "MaxNodes" -> 60, "IncludeWhile" -> True}
Options[MutateRecursor] = Options[RandomRecursor]
Options[CrossoverRecursor] = {"MaxNodes" -> 60}

(* ::Section:: *)
(*Function Definitions*)

(* The order of the random draws is part of the result of a seeded search: leaves, then the choice between a leaf
   and an operator, then the operator, then the arguments from left to right. *)
generate[depth_Integer, bindings_List, maximumConstant_Integer, includeWhile : True | False, budget : _Integer | Infinity] := Module[{
	leaves, operators, operator, arity, template
},
	leaves = Join[{Var, Const[RandomInteger[maximumConstant]]}, Intersection[bindings, {Acc, Idx}]];
	If[depth === 0 || budget === 1 || RandomReal[] < 0.3,
		RandomChoice[leaves],
		operators = Join[{Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, Let},
			If[MemberQ[bindings, CGet], {CGet}, {}], If[includeWhile, {WhileLoop}, {}]];
		operators = Select[operators, Lookup[$RecursorGrammar, SymbolName[#]] < budget &];
		operator = RandomChoice[operators];
		arity = Lookup[$RecursorGrammar, SymbolName[operator]];
		template = operator @@ ConstantArray[Var, arity];
		operator @@ Table[
			generate[depth - 1, Union[bindings, recursorBindings[template, index]], maximumConstant, includeWhile, Floor[(budget - 1) / arity]],
			{index, arity}
		]
	]
]

generationOptionsQ[_Integer?NonNegative, _Integer?Positive | Infinity, True | False] := True
generationOptionsQ[___] := False

RandomRecursor[depth_Integer?NonNegative, OptionsPattern[]] := Enclose @ Module[{
	maximumConstant = OptionValue["MaxConstant"], maximumNodes = OptionValue["MaxNodes"], includeWhile = OptionValue["IncludeWhile"]
},
	ConfirmAssert[generationOptionsQ[maximumConstant, maximumNodes, includeWhile], "Invalid random-program options."];
	generate[depth, {}, maximumConstant, includeWhile, maximumNodes]
]
RandomRecursor[opts : OptionsPattern[]] := RandomRecursor[3, opts]
RandomRecursor[___] := invalidArgumentsFailure[RandomRecursor]

MutateRecursor[program_?RecursorProgramQ, depth_Integer?NonNegative, OptionsPattern[]] := Enclose @ Module[{
	maximumConstant = OptionValue["MaxConstant"], maximumNodes = OptionValue["MaxNodes"], includeWhile = OptionValue["IncludeWhile"], site, budget
},
	ConfirmAssert[generationOptionsQ[maximumConstant, maximumNodes, includeWhile], "Invalid mutation options."];
	ConfirmAssert[RecursorNodeCount[program] <= maximumNodes, "The parent exceeds MaxNodes."];
	site = RandomChoice[RecursorSites[program]];
	budget = maximumNodes - RecursorNodeCount[program] + RecursorNodeCount[site["Expression"]];
	ReplaceRecursorPart[program, site["Path"], generate[depth, site["Bindings"], maximumConstant, includeWhile, budget]]
]
MutateRecursor[program_?RecursorProgramQ, opts : OptionsPattern[]] := MutateRecursor[program, 3, opts]
MutateRecursor[___] := invalidArgumentsFailure[MutateRecursor]

CrossoverRecursor[left_?RecursorProgramQ, right_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{
	maximumNodes = OptionValue["MaxNodes"], site, budget, donors
},
	ConfirmAssert[
		MatchQ[maximumNodes, _Integer?Positive | Infinity] && RecursorNodeCount[left] <= maximumNodes,
		"The parent exceeds MaxNodes, or MaxNodes is invalid."
	];
	site = RandomChoice[RecursorSites[left]];
	budget = maximumNodes - RecursorNodeCount[left] + RecursorNodeCount[site["Expression"]];
	donors = Select[Lookup[RecursorSites[right], "Expression"],
		Function[donor, RecursorNodeCount[donor] <= budget && Complement[RecursorFreeVariables[donor], site["Bindings"]] === {}]
	];
	If[donors === {}, left, ReplaceRecursorPart[left, site["Path"], RandomChoice[donors]]]
]
CrossoverRecursor[___] := invalidArgumentsFailure[CrossoverRecursor]

(* An operand with a WhileLoop may not end, so a rule that drops an operand asks that it has none: FreeQ[_WhileLoop]. *)
SimplifyRecursor[program_?RecursorProgramQ] := FixedPoint[
	ReplaceAll[{
		Succ[Const[value_]] :> Const[value + 1],
		Pred[Const[value_]] :> Const[Max[value - 1, 0]],
		Half[Const[value_]] :> Const[Quotient[value, 2]],
		Add[Const[left_], Const[right_]] :> Const[left + right],
		Mul[Const[left_], Const[right_]] :> Const[left * right],
		Monus[Const[left_], Const[right_]] :> Const[Max[left - right, 0]],
		Rem[Const[left_], Const[right_]] :> Const[If[right === 0, left, Mod[left, right]]],
		Quot[Const[left_], Const[right_]] :> Const[If[right === 0, 0, Quotient[left, right]]],
		Add[operand_, Const[0]] :> operand,
		Add[Const[0], operand_] :> operand,
		Mul[operand_, Const[1]] :> operand,
		Mul[Const[1], operand_] :> operand,
		Mul[_?(FreeQ[_WhileLoop]), Const[0]] :> Const[0],
		Mul[Const[0], _?(FreeQ[_WhileLoop])] :> Const[0],
		Monus[operand_, Const[0]] :> operand,
		Monus[operand_?(FreeQ[_WhileLoop]), operand_] :> Const[0],
		Rem[operand_, Const[0]] :> operand,
		Rem[_?(FreeQ[_WhileLoop]), Const[1]] :> Const[0],
		Quot[operand_, Const[1]] :> operand,
		Quot[_?(FreeQ[_WhileLoop]), Const[0]] :> Const[0],
		Let[value_, Var] :> value,
		Let[Var, body_] :> body,
		Let[_?(FreeQ[_WhileLoop]), body_] /; FreeQ[body, Var] :> body,
		Ifz[Const[0], zero_, _] :> zero,
		Ifz[Const[_Integer?Positive], _, positive_] :> positive,
		Iter[Const[0], base_, _] :> base,
		Rec[Const[0], base_, _] :> base,
		WhileLoop[base_, Const[0], _] :> base
	}],
	program
]
SimplifyRecursor[___] := invalidArgumentsFailure[SimplifyRecursor]
