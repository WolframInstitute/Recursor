(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{$RecursorVersion, RecursorExamples}]

(* ::Section:: *)
(*Usage Messages*)

$RecursorVersion::usage = "$RecursorVersion is the version of the loaded Recursor paclet."
RecursorExamples::usage = "RecursorExamples[] gives named example programs. RecursorExamples[name] gives one program."

compositeTest::usage = "compositeTest[] gives a program that is zero exactly when its input has two divisors, which is when it is prime."

(* ::Section:: *)
(*Function Definitions*)

$RecursorVersion = "0.3.0"

compositeTest[] := Let[
	Rec[Var, Const[0], Ifz[Rem[Var, Succ[Idx]], Succ[Acc], Acc]],
	Add[Monus[Var, Const[2]], Monus[Const[2], Var]]
]

RecursorExamples[] := <|
	"Catalan" -> Rec[Var, Const[1], Quot[Mul[Monus[Mul[Const[4], Succ[Idx]], Const[2]], Acc], Add[Idx, Const[2]]]],
	"Countdown" -> WhileLoop[Var, Acc, Pred[Acc]],
	"DigitSum" -> CoRec[Var, Ifz[Idx, Const[0], Add[CGet[Quot[Idx, Const[10]]], Rem[Idx, Const[10]]]]],
	"DivisorCount" -> Rec[Var, Const[0], Ifz[Rem[Var, Succ[Idx]], Succ[Acc], Acc]],
	"Factorial" -> Rec[Var, Const[1], Mul[Succ[Idx], Acc]],
	"Fibonacci" -> CoRec[Var, Ifz[Idx, Const[0], Ifz[Pred[Idx], Const[1], Add[CGet[Pred[Idx]], CGet[Pred[Pred[Idx]]]]]]],
	"Nonterminating" -> WhileLoop[Const[0], Const[1], Acc],
	"PopulationCount" -> CoRec[Var, Ifz[Idx, Const[0], Add[CGet[Half[Idx]], Rem[Idx, Const[2]]]]],
	"PowerOfTwo" -> Iter[Var, Const[1], Mul[Const[2], Acc]],
	"Prime" -> Pred[Iter[Succ[Var], Const[0], Succ[WhileLoop[Acc, Let[Acc, compositeTest[]], Succ[Acc]]]]],
	"Square" -> Mul[Var, Var]
|>

RecursorExamples[name_String] := Lookup[RecursorExamples[], name, Missing["UnknownExample", name]]
RecursorExamples[___] := invalidArgumentsFailure[RecursorExamples]
