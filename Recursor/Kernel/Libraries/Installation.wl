PackageExported[{RecursorLibraries, InstallRecursorLibraries}]
PackageScoped[{libraryReadyQ, libraryInstall, proofDirectory, proofSourceDirectory, mathlibInformation}]

RecursorLibraries::usage = "RecursorLibraries[] gives the external libraries and their status. RecursorLibraries[name] gives information about one library."
InstallRecursorLibraries::usage = "InstallRecursorLibraries[{name1, name2, ...}] installs and checks selected external libraries, keeping those already ready."

$libraryRegistry = <|
	"Lambda" -> <|"Paclet" -> "Wolfram/Lambda", "Context" -> "Wolfram`Lambda`", "MinimumVersion" -> "1.2.5",
		"Description" -> "Lambda-term diagrams and reduction graphs.", "URL" -> "https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/Lambda/"|>,
	"LeanLink" -> <|"Paclet" -> "Wolfram/LeanLink", "Context" -> "Wolfram`LeanLink`", "MinimumVersion" -> "1.2.5",
		"Description" -> "Lean proof checking from Wolfram Language.", "URL" -> "https://github.com/WolframInstitute/LeanLink",
		"Archive" -> "https://www.wolframcloud.com/obj/wolframinstitute/Resources/49e/49e8aa40-9838-4632-a71f-7a9e5aa43f48/download/1-2-5/PacletArchive.paclet"|>,
	"MathlibLink" -> <|"Paclet" -> "WolframInstitute/MathlibLink", "Context" -> "WolframInstitute`MathlibLink`", "MinimumVersion" -> "0.1.0",
		"Description" -> "Mathlib declarations, computation and proofs.", "URL" -> "https://leanprover-community.github.io/mathlib4_docs/"|>
|>

versionAtLeastQ[installed_String, minimum_String] := With[{
	a = FromDigits /@ StringSplit[installed, "."], b = FromDigits /@ StringSplit[minimum, "."]
}, OrderedQ[{PadRight[b, Max[Length[a], Length[b]]], PadRight[a, Max[Length[a], Length[b]]]}]]

libraryLoadQ[entry_Association] := Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs[entry["Context"]] === Null, False]]]

(* Probe the local runtime before compilation so readiness cannot trigger an elan download. *)
libraryReadyQ["LeanLink"] := Module[{handle, environment},
	handle = Quiet[Symbol["Wolfram`LeanLink`LeanLoadEnvironment"][{}, ""]];
	If[! IntegerQ[handle] || handle <= 0, Return[False]];
	Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][handle];
	environment = TimeConstrained[Quiet[Symbol["Wolfram`LeanLink`LeanImportString"]["theorem recursor_library_probe : 1 = 1 := rfl"]], 30, $TimedOut];
	If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]], Return[False]];
	WithCleanup[True, Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][Information[environment, "Handle"]]]
]

libraryReadyQ["Lambda"] := True
libraryReadyQ["MathlibLink"] := With[{info = mathlibInformation[]}, AssociationQ[info] && Lookup[info, "Status", None] === "Ready"]

mathlibInformation[] := If[libraryLoadQ[$libraryRegistry["MathlibLink"]],
	Quiet[Check[Symbol["WolframInstitute`MathlibLink`MathlibInstallation"][], $Failed]], $Failed
]

proofDirectory[] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "Recursor", "Lean", "4.35.0"}]
proofSourceDirectory[] := FileNameJoin[{PacletObject["WolframInstitute/Recursor"]["Location"], "Assets", "Lean"}]

libraryStatus[name_String] := With[{entry = $libraryRegistry[name]}, With[{installed = PacletFind[entry["Paclet"]]},
	Which[
		installed === {}, "Not installed",
		! versionAtLeastQ[First[installed]["Version"], entry["MinimumVersion"]], "Update available",
		! libraryLoadQ[entry], "Needs setup",
		TrueQ[Quiet[Check[libraryReadyQ[name], False]]], "Ready",
		True, "Needs setup"
	]
]]

