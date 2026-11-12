PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

written[function_] :=
	ToString[function, InputForm]

agrees[program_, inputs_] :=
	With[{function = TranslateRecursor[program]},
		MatchQ[function, _Function] && function /@ inputs === (EvaluateRecursor[program, #, "MaxSteps" -> 2000000] & /@ inputs)
	]

randomProgram[seed_Integer] :=
	BlockRandom[
		SeedRandom[seed];
		RandomRecursor[3, "IncludeWhile" -> False]
	]

VerificationTest[written[TranslateRecursor[RecursorExamples["Factorial"]]], "Function[n, n!]", TestID -> "a-product-loop-is-the-factorial"]

VerificationTest[written[TranslateRecursor[RecursorExamples["PowerOfTwo"]]], "Function[n, 2^n]", TestID -> "an-iterated-product-is-a-power"]

VerificationTest[written[TranslateRecursor[RecursorExamples["Prime"]]], "Function[n, Prime[1 + n]]", TestID -> "a-search-for-two-divisors-is-the-primes"]

VerificationTest[
	written[TranslateRecursor[RecursorExamples["DivisorCount"]]],
	"Function[n, Count[Range[1, n], i_ /; Divisible[n, i]]]",
	TestID -> "a-counting-loop-is-a-count"
]

VerificationTest[
	written[TranslateRecursor[RecursorExamples["Fibonacci"]]],
	"Function[n, Module[{s}, s[0] = 0; s[1] = 1; s[i_] := s[i] = s[-2 + i] + s[-1 + i]; Last[Array[s, 1 + n, 0]]]]",
	TestID -> "a-recurrence-remembers-its-values"
]

VerificationTest[
	written[TranslateRecursor[RecursorExamples["Factorial"], Method -> "Literal"]],
	"Function[n, Fold[Function[{a, i}, a*(1 + i)], 1, Range[0, -1 + n]]]",
	TestID -> "literal-keeps-the-structure"
]

VerificationTest[
	AllTrue[Values[KeyDrop[RecursorExamples[], "Nonterminating"]], agrees[#, Range[0, 12]] &],
	True,
	TestID -> "translations-of-the-examples-have-their-values"
]

VerificationTest[
	AllTrue[
		Range[40],
		Function[seed, MatchQ[TranslateRecursor[randomProgram[seed], "TestInputs" -> 8], _Function] && agrees[randomProgram[seed], Range[8, 11]]]
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

(* The translation is written with the symbol n of the current context; With puts that symbol into Block. *)
VerificationTest[
	With[{inputSymbol = Symbol["n"]},
		Block[{inputSymbol = 5}, TranslateRecursor[Mul[Var, Var]][3]]
	],
	9,
	TestID -> "a-value-of-the-variable-does-not-leak"
]

VerificationTest[FailureQ[TranslateRecursor[Var, Method -> "Shortest"]], True, TestID -> "an-unknown-method-fails"]

VerificationTest[
	FailureQ[TranslateRecursor[Var, "TestInputs" -> -1]],
	True,
	TestID -> "invalid-test-inputs-fail"
]

VerificationTest[
	TranslateRecursor[Nest[Iter[Var, Var, #] &, Succ[Acc], 5]]["Tag"],
	"ConfirmationFailed",
	TestID -> "more-loops-than-names-fail"
]

VerificationTest[
	TranslateRecursor[Acc]["Tag"],
	"InvalidArguments",
	{TranslateRecursor::args},
	TestID -> "an-open-expression-is-not-translated"
]

VerificationTest[
	TranslateRecursor[]["Tag"],
	"InvalidArguments",
	{TranslateRecursor::args},
	TestID -> "translaterecursor-invalid-arguments"
]

VerificationTest[
	TranslateRecursor[Rem[Const[3], Half[Rec[Var, Const[1], Acc]]]],
	Function[n, 3],
	TestID -> "a-divisor-rewritten-to-zero-gives-no-message"
]

VerificationTest[
	Map[TranslateRecursor[Let[Add[CoRec[Var, Idx], Var], Let[Rem[Const[2], Var], CoRec[Const[3], Var]]], Method -> "Literal"], Range[0, 5]],
	Map[EvaluateRecursor[Let[Add[CoRec[Var, Idx], Var], Let[Rem[Const[2], Var], CoRec[Const[3], Var]]], #] &, Range[0, 5]],
	TestID -> "a-bound-value-with-a-loop-is-not-captured"
]
