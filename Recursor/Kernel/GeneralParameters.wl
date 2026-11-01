PackageExported[{$RecursorVersion, RecursorExamples}]

$RecursorVersion::usage = "$RecursorVersion is the version of the loaded Recursor paclet."
RecursorExamples::usage = "RecursorExamples[] gives named example programs. RecursorExamples[name] gives one program."

$RecursorVersion = "0.1.0"

RecursorExamples[] := <|
	"Countdown" -> WhileLoop[Var, Acc, Pred[Acc]],
	"Factorial" -> Rec[Var, Const[1], Mul[Succ[Idx], Acc]],
	"Fibonacci" -> CoRec[Var, Ifz[Idx, Const[0], Ifz[Pred[Idx], Const[1], Add[CGet[Pred[Idx]], CGet[Pred[Pred[Idx]]]]]]],
	"Nonterminating" -> WhileLoop[Const[0], Const[1], Acc],
	"PopulationCount" -> CoRec[Var, Ifz[Idx, Const[0], Add[CGet[Half[Idx]], Rem[Idx, Const[2]]]]],
	"PowerOfTwo" -> Iter[Var, Const[1], Mul[Const[2], Acc]],
	"Square" -> Mul[Var, Var]
|>

RecursorExamples[name_String] := Lookup[RecursorExamples[], name, Missing["UnknownExample", name]]
