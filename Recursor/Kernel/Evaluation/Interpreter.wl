PackageExported[EvaluateRecursor]
PackageScoped[{recursorBudget, recursorBudgetQ, recursorTick, recursorFailure, recursorEvaluateNode, recursorLambdaEvaluate}]

EvaluateRecursor::usage = "EvaluateRecursor[program, n] evaluates a closed program on a natural number. Method is \"Interpreter\" or \"Lambda\". Resource exhaustion returns Failure."

Options[EvaluateRecursor] = {
	Method -> "Interpreter",
	"MaxSteps" -> 100000,
	"TimeLimit" -> 5,
	"MemoryLimit" -> 268435456
}

recursorFailure[tag_String] := Failure[tag, <|"MessageTemplate" -> Switch[tag,
	"StepLimit", "The evaluation step limit was reached; this does not establish nontermination.",
	"TimeLimit", "The evaluation time limit was reached; this does not establish nontermination.",
	"MemoryLimit", "The evaluation memory limit was reached.",
	_, "The evaluation could not finish."
]|>]

recursorTick[] := If[++$steps > $maximumSteps, Throw[recursorFailure["StepLimit"], $budgetTag]]

recursorBudgetQ[steps_, seconds_, bytes_] :=
	MatchQ[steps, _Integer?NonNegative | Infinity] &&
	MatchQ[seconds, _?Positive | Infinity] &&
	MatchQ[bytes, _Integer?Positive | Infinity]

SetAttributes[recursorBudget, HoldFirst]
recursorBudget[body_, steps_, seconds_, bytes_] := Block[{
	$steps = 0, $maximumSteps = steps, $budgetTag = Unique["budget"],
	$IterationLimit = Infinity, $RecursionLimit = 4096
},
	Catch[
		TimeConstrained[MemoryConstrained[body, bytes, recursorFailure["MemoryLimit"]], seconds, recursorFailure["TimeLimit"]],
		$budgetTag
	]
]

EvaluateRecursor[program_?RecursorProgramQ, input_Integer?NonNegative, OptionsPattern[]] := Enclose @ Module[{
	method = OptionValue[Method], steps = OptionValue["MaxSteps"],
	seconds = OptionValue["TimeLimit"], bytes = OptionValue["MemoryLimit"]
},
	ConfirmAssert[MemberQ[{"Interpreter", "Lambda"}, method], "Method must be Interpreter or Lambda."];
	ConfirmAssert[recursorBudgetQ[steps, seconds, bytes], "Invalid step, time or memory limit."];
	recursorBudget[
		If[method === "Interpreter",
			recursorEvaluateNode[program, <|"Input" -> input|>],
			recursorLambdaEvaluate[program, input]
		],
		steps, seconds, bytes
	]
]

recursorEvaluateNode[expression_, environment_] := (recursorTick[]; interpret[expression, environment])

interpret[Var, environment_] := environment["Input"]
interpret[Acc, environment_] := environment["Accumulator"]
interpret[Idx, environment_] := environment["Index"]
interpret[Const[value_], _] := value
interpret[Succ[e_], environment_] := recursorEvaluateNode[e, environment] + 1
interpret[Pred[e_], environment_] := Max[recursorEvaluateNode[e, environment] - 1, 0]
interpret[Half[e_], environment_] := Quotient[recursorEvaluateNode[e, environment], 2]
interpret[Add[a_, b_], environment_] := recursorEvaluateNode[a, environment] + recursorEvaluateNode[b, environment]
interpret[Mul[a_, b_], environment_] := recursorEvaluateNode[a, environment] * recursorEvaluateNode[b, environment]
interpret[Monus[a_, b_], environment_] := Max[recursorEvaluateNode[a, environment] - recursorEvaluateNode[b, environment], 0]
interpret[Rem[a_, b_], environment_] := With[{
	dividend = recursorEvaluateNode[a, environment], divisor = recursorEvaluateNode[b, environment]
},
	If[divisor === 0, dividend, Mod[dividend, divisor]]
]
interpret[Ifz[condition_, zero_, positive_], environment_] :=
	recursorEvaluateNode[If[recursorEvaluateNode[condition, environment] === 0, zero, positive], environment]

interpret[Iter[count_, base_, step_], environment_] := Module[{
	iterations = recursorEvaluateNode[count, environment], accumulator = recursorEvaluateNode[base, environment]
},
	Do[accumulator = recursorEvaluateNode[step, Append[environment, "Accumulator" -> accumulator]], {iterations}];
	accumulator
]

interpret[Rec[count_, base_, step_], environment_] := Module[{
	iterations = recursorEvaluateNode[count, environment], accumulator = recursorEvaluateNode[base, environment]
},
	Do[
		accumulator = recursorEvaluateNode[step, Join[environment, <|"Accumulator" -> accumulator, "Index" -> index|>]],
		{index, 0, iterations - 1}
	];
	accumulator
]

historyStep[step_, environment_, history_] := Append[history,
	Length[history] -> recursorEvaluateNode[step, Join[environment, <|"Index" -> Length[history], "History" -> history|>]]
]

interpret[CoRec[count_, step_], environment_] := With[{last = recursorEvaluateNode[count, environment]},
	Lookup[Nest[historyStep[step, environment, #] &, <||>, last + 1], last]
]

interpret[CGet[index_], environment_] := Lookup[environment["History"], recursorEvaluateNode[index, environment], 0]

interpret[WhileLoop[base_, condition_, step_], environment_] := Module[{
	accumulator = recursorEvaluateNode[base, environment], local
},
	local = Append[environment, "Accumulator" -> accumulator];
	While[recursorEvaluateNode[condition, local] =!= 0,
		accumulator = recursorEvaluateNode[step, local];
		local = Append[environment, "Accumulator" -> accumulator]
	];
	accumulator
]
