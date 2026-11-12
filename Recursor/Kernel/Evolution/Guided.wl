(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{guidedEvolution}]

(* ::Section:: *)
(*Usage Messages*)

guidedEvolution::usage = "guidedEvolution[examples, settings] searches for a program matching the examples by variation guided by the values \
the examples require, and gives the result of EvolveRecursor. settings is an association with the keys \"PopulationSize\", \"MaxGenerations\", \
\"EliteCount\", \"MaxNodes\", \"MaxConstant\", \"LibraryCost\", \"StopOnSolve\" and \"InitialPopulation\", and with the options of ScoreRecursor \
as a list of rules under \"ScoreOptions\"."

$unbounded::usage = "$unbounded is the upper end of an interval without an upper bound."
$syntaxNode::usage = "$syntaxNode is the pattern of a value that can be a program or the step of a recurrence: a symbol or an expression \
with arguments."
needed::usage = "needed[head, position, {lower, upper}, others] gives the interval {lower, upper} in which the argument of head at the given \
position must lie, at every input, for head[...] to lie in the given interval, when the other arguments have the values others. An interval \
whose lower end is above its upper end is empty. Where the true set is not an interval, a part of it is given."
openPaths::usage = "openPaths[expression] gives the paths of the nodes reached from the root through operations that can be run backwards. \
The nodes lie outside every binder, so each is a program of the same leaves.\n\
openPaths[expression, path] gives the paths for an expression that is itself at path."
backwardStep::usage = "backwardStep[state, position, search] runs one operation backwards. state is {lower, upper, dead, node}: the interval \
wanted of node at every case, with dead one at the cases where the interval is empty. The result is the state of the argument of node at \
position, or None when a value beside it is not a number. A state None stays None."
desiredIntervals::usage = "desiredIntervals[expression, path, search] gives the interval {lower, upper} in which the value of the node at \
path must lie, at every case, for expression to reach the targets of search, or None when a value beside the path is not a number."
graft::usage = "graft[expression, path, replacement] gives expression with the node at path replaced; for the empty path that is the replacement."
libraryRepair::usage = "libraryRepair[expression, path, intervals, library] gives expression with the node at path replaced by the library \
program inside most of the intervals; of several, one of the four cheapest at random. It gives None when intervals is None or when no library \
program helps at any case."
repairAt::usage = "repairAt[expression, path, search] gives expression with the node at path replaced by the program of the library of \
search that best gives the values wanted there, or None."
$extensions::usage = "$extensions is the list of the operations put around a parent, each as {operation, path}: a function of the parent \
and of a placeholder for the missing operand, and the path of that operand."
classesOf::usage = "classesOf[leaves, maximum, loops] enumerates the expressions over leaves up to the cost maximum and gives a library: an \
association with one expression for each distinct list of values under \"Programs\", cheapest first, and under \"Columns\" the values of all \
of them at each case. loops is None or the settings for bounded loops."
closedLibrary::usage = "closedLibrary[inputs, maximum, maximumConstant] gives the library of closed programs of the input, with bounded \
loops, up to the cost maximum."
stepEnvironment::usage = "stepEnvironment[offset, terms] gives the values of the leaves of a recurrence step at the positions after the \
first three: an association with the keys \"Index\", \"Earlier\" and \"Halved\". offset is the input of the first term."
stepLibrary::usage = "stepLibrary[offset, environment, maximum, maximumConstant] gives the library of recurrence steps up to the cost maximum. \
At a position the leaves are the index and the recorded earlier outputs."
stepSize::usage = "stepSize[expression] gives the number of nodes of a recurrence step."
affineFit::usage = "affineFit[outputs, targets] gives {scale, shift} when scale outputs + shift is targets for a scale of at least one, other \
than the identity, and None otherwise."
affineFitAt::usage = "affineFitAt[outputs, targets, position] gives the result of affineFit from the scale that the outputs and targets at \
position and after it ask for."
cachedProgramValues::usage = "cachedProgramValues[cache, inputs, options][program] gives the list of the values of program at the inputs, \
evaluated with the given options of EvaluateRecursor. It keeps the list in the hash table cache."
cachedStepValues::usage = "cachedStepValues[cache, environment, length][step] gives the list of the length values of a recurrence step in \
the environment. It keeps the list in the hash table cache."
completeProgram::usage = "completeProgram[program, search] gives scale program + shift as a program when that reaches the targets of search \
and fits its \"MaximumSize\", and program otherwise."
guidedIndividual::usage = "guidedIndividual[candidate, parents, generation, search] gives the individual of a guided search for a candidate \
expression: an association with a new \"ID\", the \"Expression\", the IDs of its \"Parents\", its \"Generation\", its \"Values\" at the cases, \
its \"Size\", a list \"Passed\" with one at the cases it gets right, and their count \"Matches\"."
expressionRank::usage = "expressionRank[individual] gives {matches, -size} of an individual of a guided search."
narrowPool::usage = "narrowPool[remaining, case] gives the individuals of remaining that pass the case, or all of them when none does or \
when one remains."
lexicaseParent::usage = "lexicaseParent[pool, cases] chooses an individual of pool by lexicase selection on the cases in a random order \
and, of the individuals it leaves, one of the smallest at random."
narrowLibrary::usage = "narrowLibrary[remaining, case, passes] gives the positions among remaining of the library programs that pass the \
case, or all of them when none does or when one remains. passes has a row for each library program."
libraryPick::usage = "libraryPick[search] chooses a program of the library of search by lexicase selection on the cases in a random order."
guidedChild::usage = "guidedChild[pool, generation, search] gives a new individual from a parent of pool: a node of the parent repaired \
from the library, the parent inside a new operation, a choice between two parents, or a random library program at a random node."
distinctIndividuals::usage = "distinctIndividuals[pool] gives the best individual of pool for each distinct list of values."
guidedGeneration::usage = "guidedGeneration[state, search, childCount, eliteCount] gives the state of a guided search one generation after \
state. A state is an association with the keys \"Born\", \"Population\", \"Best\" and \"Generation\"."
guidedSearch::usage = "guidedSearch[search, {initialCount, generations, childCount, eliteCount}, stop, seeds, firstGeneration] runs one guided \
search and gives an association of the individuals \"Born\", the last \"Population\", best first, and the last \"Generation\". search is an \
association: the \"Targets\" at the cases, the \"Library\", the functions \"Values\" and \"Size\" of an expression, whether \"AffineCompletion\" \
is made to every new expression, the counter \"Identifiers\" of IDs and the \"MaximumSize\" of an expression. The individuals are born in \
generations from firstGeneration on. With stop True, the search ends when an expression matches every target."
stepProgram::usage = "stepProgram[offset, terms][step] gives {program, cost} for a recurrence step: the program of the step with its initial \
outputs, and its cost, which is the size of the step, those outputs as constants and one more."
costRank::usage = "costRank[individual] gives {score, -cost} of an individual of the whole guided evolution."
closedIndividual::usage = "closedIndividual[individual] gives the individual of the evolution for one of the search for closed programs. A \
closed program is itself, and its cost is its size."
stepIndividual::usage = "stepIndividual[individual, {program, cost}, search] gives the individual of the evolution for one of the search for \
recurrence steps, with its program scored on the targets of the closed search."
stepEvolution::usage = "stepEvolution[examples, settings, closedSearch, {generations, firstGeneration}] runs the guided search for the step of a \
recurrence and gives an association of the \"Individuals\" of the evolution born in it, the IDs of its last \"Population\" and its last \
\"Generation\". closedSearch is the association of the search for closed programs, whose values and IDs it shares."

