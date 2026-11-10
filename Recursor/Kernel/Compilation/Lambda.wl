PackageExported[{CompileRecursor, NormalizeRecursor}]
PackageScoped[{recursorChurchNumeral, recursorNormalizeLambda}]

CompileRecursor::usage = "CompileRecursor[p] compiles a closed Recursor program to a closed lambda term using FormalLambda, one-based de Bruijn indices and unary application."
NormalizeRecursor::usage = "NormalizeRecursor[p] normalizes the compiled function within the same resource options as EvaluateRecursor. Some functions have no normal form."

Options[NormalizeRecursor] = {"MaxSteps" -> 100000, "TimeLimit" -> 5, "MemoryLimit" -> 268435456}

(* Named intermediate terms make binding explicit. Only the final pass numbers variables. *)
function[body_Function] := With[{variable = Unique["variable"]}, abstraction[variable, body[variable]]]
call[head_, arguments__] := Fold[application, head, {arguments}]

fromIndices[index_Integer, environment_List] := Extract[environment, {index}]
fromIndices[\[FormalLambda][body_], environment_List] := function[Function[variable, fromIndices[body, Prepend[environment, variable]]]]
fromIndices[head_[argument_], environment_List] := application[fromIndices[head, environment], fromIndices[argument, environment]]

toIndices[abstraction[variable_, body_], environment_List] := \[FormalLambda][toIndices[body, Prepend[environment, variable]]]
toIndices[application[head_, argument_], environment_List] := toIndices[head, environment][toIndices[argument, environment]]
toIndices[variable_Symbol, environment_List] := First @ FirstPosition[environment, variable]

recursorChurchNumeral[n_Integer?NonNegative] := \[FormalLambda][\[FormalLambda][Nest[2[#] &, 1, n]]]
numeral[n_] := fromIndices[recursorChurchNumeral[n], {}]

combinator["Identity"] = fromIndices[\[FormalLambda][1], {}]
combinator["True"] = fromIndices[\[FormalLambda][\[FormalLambda][2]], {}]
combinator["False"] = fromIndices[\[FormalLambda][\[FormalLambda][1]], {}]
combinator["Succ"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][2[3[2][1]]]]], {}]
combinator["Add"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][\[FormalLambda][4[2][3[2][1]]]]]], {}]
combinator["Mul"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][3[2[1]]]]], {}]
combinator["Pred"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][3[\[FormalLambda][\[FormalLambda][1[2[4]]]]][\[FormalLambda][2]][\[FormalLambda][1]]]]], {}]
combinator["Pair"] = fromIndices[\[FormalLambda][\[FormalLambda][\[FormalLambda][1[3][2]]]], {}]
combinator["First"] = fromIndices[\[FormalLambda][1[\[FormalLambda][\[FormalLambda][2]]]], {}]
combinator["Second"] = fromIndices[\[FormalLambda][1[\[FormalLambda][\[FormalLambda][1]]]], {}]
combinator["Fix"] = fromIndices[\[FormalLambda][\[FormalLambda][2[1[1]]][\[FormalLambda][2[1[1]]]]], {}]
combinator["ZeroQ"] = function[Function[number, call[number, function[Function[ignored, combinator["False"]]], combinator["True"]]]]
combinator["Monus"] = function[Function[left, function[Function[right, call[right, combinator["Pred"], left]]]]]

zeroBranch[condition_, zero_, positive_] := call[combinator["ZeroQ"], condition, zero, positive]
pair[left_, right_] := call[combinator["Pair"], left, right]
first[value_] := call[combinator["First"], value]
second[value_] := call[combinator["Second"], value]
successor[value_] := call[combinator["Succ"], value]

(* n I I is I precisely when a natural-number computation finishes. This sequencing
   preserves strict arithmetic and loop state even under normal-order reduction. *)
strict[value_, body_Function] := call[function[Function[bound,
	call[bound, combinator["Identity"], combinator["Identity"], body[bound]]
]], value]

equalBranch[left_, right_, equal_, unequal_] := zeroBranch[
	call[combinator["Add"], call[combinator["Monus"], left, right], call[combinator["Monus"], right, left]], equal, unequal
]

combinator["Half"] = function[Function[number,
	first @ call[number, function[Function[state,
		pair[call[second[state], successor[first[state]], first[state]], call[second[state], combinator["False"], combinator["True"]]]
	]], pair[numeral[0], combinator["False"]]]
]]

