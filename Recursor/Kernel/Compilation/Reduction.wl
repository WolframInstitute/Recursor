(* ::Package:: *)

(* Call-by-need normalization with a local heap and evaluation frames.
   Heap cells are local to one normalization; no cache survives a call. *)

(* ::Section:: *)
(*Usage Messages*)

recursorNormalizeLambda::usage = "recursorNormalizeLambda[term] gives the normal form of a lambda term with de Bruijn indices. It counts its steps \
with recursorTick, so it runs within recursorBudget."

recursorLambdaEvaluate::usage = "recursorLambdaEvaluate[program, input] gives the value of a closed Recursor program at the natural number input, \
found by normalizing the compiled lambda term applied to the Church numeral of input."

newThunk::usage = "newThunk[machine, expression, environment] stores the delayed evaluation of expression in environment in a new heap cell of \
machine and gives the identifier of the cell."

newValue::usage = "newValue[machine, value] stores the evaluated value in a new heap cell of machine and gives the identifier of the cell."

machineTransition::usage = "machineTransition[machine, state] gives the state that follows state. A state is evaluate[expression, environment, stack], \
apply[value, stack] or done[value]; the step may update heap cells of machine."

runningQ::usage = "runningQ[state] gives False when state is done[value], and True for a state that has a next step."

weakHead::usage = "weakHead[machine, expression, environment] gives the weak head normal form of expression in environment: closure[body, environment] \
or neutral[value]."

forceThunk::usage = "forceThunk[machine, identifier] gives the value of the heap cell identifier of machine, evaluating and updating a delayed cell."

readBack::usage = "readBack[machine, value, depth] gives the normal lambda term of a weak head normal form under depth enclosing abstractions."

readNeutral::usage = "readNeutral[machine, value, depth] gives the normal lambda term of a neutral value, level[index] or \
neutralApplication[head, argument], under depth enclosing abstractions."

decodeNumeral::usage = "decodeNumeral[term] gives the natural number of a Church numeral in normal form, and a Failure with the tag \
\"InvalidNumeral\" for another term with two abstractions."

(* ::Section:: *)
(*Function Definitions*)

newThunk[machine_Symbol, expression : (_Integer | _[_]), environment_List] := With[{identifier = ++machine["Next"]},
	machine[identifier] = delayed[expression, environment];
	identifier
]

newValue[machine_Symbol, value_neutral] := With[{identifier = ++machine["Next"]},
	machine[identifier] = forced[value];
	identifier
]

machineTransition[machine_Symbol, evaluate[index_Integer, environment_, stack_]] := With[{
	identifier = Extract[environment, {index}]
},
	Replace[machine[identifier], {
		forced[value_] :> apply[value, stack],
		delayed[expression_, scope_] :> evaluate[expression, scope, Prepend[stack, updateFrame[identifier]]]
	}]
]
machineTransition[_Symbol, evaluate[\[FormalLambda][body_], environment_, stack_]] := apply[closure[body, environment], stack]
machineTransition[machine_Symbol, evaluate[head_[argument_], environment_, stack_]] :=
	evaluate[head, environment, Prepend[stack, argumentFrame[newThunk[machine, argument, environment]]]]
machineTransition[_Symbol, apply[value_, {}]] := done[value]
machineTransition[machine_Symbol, apply[value_, {updateFrame[identifier_], rest___}]] := (
	machine[identifier] = forced[value];
	apply[value, {rest}]
)
machineTransition[_Symbol, apply[closure[body_, environment_], {argumentFrame[identifier_], rest___}]] :=
	evaluate[body, Prepend[environment, identifier], {rest}]
machineTransition[_Symbol, apply[neutral[value_], {argumentFrame[identifier_], rest___}]] :=
	apply[neutral[neutralApplication[value, identifier]], {rest}]

runningQ[_done] := False
runningQ[_] := True

weakHead[machine_Symbol, expression : (_Integer | _[_]), environment_List] := First @ NestWhile[
	Function[state,
		recursorTick[];
		machineTransition[machine, state]
	],
	evaluate[expression, environment, {}],
	runningQ
]

forceThunk[machine_Symbol, identifier_Integer] := Replace[machine[identifier], {
	forced[value_] :> value,
	delayed[expression_, environment_] :> With[{value = weakHead[machine, expression, environment]},
		machine[identifier] = forced[value];
		value
	]
}]

readBack[machine_Symbol, closure[body_, environment_], depth_Integer] := (
	recursorTick[];
	\[FormalLambda][readBack[machine,
		weakHead[machine, body, Prepend[environment, newValue[machine, neutral[level[depth]]]]], depth + 1
	]]
)
readBack[machine_Symbol, neutral[value_], depth_Integer] := readNeutral[machine, value, depth]

readNeutral[_Symbol, level[index_], depth_Integer] := depth - index
readNeutral[machine_Symbol, neutralApplication[head_, argument_], depth_Integer] := (
	recursorTick[];
	readNeutral[machine, head, depth][readBack[machine, forceThunk[machine, argument], depth]]
)

recursorNormalizeLambda[term : (_Integer | _[_])] := Module[{machine},
	machine["Next"] = 0;
	readBack[machine, weakHead[machine, term, {}], 0]
]

decodeNumeral[\[FormalLambda][\[FormalLambda][body_]]] := Module[{tails},
	tails = NestWhileList[First, body, MatchQ[#, 2[_]] &];
	If[Last[tails] === 1, Length[tails] - 1, recursorFailure["InvalidNumeral"]]
]

recursorLambdaEvaluate[program_?RecursorProgramQ, input_Integer?NonNegative] :=
	decodeNumeral @ recursorNormalizeLambda[CompileRecursor[program][recursorChurchNumeral[input]]]
