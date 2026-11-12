(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{CompileRecursor, NormalizeRecursor}]

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{recursorChurchNumeral, recursorNormalizeLambda}]

(* ::Section:: *)
(*Usage Messages*)

CompileRecursor::usage = "CompileRecursor[p] compiles a closed Recursor program to a closed lambda term using FormalLambda, one-based de Bruijn \
indices and unary application."

NormalizeRecursor::usage = "NormalizeRecursor[p] normalizes the compiled function within the same resource options as EvaluateRecursor. Some \
functions have no normal form."

recursorChurchNumeral::usage = "recursorChurchNumeral[count] gives the Church numeral of the natural number count as a lambda term with de Bruijn indices."

namedTermQ::usage = "namedTermQ[term] gives True when term is a lambda term with named variables: a variable symbol, abstraction[variable, body] \
or application[head, argument], and False otherwise."

namedLambda::usage = "namedLambda[body] gives the named abstraction of a new variable over body[variable], where body is a Function."

curriedCall::usage = "curriedCall[head, argument1, argument2, ...] gives the named term that applies head to the arguments one at a time."

fromIndices::usage = "fromIndices[term, environment] gives the named term of a lambda term with de Bruijn indices. environment lists the \
variables of the enclosing abstractions, innermost first."

toIndices::usage = "toIndices[term, environment] gives the lambda term with de Bruijn indices of a named term. environment lists the \
variables of the enclosing abstractions, innermost first."

namedNumeral::usage = "namedNumeral[count] gives the Church numeral of the natural number count as a named term."

lambdaCombinator::usage = "lambdaCombinator[name] gives the closed named term of a combinator: \"Identity\", \"True\", \"False\", \"Succ\", \"Add\", \
\"Mul\", \"Pred\", \"Pair\", \"First\", \"Second\", \"Fix\", \"ZeroQ\", \"Monus\", \"Half\", \"Rem\" or \"Quot\"."

zeroBranch::usage = "zeroBranch[condition, zero, positive] gives the named term that reduces to zero when the numeral condition is zero and to \
positive otherwise."

churchPair::usage = "churchPair[left, right] gives the named term of the pair of left and right."

pairFirst::usage = "pairFirst[value] gives the named term of the first component of the pair value."

pairSecond::usage = "pairSecond[value] gives the named term of the second component of the pair value."

churchSuccessor::usage = "churchSuccessor[value] gives the named term of the successor of the numeral value."

strictBind::usage = "strictBind[value, body] gives the named term that reduces the numeral value to its end and then continues as body[bound], \
where body is a Function and bound is a variable that holds the numeral."

equalBranch::usage = "equalBranch[left, right, equal, unequal] gives the named term that reduces to equal when the numerals left and right are \
the same and to unequal otherwise."

compileNode::usage = "compileNode[expression, environment] gives the named term of a Recursor expression. environment gives the terms bound to \
\"Input\", \"Accumulator\", \"Index\" and \"History\"."

(* ::Section:: *)
(*Function Definitions*)

Options[NormalizeRecursor] = {"MaxSteps" -> 100000, "TimeLimit" -> 5, "MemoryLimit" -> 268435456}

namedTermQ[_Symbol | _abstraction | _application] := True
namedTermQ[___] := False

(* Named intermediate terms make binding explicit. Only the final pass numbers variables. *)
namedLambda[body_Function] := With[{variable = Unique["variable"]}, abstraction[variable, body[variable]]]

curriedCall[head_?namedTermQ, arguments__?namedTermQ] := Fold[application, head, {arguments}]

fromIndices[index_Integer, environment_List] := Extract[environment, {index}]
fromIndices[\[FormalLambda][body_], environment_List] := namedLambda[Function[variable, fromIndices[body, Prepend[environment, variable]]]]
fromIndices[head_[argument_], environment_List] := application[fromIndices[head, environment], fromIndices[argument, environment]]

toIndices[abstraction[variable_, body_], environment_List] := \[FormalLambda][toIndices[body, Prepend[environment, variable]]]
toIndices[application[head_, argument_], environment_List] := toIndices[head, environment][toIndices[argument, environment]]
toIndices[variable_Symbol, environment_List] := First @ FirstPosition[environment, variable]

