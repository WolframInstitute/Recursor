PackageScoped[{guidedEvolution}]

(* Evolution guided by the values the examples require: semantic
   backpropagation with a library (Wieloch and Krawiec 2013; Pawlak, Wieloch
   and Krawiec 2015).

   A library holds one program for each distinct list of values of small
   cost on the training inputs. A variation picks a node of a parent and runs
   the program backwards: the outputs and the values of the rest of the
   program give, at every input, the interval in which the value of the node
   must lie for the program to be right there. The library program inside
   most intervals replaces the node.

   Two searches share the budget. One evolves closed programs of the input.
   The other evolves the step of a recurrence, which is right at a position
   when it gives the recorded output from the recorded earlier outputs. *)

$unbounded = 2^200

(* needed[head, k, {lo, hi}, others]: the interval in which argument k must
   lie, at every input, for head[...] to lie in {lo, hi}, given the values of
   the other arguments. An interval with lo > hi is empty. Where the true set
   is not an interval, a part of it is given. *)
needed[Succ, 1, {lo_, hi_}, {}] := {Ramp[lo - 1], hi - 1}
needed[Pred, 1, {lo_, hi_}, {}] := {(lo + 1) Unitize[lo], hi + 1}
needed[Half, 1, {lo_, hi_}, {}] := {2 lo, 2 hi + 1}
needed[Add, _, {lo_, hi_}, {b_}] := {Ramp[lo - b], hi - b}
needed[Mul, _, {lo_, hi_}, {b_}] := With[{zero = 1 - Unitize[b], safe = b + (1 - Unitize[b])},
	{(1 - zero) Quotient[lo + safe - 1, safe] + zero Unitize[lo], (1 - zero) Quotient[hi, safe] + zero (1 - Unitize[lo]) $unbounded}
]
needed[Monus, 1, {lo_, hi_}, {b_}] := {(lo + b) Unitize[lo], hi + b}
needed[Monus, 2, {lo_, hi_}, {a_}] := {Ramp[a - hi], Unitize[lo] (a - lo) + (1 - Unitize[lo]) $unbounded}
needed[Quot, 1, {lo_, hi_}, {b_}] := With[{zero = 1 - Unitize[b]},
	{(1 - zero) lo b + zero Unitize[lo], (1 - zero) (hi b + b - 1) + zero (1 - Unitize[lo]) $unbounded}
]
needed[Quot, 2, {lo_, hi_}, {a_}] := {Quotient[a, hi + 1] + 1, Unitize[lo] Quotient[a, lo + (1 - Unitize[lo])] + (1 - Unitize[lo]) $unbounded}
(* Rem[x, 0] is x; otherwise the values below the divisor *)
needed[Rem, 1, {lo_, hi_}, {b_}] := With[{zero = 1 - Unitize[b]}, {lo, zero hi + (1 - zero) (hi - Ramp[hi - (b - 1)])}]
(* a divisor above a leaves a, which helps where a is wanted *)
needed[Rem, 2, {lo_, hi_}, {a_}] := With[{inside = UnitStep[a - lo] UnitStep[hi - a]}, {inside (a + 1) + (1 - inside), inside $unbounded}]
(* the condition: zero where only the zero branch is right, positive where only the other is *)
needed[Ifz, 1, {lo_, hi_}, {z_, p_}] := {1 - UnitStep[z - lo] UnitStep[hi - z], UnitStep[p - lo] UnitStep[hi - p] $unbounded}
needed[Ifz, 2, {lo_, hi_}, {c_, p_}] := With[{taken = 1 - Unitize[c], good = UnitStep[p - lo] UnitStep[hi - p]},
	{taken lo + (1 - taken) (1 - good), taken hi + (1 - taken) good $unbounded}
]
needed[Ifz, 3, {lo_, hi_}, {c_, z_}] := With[{taken = Unitize[c], good = UnitStep[z - lo] UnitStep[hi - z]},
	{taken lo + (1 - taken) (1 - good), taken hi + (1 - taken) good $unbounded}
]

(* Nodes reached from the root through operations that can be run backwards.
   They lie outside every binder, so each is a program of the same leaves. *)
