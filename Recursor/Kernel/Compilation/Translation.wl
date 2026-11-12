PackageExported[TranslateRecursor]

TranslateRecursor::usage = "TranslateRecursor[program] gives a Wolfram Language function with the values of a closed Recursor program. \
Method -> \"Literal\" keeps the structure of the program; the default also uses sums, products, counts, searches and known functions \
wherever they give the same values on the inputs tested."

Options[TranslateRecursor] = {Method -> Automatic, "TestInputs" -> 24}

testInputs[count_Integer?NonNegative] := Range[0, count - 1]
testInputs[inputs : {___Integer?NonNegative}] := inputs
testInputs[_] := $Failed

(* The translation is built from formal symbols and inactive heads, so nothing
   runs while it is put together. Arithmetic on naturals that agrees with
   integer arithmetic is written with Plus and Times and simplifies by itself. *)
$inputNames = {\[FormalN] -> "n", \[FormalM] -> "m", \[FormalP] -> "p", \[FormalQ] -> "q"}
$indexNames = {\[FormalI] -> "i", \[FormalJ] -> "j", \[FormalK] -> "k", \[FormalL] -> "l"}
$accumulatorNames = {\[FormalA] -> "a", \[FormalB] -> "b", \[FormalC] -> "c", \[FormalD] -> "d"}
$historyNames = {\[FormalS] -> "s", \[FormalT] -> "t", \[FormalU] -> "u"}
$searchNames = {\[FormalX] -> "x", \[FormalY] -> "y", \[FormalZ] -> "z"}

fresh[environment_, kind_String, names_List] := With[{used = environment[kind]},
	If[used < Length[names], names[[used + 1, 1]], Throw[$Failed, translation]]
]

deeper[environment_, kind_String] := Append[environment, kind -> environment[kind] + 1]

knowing[environment_, fact_] := Append[environment, "Facts" -> Append[environment["Facts"], fact]]

provedQ[statement_, environment_] := TrueQ[Quiet[TimeConstrained[Simplify[statement, And @@ environment["Facts"]], 0.3, False]]]

monus[x_, 0, _] := x
monus[x_Integer, y_Integer, _] := Max[x - y, 0]
monus[x_, y_, environment_] := If[provedQ[x - y >= 0, environment], x - y, Max[x - y, 0]]

(* Rem[a, 0] is a and Quot[a, 0] is zero; a divisor known to be positive needs no test. *)
remainder[x_, 0, _] := x
remainder[x_, y_, environment_] := If[IntegerQ[y] || provedQ[y > 0, environment], Mod[x, y], Inactive[If][y == 0, x, Mod[x, y]]]
quotient[_, 0, _] := 0
quotient[x_, y_, environment_] := If[IntegerQ[y] || provedQ[y > 0, environment], Quotient[x, y], Inactive[If][y == 0, 0, Quotient[x, y]]]

translate[Var, environment_] := environment["Input"]
translate[Acc, environment_] := environment["Accumulator"]
translate[Idx, environment_] := environment["Index"]
translate[Const[c_], _] := c
translate[Succ[a_], environment_] := translate[a, environment] + 1
translate[Pred[a_], environment_] := monus[translate[a, environment], 1, environment]
translate[Half[a_], environment_] := Quotient[translate[a, environment], 2]
translate[Add[a_, b_], environment_] := translate[a, environment] + translate[b, environment]
translate[Mul[a_, b_], environment_] := translate[a, environment] translate[b, environment]
translate[Monus[a_, b_], environment_] := monus[translate[a, environment], translate[b, environment], environment]
translate[Rem[a_, b_], environment_] := remainder[translate[a, environment], translate[b, environment], environment]
translate[Quot[a_, b_], environment_] := quotient[translate[a, environment], translate[b, environment], environment]
translate[Let[value_, body_], environment_] := translate[body, Append[environment, "Input" -> translate[value, environment]]]