recursorChurchNumeral[count_Integer?NonNegative] := \[FormalLambda][\[FormalLambda][Nest[2[#] &, 1, count]]]

namedNumeral[count_Integer?NonNegative] := fromIndices[recursorChurchNumeral[count], {}]

lambdaCombinator["Identity"] = fromIndices[\[FormalLambda][1], {}]
lambdaCombinator["True"] = fromIndices[\[FormalLambda][\[FormalLambda][2]], {}]
lambdaCombinator["False"] = fromIndices[\[FormalLambda][\[FormalLambda][1]], {}]
lambdaCombinator["Succ"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][2[3[2][1]]]]], {}]
lambdaCombinator["Add"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][\[FormalLambda][4[2][3[2][1]]]]]], {}]
lambdaCombinator["Mul"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][3[2[1]]]]], {}]
lambdaCombinator["Pred"] = fromIndices[
	\[FormalLambda][\[FormalLambda][\[FormalLambda][3[\[FormalLambda][\[FormalLambda][1[2[4]]]]][\[FormalLambda][2]][\[FormalLambda][1]]]]],
	{}
]
lambdaCombinator["Pair"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][1[3][2]]]], {}]
lambdaCombinator["First"] = fromIndices[\[FormalLambda][1[\[FormalLambda][\[FormalLambda][2]]]], {}]
lambdaCombinator["Second"] = fromIndices[\[FormalLambda][1[\[FormalLambda][\[FormalLambda][1]]]], {}]
lambdaCombinator["Fix"] = fromIndices[\[FormalLambda][\[FormalLambda][2[1[1]]][\[FormalLambda][2[1[1]]]]], {}]
lambdaCombinator["ZeroQ"] = namedLambda[
	Function[number, curriedCall[number, namedLambda[Function[ignored, lambdaCombinator["False"]]], lambdaCombinator["True"]]]
]
lambdaCombinator["Monus"] = namedLambda[Function[left, namedLambda[Function[right, curriedCall[right, lambdaCombinator["Pred"], left]]]]]

zeroBranch[condition_?namedTermQ, zero_?namedTermQ, positive_?namedTermQ] := curriedCall[lambdaCombinator["ZeroQ"], condition, zero, positive]

churchPair[left_?namedTermQ, right_?namedTermQ] := curriedCall[lambdaCombinator["Pair"], left, right]

pairFirst[value_?namedTermQ] := curriedCall[lambdaCombinator["First"], value]

pairSecond[value_?namedTermQ] := curriedCall[lambdaCombinator["Second"], value]

churchSuccessor[value_?namedTermQ] := curriedCall[lambdaCombinator["Succ"], value]

(* n I I is I precisely when a natural-number computation finishes. This sequencing
   preserves strict arithmetic and loop state even under normal-order reduction. *)
strictBind[value_?namedTermQ, body_Function] := curriedCall[
	namedLambda[Function[bound, curriedCall[bound, lambdaCombinator["Identity"], lambdaCombinator["Identity"], body[bound]]]],
	value
]

equalBranch[left_?namedTermQ, right_?namedTermQ, equal_?namedTermQ, unequal_?namedTermQ] := zeroBranch[
	curriedCall[lambdaCombinator["Add"], curriedCall[lambdaCombinator["Monus"], left, right], curriedCall[lambdaCombinator["Monus"], right, left]],
	equal,
	unequal
]

lambdaCombinator["Half"] = namedLambda[Function[number,
	pairFirst @ curriedCall[
		number,
		namedLambda[Function[state,
			churchPair[
				curriedCall[pairSecond[state], churchSuccessor[pairFirst[state]], pairFirst[state]],
				curriedCall[pairSecond[state], lambdaCombinator["False"], lambdaCombinator["True"]]
			]
		]],
		churchPair[namedNumeral[0], lambdaCombinator["False"]]
	]
]]

lambdaCombinator["Rem"] = namedLambda[Function[left, namedLambda[Function[right,
	zeroBranch[right, left,
		curriedCall[left, namedLambda[Function[remainder,
			zeroBranch[curriedCall[lambdaCombinator["Monus"], right, churchSuccessor[remainder]], namedNumeral[0], churchSuccessor[remainder]]
		]], namedNumeral[0]]
	]
]]]]

(* The fold keeps a pair of quotient and remainder; a zero divisor gives zero. *)
lambdaCombinator["Quot"] = namedLambda[Function[left, namedLambda[Function[right,
	zeroBranch[right, namedNumeral[0],
		pairFirst @ curriedCall[left, namedLambda[Function[state,
			zeroBranch[curriedCall[lambdaCombinator["Monus"], right, churchSuccessor[pairSecond[state]]],
				churchPair[churchSuccessor[pairFirst[state]], namedNumeral[0]],
				churchPair[pairFirst[state], churchSuccessor[pairSecond[state]]]
			]
		]], churchPair[namedNumeral[0], namedNumeral[0]]]
	]
]]]]

