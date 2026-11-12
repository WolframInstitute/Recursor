Needs["WolframInstitute`Recursor`"]

written[function_] :=
	ToString[function, InputForm]

agrees[program_, inputs_] :=
	With[{function = TranslateRecursor[program]},
		MatchQ[function, _Function] && function /@ inputs === (EvaluateRecursor[program, #, "MaxSteps" -> 2000000]& /@ inputs)
	]

VerificationTest[written[TranslateRecursor[RecursorExamples["Factorial"]]], "Function[n, n!]", TestID -> "a-product-loop-is-the-factorial"]

VerificationTest[written[TranslateRecursor[RecursorExamples["PowerOfTwo"]]], "Function[n, 2^n]", TestID -> "an-iterated-product-is-a-power"]

VerificationTest[written[TranslateRecursor[RecursorExamples["Prime"]]], "Function[n, Prime[1 + n]]", TestID -> "a-search-for-two-divisors-is-the-primes"]

VerificationTest[written[TranslateRecursor[RecursorExamples["DivisorCount"]]], "Function[n, Count[Range[1, n], i_ /; Divisible[n, i]]]",
	TestID -> "a-counting-loop-is-a-count"]

VerificationTest[written[TranslateRecursor[RecursorExamples["Fibonacci"]]],
	"Function[n, Module[{s}, s[0] = 0; s[1] = 1; s[i_] := s[i] = s[-2 + i] + s[-1 + i]; Last[Array[s, 1 + n, 0]]]]",
	TestID -> "a-recurrence-remembers-its-values"]

VerificationTest[written[TranslateRecursor[RecursorExamples["Factorial"], Method -> "Literal"]],
	"Function[n, Fold[Function[{a, i}, a*(1 + i)], 1, Range[0, -1 + n]]]", TestID -> "literal-keeps-the-structure"]

VerificationTest[
	AllTrue[Values[KeyDrop[RecursorExamples[], "Nonterminating"]], agrees[#, Range[0, 12]]&],
	True,
	TestID -> "translations-of-the-examples-have-their-values"
]

VerificationTest[
	AllTrue[Range[40],
		With[{program = BlockRandom[SeedRandom[#]; RandomRecursor[3, "IncludeWhile" -> False]]},
			MatchQ[TranslateRecursor[program, "TestInputs" -> 8], _Function] && agrees[program, Range[8, 11]]
		]&
	],
	True,
	TestID -> "translations-of-random-programs-agree-beyond-the-tested-inputs"
]

VerificationTest[
	{TranslateRecursor[Rem[Const[7], Var]] /@ {0, 1, 2, 5}, TranslateRecursor[Quot[Const[7], Var]] /@ {0, 1, 2, 5}},
	{{7, 0, 1, 2}, {0, 7, 3, 1}},
	TestID -> "a-zero-divisor-keeps-its-meaning"
]

VerificationTest[
	TranslateRecursor[CoRec[Var, Succ[CGet[Idx]]]] /@ Range[0, 4],
	{1, 1, 1, 1, 1},
	TestID -> "reading-a-later-index-gives-zero"
]

VerificationTest[
	Block[{n = 5}, TranslateRecursor[Mul[Var, Var]][3]],
	9,
	TestID -> "a-value-of-the-variable-does-not-leak"
]

VerificationTest[FailureQ[TranslateRecursor[Var, Method -> "Shortest"]], True, TestID -> "an-unknown-method-fails"]

VerificationTest[Head[TranslateRecursor[Acc]], TranslateRecursor, TestID -> "an-open-expression-is-not-translated"]
