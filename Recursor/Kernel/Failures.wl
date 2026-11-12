(* ::Package:: *)

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{invalidArgumentsFailure, innerFailure}];

(* ::Section:: *)
(*Usage Messages*)

invalidArgumentsFailure::usage = "invalidArgumentsFailure[symbol] issues the message symbol::args and gives the Failure that a public \
function returns for arguments that match none of its definitions. The Failure has the tag \"InvalidArguments\".";

innerFailure::usage = "innerFailure[failure] gives the Failure that a failed confirmation passed up: the confirmed expression when it is \
itself a Failure, and failure otherwise. Used as the second argument of Enclose, it keeps the tag and the data of a Failure that a helper made.";

(* ::Section:: *)
(*Function Definitions*)

(* Every public function ends with Name[___] := invalidArgumentsFailure[Name]. The message is the generic one
   every symbol inherits (General::args), so no file defines its own. *)
invalidArgumentsFailure[symbol_Symbol] := (
	Message[MessageName[symbol, "args"], symbol];
	Failure["InvalidArguments", <|"MessageTemplate" -> MessageName[symbol, "args"], "MessageParameters" -> {symbol}|>]
)

(* Enclose[body, innerFailure] returns a helper's own Failure, such as one with the tag "MissingCase", instead of
   wrapping it in a "ConfirmationFailed" Failure. A failed ConfirmAssert or ConfirmBy is returned as it is. *)
innerFailure[failure_Failure] := Replace[failure["Expression"], Except[_Failure] -> failure]