(* ::Section:: *)
(*Function Definitions*)

(* Evolution guided by the values the examples require: semantic
   backpropagation with a library (Wieloch and Krawiec 2013; Pawlak, Wieloch
   and Krawiec 2015).

   A library holds one program for each distinct list of values of small
   cost on the training inputs. A variation picks a node of a parent and runs
   the program backwards: the outputs and the values of the rest of the
   program give, at every input, the interval in which the value of the node
   must lie for the program to be right there. The library program inside
   most intervals replaces the node.

   Two searches share the budget. One evolves closedSearch programs of the input.
   The other evolves the step of a recurrence, which is right at a position
   when it gives the recorded output from the recorded earlier outputs. *)

$unbounded = 2 ^ 200

$syntaxNode = _Symbol | _[___]

needed[Succ, 1, {lower_, upper_}, {}] := {Ramp[lower - 1], upper - 1}
needed[Pred, 1, {lower_, upper_}, {}] := {(lower + 1) Unitize[lower], upper + 1}
needed[Half, 1, {lower_, upper_}, {}] := {2 lower, 2 upper + 1}
needed[Add, _, {lower_, upper_}, {other_}] := {Ramp[lower - other], upper - other}
needed[Mul, _, {lower_, upper_}, {other_}] := Module[{zero = 1 - Unitize[other], safe = other + (1 - Unitize[other])},
	{(1 - zero) Quotient[lower + safe - 1, safe] + zero Unitize[lower], (1 - zero) Quotient[upper, safe] + zero (1 - Unitize[lower]) $unbounded}
]
needed[Monus, 1, {lower_, upper_}, {subtrahend_}] := {(lower + subtrahend) Unitize[lower], upper + subtrahend}
needed[Monus, 2, {lower_, upper_}, {minuend_}] := {Ramp[minuend - upper], Unitize[lower] (minuend - lower) + (1 - Unitize[lower]) $unbounded}
needed[Quot, 1, {lower_, upper_}, {divisor_}] := Module[{zero = 1 - Unitize[divisor]},
	{(1 - zero) lower divisor + zero Unitize[lower], (1 - zero) (upper divisor + divisor - 1) + zero (1 - Unitize[lower]) $unbounded}
]
needed[Quot, 2, {lower_, upper_}, {dividend_}] :=
	{Quotient[dividend, upper + 1] + 1, Unitize[lower] Quotient[dividend, lower + (1 - Unitize[lower])] + (1 - Unitize[lower]) $unbounded}
