(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[TranslateRecursor]

(* ::Section:: *)
(*Usage Messages*)

TranslateRecursor::usage = "TranslateRecursor[program] gives a Wolfram Language function with the values of a closed Recursor program. \
Method -> \"Literal\" keeps the structure of the program; the default also uses sums, products, counts, searches and known functions \
wherever they give the same values on the inputs tested."

TranslateRecursor::differs = "The translation does not reproduce the values of the program."

$inputNames::usage = "$inputNames lists the formal symbols that stand for inputs in a translation, each with the name it is written with."

$indexNames::usage = "$indexNames lists the formal symbols that stand for loop indices in a translation, each with the name it is written with."

$accumulatorNames::usage = "$accumulatorNames lists the formal symbols that stand for accumulators in a translation, each with the name it is written with."

$historyNames::usage = "$historyNames lists the formal symbols that stand for remembered functions in a translation, each with the name it is written with."

$searchNames::usage = "$searchNames lists the formal symbols that stand for searched values in a translation, each with the name it is written with."

$idioms::usage = "$idioms lists the rules that rewrite loops of a translation as sums, products, counts, multiples and powers."

$comparisons::usage = "$comparisons lists the rules that rewrite tests for zero in a translation as comparisons."

$knownFunctions::usage = "$knownFunctions lists the rules that rewrite parts of a translation as named functions, such as DivisorSigma, PrimeQ, \
PrimePi, Factorial and Prime."

testInputList::usage = "testInputList[setting] gives the inputs that the setting of the option \"TestInputs\" names: the first setting naturals \
for a count, and a list of naturals itself. Any other setting gives a Failure."

formulaQ::usage = "formulaQ[expression] gives True when expression is an exact number, a symbol or a compound expression, which is what a \
translation is made of, and False otherwise."

freshSymbol::usage = "freshSymbol[environment, kind, names] gives the first formal symbol of names that the enclosing loops do not use. kind is the \
key of environment that counts the symbols in use. With no symbol left, it throws a Failure to the tag \"TranslationNames\"."

deeper::usage = "deeper[environment, kind] gives environment with one more symbol of the kind in use."

knowing::usage = "knowing[environment, fact] gives environment with fact added to what is known of its symbols."

provedQ::usage = "provedQ[statement, environment] gives True when Simplify proves statement from the facts of environment within a short time, \
and False otherwise."

monusForm::usage = "monusForm[minuend, subtrahend, environment] gives the translation of a truncated subtraction, without Max when the difference \
is known to be nonnegative."

remainderForm::usage = "remainderForm[dividend, divisor, environment] gives the translation of Rem, without a test for a zero divisor when the \
divisor is known to be positive."

quotientForm::usage = "quotientForm[dividend, divisor, environment] gives the translation of Quot, without a test for a zero divisor when the \
divisor is known to be positive."

translate::usage = "translate[expression, environment] gives the translation of a Recursor expression, built from formal symbols and inactive \
heads. environment gives the translations bound to \"Input\", \"Accumulator\", \"Index\" and \"History\", the counts of symbols in use and the \"Facts\" known."

earlierQ::usage = "earlierQ[position, index, environment] gives True when position is known to be less than index, and False otherwise."

literalTranslation::usage = "literalTranslation[program] gives the translation that keeps the structure of a closed Recursor program, with \
\\[FormalN] as its input."

freeOf::usage = "freeOf[expression, symbol1, symbol2, ...] gives True when expression has none of the symbols, and False otherwise."

shiftedRange::usage = "shiftedRange[term, index, from, last] gives {term, {index, from, last}}, or the same with the index moved up by one when \
from is zero and that makes the term shorter."

countForm::usage = "countForm[test, index, last, wrapper] gives the inactive Count of the indices from zero to last on which wrapper[test] holds. \
wrapper is Identity or Inactive[Not]."

powerForm::usage = "powerForm[start, factor, times] gives the translation of start multiplied times times by factor. It tests for a zero count \
unless factor is a positive integer."

seedStep::usage = "seedStep[{rest, seeds, covered}, index, history] moves the first branch of rest to seeds when it is a constant that holds on \
a few first values of index only, and gives the state unchanged otherwise. seeds are definitions of history and covered lists their indices."

seededModule::usage = "seededModule[module] gives the remembered function module with its initial values written as definitions of their own, or \
module itself when it has none."

balancedRelation::usage = "balancedRelation[difference, relation] gives relation[difference, 0] written with the integer of difference on the right."

closedForm::usage = "closedForm[expression] gives expression with each inactive sum and product that the system can do replaced by its closed form."

rewriteAll::usage = "rewriteAll[expression, rules] applies rules to all parts of expression until nothing changes, at most twelve times."

slotForm::usage = "slotForm[expression] gives expression with each one-argument inactive function that has no inner function written with a slot."

symbolRule::usage = "symbolRule[formal -> name] gives a rule that replaces the formal symbol by the symbol with that name in the current context."

symbolRules::usage = "symbolRules[] gives the rules that replace every formal symbol of a translation by the symbol it is written with."

functionCode::usage = "functionCode[candidate] gives the Function of the translation candidate, with active heads and the symbols of the caller's context."

translationValues::usage = "translationValues[translated, inputs] gives the values of the function translated at inputs, with a Failure where \
it does not finish in time."

agreesQ::usage = "agreesQ[candidate, inputs, reference] gives True when the function of candidate has the values reference at inputs, and False otherwise."

referenceStep::usage = "referenceStep[outputs, input, program] appends the value of program at input to outputs, unless outputs ends with a \
value that is not an integer."

referenceValues::usage = "referenceValues[program, tested] gives {inputs, outputs}: the inputs of tested on which program finishes, up to the \
first on which it does not, and its values."

candidateTranslations::usage = "candidateTranslations[base] lists the rewritten forms of the literal translation base, from the most rewritten to base itself."

differingFailure::usage = "differingFailure[] issues the message TranslateRecursor::differs and gives the Failure with the tag \"TranslationFailure\"."

(* ::Section:: *)
(*Function Definitions*)

Options[TranslateRecursor] = {Method -> Automatic, "TestInputs" -> 24}

testInputList[count_Integer?NonNegative] := Range[0, count - 1]
testInputList[inputs : {___Integer?NonNegative}] := inputs
testInputList[_] := Failure["InvalidTestInputs", <|"MessageTemplate" -> "TestInputs must be a nonnegative integer or a list of natural numbers."|>]

(* The translation is built from formal symbols and inactive heads, so nothing
   runs while it is put together. Arithmetic on naturals that agrees with
   integer arithmetic is written with Plus and Times and simplifies by itself. *)
$inputNames = {\[FormalN] -> "n", \[FormalM] -> "m", \[FormalP] -> "p", \[FormalQ] -> "q"}
$indexNames = {\[FormalI] -> "i", \[FormalJ] -> "j", \[FormalK] -> "k", \[FormalL] -> "l"}
$accumulatorNames = {\[FormalA] -> "a", \[FormalB] -> "b", \[FormalC] -> "c", \[FormalD] -> "d"}
$historyNames = {\[FormalS] -> "s", \[FormalT] -> "t", \[FormalU] -> "u"}
$searchNames = {\[FormalX] -> "x", \[FormalY] -> "y", \[FormalZ] -> "z"}

formulaQ[_Integer | _Rational | _Symbol | _[___]] := True
formulaQ[___] := False

freshSymbol[environment_Association, kind_String, names : {__Rule}] :=
	Module[{used},
		used = environment[kind];
		If[used < Length[names],
			Keys[names][[used + 1]],
			Throw[Failure["NamesExhausted", <|"MessageTemplate" -> "The program nests more loops than the translation names."|>], "TranslationNames"]
		]
	]

deeper[environment_Association, kind_String] := Append[environment, kind -> environment[kind] + 1]

knowing[environment_Association, fact_?formulaQ] := Append[environment, "Facts" -> Append[environment["Facts"], fact]]

(* Simplify warns of facts that contradict each other, as they do in a branch that cannot be taken. *)
provedQ[statement_?formulaQ, environment_Association] := TrueQ @ Quiet[
	TimeConstrained[Simplify[statement, environment["Facts"]], 0.3, False],
	{Simplify::cas, Mod::indet, Quotient::indet, Quotient::infy, Power::infy, Power::indet, Infinity::indet}
]

monusForm[minuend_?formulaQ, 0, _Association] := minuend
monusForm[minuend_Integer, subtrahend_Integer, _Association] := Max[minuend - subtrahend, 0]
monusForm[minuend_?formulaQ, subtrahend_?formulaQ, environment_Association] :=
	If[provedQ[minuend - subtrahend >= 0, environment], minuend - subtrahend, Max[minuend - subtrahend, 0]]

(* Rem[a, 0] is a and Quot[a, 0] is zero; a divisor known to be positive needs no test. *)
remainderForm[dividend_?formulaQ, 0, _Association] := dividend
remainderForm[dividend_?formulaQ, divisor_?formulaQ, environment_Association] :=
	If[IntegerQ[divisor] || provedQ[divisor > 0, environment], Mod[dividend, divisor], Inactive[If][divisor == 0, dividend, Mod[dividend, divisor]]]

quotientForm[_?formulaQ, 0, _Association] := 0
quotientForm[dividend_?formulaQ, divisor_?formulaQ, environment_Association] :=
	If[IntegerQ[divisor] || provedQ[divisor > 0, environment], Quotient[dividend, divisor], Inactive[If][divisor == 0, 0, Quotient[dividend, divisor]]]

translate[Var, environment_Association] := environment["Input"]
translate[Acc, environment_Association] := environment["Accumulator"]
translate[Idx, environment_Association] := environment["Index"]
translate[Const[value_], _Association] := value
translate[Succ[argument_], environment_Association] := translate[argument, environment] + 1
translate[Pred[argument_], environment_Association] := monusForm[translate[argument, environment], 1, environment]
translate[Half[argument_], environment_Association] := Quotient[translate[argument, environment], 2]
translate[Add[left_, right_], environment_Association] := translate[left, environment] + translate[right, environment]
translate[Mul[left_, right_], environment_Association] := translate[left, environment] * translate[right, environment]
translate[Monus[left_, right_], environment_Association] := monusForm[translate[left, environment], translate[right, environment], environment]
translate[Rem[left_, right_], environment_Association] := remainderForm[translate[left, environment], translate[right, environment], environment]
translate[Quot[left_, right_], environment_Association] := quotientForm[translate[left, environment], translate[right, environment], environment]
translate[Let[value_, body_], environment_Association] := translate[body, Append[environment, "Input" -> translate[value, environment]]]

translate[Ifz[condition_, zero_, positive_], environment_Association] :=
	Module[{test},
		test = translate[condition, environment];
		If[IntegerQ[test],
			translate[If[test === 0, zero, positive], environment],
			Inactive[If][test == 0, translate[zero, knowing[environment, test == 0]], translate[positive, knowing[environment, test >= 1]]]
		]
	]

translate[Iter[count_, base_, step_], environment_Association] :=
	Module[{accumulator, times, start, inner},
		accumulator = freshSymbol[environment, "Accumulators", $accumulatorNames];
		times = translate[count, environment];
		start = translate[base, environment];
		inner = knowing[deeper[Append[environment, "Accumulator" -> accumulator], "Accumulators"], accumulator >= 0];
		Inactive[Nest][Inactive[Function][accumulator, translate[step, inner]], start, times]
	]

translate[Rec[count_, base_, step_], environment_Association] :=
	Module[{accumulator, index, times, start, bound, inner},
		accumulator = freshSymbol[environment, "Accumulators", $accumulatorNames];
		index = freshSymbol[environment, "Indices", $indexNames];
		times = translate[count, environment];
		start = translate[base, environment];
		bound = deeper[deeper[Join[environment, <|"Accumulator" -> accumulator, "Index" -> index|>], "Accumulators"], "Indices"];
		inner = knowing[knowing[bound, accumulator >= 0], index >= 0];
		Inactive[Fold][Inactive[Function][{accumulator, index}, translate[step, inner]], start, Inactive[Range][0, times - 1]]
	]

translate[WhileLoop[base_, condition_, step_], environment_Association] :=
	Module[{accumulator, start, inner},
		accumulator = freshSymbol[environment, "Accumulators", $accumulatorNames];
		start = translate[base, environment];
		inner = knowing[deeper[Append[environment, "Accumulator" -> accumulator], "Accumulators"], accumulator >= 0];
		Inactive[NestWhile][
			Inactive[Function][accumulator, translate[step, inner]],
			start,
			Inactive[Function][accumulator, translate[condition, inner] != 0]
		]
	]

(* Course-of-values recursion is a function that remembers its values. CGet
   reads zero outside the earlier indices, so it keeps a test unless its
   argument is known to be earlier. *)
translate[CoRec[count_, step_], environment_Association] :=
	Module[{history, index, lastIndex, bound, body},
		history = freshSymbol[environment, "Histories", $historyNames];
		index = freshSymbol[environment, "Indices", $indexNames];
		lastIndex = translate[count, environment];
		bound = deeper[deeper[Join[environment, <|"Index" -> index, "History" -> {history, index}|>], "Histories"], "Indices"];
		body = translate[step, knowing[bound, index >= 0]];
		Inactive[Module][{history},
			Inactive[CompoundExpression][
				Inactive[SetDelayed][history[Inactive[Pattern][index, Blank[]]], Inactive[Set][history[index], body]],
				Inactive[Last][Inactive[Array][history, lastIndex + 1, 0]]
			]
		]
	]

translate[CGet[argument_], environment_Association] :=
	Module[{position, history, index},
		position = translate[argument, environment];
		{history, index} = environment["History"];
		If[earlierQ[position, index, environment], history[position], Inactive[If][position < index, history[position], 0]]
	]

earlierQ[Quotient[index_, divisor_Integer], index_, environment_Association] := divisor >= 2 && provedQ[index >= 1, environment]
earlierQ[position_?formulaQ, index_Symbol, environment_Association] := provedQ[position < index, environment]

literalTranslation[program_?RecursorProgramQ] := translate[program, <|
	"Input" -> \[FormalN], "Accumulators" -> 0, "Indices" -> 0, "Histories" -> 0,
	"Facts" -> {\[FormalN] >= 0, Element[Keys[Join[$inputNames, $indexNames, $accumulatorNames]], Integers]}
|>]

(* Loops whose step uses the accumulator in one fixed way are sums, products,
   counts and powers. *)
freeOf[expression_?formulaQ, symbols__Symbol] := FreeQ[expression, Alternatives[symbols]]

shiftedRange[term_?formulaQ, index_Symbol, from_Integer, last_?formulaQ] :=
	Module[{moved},
		moved = Expand[term /. index -> index - 1];
		If[from === 0 && LeafCount[moved] < LeafCount[term], {moved, {index, 1, last + 1}}, {term, {index, from, last}}]
	]

countForm[test_?formulaQ, index_Symbol, last_?formulaQ, wrapper : (Identity | Inactive[Not])] :=
	Module[{shifted},
		shifted = shiftedRange[test, index, 0, last];
		Inactive[Count][Inactive[Range] @@ Rest[Last[shifted]], Inactive[Condition][Inactive[Pattern][index, Blank[]], wrapper[First[shifted]]]]
	]

powerForm[start_?formulaQ, factor_?formulaQ, times_?formulaQ] :=
	If[IntegerQ[factor] && factor > 0, start * factor ^ times, Inactive[If][times == 0, start, start * factor ^ times]]

$idioms = {
	Inactive[Fold][
		Inactive[Function][{accumulator_, index_}, step_], start_, Inactive[Range][0, last_]
	] /; freeOf[Expand[step - accumulator], accumulator] :> start + Inactive[Sum] @@ shiftedRange[Expand[step - accumulator], index, 0, last],
	Inactive[Fold][
		Inactive[Function][{accumulator_, index_}, step_], start_, Inactive[Range][0, last_]
	] /; step =!= 0 && freeOf[Cancel[step / accumulator], accumulator] :> start * Inactive[Product] @@ shiftedRange[Cancel[step / accumulator], index, 0, last],
	Inactive[Fold][
		Inactive[Function][{accumulator_, index_}, Inactive[If][test_, counted_, kept_]], start_, Inactive[Range][0, last_]
	] /; Expand[counted - accumulator] === 1 && kept === accumulator && freeOf[test, accumulator] :> start + countForm[test, index, last, Identity],
	Inactive[Fold][
		Inactive[Function][{accumulator_, index_}, Inactive[If][test_, kept_, counted_]], start_, Inactive[Range][0, last_]
	] /; Expand[counted - accumulator] === 1 && kept === accumulator && freeOf[test, accumulator] :> start + countForm[test, index, last, Inactive[Not]],
	Inactive[Nest][
		Inactive[Function][accumulator_, step_], start_, times_
	] /; freeOf[Expand[step - accumulator], accumulator] :> start + times * Expand[step - accumulator],
	Inactive[Nest][
		Inactive[Function][accumulator_, step_], start_, times_
	] /; step =!= 0 && freeOf[Cancel[step / accumulator], accumulator] :> powerForm[start, Cancel[step / accumulator], times],
	Inactive[Sum][0, _] :> 0,
	Inactive[Product][1, _] :> 1,
	(* a term that is zero at index zero starts the sum at one *)
	Inactive[Sum][Inactive[If][index_ == 0, 0, term_], {index_, 0, last_}] :> Inactive[Sum][term, {index, 1, last}],
	Inactive[Product][Inactive[If][index_ == 0, 1, term_], {index_, 0, last_}] :> Inactive[Product][term, {index, 1, last}],
	module : Inactive[Module][{_}, Inactive[CompoundExpression][Inactive[SetDelayed][__], _]] :> seededModule[module]
}

(* Initial values of a course-of-values recursion become definitions of their
   own: a test on the index that holds for a few first indices only. *)
seedStep[{Inactive[If][test_, value_, otherwise_], seeds_List, covered_List}, index_Symbol, history_Symbol] :=
	Module[{indices},
		indices = If[FreeQ[value, index | history],
			Select[Range[0, 12], TrueQ[Quiet[test /. index -> #, {Mod::indet, Quotient::indet, Quotient::infy, Power::infy, Power::indet, Infinity::indet}]] &],
			{}
		];
		If[indices === {} || Max[indices] === 12,
			{Inactive[If][test, value, otherwise], seeds, covered},
			{otherwise, Join[seeds, Map[Inactive[Set][history[#], value] &, Complement[indices, covered]]], Union[covered, indices]}
		]
	]
seedStep[state_List, _Symbol, _Symbol] := state

seededModule[
	module : Inactive[Module][
		{history_Symbol},
		Inactive[CompoundExpression][Inactive[SetDelayed][history_[Inactive[Pattern][index_Symbol, Blank[]]], Inactive[Set][history_[index_], body_]], result_]
	]
] :=
	Module[{rest, seeds, covered},
		{rest, seeds, covered} = FixedPoint[Function[state, seedStep[state, index, history]], {body, {}, {}}];
		If[seeds === {} || covered =!= Range[0, Max[covered]],
			module,
			Inactive[Module][
				{history},
				Inactive[CompoundExpression] @@ Join[
					seeds,
					{Inactive[SetDelayed][history[Inactive[Pattern][index, Blank[]]], Inactive[Set][history[index], rest]], result}
				]
			]
		]
	]
seededModule[module_] := module

(* The difference compared with zero, written with its integer on the right. *)
balancedRelation[difference_?formulaQ, relation_Symbol] :=
	Module[{constant, rest},
		constant = Replace[difference, {Plus[integer_Integer, ___] :> integer, _ -> 0}];
		rest = difference - constant;
		If[MatchQ[rest, Times[_?Negative, __]],
			Replace[relation, {LessEqual -> GreaterEqual, Greater -> Less}][-rest, constant],
			relation[rest, -constant]
		]
	]

(* Properties written as tests for zero read better as comparisons. *)
$comparisons = {
	(Max[difference_, 0] + Max[opposite_, 0] == 0) /; Expand[difference + opposite] === 0 :> balancedRelation[difference, Equal],
	(Max[difference_, 0] + Max[opposite_, 0] != 0) /; Expand[difference + opposite] === 0 :> balancedRelation[difference, Unequal],
	(Max[difference_, 0] == 0) :> balancedRelation[difference, LessEqual],
	(Max[difference_, 0] != 0) :> balancedRelation[difference, Greater],
	(Inactive[If][test_, 1, 0] == 0) :> Inactive[Not][test],
	(Inactive[If][test_, 1, 0] != 0) :> test,
	(Inactive[If][test_, 0, 1] == 0) :> test,
	(Inactive[If][test_, 0, 1] != 0) :> Inactive[Not][test],
	Inactive[Not][left_ == right_] :> (left != right),
	Inactive[Not][left_ != right_] :> (left == right),
	Inactive[Not][Inactive[Not][test_]] :> test,
	(difference_ == 0) /; MatchQ[difference, Plus[_Integer, __]] :> balancedRelation[difference, Equal],
	(relation : Equal | Unequal | Less | LessEqual | Greater | GreaterEqual)[Plus[constant_Integer, terms__], limit_Integer] :> relation[Plus[terms], limit - constant],
	(Mod[dividend_, divisor_] == 0) :> Inactive[Divisible][dividend, divisor],
	(Mod[dividend_, divisor_] != 0) :> Inactive[Not][Inactive[Divisible][dividend, divisor]],
	(* a remainder by zero is the number itself, which is zero only at zero *)
	Inactive[Count][
		Inactive[Range][0, last_],
		Inactive[Condition][pattern_, Inactive[If][index_ == 0, dividend_, Mod[dividend_, index_]] == 0]
	] :> Inactive[Count][Inactive[Range][1, last], Inactive[Condition][pattern, Inactive[Divisible][dividend, index]]],
	constant_Integer + Max[0, difference_] /; constant > 0 && MatchQ[difference, Plus[_Integer, __]] && First[difference] === -constant :> Max[constant, difference + constant]
}

(* Known functions, kept only where the values agree on the inputs tested. *)
$knownFunctions = {
	Inactive[Count][
		Inactive[Range][1, number_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] :> Inactive[DivisorSigma][0, number],
	Inactive[Count][
		Inactive[Range][1, last_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] /; Expand[last - number] === -1 :> Inactive[DivisorSigma][0, number] - 1,
	Inactive[Sum][index_ * Inactive[Boole][Inactive[Divisible][number_, index_]], {index_, 1, number_}] :> Inactive[DivisorSigma][1, number],
	(Inactive[DivisorSigma][0, number_] == 2) :> Inactive[PrimeQ][number],
	(Inactive[DivisorSigma][0, number_] != 2) :> Inactive[Not][Inactive[PrimeQ][number]],
	(Inactive[DivisorSigma][0, number_] >= 3) :> Inactive[CompositeQ][number],
	(Inactive[DivisorSigma][0, number_] < 3) :> Inactive[Not][Inactive[CompositeQ][number]],
	(* divisors below the number itself: one for a prime, two or more for a composite *)
	Inactive[Count][
		Inactive[Range][1, last_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] == 1 /; Expand[last - number] === -1 :> Inactive[PrimeQ][number],
	Inactive[Count][
		Inactive[Range][1, last_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] != 1 /; Expand[last - number] === -1 :> Inactive[Not][Inactive[PrimeQ][number]],
	Inactive[Count][
		Inactive[Range][1, last_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] >= 2 /; Expand[last - number] === -1 :> Inactive[CompositeQ][number],
	Inactive[Count][
		Inactive[Range][1, last_],
		Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[Divisible][number_, index_]]
	] < 2 /; Expand[last - number] === -1 :> Inactive[Not][Inactive[CompositeQ][number]],
	Inactive[Count][Inactive[Range][0 | 1, number_], Inactive[Condition][Inactive[Pattern][index_, Blank[]], Inactive[PrimeQ][index_]]] :> Inactive[PrimePi][number],
	Inactive[Product][index_, {index_, 1, number_}] :> Inactive[Factorial][number],
	(* the search for the t-th prime from a start of at most two *)
	Max[
		-1 + Inactive[Nest][
			Inactive[Function][
				outer_,
				1 + Inactive[NestWhile][Inactive[Function][inner_, 1 + inner_], outer_, Inactive[Function][inner_, Inactive[Not][Inactive[PrimeQ][inner_]]]]
			],
			start_Integer,
			times_
		],
		0
	] /; start <= 2 :> Inactive[Prime][times]
}

(* Sums and products that the system can do in closed form. *)
closedForm[expression_?formulaQ] := Quiet[
	TimeConstrained[
		(expression /. {Inactive[Sum] -> Sum, Inactive[Product] -> Product}) /. {Sum -> Inactive[Sum], Product -> Inactive[Product]},
		3,
		expression
	],
	{Mod::indet, Quotient::indet, Quotient::infy, Power::infy, Power::indet, Infinity::indet}
]

rewriteAll[expression_?formulaQ, rules_List] := FixedPoint[Replace[#, rules, {0, Infinity}] &, expression, 12]

(* One-argument functions without inner functions are written with slots. *)
slotForm[expression_?formulaQ] :=
	expression //. Inactive[Function][variable_Symbol, body_] /; FreeQ[body, Inactive[Function]] :> Inactive[Function][body /. variable -> Slot[1]]

(* A candidate becomes held code in the symbols of the caller's context. *)
symbolRule[formal_Symbol -> name_String] := Replace[ToExpression[name, InputForm, Hold], Hold[symbol_] :> (HoldPattern[formal] :> symbol)]

symbolRules[] := Map[symbolRule, Join[$inputNames, $indexNames, $accumulatorNames, $historyNames, $searchNames]]

functionCode[candidate_?formulaQ] := Replace[
	Hold[\[FormalN], candidate] //. Inactive[head_] :> head /. symbolRules[],
	Hold[variable_, body_] :> Function[variable, body]
]

(* Values of a translation at the inputs, or a Failure where it does not finish. A candidate is code that was
   rewritten by rules and is run only to see its values. One that is wrong can issue any message, such as
   Prime::intpp, Function::flpar or Pattern::patvar, so all of its messages are quieted, not a list of them. *)
translationValues[translated_Function, inputs_List] := Quiet[
	Map[TimeConstrained[translated[#], 5, recursorFailure["TimeLimit"]] &, inputs],
	All
]

agreesQ[candidate_?formulaQ, inputs_List, reference_List] :=
	Module[{translated},
		translated = functionCode[candidate];
		MatchQ[translated, _Function] && translationValues[translated, inputs] === reference
	]

referenceStep[outputs : {___Integer}, input_Integer, program_?RecursorProgramQ] :=
	Append[outputs, EvaluateRecursor[program, input, "MaxSteps" -> 2000000, "TimeLimit" -> 5]]
referenceStep[outputs_List, _Integer, _] := outputs

(* The inputs on which the program finishes, up to the first on which it does not, with its values. *)
referenceValues[program_?RecursorProgramQ, tested_List] :=
	Module[{outputs},
		outputs = Cases[Fold[Function[{found, input}, referenceStep[found, input, program]], {}, tested], _Integer];
		{Take[tested, Length[outputs]], outputs}
	]

candidateTranslations[base_?formulaQ] :=
	Module[{idioms, compared, known},
		idioms = rewriteAll[base, $idioms];
		compared = rewriteAll[idioms, $comparisons];
		known = rewriteAll[compared, Join[$knownFunctions, $comparisons]];
		DeleteDuplicates[Map[slotForm, {closedForm[known], known, closedForm[compared], compared, idioms, base}]]
	]

differingFailure[] := (
	Message[TranslateRecursor::differs];
	Failure["TranslationFailure", <|"MessageTemplate" -> "The translation does not reproduce the values of the program."|>]
)

TranslateRecursor[program_?RecursorProgramQ, OptionsPattern[]] := Enclose @ Module[{method, tested, base, inputs, reference},
	method = OptionValue[Method];
	tested = testInputList[OptionValue["TestInputs"]];
	ConfirmAssert[MemberQ[{Automatic, "Literal"}, method], "Method must be Automatic or \"Literal\"."];
	ConfirmAssert[ListQ[tested], "TestInputs must be a nonnegative integer or a list of natural numbers."];
	base = Catch[literalTranslation[program], "TranslationNames"];
	ConfirmAssert[!FailureQ[base], "The program nests more loops than the translation names."];
	{inputs, reference} = referenceValues[program, tested];
	Which[
		!agreesQ[base, inputs, reference],
			differingFailure[],
		method === "Literal",
			functionCode[slotForm[base]],
		True,
			functionCode[SelectFirst[candidateTranslations[base], agreesQ[#, inputs, reference] &, slotForm[base]]]
	]
]
TranslateRecursor[___] := invalidArgumentsFailure[TranslateRecursor]