translate[Ifz[condition_, zero_, positive_], environment_] := With[{test = translate[condition, environment]},
	If[IntegerQ[test],
		translate[If[test === 0, zero, positive], environment],
		Inactive[If][test == 0, translate[zero, knowing[environment, test == 0]], translate[positive, knowing[environment, test >= 1]]]
	]
]

translate[Iter[count_, base_, step_], environment_] := With[{
	a = fresh[environment, "Accumulators", $accumulatorNames], times = translate[count, environment], start = translate[base, environment]
},
	Inactive[Nest][
		Inactive[Function][a, translate[step, knowing[deeper[Append[environment, "Accumulator" -> a], "Accumulators"], a >= 0]]],
		start, times
	]
]

translate[Rec[count_, base_, step_], environment_] := With[{
	a = fresh[environment, "Accumulators", $accumulatorNames], i = fresh[environment, "Indices", $indexNames],
	times = translate[count, environment], start = translate[base, environment]
},
	Inactive[Fold][
		Inactive[Function][{a, i}, translate[step,
			knowing[knowing[deeper[deeper[Join[environment, <|"Accumulator" -> a, "Index" -> i|>], "Accumulators"], "Indices"], a >= 0], i >= 0]]],
		start, Inactive[Range][0, times - 1]
	]
]

translate[WhileLoop[base_, condition_, step_], environment_] := With[{
	a = fresh[environment, "Accumulators", $accumulatorNames], start = translate[base, environment]
},
	With[{inner = knowing[deeper[Append[environment, "Accumulator" -> a], "Accumulators"], a >= 0]},
		Inactive[NestWhile][Inactive[Function][a, translate[step, inner]], start, Inactive[Function][a, translate[condition, inner] != 0]]
	]
]

(* Course-of-values recursion is a function that remembers its values. CGet
   reads zero outside the earlier indices, so it keeps a test unless its
   argument is known to be earlier. *)
translate[CoRec[count_, step_], environment_] := With[{
	s = fresh[environment, "Histories", $historyNames], i = fresh[environment, "Indices", $indexNames], last = translate[count, environment]
},
	With[{body = translate[step, knowing[deeper[deeper[Join[environment, <|"Index" -> i, "History" -> {s, i}|>], "Histories"], "Indices"], i >= 0]]},
		Inactive[Module][{s},
			Inactive[CompoundExpression][
				Inactive[SetDelayed][s[Inactive[Pattern][i, Blank[]]], Inactive[Set][s[i], body]],
				Inactive[Last][Inactive[Array][s, last + 1, 0]]
			]
		]
	]
]

earlierQ[Quotient[i_, c_Integer], i_, environment_] := c >= 2 && provedQ[i >= 1, environment]
earlierQ[at_, i_, environment_] := provedQ[at < i, environment]

translate[CGet[index_], environment_] := With[{at = translate[index, environment], s = First[environment["History"]], i = Last[environment["History"]]},
	If[earlierQ[at, i, environment], s[at], Inactive[If][at < i, s[at], 0]]
]

literal[program_] := translate[program, <|"Input" -> \[FormalN], "Accumulators" -> 0, "Indices" -> 0, "Histories" -> 0,
	"Facts" -> {\[FormalN] >= 0, Element[Join[$inputNames, $indexNames, $accumulatorNames][[All, 1]], Integers]}|>]

(* Loops whose step uses the accumulator in one fixed way are sums, products,
   counts and powers. *)
freeOf[expression_, symbols__] := FreeQ[expression, Alternatives[symbols]]

shifted[term_, i_, from_, to_] := With[{moved = Expand[term /. i -> i - 1]},
	If[from === 0 && LeafCount[moved] < LeafCount[term], {moved, {i, 1, to + 1}}, {term, {i, from, to}}]
]