combinator["Rem"] = function[Function[left, function[Function[right,
	zeroBranch[right, left,
		call[left, function[Function[remainder,
			zeroBranch[call[combinator["Monus"], right, successor[remainder]], numeral[0], successor[remainder]]
		]], numeral[0]]
	]
]]]]

(* The fold keeps a pair of quotient and remainder; a zero divisor gives zero. *)
combinator["Quot"] = function[Function[left, function[Function[right,
	zeroBranch[right, numeral[0],
		first @ call[left, function[Function[state,
			zeroBranch[call[combinator["Monus"], right, successor[second[state]]],
				pair[successor[first[state]], numeral[0]],
				pair[first[state], successor[second[state]]]
			]
		]], pair[numeral[0], numeral[0]]]
	]
]]]]

compile[Var, environment_] := environment["Input"]
compile[Acc, environment_] := environment["Accumulator"]
compile[Idx, environment_] := environment["Index"]
compile[Const[n_], _] := numeral[n]

compile[node : (Succ | Pred | Half)[argument_], environment_] := strict[compile[argument, environment],
	Function[value, call[combinator[SymbolName[Head[node]]], value]]
]
compile[node : (Add | Mul | Monus | Rem | Quot)[left_, right_], environment_] := strict[compile[left, environment],
	Function[firstValue, strict[compile[right, environment],
		Function[secondValue, call[combinator[SymbolName[Head[node]]], firstValue, secondValue]]
	]]
]
compile[Ifz[condition_, zero_, positive_], environment_] := strict[compile[condition, environment],
	Function[value, zeroBranch[value, compile[zero, environment], compile[positive, environment]]]
]

(* The bound value is forced before the body, including when the body ignores it. *)
compile[Let[value_, body_], environment_] := strict[compile[value, environment],
	Function[bound, compile[body, Append[environment, "Input" -> bound]]]
]

compile[Iter[count_, base_, step_], environment_] := strict[compile[count, environment],
	Function[iterations, strict[compile[base, environment], Function[initial,
		call[iterations, function[Function[accumulator, strict[accumulator,
			Function[value, compile[step, Append[environment, "Accumulator" -> value]]]
		]]], initial]
	]]]
]

compile[Rec[count_, base_, step_], environment_] := strict[compile[count, environment],
	Function[iterations, strict[compile[base, environment], Function[initial,
		second @ call[iterations, function[Function[state, strict[second[state], Function[accumulator,
			strict[compile[step, Join[environment, <|"Index" -> first[state], "Accumulator" -> accumulator|>]],
				Function[value, pair[successor[first[state]], value]]
			]
		]]]], pair[numeral[0], initial]]
	]]]
]

compile[CoRec[count_, step_], environment_] := strict[compile[count, environment], Function[lastIndex,
	call[second @ call[successor[lastIndex], function[Function[state,
		strict[first[state], Function[index,
			strict[compile[step, Join[environment, <|"Index" -> index, "History" -> second[state]|>]], Function[value,
				pair[successor[index], function[Function[query, equalBranch[query, index, value, call[second[state], query]]]]]
			]]
		]]
	]], pair[numeral[0], function[Function[query, numeral[0]]]]], lastIndex]
]]

compile[CGet[index_], environment_] := strict[compile[index, environment], Function[value, call[environment["History"], value]]]

compile[WhileLoop[base_, condition_, step_], environment_] := call[
	combinator["Fix"],
	function[Function[recur, function[Function[state, strict[state, Function[accumulator,
		With[{local = Append[environment, "Accumulator" -> accumulator]},
			strict[compile[condition, local], Function[test,
				zeroBranch[test, accumulator, call[recur, compile[step, local]]]
			]]
		]
	]]]]]],
	compile[base, environment]
]

CompileRecursor[program_?RecursorProgramQ] := toIndices[
	function[Function[input, compile[program, <|"Input" -> input|>]]], {}
]

NormalizeRecursor[program_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{
	steps = OptionValue["MaxSteps"], seconds = OptionValue["TimeLimit"], bytes = OptionValue["MemoryLimit"]
},
	ConfirmAssert[recursorBudgetQ[steps, seconds, bytes], "Invalid step, time or memory limit."];
	recursorBudget[recursorNormalizeLambda[CompileRecursor[program]], steps, seconds, bytes]
]
