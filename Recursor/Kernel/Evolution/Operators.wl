PackageExported[{RandomRecursor, MutateRecursor, CrossoverRecursor, SimplifyRecursor}]
PackageScoped[generationOptionsQ]

RandomRecursor::usage = "RandomRecursor[depth] generates a closed program with maximum syntax depth depth. MaxNodes bounds search size; IncludeWhile controls unbounded loops."
MutateRecursor::usage = "MutateRecursor[p, depth] replaces a random subtree with a scope-correct expression of at most depth levels."
CrossoverRecursor::usage = "CrossoverRecursor[a, b] replaces a subtree of a by a scope-compatible subtree of b, subject to MaxNodes."
SimplifyRecursor::usage = "SimplifyRecursor[p] simplifies a program while preserving its value and possible nontermination."

Options[RandomRecursor] = {"MaxConstant" -> 3, "MaxNodes" -> 60, "IncludeWhile" -> True}
Options[MutateRecursor] = Options[RandomRecursor]
Options[CrossoverRecursor] = {"MaxNodes" -> 60}

generate[depth_, bindings_, maximumConstant_, includeWhile_, budget_] := Module[{
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

generationOptionsQ[constant_, nodes_, loops_] := And[
	MatchQ[constant, _Integer?NonNegative], MatchQ[nodes, _Integer?Positive | Infinity], MemberQ[{True, False}, loops]
]

RandomRecursor[Optional[depth_Integer?NonNegative, 3], OptionsPattern[]] := Enclose @ With[{
	constant = OptionValue["MaxConstant"], nodes = OptionValue["MaxNodes"], loops = OptionValue["IncludeWhile"]
},
	ConfirmAssert[generationOptionsQ[constant, nodes, loops], "Invalid random-program options."];
	generate[depth, {}, constant, loops, nodes]
]

MutateRecursor[program_?RecursorProgramQ, Optional[depth_Integer?NonNegative, 3], OptionsPattern[]] := Enclose @ Module[{
	constant = OptionValue["MaxConstant"], nodes = OptionValue["MaxNodes"], loops = OptionValue["IncludeWhile"], site, budget
},
	ConfirmAssert[generationOptionsQ[constant, nodes, loops], "Invalid mutation options."];
	ConfirmAssert[RecursorNodeCount[program] <= nodes, "The parent exceeds MaxNodes."];
	site = RandomChoice[RecursorSites[program]];
	budget = nodes - RecursorNodeCount[program] + RecursorNodeCount[site["Expression"]];
	ReplaceRecursorPart[program, site["Path"], generate[depth, site["Bindings"], constant, loops, budget]]
]

CrossoverRecursor[left_?RecursorProgramQ, right_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{
	nodes = OptionValue["MaxNodes"], site, budget, donors
},
	ConfirmAssert[MatchQ[nodes, _Integer?Positive | Infinity] && RecursorNodeCount[left] <= nodes, "The parent exceeds MaxNodes, or MaxNodes is invalid."];
	site = RandomChoice[RecursorSites[left]];
	budget = nodes - RecursorNodeCount[left] + RecursorNodeCount[site["Expression"]];
	donors = Select[Lookup[RecursorSites[right], "Expression"],
		Function[donor, RecursorNodeCount[donor] <= budget && Complement[RecursorFreeVariables[donor], site["Bindings"]] === {}]
	];
	If[donors === {}, left, ReplaceRecursorPart[left, site["Path"], RandomChoice[donors]]]
]

boundedQ[expression_] := FreeQ[expression, _WhileLoop]

SimplifyRecursor[program_?RecursorProgramQ] := FixedPoint[
	ReplaceAll[{
		Succ[Const[n_]] :> Const[n + 1],
		Pred[Const[n_]] :> Const[Max[n - 1, 0]],
		Half[Const[n_]] :> Const[Quotient[n, 2]],
		Add[Const[a_], Const[b_]] :> Const[a + b],
		Mul[Const[a_], Const[b_]] :> Const[a * b],
		Monus[Const[a_], Const[b_]] :> Const[Max[a - b, 0]],
		Rem[Const[a_], Const[b_]] :> Const[If[b === 0, a, Mod[a, b]]],
		Quot[Const[a_], Const[b_]] :> Const[If[b === 0, 0, Quotient[a, b]]],
		Add[x_, Const[0]] :> x,
		Add[Const[0], x_] :> x,
		Mul[x_, Const[1]] :> x,
		Mul[Const[1], x_] :> x,
		Mul[x_?boundedQ, Const[0]] :> Const[0],
		Mul[Const[0], x_?boundedQ] :> Const[0],
		Monus[x_, Const[0]] :> x,
		Monus[x_?boundedQ, x_] :> Const[0],
		Rem[x_, Const[0]] :> x,
		Rem[x_?boundedQ, Const[1]] :> Const[0],
		Quot[x_, Const[1]] :> x,
		Quot[x_?boundedQ, Const[0]] :> Const[0],
		Let[value_, Var] :> value,
		Let[Var, body_] :> body,
		Let[value_?boundedQ, body_] /; FreeQ[body, Var] :> body,
		Ifz[Const[0], zero_, _] :> zero,
		Ifz[Const[n_Integer?Positive], _, positive_] :> positive,
		Iter[Const[0], base_, _] :> base,
		Rec[Const[0], base_, _] :> base,
		WhileLoop[base_, Const[0], _] :> base
	}],
	program
]