$idioms = {
	Inactive[Fold][Inactive[Function][{a_, i_}, step_], start_, Inactive[Range][0, last_]] /; freeOf[Expand[step - a], a] :>
		With[{sum = shifted[Expand[step - a], i, 0, last]}, start + Inactive[Sum][First[sum], Last[sum]]],
	Inactive[Fold][Inactive[Function][{a_, i_}, step_], start_, Inactive[Range][0, last_]] /; step =!= 0 && freeOf[Cancel[step/a], a] :>
		With[{product = shifted[Cancel[step/a], i, 0, last]}, start Inactive[Product][First[product], Last[product]]],
	Inactive[Fold][Inactive[Function][{a_, i_}, Inactive[If][test_, yes_, no_]], start_, Inactive[Range][0, last_]] /;
		Expand[yes - a] === 1 && no === a && freeOf[test, a] :>
		With[{count = shifted[test, i, 0, last]},
			start + Inactive[Count][Inactive[Range] @@ Rest[Last[count]], Inactive[Condition][Inactive[Pattern][i, Blank[]], First[count]]]],
	Inactive[Fold][Inactive[Function][{a_, i_}, Inactive[If][test_, no_, yes_]], start_, Inactive[Range][0, last_]] /;
		Expand[yes - a] === 1 && no === a && freeOf[test, a] :>
		With[{count = shifted[test, i, 0, last]},
			start + Inactive[Count][Inactive[Range] @@ Rest[Last[count]], Inactive[Condition][Inactive[Pattern][i, Blank[]], Inactive[Not][First[count]]]]],
	Inactive[Nest][Inactive[Function][a_, step_], start_, times_] /; freeOf[Expand[step - a], a] :> start + times Expand[step - a],
	Inactive[Nest][Inactive[Function][a_, step_], start_, times_] /; step =!= 0 && freeOf[Cancel[step/a], a] :>
		With[{factor = Cancel[step/a]}, If[IntegerQ[factor] && factor > 0, start factor^times, Inactive[If][times == 0, start, start factor^times]]],
	Inactive[Sum][0, _] :> 0,
	Inactive[Product][1, _] :> 1,
	(* a term that is zero at index zero starts the sum at one *)
	Inactive[Sum][Inactive[If][i_ == 0, 0, term_], {i_, 0, last_}] :> Inactive[Sum][term, {i, 1, last}],
	Inactive[Product][Inactive[If][i_ == 0, 1, term_], {i_, 0, last_}] :> Inactive[Product][term, {i, 1, last}],
	module : Inactive[Module][{_}, Inactive[CompoundExpression][Inactive[SetDelayed][__], _]] :> seeded[module]
}

(* Initial values of a course-of-values recursion become definitions of their
   own: a test on the index that holds for a few first indices only. *)