openPaths[expression_, path_ : {}] := Join[{path},
	If[MatchQ[expression, (Succ | Pred | Half | Add | Mul | Monus | Quot | Rem | Ifz)[__]],
		Catenate[MapIndexed[openPaths[#1, Append[path, First[#2]]] &, List @@ expression]], {}]
]

(* The intervals for the node at a path, or None when a value beside the path is not a number. *)
desired[program_, path_, targets_, values_] := Module[{lo = targets, hi = targets, dead = 0 targets, node = program, others, known = True},
	Do[
		others = values /@ Delete[List @@ node, step];
		If[others =!= {} && ! MatrixQ[others, IntegerQ], known = False; Break[]];
		{lo, hi} = needed[Head[node], step, {lo, hi}, others];
		dead = Unitize[dead + UnitStep[lo - hi - 1]];
		lo = (1 - dead) lo;
		hi = (1 - dead) hi;
		node = node[[step]],
		{step, path}
	];
	If[known, {lo + dead, (1 - dead) hi}, None]
]

(* The program with the node at the path replaced by the library program
   inside most intervals; of several, one of the four cheapest. None when no
   library program helps at any input. *)
repairAt[program_, path_, targets_, values_, library_] := Module[{need = desired[program, path, targets, values], scores, best, at},
	If[need === None, Return[None]];
	scores = Total[MapThread[UnitStep[#1 - #2] UnitStep[#3 - #1] &, {library["Columns"], First[need], Last[need]}]];
	best = Max[scores];
	If[best === 0, Return[None]];
	at = Flatten[Position[scores, best, {1}, 4, Heads -> False]];
	With[{part = library["Programs"][[RandomChoice[at]]]}, If[path === {}, part, ReplacePart[program, path -> part]]]
]

(* an operation around a parent, with the path of its missing operand *)
$extensions = {{Add[#1, #2] &, {2}}, {Mul[#1, #2] &, {2}}, {Monus[#1, #2] &, {2}}, {Monus[#2, #1] &, {1}}, {Quot[#1, #2] &, {2}}, {Rem[#1, #2] &, {2}}}

classesOf[leaves_, maximum_, loops_] := With[{classes = synthesisClasses[leaves, None, maximum, AbsoluteTime[] + 20, loops, False, None &]},
	With[{costs = Sort[Keys[classes["Expressions"]]]},
		<|"Programs" -> Catenate[classes["Expressions"] /@ costs], "Columns" -> Transpose[Catenate[classes["Vectors"] /@ costs]]|>
	]
]

(* closed programs of the input, with bounded loops *)
closedLibrary[inputs_, maximum_, maximumConstant_] := classesOf[
	Join[{{Var, inputs}}, Table[{Const[c], ConstantArray[c, Length[inputs]]}, {c, 0, maximumConstant}]], maximum,
	<|"Bodies" -> synthesisLoopBodies[3, maximumConstant, AbsoluteTime[] + 20], "Inputs" -> inputs, "MaxBody" -> 3|>
]

(* recurrence steps: at a position the leaves are the index and the recorded earlier outputs *)
stepEnvironment[offset_, terms_] := With[{positions = Range[3, Length[terms] - 1]},
	<|"Index" -> offset + positions, "Earlier" -> Table[terms[[positions + 1 - k]], {k, 3}],
		"Halved" -> terms[[Clip[Quotient[offset + positions, 2] - offset + 1, {1, Length[terms]}]]]|>
]
stepLibrary[offset_, environment_, maximum_, maximumConstant_] := classesOf[
	Join[{{Idx, environment["Index"]}}, Table[{synthesisEarlier[k], environment["Earlier"][[k]]}, {k, 3}],
		If[offset <= 1, {{synthesisHalved, environment["Halved"]}}, {}],
		Table[{Const[c], ConstantArray[c, Length[environment["Index"]]]}, {c, 0, maximumConstant}]],
	maximum, None
]
stepSize[_Const | Idx | _synthesisEarlier | synthesisHalved] := 1
stepSize[expression_] := 1 + Total[stepSize /@ List @@ expression]

(* scale and shift taking the values to the targets, or None *)
affineFit[values_, targets_] := Module[{at, scale, shift},
	If[! VectorQ[values, IntegerQ], Return[None]];
	at = FirstPosition[Differences[values], _?(# =!= 0 &), None, {1}, Heads -> False];
	If[at === None, Return[None]];
	at = First[at];
	If[! Divisible[targets[[at + 1]] - targets[[at]], values[[at + 1]] - values[[at]]], Return[None]];
	scale = Quotient[targets[[at + 1]] - targets[[at]], values[[at + 1]] - values[[at]]];
	shift = First[targets] - scale First[values];
	If[scale >= 1 && scale values + shift === targets && ! (scale === 1 && shift === 0), {scale, shift}, None]
]

(* One guided search. values gives the values of an expression at the cases,
   size its size, finish a last change made to every new expression, and
   identifier a new ID. budget is {first expressions, generations, children,
   elites}. Individuals are born in generations from the given one on.
   Parents are chosen by lexicase selection on the cases and, of the
   expressions it leaves, the smallest. *)
guidedSearch[targets_, library_, values_, size_, finish_, {first_, generations_, children_, elites_}, maximumSize_, stop_, seeds_, identifier_, from_] := Module[{
	individual, rank, select, pick, breed, distinct, passes, population, best, born, generation = from, cases = Range[Length[targets]], result
},
	individual[candidate_, parents_] := With[{expression = finish[candidate]},
		With[{passed = Boole[MapThread[SameQ, {values[expression], targets}]]},
			<|"ID" -> identifier[], "Expression" -> expression, "Parents" -> parents, "Generation" -> generation, "Values" -> values[expression],
				"Size" -> size[expression], "Passed" -> passed, "Matches" -> Total[passed]|>
		]
	];
	rank[one_] := {one["Matches"], -one["Size"]};
	select[pool_] := Module[{rest = pool},
		Do[
			With[{passing = Select[rest, #["Passed"][[case]] === 1 &]}, If[passing =!= {}, rest = passing]];
			If[Length[rest] === 1, Break[]],
			{case, RandomSample[cases]}
		];
		RandomChoice[MinimalBy[rest, #["Size"] &]]
	];
	(* lexicase selection in the library itself *)
	passes = Transpose[MapThread[1 - Unitize[#1 - #2] &, {library["Columns"], targets}]];
	pick[] := Module[{rest = Range[Length[passes]]},
		Do[
			With[{passing = Pick[rest, passes[[rest, case]], 1]}, If[passing =!= {}, rest = passing]];
			If[Length[rest] === 1, Break[]],
			{case, RandomSample[cases]}
		];
		library["Programs"][[RandomChoice[Take[rest, UpTo[3]]]]]
	];
	breed[pool_] := Module[{parent = select[pool], other, child, parents, choice = RandomReal[]},
		parents = {parent["ID"]};
		child = Which[
			choice < 0.45, repairAt[parent["Expression"], RandomChoice[openPaths[parent["Expression"]]], targets, values, library],
			choice < 0.70, With[{form = RandomChoice[$extensions]}, repairAt[First[form][parent["Expression"], Const[1]], Last[form], targets, values, library]],
			choice < 0.80,
				other = select[pool];
				parents = DeleteDuplicates[{parent["ID"], other["ID"]}];
				repairAt[Ifz[Const[0], parent["Expression"], other["Expression"]], {1}, targets, values, library],
			True, With[{path = RandomChoice[openPaths[parent["Expression"]]], part = RandomChoice[Take[library["Programs"], UpTo[300]]]},
				If[path === {}, part, ReplacePart[parent["Expression"], path -> part]]]
		];
		individual[If[child === None || size[child] > maximumSize, parent["Expression"], child], parents]
	];
	distinct[pool_] := Values[GroupBy[ReverseSortBy[pool, rank], #["Values"] &, First]];
	born = individual[#, {}] & /@ Take[DeleteDuplicates[Join[seeds, Table[pick[], first], Take[library["Programs"], UpTo[first]]]], UpTo[first]];
	population = distinct[born];
	best = First[MaximalBy[population, rank]];
	Do[
		If[stop && best["Matches"] === Length[targets], Break[]];
		generation++;
		With[{young = Table[breed[population], {children}]},
			born = Join[born, young];
			population = distinct[Join[Take[ReverseSortBy[population, rank], UpTo[elites]], young]]
		];
		best = First[MaximalBy[Append[population, best], rank]],
		{generations}
	];
	result = <|"Born" -> born, "Population" -> ReverseSortBy[population, rank], "Generation" -> generation|>;
	Remove[individual, rank, select, pick, breed, distinct];
	result
]

(* settings: PopulationSize, MaxGenerations, EliteCount, MaxNodes, MaxConstant, LibraryCost, StopOnSolve, InitialPopulation
   and the options of ScoreRecursor as a list of rules under ScoreOptions. *)
guidedEvolution[examples_, settings_] := Module[{
	inputs = examples[[All, 1]], targets = examples[[All, 2]], populationSize, generations, elites, maximumNodes, maximumConstant, libraryCost, stop,
	values, complete, nextIdentifier = 0, identifier, half, stepsQ, closed, steps = None, environment, stepValues, toProgram, public, individuals,
	population, best, last, result
},
	{populationSize, generations, elites, maximumNodes, maximumConstant, libraryCost, stop} =
		Lookup[settings, {"PopulationSize", "MaxGenerations", "EliteCount", "MaxNodes", "MaxConstant", "LibraryCost", "StopOnSolve"}];
	identifier = Function[++nextIdentifier];
	values[program_] := values[program] = Quiet[EvaluateRecursor[program, #, Sequence @@ settings["ScoreOptions"]] & /@ inputs];
	complete[program_] := With[{fit = affineFit[values[program], targets]},
		If[fit === None || RecursorNodeCount[program] + 4 > maximumNodes, program, synthesisAffineProgram[program, First[fit], Last[fit]]]
	];
	stepsQ = generations >= 2 && populationSize > elites && DuplicateFreeQ[inputs] && Length[targets] >= 6 && Sort[inputs] === Range[Min[inputs], Max[inputs]];
	half = If[stepsQ, Quotient[generations, 2], generations];
	closed = guidedSearch[targets, closedLibrary[inputs, libraryCost, maximumConstant], values, RecursorNodeCount, complete,
		{populationSize, half, Max[populationSize - elites, 0], elites}, maximumNodes, stop, settings["InitialPopulation"], identifier, 0];
	(* a closed program is itself; its cost is its size *)
	individuals = <|"ID" -> #ID, "Program" -> #Expression, "Parents" -> #Parents, "Generation" -> #Generation, "Score" -> #Matches,
		"Size" -> #Size, "Cost" -> #Size|> & /@ closed["Born"];
	population = closed["Population"][[All, "ID"]];
	last = closed["Generation"];
	If[stepsQ,
		With[{ordered = SortBy[examples, First]},
			environment = stepEnvironment[ordered[[1, 1]], ordered[[All, 2]]];
			stepValues[step_] := stepValues[step] = Replace[synthesisVectorValue[step, environment], scalar_Integer :> ConstantArray[scalar, Length[targets] - 3]];
			steps = guidedSearch[Drop[ordered[[All, 2]], 3], stepLibrary[ordered[[1, 1]], environment, Max[libraryCost - 1, 1], maximumConstant],
				stepValues, stepSize, Identity, {Max[populationSize - elites, 1], generations - half - 1, populationSize - elites, elites},
				Max[maximumNodes - 20, 1], stop, {}, identifier, last + 1];
			(* a step becomes a program with its initial outputs; it costs its step, those outputs as constants and one more *)
			toProgram[step_] := toProgram[step] = With[{seeds = synthesisStepSeeds[step, ordered[[1, 1]], ordered[[All, 2]]]},
				{synthesisRecurrenceProgram[step, seeds, ordered[[1, 1]], ordered[[All, 2]]],
					stepSize[step] + Total[synthesisConstantCost /@ Take[ordered[[All, 2]], seeds]] + 1}
			];
			individuals = Join[individuals, Map[
				With[{made = toProgram[#Expression]},
					<|"ID" -> #ID, "Program" -> First[made], "Parents" -> #Parents, "Generation" -> #Generation,
						"Score" -> Count[MapThread[SameQ, {values[First[made]], targets}], True], "Size" -> RecursorNodeCount[First[made]], "Cost" -> Last[made]|>
				] &,
				steps["Born"]
			]];
			population = Join[population, steps["Population"][[All, "ID"]]];
			last = steps["Generation"]
		]
	];
	public = KeyDrop["Cost"];
	With[{byIdentifier = Association[#ID -> # & /@ individuals], order = Function[one, {one["Score"], -one["Cost"]}]},
		population = Take[ReverseSortBy[Lookup[byIdentifier, population], order], UpTo[populationSize]];
		best = First[MaximalBy[Select[individuals, #Size <= maximumNodes &], order]];
		result = <|
			"Program" -> best["Program"], "Solved" -> best["Score"] === Length[examples], "Fitness" -> best["Score"], "MaxFitness" -> Length[examples],
			"Generations" -> last,
			(* the best score so far among the programs that may be returned: one above MaxNodes is tried but not kept *)
			"FitnessHistory" -> Rest[FoldList[Max, 0, Table[
				Max[Cases[individuals, one_ /; one["Generation"] === generation && one["Size"] <= maximumNodes :> one["Score"]], 0], {generation, 0, last}]]],
			"Population" -> public /@ population, "Genealogy" -> public /@ individuals
		|>
	];
	Remove[values, complete, stepValues, toProgram];
	result
]
