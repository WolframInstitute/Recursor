(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[{$RepositoryRoot, $PacletDirectory, $GitHubActionsQ, $ScriptArguments, LogInfo, LogError, RepositoryPath, ErrorCount, FinishScript, RunScript}];

(* ::Section:: *)
(*PackageScoped*)

PackageScoped[{invalidArgumentsFailure}];

(* ::Section:: *)
(*Usage Messages*)

$RepositoryRoot::usage = "$RepositoryRoot is the repository directory.";
$PacletDirectory::usage = "$PacletDirectory is the paclet source directory.";
$GitHubActionsQ::usage = "$GitHubActionsQ indicates whether GitHub Actions is running.";
$ScriptArguments::usage = "$ScriptArguments lists the command-line arguments after the script path.";
LogInfo::usage = "LogInfo[parts] prints information. Each of the parts is a string or any expression, which prints in InputForm.";
LogError::usage = "LogError[parts] prints an error and marks the script as failed.\n\
LogError[location, parts] prints an error for the file and position that the association location names. location has the key \"File\" \
and may have the keys \"Line\" and \"Column\". On GitHub Actions the error becomes an ::error file=...:: annotation.";
RepositoryPath::usage = "RepositoryPath[file] gives a path relative to the repository.";
ErrorCount::usage = "ErrorCount[] gives the number of logged errors.";
FinishScript::usage = "FinishScript[] exits with a status determined by logged errors.";
RunScript::usage = "RunScript[command] runs command[] and exits with its logged status. command is a symbol or a pure function.";
invalidArgumentsFailure::usage = "invalidArgumentsFailure[function] issues the message function::args and gives the Failure that a script \
command returns for arguments that match none of its definitions. The Failure has the tag \"InvalidArguments\".";
normalizePath::usage = "normalizePath[path] gives the absolute path with the separators of this platform.";
$errorCount::usage = "$errorCount is the number of errors logged so far.";
toText::usage = "toText[expression] gives expression itself when it is a string, and its InputForm text otherwise.";
joinText::usage = "joinText[parts] joins the text of the parts, as toText gives it.";
locationQ::usage = "locationQ[expression] gives True when expression is an association with the key \"File\".";
escapeData::usage = "escapeData[text] escapes the characters of a GitHub Actions message that the runner reads as markup.";
escapeProperty::usage = "escapeProperty[text] escapes the characters of a GitHub Actions annotation property.";
locationProperties::usage = "locationProperties[location] gives the properties file=..., line=... and col=... of an annotation, as one string.";
locationText::usage = "locationText[location] gives the text file:line:column: that starts a local log line.";
emit::usage = "emit[command, label, location, parts] prints a log line. On GitHub Actions it is the workflow command ::command::, and elsewhere \
a line that starts with label. location is an association or None.";
log::usage = "log[command, label, parts] prints a log line, with the location when the first of the parts is an association with a \"File\" key.";

(* ::Section:: *)
(*Function Definitions*)

normalizePath[path_String] := FileNameJoin @ FileNameSplit @ ExpandFileName[path]

$RepositoryRoot = normalizePath @ DirectoryName[ExpandFileName[$InputFileName], 3];
$PacletDirectory = FileNameJoin[{$RepositoryRoot, "Recursor"}];
$GitHubActionsQ = Environment["GITHUB_ACTIONS"] === "true";
$ScriptArguments = Replace[$ScriptCommandLine, {{_, rest___} :> {rest}, _ -> {}}];

(* normalizePath joins with $PathnameSeparator, a backslash on Windows, so
   strip that separator rather than a literal "/"; a literal "/" never
   matched there, so every RepositoryPath caller printed the full absolute
   path on Windows instead of a short relative one. *)
RepositoryPath[file_String] := StringDelete[normalizePath[file], StartOfString ~~ $RepositoryRoot ~~ $PathnameSeparator]
RepositoryPath[___] := invalidArgumentsFailure[RepositoryPath]

$errorCount = 0;

toText[text_String] := text
toText[expression_] := ToString[expression, InputForm]
joinText[parts___] := StringJoin[toText /@ {parts}]

locationQ[candidate_Association] := KeyExistsQ[candidate, "File"]
locationQ[___] := False

escapeData[text_String] := StringReplace[text, {"%" -> "%25", "\r" -> "%0D", "\n" -> "%0A"}]
escapeProperty[text_String] := StringReplace[text, {"%" -> "%25", "\r" -> "%0D", "\n" -> "%0A", ":" -> "%3A", "," -> "%2C"}]

locationProperties[sourceLocation_Association] :=
	StringRiffle[
		DeleteMissing @ {
			"file=" <> escapeProperty[RepositoryPath[sourceLocation["File"]]],
			If[IntegerQ[sourceLocation["Line"]], "line=" <> ToString[sourceLocation["Line"]], Missing[]],
			If[IntegerQ[sourceLocation["Column"]], "col=" <> ToString[sourceLocation["Column"]], Missing[]]
		},
		","
	]

locationText[sourceLocation_Association] :=
	StringJoin[
		RepositoryPath[sourceLocation["File"]],
		If[IntegerQ[sourceLocation["Line"]], ":" <> ToString[sourceLocation["Line"]], ""],
		If[IntegerQ[sourceLocation["Column"]], ":" <> ToString[sourceLocation["Column"]], ""],
		": "
	]

emit[command_String, label_String, sourceLocation : (_Association | None), parts___] :=
	Print @ If[$GitHubActionsQ,
		StringJoin["::", command, If[locationQ[sourceLocation], " " <> locationProperties[sourceLocation], ""], "::", escapeData[joinText[parts]]],
		StringJoin[label, ": ", If[locationQ[sourceLocation], locationText[sourceLocation], ""], joinText[parts]]
	]

log[command_String, label_String, sourceLocation_?locationQ, parts___] := emit[command, label, sourceLocation, parts]
log[command_String, label_String, parts___] := emit[command, label, None, parts]

(* Any expression is a valid part: it prints in InputForm. So a call never gives a Failure. *)
(* allow MissingCatchAll: every sequence of parts is valid, so there is no invalid call to catch *)
LogInfo[parts___] := Print[joinText[parts]]
(* allow MissingCatchAll: every sequence of parts is valid, so there is no invalid call to catch *)
LogError[parts___] := (
	$errorCount++;
	log["error", "ERROR", parts]
)

ErrorCount[] := $errorCount
ErrorCount[___] := invalidArgumentsFailure[ErrorCount]

FinishScript[] :=
	If[$errorCount > 0,
		Print["\nFAILED: ", $errorCount, " error(s)."];
		Exit[1],

		Print["\nOK."];
		Exit[0]
	]
FinishScript[___] := invalidArgumentsFailure[FinishScript]

RunScript[command : (_Symbol | _Function)] := (
	command[];
	FinishScript[]
)
RunScript[___] := invalidArgumentsFailure[RunScript]

(* The same catch-all as in the paclet: every exported command ends with Name[___] := invalidArgumentsFailure[Name]. *)
invalidArgumentsFailure[function_Symbol] := (
	Message[MessageName[function, "args"], function];
	Failure["InvalidArguments", <|"MessageTemplate" -> MessageName[function, "args"], "MessageParameters" -> {function}|>]
)