compileNode[Var, environment_Association] := environment["Input"]
compileNode[Acc, environment_Association] := environment["Accumulator"]
compileNode[Idx, environment_Association] := environment["Index"]
compileNode[Const[count_], _Association] := namedNumeral[count]

compileNode[node : (Succ | Pred | Half)[argument_], environment_Association] := strictBind[compileNode[argument, environment],
	Function[value, curriedCall[lambdaCombinator[SymbolName[Head[node]]], value]]
]
compileNode[node : (Add | Mul | Monus | Rem | Quot)[left_, right_], environment_Association] := strictBind[compileNode[left, environment],
	Function[firstValue, strictBind[compileNode[right, environment],
		Function[secondValue, curriedCall[lambdaCombinator[SymbolName[Head[node]]], firstValue, secondValue]]
	]]
]
compileNode[Ifz[condition_, zero_, positive_], environment_Association] := strictBind[compileNode[condition, environment],
	Function[value, zeroBranch[value, compileNode[zero, environment], compileNode[positive, environment]]]
]

(* The bound value is forced before the body, including when the body ignores it. *)
compileNode[Let[value_, body_], environment_Association] := strictBind[compileNode[value, environment],
	Function[bound, compileNode[body, Append[environment, "Input" -> bound]]]
]

compileNode[Iter[count_, base_, step_], environment_Association] := strictBind[compileNode[count, environment],
	Function[iterations, strictBind[compileNode[base, environment], Function[initial,
		curriedCall[iterations, namedLambda[Function[accumulator, strictBind[accumulator,
			Function[value, compileNode[step, Append[environment, "Accumulator" -> value]]]
		]]], initial]
	]]]
]

compileNode[Rec[count_, base_, step_], environment_Association] := strictBind[compileNode[count, environment],
	Function[iterations, strictBind[compileNode[base, environment], Function[initial,
		pairSecond @ curriedCall[iterations, namedLambda[Function[state, strictBind[pairSecond[state], Function[accumulator,
			strictBind[compileNode[step, Join[environment, <|"Index" -> pairFirst[state], "Accumulator" -> accumulator|>]],
				Function[value, churchPair[churchSuccessor[pairFirst[state]], value]]
			]
		]]]], churchPair[namedNumeral[0], initial]]
	]]]
]

compileNode[CoRec[count_, step_], environment_Association] := strictBind[compileNode[count, environment], Function[lastIndex,
	curriedCall[pairSecond @ curriedCall[churchSuccessor[lastIndex], namedLambda[Function[state,
		strictBind[pairFirst[state], Function[index,
			strictBind[compileNode[step, Join[environment, <|"Index" -> index, "History" -> pairSecond[state]|>]], Function[value,
				churchPair[
					churchSuccessor[index],
					namedLambda[Function[query, equalBranch[query, index, value, curriedCall[pairSecond[state], query]]]]
				]
			]]
		]]
	]], churchPair[namedNumeral[0], namedLambda[Function[query, namedNumeral[0]]]]], lastIndex]
]]

compileNode[CGet[index_], environment_Association] := strictBind[
	compileNode[index, environment],
	Function[value, curriedCall[environment["History"], value]]
]

compileNode[WhileLoop[base_, condition_, step_], environment_Association] := curriedCall[
	lambdaCombinator["Fix"],
	namedLambda[Function[recur, namedLambda[Function[state, strictBind[state, Function[accumulator,
		strictBind[compileNode[condition, Append[environment, "Accumulator" -> accumulator]], Function[test,
			zeroBranch[test, accumulator, curriedCall[recur, compileNode[step, Append[environment, "Accumulator" -> accumulator]]]]
		]]
	]]]]]],
	compileNode[base, environment]
]

CompileRecursor[program_?RecursorProgramQ] := toIndices[
	namedLambda[Function[input, compileNode[program, <|"Input" -> input|>]]], {}
]
CompileRecursor[___] := invalidArgumentsFailure[CompileRecursor]

NormalizeRecursor[program_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{steps, seconds, bytes},
	steps = OptionValue["MaxSteps"];
	seconds = OptionValue["TimeLimit"];
	bytes = OptionValue["MemoryLimit"];
	ConfirmAssert[recursorBudgetQ[steps, seconds, bytes], "Invalid step, time or memory limit."];
	recursorBudget[recursorNormalizeLambda[CompileRecursor[program]], steps, seconds, bytes]
]
NormalizeRecursor[___] := invalidArgumentsFailure[NormalizeRecursor]
