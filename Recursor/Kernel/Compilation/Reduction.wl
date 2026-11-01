(* Call-by-need normalization with a local heap and evaluation frames.
   Heap cells are local to one normalization; no cache survives a call. *)

newThunk[machine_, expression_, environment_] := With[{identifier = ++machine["Next"]},
	machine[identifier] = delayed[expression, environment];
	identifier
]

newValue[machine_, value_] := With[{identifier = ++machine["Next"]},
	machine[identifier] = forced[value];
	identifier
]

transition[machine_, evaluate[index_Integer, environment_, stack_]] := With[{
	identifier = Extract[environment, {index}]
},
	Replace[machine[identifier], {
		forced[value_] :> apply[value, stack],
		delayed[expression_, scope_] :> evaluate[expression, scope, Prepend[stack, updateFrame[identifier]]]
	}]
]
transition[_, evaluate[\[FormalLambda][body_], environment_, stack_]] := apply[closure[body, environment], stack]
transition[machine_, evaluate[head_[argument_], environment_, stack_]] :=
	evaluate[head, environment, Prepend[stack, argumentFrame[newThunk[machine, argument, environment]]]]
transition[_, apply[value_, {}]] := done[value]
transition[machine_, apply[value_, {updateFrame[identifier_], rest___}]] := (
	machine[identifier] = forced[value];
	apply[value, {rest}]
)
transition[_, apply[closure[body_, environment_], {argumentFrame[identifier_], rest___}]] := evaluate[body, Prepend[environment, identifier], {rest}]
transition[_, apply[neutral[value_], {argumentFrame[identifier_], rest___}]] := apply[neutral[neutralApplication[value, identifier]], {rest}]

weakHead[machine_, expression_, environment_] := Module[{state = evaluate[expression, environment, {}]},
	While[! MatchQ[state, _done],
		recursorTick[];
		state = transition[machine, state]
	];
	First[state]
]

force[machine_, identifier_] := Replace[machine[identifier], {
	forced[value_] :> value,
	delayed[expression_, environment_] :> With[{value = weakHead[machine, expression, environment]},
		machine[identifier] = forced[value];
		value
	]
}]

readBack[machine_, closure[body_, environment_], depth_] := (
	recursorTick[];
	\[FormalLambda][readBack[machine,
		weakHead[machine, body, Prepend[environment, newValue[machine, neutral[level[depth]]]]], depth + 1
	]]
)
readBack[machine_, neutral[value_], depth_] := readNeutral[machine, value, depth]
readNeutral[_, level[index_], depth_] := depth - index
readNeutral[machine_, neutralApplication[head_, argument_], depth_] := (
	recursorTick[];
	readNeutral[machine, head, depth][readBack[machine, force[machine, argument], depth]]
)

recursorNormalizeLambda[term_] := Module[{machine},
	machine["Next"] = 0;
	readBack[machine, weakHead[machine, term, {}], 0]
]

decode[\[FormalLambda][\[FormalLambda][body_]]] := Module[{tail = body, count = 0},
	While[MatchQ[tail, 2[_]],
		count++;
		tail = First[tail]
	];
	If[tail === 1, count, recursorFailure["InvalidNumeral"]]
]

recursorLambdaEvaluate[program_, input_] := decode @ recursorNormalizeLambda[CompileRecursor[program][recursorChurchNumeral[input]]]
