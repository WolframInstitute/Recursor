(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[ParseRecursor]

(* ::Section:: *)
(*Usage Messages*)

ParseRecursor::usage = "ParseRecursor[text] parses closed Recursor source without evaluating Wolfram Language. Invalid text returns Failure."

parseFailure::usage = "parseFailure[detail] gives the Failure with the tag \"ParseRecursor\" whose message is detail."
requireSyntax::usage = "requireSyntax[condition, message] stops the parse with parseFailure[message] unless condition is True."
readArgument::usage = "readArgument[head, index, depth] reads the argument at position index of a node with the given head, which is \
at the given depth: the comma before it, then a nonnegative integer for Const and a syntax node for any other head."
readNode::usage = "readNode[depth] reads one syntax node at the given depth from the tokens at the current position and gives the expression."
readProgram::usage = "readProgram[compact] checks the parser limits, reads the tokens as one closed program and gives it. compact is the \
source text without whitespace, which the tokens must cover."
$parseNames::usage = "$parseNames gives the syntax head for each name of the Recursor grammar."
$parseTag::usage = "$parseTag is the tag with which requireSyntax throws a Failure to ParseRecursor."
$tokens::usage = "$tokens is the list of tokens of the source that ParseRecursor is reading."
$position::usage = "$position is the position in $tokens of the next token to read."
$nodeCount::usage = "$nodeCount is the number of syntax nodes read so far."
$maximumNodes::usage = "$maximumNodes is the value of the option \"MaxNodes\" for the source that ParseRecursor is reading."
$maximumDepth::usage = "$maximumDepth is the value of the option \"MaxDepth\" for the source that ParseRecursor is reading."

(* ::Section:: *)
(*Options*)

Options[ParseRecursor] = {"MaxNodes" -> Infinity, "MaxDepth" -> 256}

(* ::Section:: *)
(*Function Definitions*)

$parseNames = AssociationThread[
	{"Var", "Acc", "Idx", "Const", "Succ", "Pred", "Half", "Add", "Mul", "Monus", "Rem", "Quot", "Ifz", "Iter", "Rec", "CoRec", "CGet", "WhileLoop", "Let"},
	{Var, Acc, Idx, Const, Succ, Pred, Half, Add, Mul, Monus, Rem, Quot, Ifz, Iter, Rec, CoRec, CGet, WhileLoop, Let}
]

$parseTag = "ParseRecursor"

parseFailure[detail_String] := Failure["ParseRecursor", <|"MessageTemplate" -> detail|>]

requireSyntax[True, _String] := Null
requireSyntax[_, message_String] := Throw[parseFailure[message], $parseTag]

(* The parser reads $tokens from $position on. ParseRecursor binds both, with the limits and the node count, for one source. *)
readArgument[head_Symbol, index_Integer, depth_Integer] := (
	If[index > 1,
		requireSyntax[$position <= Length[$tokens] && Extract[$tokens, {$position++}] === ",", "Expected a comma."]
	];
	If[head === Const,
		requireSyntax[$position <= Length[$tokens] && StringMatchQ[Extract[$tokens, {$position}], DigitCharacter..], "Expected a nonnegative integer."];
		FromDigits[Extract[$tokens, {$position++}]],

		readNode[depth + 1]
	]
)

readNode[depth_Integer] := Module[{token, head, arity, arguments},
	requireSyntax[depth <= $maximumDepth && ++$nodeCount <= $maximumNodes, "The parser's size or nesting limit was reached."];
	requireSyntax[$position <= Length[$tokens], "Expected a Recursor expression."];
	token = Extract[$tokens, {$position++}];
	requireSyntax[KeyExistsQ[$parseNames, token], "Expected a known Recursor node."];
	head = $parseNames[token];
	arity = Lookup[$RecursorGrammar, token];
	If[arity === 0,
		head,

		requireSyntax[$position <= Length[$tokens] && Extract[$tokens, {$position++}] === "[", "Expected an opening bracket."];
		arguments = Table[readArgument[head, index, depth], {index, arity}];
		requireSyntax[$position <= Length[$tokens] && Extract[$tokens, {$position++}] === "]", "Expected a closing bracket."];
		head @@ arguments
	]
]

readProgram[compact_String] := Module[{result},
	requireSyntax[
		MatchQ[$maximumNodes, _Integer?Positive | Infinity] && MatchQ[$maximumDepth, _Integer?Positive | Infinity],
		"Parser limits must be positive integers or Infinity."
	];
	requireSyntax[StringJoin[$tokens] === compact, "Source contains characters outside the Recursor grammar."];
	result = readNode[1];
	requireSyntax[$position > Length[$tokens], "Unexpected trailing source."];
	requireSyntax[RecursorProgramQ[result], "The expression has unbound Acc, Idx or CGet."];
	result
]

ParseRecursor[text_String, OptionsPattern[]] := Block[{
	$tokens = StringCases[text, RegularExpression["[A-Za-z][A-Za-z0-9]*|[0-9]+|\\[|\\]|,"]], $position = 1, $nodeCount = 0,
	$maximumNodes = OptionValue["MaxNodes"], $maximumDepth = OptionValue["MaxDepth"]
},
	Catch[readProgram[StringReplace[text, WhitespaceCharacter -> ""]], $parseTag]
]
ParseRecursor[___] := invalidArgumentsFailure[ParseRecursor]