seeded[module : Inactive[Module][{s_}, Inactive[CompoundExpression][Inactive[SetDelayed][s_[Inactive[Pattern][i_, Blank[]]], Inactive[Set][s_[i_], body_]], result_]]] :=
	Module[{rest = body, seeds = {}, covered = {}, indices},
		While[MatchQ[rest, Inactive[If][_, value_ /; FreeQ[value, i | s], _]],
			indices = Select[Range[0, 12], TrueQ[Quiet[First[rest] /. i -> #]] &];
			If[indices === {} || Max[indices] === 12, Break[]];
			seeds = Join[seeds, Inactive[Set][s[#], rest[[2]]] & /@ Complement[indices, covered]];
			covered = Union[covered, indices];
			rest = rest[[3]]
		];
		If[seeds === {} || covered =!= Range[0, Max[covered]], module,
			Inactive[Module][{s}, Inactive[CompoundExpression] @@ Join[seeds,
				{Inactive[SetDelayed][s[Inactive[Pattern][i, Blank[]]], Inactive[Set][s[i], rest]], result}]]
		]
	]
seeded[module_] := module

(* d compared with zero, written with its integer on the right. *)
balanced[d_, relation_] := With[{constant = Replace[d, {Plus[c_Integer, ___] :> c, _ -> 0}]},
	With[{rest = d - constant},
		If[MatchQ[rest, Times[_?Negative, __]],
			(relation /. {LessEqual -> GreaterEqual, Greater -> Less})[-rest, constant],
			relation[rest, -constant]
		]
	]
]

(* Properties written as tests for zero read better as comparisons. *)
$comparisons = {
	(Max[d_, 0] + Max[e_, 0] == 0) /; Expand[d + e] === 0 :> balanced[d, Equal],
	(Max[d_, 0] + Max[e_, 0] != 0) /; Expand[d + e] === 0 :> balanced[d, Unequal],
	(Max[d_, 0] == 0) :> balanced[d, LessEqual],
	(Max[d_, 0] != 0) :> balanced[d, Greater],
	(Inactive[If][test_, 1, 0] == 0) :> Inactive[Not][test],
	(Inactive[If][test_, 1, 0] != 0) :> test,
	(Inactive[If][test_, 0, 1] == 0) :> test,
	(Inactive[If][test_, 0, 1] != 0) :> Inactive[Not][test],
	Inactive[Not][x_ == y_] :> (x != y),
	Inactive[Not][x_ != y_] :> (x == y),
	Inactive[Not][Inactive[Not][x_]] :> x,
	(d_ == 0) /; MatchQ[d, Plus[_Integer, __]] :> balanced[d, Equal],
	(relation : Equal | Unequal | Less | LessEqual | Greater | GreaterEqual)[Plus[c_Integer, rest__], k_Integer] :> relation[Plus[rest], k - c],
	(Mod[x_, y_] == 0) :> Inactive[Divisible][x, y],
	(Mod[x_, y_] != 0) :> Inactive[Not][Inactive[Divisible][x, y]],
	(* a remainder by zero is the number itself, which is zero only at zero *)
	Inactive[Count][Inactive[Range][0, last_], Inactive[Condition][pattern_, Inactive[If][i_ == 0, x_, Mod[x_, i_]] == 0]] :>
		Inactive[Count][Inactive[Range][1, last], Inactive[Condition][pattern, Inactive[Divisible][x, i]]],
	c_Integer + Max[0, d_] /; c > 0 && MatchQ[d, Plus[_Integer, __]] && First[d] === -c :> Max[c, d + c]
}

(* Known functions, kept only where the values agree on the inputs tested. *)
$known = {
	Inactive[Count][Inactive[Range][1, x_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]] :> Inactive[DivisorSigma][0, x],
	Inactive[Count][Inactive[Range][1, last_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]] /; Expand[last - x] === -1 :>
		Inactive[DivisorSigma][0, x] - 1,
	Inactive[Sum][i_ Inactive[Boole][Inactive[Divisible][x_, i_]], {i_, 1, x_}] :> Inactive[DivisorSigma][1, x],
	(Inactive[DivisorSigma][0, x_] == 2) :> Inactive[PrimeQ][x],
	(Inactive[DivisorSigma][0, x_] != 2) :> Inactive[Not][Inactive[PrimeQ][x]],
	(Inactive[DivisorSigma][0, x_] >= 3) :> Inactive[CompositeQ][x],
	(Inactive[DivisorSigma][0, x_] < 3) :> Inactive[Not][Inactive[CompositeQ][x]],
	(* divisors below the number itself: one for a prime, two or more for a composite *)
	(proper : Inactive[Count][Inactive[Range][1, last_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]]) == 1 /;
		Expand[last - x] === -1 :> Inactive[PrimeQ][x],
	(proper : Inactive[Count][Inactive[Range][1, last_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]]) != 1 /;
		Expand[last - x] === -1 :> Inactive[Not][Inactive[PrimeQ][x]],
	(proper : Inactive[Count][Inactive[Range][1, last_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]]) >= 2 /;
		Expand[last - x] === -1 :> Inactive[CompositeQ][x],
	(proper : Inactive[Count][Inactive[Range][1, last_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[Divisible][x_, i_]]]) < 2 /;
		Expand[last - x] === -1 :> Inactive[Not][Inactive[CompositeQ][x]],
	Inactive[Count][Inactive[Range][0 | 1, x_], Inactive[Condition][Inactive[Pattern][i_, Blank[]], Inactive[PrimeQ][i_]]] :> Inactive[PrimePi][x],
	Inactive[Product][i_, {i_, 1, x_}] :> Inactive[Factorial][x],
	(* the search for the t-th prime from a start of at most two *)
	Max[-1 + Inactive[Nest][
		Inactive[Function][a_, 1 + Inactive[NestWhile][Inactive[Function][b_, 1 + b_], a_, Inactive[Function][b_, Inactive[Not][Inactive[PrimeQ][b_]]]]],
		start_Integer, times_], 0] /; start <= 2 :> Inactive[Prime][times]
}

(* Sums and products that the system can do in closed form. *)
closed[expression_] := Quiet[TimeConstrained[
	(expression /. {Inactive[Sum] -> Sum, Inactive[Product] -> Product}) /. {Sum -> Inactive[Sum], Product -> Inactive[Product]},
	3, expression
]]

rewrite[expression_, rules_] := FixedPoint[Replace[#, rules, {0, Infinity}] &, expression, 12]

(* One-argument functions without inner functions are written with slots. *)
slots[expression_] := expression //. Inactive[Function][a_Symbol, body_] /; FreeQ[body, Inactive[Function]] :> Inactive[Function][body /. a -> Slot[1]]

(* A candidate becomes held code in the symbols of the caller's context. *)
symbolRules[] := Map[
	With[{formal = First[#]}, Replace[ToExpression[Last[#], InputForm, Hold], Hold[symbol_] :> (HoldPattern[formal] :> symbol)]] &,
	Join[$inputNames, $indexNames, $accumulatorNames, $historyNames, $searchNames]
]

code[candidate_] := Replace[
	Hold[\[FormalN], candidate] //. Inactive[head_] :> head /. symbolRules[],
	Hold[variable_, body_] :> Function[variable, body]
]

(* Values of a translation at the inputs, or $Failed where it does not finish. *)
values[function_, inputs_] := Quiet[Map[TimeConstrained[function[#], 5, $Failed] &, inputs]]

agreesQ[candidate_, inputs_, reference_] := With[{function = code[candidate]}, MatchQ[function, _Function] && values[function, inputs] === reference]

(* The inputs on which the program finishes, up to the first on which it does not, with its values. *)
referenceValues[program_, tested_List] := Module[{inputs = {}, outputs = {}, value},
	Do[
		value = EvaluateRecursor[program, n, "MaxSteps" -> 2000000, "TimeLimit" -> 5];
		If[! IntegerQ[value], Break[]];
		AppendTo[inputs, n]; AppendTo[outputs, value],
		{n, tested}
	];
	{inputs, outputs}
]

TranslateRecursor::differs = "The translation does not reproduce the values of the program."

TranslateRecursor[program_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{
	method = OptionValue[Method], tested = testInputs[OptionValue["TestInputs"]], base, inputs, reference, candidates, chosen
},
	ConfirmAssert[MemberQ[{Automatic, "Literal"}, method], "Method must be Automatic or \"Literal\"."];
	ConfirmAssert[ListQ[tested], "TestInputs must be a nonnegative integer or a list of natural numbers."];
	base = Catch[literal[program], translation];
	ConfirmAssert[base =!= $Failed, "The program nests more loops than the translation names."];
	{inputs, reference} = referenceValues[program, tested];
	If[! agreesQ[base, inputs, reference], Message[TranslateRecursor::differs]; Return[Failure["TranslationFailure", <|"MessageTemplate" -> "The translation does not reproduce the values of the program."|>], Module]];
	If[method === "Literal", Return[code[slots[base]], Module]];
	candidates = With[{idioms = rewrite[base, $idioms]},
		With[{compared = rewrite[idioms, $comparisons]},
			With[{known = rewrite[compared, Join[$known, $comparisons]]},
				DeleteDuplicates[slots /@ {closed[known], known, closed[compared], compared, idioms, base}]
			]
		]
	];
	chosen = SelectFirst[candidates, agreesQ[#, inputs, reference] &, slots[base]];
	code[chosen]
]
