(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[EvaluateRecursor]

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{recursorBudget, recursorBudgetQ, recursorTick, recursorFailure, recursorEvaluateNode, recursorLambdaEvaluate}]

(* ::Section:: *)
(*Usage Messages*)

EvaluateRecursor::usage = "EvaluateRecursor[program, n] evaluates a closed program on a natural number. Method is \"Interpreter\" or \"Lambda\". \
Resource exhaustion returns Failure."

recursorFailure::usage = "recursorFailure[tag] gives the Failure with which an evaluation stops, such as the one with the tag \"StepLimit\", \
\"TimeLimit\" or \"MemoryLimit\"."
recursorTick::usage = "recursorTick[] counts one evaluation step. Past the step limit of the enclosing recursorBudget it throws the \
\"StepLimit\" Failure to that budget."
recursorBudgetQ::usage = "recursorBudgetQ[steps, seconds, bytes] gives True when the three values are valid limits: a nonnegative integer \
or Infinity steps, a positive number or Infinity seconds, and a positive integer or Infinity bytes."
recursorBudget::usage = "recursorBudget[body, steps, seconds, bytes] evaluates body within the three limits and gives its value, or the \
Failure of the limit that was reached. body is held, and its steps are those that recursorTick counts."
recursorEvaluateNode::usage = "recursorEvaluateNode[expression, environment] counts one step and gives the value of a syntax node in an \
environment, an association with the keys \"Input\", \"Accumulator\", \"Index\" and \"History\" for the bindings in scope."
interpret::usage = "interpret[expression, environment] gives the value of a syntax node in an environment. Its subexpressions are evaluated \
through recursorEvaluateNode, so each node costs one step."
historyStep::usage = "historyStep[step, environment, history] gives the history of a CoRec with the value of step at the next index added."
$steps::usage = "$steps is the number of steps counted in the current recursorBudget."
$maximumSteps::usage = "$maximumSteps is the step limit of the current recursorBudget."
$budgetTag::usage = "$budgetTag is the tag with which recursorTick throws to the current recursorBudget."

(* ::Section:: *)
(*Options*)

Options[EvaluateRecursor] = {
	Method -> "Interpreter",
	"MaxSteps" -> 100000,
	"TimeLimit" -> 5,
	"MemoryLimit" -> 268435456
}

(* ::Section:: *)
(*Function Definitions*)

recursorFailure[tag_String] := Failure[tag, <|"MessageTemplate" -> Switch[tag,
	"StepLimit", "The evaluation step limit was reached; this does not establish nontermination.",
	"TimeLimit", "The evaluation time limit was reached; this does not establish nontermination.",
	"MemoryLimit", "The evaluation memory limit was reached.",
	_, "The evaluation could not finish."
]|>]

recursorTick[] := If[++$steps > $maximumSteps, Throw[recursorFailure["StepLimit"], $budgetTag]]

recursorBudgetQ[_Integer?NonNegative | Infinity, _?Positive | Infinity, _Integer?Positive | Infinity] := True
recursorBudgetQ[___] := False

SetAttributes[recursorBudget, HoldFirst]
(* allow BarePattern: body is held code, and the callers have checked the limits with recursorBudgetQ *)
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
EvaluateRecursor[___] := invalidArgumentsFailure[EvaluateRecursor]

(* The definitions below are the step loop of every search. They take their arguments unchecked: EvaluateRecursor
   has tested the program, and a pattern test here would run once for each node evaluated. *)

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
recursorEvaluateNode[expression_, environment_] := (
	recursorTick[];
	interpret[expression, environment]
)

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Var, environment_] := environment["Input"]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Acc, environment_] := environment["Accumulator"]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Idx, environment_] := environment["Index"]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Const[value_], _] := value
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Succ[operand_], environment_] := recursorEvaluateNode[operand, environment] + 1
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Pred[operand_], environment_] := Max[recursorEvaluateNode[operand, environment] - 1, 0]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Half[operand_], environment_] := Quotient[recursorEvaluateNode[operand, environment], 2]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Add[left_, right_], environment_] := recursorEvaluateNode[left, environment] + recursorEvaluateNode[right, environment]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Mul[left_, right_], environment_] := recursorEvaluateNode[left, environment] * recursorEvaluateNode[right, environment]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Monus[left_, right_], environment_] := Max[recursorEvaluateNode[left, environment] - recursorEvaluateNode[right, environment], 0]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Rem[left_, right_], environment_] := With[{
	dividend = recursorEvaluateNode[left, environment], divisor = recursorEvaluateNode[right, environment]
},
	If[divisor === 0, dividend, Mod[dividend, divisor]]
]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Quot[left_, right_], environment_] := With[{
	dividend = recursorEvaluateNode[left, environment], divisor = recursorEvaluateNode[right, environment]
},
	If[divisor === 0, 0, Quotient[dividend, divisor]]
]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Let[value_, body_], environment_] :=
	recursorEvaluateNode[body, Append[environment, "Input" -> recursorEvaluateNode[value, environment]]]
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Ifz[condition_, zero_, positive_], environment_] :=
	recursorEvaluateNode[If[recursorEvaluateNode[condition, environment] === 0, zero, positive], environment]

(* The loops count with explicit counters, so that a count may exceed a machine integer. NestWhile tests before each
   step: the test of Iter counts the step it admits, and the step of Rec counts as it reads its index. *)
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Iter[count_, base_, step_], environment_] := Module[{iterations = recursorEvaluateNode[count, environment], index = 0},
	NestWhile[
		recursorEvaluateNode[step, Append[environment, "Accumulator" -> #]] &,
		recursorEvaluateNode[base, environment],
		index++ < iterations &
	]
]

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[Rec[count_, base_, step_], environment_] := Module[{iterations = recursorEvaluateNode[count, environment], index = 0},
	NestWhile[
		recursorEvaluateNode[step, Join[environment, <|"Accumulator" -> #, "Index" -> index++|>]] &,
		recursorEvaluateNode[base, environment],
		index < iterations &
	]
]

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
historyStep[step_, environment_, history_] := Append[history,
	Length[history] -> recursorEvaluateNode[step, Join[environment, <|"Index" -> Length[history], "History" -> history|>]]
]

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[CoRec[count_, step_], environment_] := With[{last = recursorEvaluateNode[count, environment]},
	Lookup[
		NestWhile[historyStep[step, environment, #] &, <||>, Length[#] <= last &],
		last
	]
]

(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[CGet[index_], environment_] := Lookup[environment["History"], recursorEvaluateNode[index, environment], 0]

(* The state of the loop is the environment of its condition and step, so each turn builds one environment. *)
(* allow BarePattern: step loop; EvaluateRecursor has tested the program *)
interpret[WhileLoop[base_, condition_, step_], environment_] := Lookup[
	NestWhile[
		Append[environment, "Accumulator" -> recursorEvaluateNode[step, #]] &,
		Append[environment, "Accumulator" -> recursorEvaluateNode[base, environment]],
		recursorEvaluateNode[condition, #] =!= 0 &
	],
	"Accumulator"
]