(* Rem[x, 0] is x; otherwise the values below the divisor *)
needed[Rem, 1, {lower_, upper_}, {divisor_}] := Module[{zero = 1 - Unitize[divisor]},
	{lower, zero upper + (1 - zero) (upper - Ramp[upper - (divisor - 1)])}
]
(* a divisor above the dividend leaves the dividend, which helps where the dividend is wanted *)
needed[Rem, 2, {lower_, upper_}, {dividend_}] := Module[{inside = UnitStep[dividend - lower] UnitStep[upper - dividend]},
	{inside (dividend + 1) + (1 - inside), inside $unbounded}
]
(* the condition: zero where only the zero branch is right, positive where only the other is *)
needed[Ifz, 1, {lower_, upper_}, {zeroValue_, positiveValue_}] :=
	{1 - UnitStep[zeroValue - lower] UnitStep[upper - zeroValue], UnitStep[positiveValue - lower] UnitStep[upper - positiveValue] $unbounded}
needed[Ifz, 2, {lower_, upper_}, {condition_, positiveValue_}] := Module[{
	taken = 1 - Unitize[condition], good = UnitStep[positiveValue - lower] UnitStep[upper - positiveValue]
},
	{taken lower + (1 - taken) (1 - good), taken upper + (1 - taken) good $unbounded}
]
needed[Ifz, 3, {lower_, upper_}, {condition_, zeroValue_}] := Module[{
	taken = Unitize[condition], good = UnitStep[zeroValue - lower] UnitStep[upper - zeroValue]
},
	{taken lower + (1 - taken) (1 - good), taken upper + (1 - taken) good $unbounded}
]

openPaths[expression : $syntaxNode] := openPaths[expression, {}]
openPaths[expression : (Succ | Pred | Half | Add | Mul | Monus | Quot | Rem | Ifz)[__], path_List] := Join[{path},
	Catenate[MapIndexed[Function[{argument, position}, openPaths[argument, Append[path, First[position]]]], List @@ expression]]
]
openPaths[$syntaxNode, path_List] := {path}

backwardStep[None, _Integer, _Association] := None
backwardStep[{lower_List, upper_List, dead_List, node : $syntaxNode}, position_Integer, search_Association] := Module[{others, interval, nowDead},
	others = Map[search["Values"], Delete[List @@ node, position]];
	If[others =!= {} && !MatrixQ[others, IntegerQ],
		None,
		interval = needed[Head[node], position, {lower, upper}, others];
		nowDead = Unitize[dead + UnitStep[First[interval] - Last[interval] - 1]];
		{(1 - nowDead) First[interval], (1 - nowDead) Last[interval], nowDead, node[[position]]}
	]
]