RecursorLibraries[name_String] := With[{entry = $libraryRegistry[name]},
	Join[KeyDrop[entry, {"Archive", "Context"}],
		With[{installed = PacletFind[entry["Paclet"]]}, <|"Version" -> If[installed === {}, Missing["NotInstalled"], First[installed]["Version"]]|>],
		If[name === "MathlibLink" && PacletFind[entry["Paclet"]] =!= {},
			With[{info = mathlibInformation[]}, If[AssociationQ[info], KeyTake[info, {"Directory", "MathlibDirectory", "Toolchain", "Revision"}], <||>]], <||>],
		<|"Status" -> libraryStatus[name]|>
	]
] /; KeyExistsQ[$libraryRegistry, name]
RecursorLibraries[] := AssociationMap[RecursorLibraries, Keys[$libraryRegistry]]

libraryFailure[name_, tag_, result_] := Failure[tag, <|
	"MessageTemplate" -> "`1` could not be made ready. See the setup instructions and the returned result.",
	"MessageParameters" -> {name}, "Result" -> result, "URL" -> $libraryRegistry[name]["URL"]
|>]

(* Until its first release, the bridge is installed from a local verified archive. *)
mathlibLinkArchive[] := SelectFirst[{
	Environment["MATHLIBLINK_PACLET"],
	FileNameJoin[{DirectoryName[PacletObject["WolframInstitute/Recursor"]["Location"], 3], "Mathematics", "MathlibLink", "dist", "WolframInstitute__MathlibLink-0.1.0.paclet"}]
}, StringQ[#] && FileExistsQ[#] &, Missing["NotFound"]]

installLibraryPaclet[entry_Association] := Quiet[Check[
	If[entry["Paclet"] === "WolframInstitute/MathlibLink",
		With[{archive = mathlibLinkArchive[]}, If[StringQ[archive], PacletInstall[File[archive]],
			Failure["MathlibLinkArchiveRequired", <|"MessageTemplate" -> "Build MathlibLink with make check-publish, or set MATHLIBLINK_PACLET to its local paclet archive."|>]
		]],
		If[KeyExistsQ[entry, "Archive"], PacletInstall[entry["Archive"]], PacletInstall[entry["Paclet"]]]
	], $Failed
]]

libraryInstall[name_String] := Module[{entry = $libraryRegistry[name], result, status = libraryStatus[name]},
	If[status === "Ready", Return[First[PacletFind[entry["Paclet"]]]]];
	If[status === "Needs setup", Return[libraryFailure[name, "LibrarySetupRequired", RecursorLibraries[name]]]];
	result = installLibraryPaclet[entry];
	Which[
		MatchQ[result, _Failure], result,
		! MatchQ[result, _PacletObject], libraryFailure[name, "LibraryInstallFailed", result],
		libraryStatus[name] === "Ready", result,
		True, libraryFailure[name, "LibrarySetupRequired", result]
	]
]

libraryInstall["MathlibLink"] := Module[{entry = $libraryRegistry["MathlibLink"], result, status = libraryStatus["MathlibLink"]},
	If[status === "Ready", Return[First[PacletFind[entry["Paclet"]]]]];
	If[MemberQ[{"Not installed", "Update available"}, status],
		result = installLibraryPaclet[entry];
		If[MatchQ[result, _Failure], Return[result]];
		If[! MatchQ[result, _PacletObject], Return[libraryFailure["MathlibLink", "LibraryInstallFailed", result]]]
	];
	If[! libraryLoadQ[entry], Return[libraryFailure["MathlibLink", "LibrarySetupRequired", "Restart the kernel after updating the bridge."]]];
	result = Quiet[Check[Symbol["WolframInstitute`MathlibLink`InstallMathlib"][], $Failed]];
	Which[
		MatchQ[result, _Failure], result,
		libraryReadyQ["MathlibLink"], First[PacletFind[entry["Paclet"]]],
		True, libraryFailure["MathlibLink", "LibrarySetupRequired", result]
	]
]

InstallRecursorLibraries[names : {___String}] := AssociationMap[libraryInstall, DeleteDuplicates[names]] /;
	AllTrue[names, KeyExistsQ[$libraryRegistry, #] &]
