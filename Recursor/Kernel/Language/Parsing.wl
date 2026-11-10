PackageExported[ParseRecursor]

ParseRecursor::usage = "ParseRecursor[text] parses closed Recursor source without evaluating Wolfram Language. Invalid text returns Failure."

Options[ParseRecursor] = {"MaxNodes" -> Infinity, "MaxDepth" -> 256}

parseFailure[detail_] := Failure["ParseRecursor", <|"MessageTemplate" -> detail|>]

ParseRecursor[text_String, OptionsPattern[]] := Module[{
	compact = StringReplace[text, WhitespaceCharacter -> ""], tokens, position = 1, read, require,
	nodes = 0, maximumNodes = OptionValue["MaxNodes"], maximumDepth = OptionValue["MaxDepth"],
	names = AssociationThread[
		{"Var", "Acc", "Idx", "Const", "Succ", "Pred", "Half", "Add", "Mul", "Monus", "Rem", "Quot", "Ifz", "Iter", "Rec", "CoRec", "CGet", "WhileLoop", "Let"},
		{Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let}
	], tag = Unique["parse"], result
},
	tokens = StringCases[text, RegularExpression["[A-Za-z][A-Za-z0-9]*|[0-9]+|\\[|\\]|,"]];
	require[condition_, message_] := If[! TrueQ[condition], Throw[parseFailure[message], tag]];
	read[depth_] := Module[{token, head, arity, arguments},
		require[depth <= maximumDepth && ++nodes <= maximumNodes, "The parser's size or nesting limit was reached."];
		require[position <= Length[tokens], "Expected a Recursor expression."];
		token = Extract[tokens, {position++}];
		require[KeyExistsQ[names, token], "Expected a known Recursor node."];
		head = names[token];
		arity = Lookup[$RecursorGrammar, token];
		If[arity === 0,
			head,
			require[position <= Length[tokens] && Extract[tokens, {position++}] === "[", "Expected an opening bracket."];
			arguments = Table[
				If[index > 1,
					require[position <= Length[tokens] && Extract[tokens, {position++}] === ",", "Expected a comma."]
				];
				If[head === Const,
					require[position <= Length[tokens] && StringMatchQ[Extract[tokens, {position}], DigitCharacter..], "Expected a nonnegative integer."];
					FromDigits[Extract[tokens, {position++}]],
					read[depth + 1]
				],
				{index, arity}
			];
			require[position <= Length[tokens] && Extract[tokens, {position++}] === "]", "Expected a closing bracket."];
			head @@ arguments
		]
	];
	Catch[
		require[MatchQ[maximumNodes, _Integer?Positive | Infinity] && MatchQ[maximumDepth, _Integer?Positive | Infinity], "Parser limits must be positive integers or Infinity."];
		require[StringJoin[tokens] === compact, "Source contains characters outside the Recursor grammar."];
		result = read[1];
		require[position > Length[tokens], "Unexpected trailing source."];
		require[RecursorProgramQ[result], "The expression has unbound Acc, Idx or CGet."];
		result,
		tag
	]
]