desiredIntervals[expression : $syntaxNode, path_List, search_Association] := Module[{targets = search["Targets"]},
	Replace[
		Fold[Function[{state, position}, backwardStep[state, position, search]], {targets, targets, 0 targets, expression}, path],
		{lower_List, upper_List, dead_List, _} :> {lower + dead, (1 - dead) upper}
	]
]

graft[$syntaxNode, {}, replacement : $syntaxNode] := replacement
graft[expression : $syntaxNode, path_List, replacement : $syntaxNode] := ReplacePart[expression, path -> replacement]

libraryRepair[$syntaxNode, _List, None, _Association] := None
libraryRepair[expression : $syntaxNode, path_List, {lower_List, upper_List}, library_Association] := Module[{scores, best, positions},
	scores = Total[MapThread[UnitStep[#1 - #2] UnitStep[#3 - #1] &, {library["Columns"], lower, upper}]];
	best = Max[scores];
	If[best === 0,
		None,
		positions = Flatten[Position[scores, best, {1}, 4, Heads -> False]];
		graft[expression, path, library["Programs"][[RandomChoice[positions]]]]
	]
]

repairAt[expression : $syntaxNode, path_List, search_Association] :=
	libraryRepair[expression, path, desiredIntervals[expression, path, search], search["Library"]]

$extensions = {{Add[#1, #2] &, {2}}, {Mul[#1, #2] &, {2}}, {Monus[#1, #2] &, {2}}, {Monus[#2, #1] &, {1}}, {Quot[#1, #2] &, {2}}, {Rem[#1, #2] &, {2}}}

classesOf[leaves_List, maximum_Integer, loops : None | _Association] := Module[{classes, costs},
	classes = synthesisClasses[leaves, None, maximum, AbsoluteTime[] + 20, loops, False, None &];
	costs = Sort[Keys[classes["Expressions"]]];
	<|"Programs" -> Catenate[classes["Expressions"] /@ costs], "Columns" -> Transpose[Catenate[classes["Vectors"] /@ costs]]|>
]

closedLibrary[inputs_List, maximum_Integer, maximumConstant_Integer] := classesOf[
	Join[{{Var, inputs}}, Table[{Const[constant], ConstantArray[constant, Length[inputs]]}, {constant, 0, maximumConstant}]],
	maximum,
	<|"Bodies" -> synthesisLoopBodies[3, maximumConstant, AbsoluteTime[] + 20], "Inputs" -> inputs, "MaxBody" -> 3|>
]

stepEnvironment[offset_Integer, terms_List] := With[{positions = Range[3, Length[terms] - 1]},
	<|
		"Index" -> offset + positions, "Earlier" -> Table[terms[[positions + 1 - lag]], {lag, 3}],
		"Halved" -> terms[[Clip[Quotient[offset + positions, 2] - offset + 1, {1, Length[terms]}]]]
	|>
]

stepLibrary[offset_Integer, environment_Association, maximum_Integer, maximumConstant_Integer] := classesOf[
	Join[
		{{Idx, environment["Index"]}},
		Table[{synthesisEarlier[lag], environment["Earlier"][[lag]]}, {lag, 3}],
		If[offset <= 1, {{synthesisHalved, environment["Halved"]}}, {}],
		Table[{Const[constant], ConstantArray[constant, Length[environment["Index"]]]}, {constant, 0, maximumConstant}]
	],
	maximum,
	None
]

stepSize[_Const | Idx | _synthesisEarlier | synthesisHalved] := 1
stepSize[expression : $syntaxNode] := 1 + Total[stepSize /@ List @@ expression]

affineFit[outputs_List, targets_List] := Module[{position},
	position = If[VectorQ[outputs, IntegerQ], FirstPosition[Differences[outputs], _?(# =!= 0 &), None, {1}, Heads -> False], None];
	If[position === None, None, affineFitAt[outputs, targets, First[position]]]
]

affineFitAt[outputs_List, targets_List, position_Integer] := Module[{rise, run, scale, shift},
	rise = targets[[position + 1]] - targets[[position]];
	run = outputs[[position + 1]] - outputs[[position]];
	If[!Divisible[rise, run],
		None,
		scale = Quotient[rise, run];
		shift = First[targets] - scale First[outputs];
		If[scale >= 1 && scale outputs + shift === targets && !(scale === 1 && shift === 0), {scale, shift}, None]
	]
]

(* The helpers of the search are at file level, because a function defined inside a Module keeps its memory after
   the call. What a search remembers is in data structures, which are freed with the association that holds them:
   a hash table of the values of the expressions met, and a counter of IDs. *)
cachedProgramValues[cache_DataStructure, inputs_List, options_List][program : $syntaxNode] := Module[{outputs = cache["Lookup", program]},
	If[MissingQ[outputs],
		(* a program too deep for the kernel stops with these messages and has no values *)
		outputs = Quiet[
			Map[Function[input, EvaluateRecursor[program, input, Sequence @@ options]], inputs],
			{$RecursionLimit::reclim, $RecursionLimit::reclim2, $IterationLimit::itlim}
		];
		cache["Insert", program -> outputs]
	];
	outputs
]

cachedStepValues[cache_DataStructure, environment_Association, length_Integer][step : $syntaxNode] := Module[{outputs = cache["Lookup", step]},
	If[MissingQ[outputs],
		outputs = Replace[synthesisVectorValue[step, environment], scalar_Integer :> ConstantArray[scalar, length]];
		cache["Insert", step -> outputs]
	];
	outputs
]

completeProgram[program : $syntaxNode, search_Association] := Module[{fit = affineFit[search["Values"][program], search["Targets"]]},
	If[fit === None || RecursorNodeCount[program] + 4 > search["MaximumSize"], program, synthesisAffineProgram[program, First[fit], Last[fit]]]
]

guidedIndividual[candidate : $syntaxNode, parents_List, generation_Integer, search_Association] := Module[{expression, outputs, passed},
	expression = If[search["AffineCompletion"], completeProgram[candidate, search], candidate];
	outputs = search["Values"][expression];
	passed = Boole[MapThread[SameQ, {outputs, search["Targets"]}]];
	<|
		"ID" -> search["Identifiers"]["Increment"] + 1, "Expression" -> expression, "Parents" -> parents, "Generation" -> generation,
		"Values" -> outputs, "Size" -> search["Size"][expression], "Passed" -> passed, "Matches" -> Total[passed]
	|>
]

expressionRank[individual_Association] := {individual["Matches"], -individual["Size"]}

(* Lexicase selection: the cases in a random order, each keeping those that pass it when some do. Once one is
   left no case changes it. The random draws are the order of the cases and then the last choice. *)
narrowPool[remaining : {_}, _Integer] := remaining
narrowPool[remaining_List, case_Integer] := Replace[Select[remaining, #["Passed"][[case]] === 1 &], {} -> remaining]

lexicaseParent[pool_List, cases_List] := Module[{remaining},
	remaining = Fold[narrowPool, pool, RandomSample[cases]];
	RandomChoice[MinimalBy[remaining, #["Size"] &]]
]

(* lexicase selection in the library itself *)
narrowLibrary[remaining : {_}, _Integer, _List] := remaining
narrowLibrary[remaining_List, case_Integer, passes_List] := Replace[Pick[remaining, passes[[remaining, case]], 1], {} -> remaining]

libraryPick[search_Association] := Module[{passes = search["Passes"], remaining},
	remaining = Fold[Function[{positions, case}, narrowLibrary[positions, case, passes]], Range[Length[passes]], RandomSample[search["Cases"]]];
	search["Library"]["Programs"][[RandomChoice[Take[remaining, UpTo[3]]]]]
]

(* The order of the random draws is part of the result of a seeded search: the parent, the kind of variation,
   and then the draws of that variation from left to right. *)
guidedChild[pool_List, generation_Integer, search_Association] := Module[{parent, choice, expression, other, extension, child, parents},
	parent = lexicaseParent[pool, search["Cases"]];
	choice = RandomReal[];
	expression = parent["Expression"];
	parents = {parent["ID"]};
	child = Which[
		choice < 0.45, repairAt[expression, RandomChoice[openPaths[expression]], search],
		choice < 0.70,
			extension = RandomChoice[$extensions];
			repairAt[First[extension][expression, Const[1]], Last[extension], search],
		choice < 0.80,
			other = lexicaseParent[pool, search["Cases"]];
			parents = DeleteDuplicates[{parent["ID"], other["ID"]}];
			repairAt[Ifz[Const[0], expression, other["Expression"]], {1}, search],
		True, graft[expression, RandomChoice[openPaths[expression]], RandomChoice[Take[search["Library"]["Programs"], UpTo[300]]]]
	];
	guidedIndividual[If[child === None || search["Size"][child] > search["MaximumSize"], expression, child], parents, generation, search]
]

distinctIndividuals[pool_List] := Values[GroupBy[ReverseSortBy[pool, expressionRank], #["Values"] &, First]]

guidedGeneration[state_Association, search_Association, childCount_Integer, eliteCount_Integer] := Module[{generation, young, population},
	generation = state["Generation"] + 1;
	young = Table[guidedChild[state["Population"], generation, search], {childCount}];
	population = distinctIndividuals[Join[Take[ReverseSortBy[state["Population"], expressionRank], UpTo[eliteCount]], young]];
	<|
		"Born" -> Join[state["Born"], young], "Population" -> population,
		"Best" -> First[MaximalBy[Append[population, state["Best"]], expressionRank]], "Generation" -> generation
	|>
]

guidedSearch[
	settings_Association,
	{initialCount_Integer, generations_Integer, childCount_Integer, eliteCount_Integer},
	stop : True | False,
	seeds_List,
	firstGeneration_Integer
] := Module[{targets, programs, search, candidates, born, population, initialState, finalState},
	targets = settings["Targets"];
	programs = settings["Library"]["Programs"];
	search = Join[settings, <|
		"Cases" -> Range[Length[targets]],
		"Passes" -> Transpose[MapThread[1 - Unitize[#1 - #2] &, {settings["Library"]["Columns"], targets}]]
	|>];
	candidates = Join[seeds, Table[libraryPick[search], initialCount], Take[programs, UpTo[initialCount]]];
	born = Map[Function[candidate, guidedIndividual[candidate, {}, firstGeneration, search]], Take[DeleteDuplicates[candidates], UpTo[initialCount]]];
	population = distinctIndividuals[born];
	initialState = <|"Born" -> born, "Population" -> population, "Best" -> First[MaximalBy[population, expressionRank]], "Generation" -> firstGeneration|>;
	finalState = NestWhile[
		Function[state, guidedGeneration[state, search, childCount, eliteCount]],
		initialState,
		Function[state, !(stop && state["Best"]["Matches"] === Length[targets])],
		1,
		generations
	];
	<|"Born" -> finalState["Born"], "Population" -> ReverseSortBy[finalState["Population"], expressionRank], "Generation" -> finalState["Generation"]|>
]

stepProgram[offset_Integer, terms_List][step : $syntaxNode] := Module[{seeds = synthesisStepSeeds[step, offset, terms]},
	{synthesisRecurrenceProgram[step, seeds, offset, terms], stepSize[step] + Total[synthesisConstantCost /@ Take[terms, seeds]] + 1}
]

costRank[individual_Association] := {individual["Score"], -individual["Cost"]}

closedIndividual[individual_Association] := <|
	"ID" -> individual["ID"], "Program" -> individual["Expression"], "Parents" -> individual["Parents"], "Generation" -> individual["Generation"],
	"Score" -> individual["Matches"], "Size" -> individual["Size"], "Cost" -> individual["Size"]
|>

stepIndividual[individual_Association, {program : $syntaxNode, cost_Integer}, search_Association] := <|
	"ID" -> individual["ID"], "Program" -> program, "Parents" -> individual["Parents"], "Generation" -> individual["Generation"],
	"Score" -> Count[MapThread[SameQ, {search["Values"][program], search["Targets"]}], True], "Size" -> RecursorNodeCount[program], "Cost" -> cost
|>

stepEvolution[examples_List, settings_Association, closedSearch_Association, {generations_Integer, firstGeneration_Integer}] := Module[{
	ordered, offset, terms, environment, children, search, result, programs
},
	ordered = SortBy[examples, First];
	offset = First[First[ordered]];
	terms = Map[Last, ordered];
	environment = stepEnvironment[offset, terms];
	children = settings["PopulationSize"] - settings["EliteCount"];
	search = <|
		"Targets" -> Drop[terms, 3],
		"Library" -> stepLibrary[offset, environment, Max[settings["LibraryCost"] - 1, 1], settings["MaxConstant"]],
		"Values" -> cachedStepValues[CreateDataStructure["HashTable"], environment, Length[terms] - 3],
		"Size" -> stepSize, "AffineCompletion" -> False, "Identifiers" -> closedSearch["Identifiers"], "MaximumSize" -> Max[settings["MaxNodes"] - 20, 1]
	|>;
	result = guidedSearch[search, {Max[children, 1], generations, children, settings["EliteCount"]}, settings["StopOnSolve"], {}, firstGeneration];
	(* a step becomes a program once, however many individuals have it *)
	programs = AssociationMap[stepProgram[offset, terms], DeleteDuplicates[Lookup[result["Born"], "Expression"]]];
	<|
		"Individuals" -> Map[Function[individual, stepIndividual[individual, programs[individual["Expression"]], closedSearch]], result["Born"]],
		"Population" -> Lookup[result["Population"], "ID"], "Generation" -> result["Generation"]
	|>
]

guidedEvolution[examples_List, settings_Association] := Module[{
	inputs, targets, populationSize, generations, elites, maximumNodes, stepsQ, half, closedSearch, closedResult, stepResult,
	individuals, population, lastGeneration, byIdentifier, best, kept
},
	{inputs, targets} = Transpose[examples];
	{populationSize, generations, elites, maximumNodes} = Lookup[settings, {"PopulationSize", "MaxGenerations", "EliteCount", "MaxNodes"}];
	stepsQ = generations >= 2 && populationSize > elites && DuplicateFreeQ[inputs] && Length[targets] >= 6 && Sort[inputs] === Range[Min[inputs], Max[inputs]];
	half = If[stepsQ, Quotient[generations, 2], generations];
	closedSearch = <|
		"Targets" -> targets,
		"Library" -> closedLibrary[inputs, settings["LibraryCost"], settings["MaxConstant"]],
		"Values" -> cachedProgramValues[CreateDataStructure["HashTable"], inputs, settings["ScoreOptions"]],
		"Size" -> RecursorNodeCount, "AffineCompletion" -> True, "Identifiers" -> CreateDataStructure["Counter", 0], "MaximumSize" -> maximumNodes
	|>;
	closedResult = guidedSearch[closedSearch, {populationSize, half, Max[populationSize - elites, 0], elites}, settings["StopOnSolve"],
		settings["InitialPopulation"], 0];
	stepResult = If[stepsQ,
		stepEvolution[examples, settings, closedSearch, {generations - half - 1, closedResult["Generation"] + 1}],
		<|"Individuals" -> {}, "Population" -> {}, "Generation" -> closedResult["Generation"]|>
	];
	individuals = Join[closedIndividual /@ closedResult["Born"], stepResult["Individuals"]];
	lastGeneration = stepResult["Generation"];
	byIdentifier = AssociationThread[Lookup[individuals, "ID"], individuals];
	population = Lookup[byIdentifier, Join[Lookup[closedResult["Population"], "ID"], stepResult["Population"]]];
	(* a program above MaxNodes is tried but not kept *)
	kept = Select[individuals, #Size <= maximumNodes &];
	best = First[MaximalBy[kept, costRank]];
	<|
		"Program" -> best["Program"], "Solved" -> (best["Score"] === Length[examples]), "Fitness" -> best["Score"], "MaxFitness" -> Length[examples],
		"Generations" -> lastGeneration,
		(* the best score so far among the programs that may be returned *)
		"FitnessHistory" -> Rest[FoldList[Max, 0, Table[
			Max[Cases[kept, individual_ /; individual["Generation"] === generation :> individual["Score"]], 0],
			{generation, 0, lastGeneration}
		]]],
		"Population" -> Map[KeyDrop["Cost"], Take[ReverseSortBy[population, costRank], UpTo[populationSize]]],
		"Genealogy" -> Map[KeyDrop["Cost"], individuals]
	|>
]
