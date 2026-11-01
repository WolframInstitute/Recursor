PackageExported[{RecursorLibraries, InstallRecursorLibraries}]
PackageScoped[{$libraryRegistry, libraryStatus, libraryReadyQ, libraryInstall, libraryUninstall,
	$libraryProgressFunction, libraryCancelledQ, proofDirectory, proofSourceDirectory, mathlibInformation}]

RecursorLibraries::usage = "RecursorLibraries[] gives the external libraries and their status. RecursorLibraries[name] gives information about one library."
InstallRecursorLibraries::usage = "InstallRecursorLibraries[{name1, name2, ...}] installs and checks selected external libraries, keeping those already ready."

$libraryProgressFunction = (Null &)
libraryCancelledQ[] := False

(* Reading the registry never installs or downloads a library. *)
$libraryRegistry = <|
	"Lambda" -> <|"Paclet" -> "Wolfram/Lambda", "Context" -> "Wolfram`Lambda`", "MinimumVersion" -> "1.2.5",
		"Description" -> "Lambda-term diagrams and reduction graphs.",
		"URL" -> "https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/Lambda/",
		"Platforms" -> {"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"},
		"DownloadSize" -> AssociationMap["varies by release" &,
			{"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"}],
		"License" -> "MIT"|>,
	"LeanLink" -> <|"Paclet" -> "Wolfram/LeanLink", "Context" -> "Wolfram`LeanLink`", "MinimumVersion" -> "1.2.5",
		"Description" -> "Lean proof checking. Requires a compatible Lean toolchain.",
		"URL" -> "https://github.com/WolframInstitute/LeanLink#install",
		"SetupLinks" -> <|"Lean toolchain installation guide" -> "https://lean-lang.org/install/"|>,
		"Platforms" -> {"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"},
		"DownloadSize" -> AssociationMap["1.7 MB (paclet only)" &,
			{"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"}],
		"License" -> "MIT",
		"Archive" -> "https://www.wolframcloud.com/obj/wolframinstitute/Resources/49e/49e8aa40-9838-4632-a71f-7a9e5aa43f48/download/1-2-5/PacletArchive.paclet"|>,
	"MathlibLink" -> <|"Paclet" -> "WolframInstitute/MathlibLink", "Context" -> "WolframInstitute`MathlibLink`", "MinimumVersion" -> "0.1.0",
		"Description" -> "Mathlib declarations, computation and proofs. Requires elan and Git.",
		"URL" -> "https://leanprover-community.github.io/install/project.html",
		"SetupLinks" -> <|"mathlib documentation" -> "https://leanprover-community.github.io/mathlib4_docs/"|>,
		"Platforms" -> {"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"},
		"DownloadSize" -> AssociationMap["varies; Lean and mathlib" &,
			{"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"}],
		"License" -> "MIT; runtime licenses apply"|>
|>

versionAtLeastQ[installed_String, minimum_String] := With[{
	a = FromDigits /@ StringSplit[installed, "."], b = FromDigits /@ StringSplit[minimum, "."]
}, OrderedQ[{PadRight[b, Max[Length[a], Length[b]]], PadRight[a, Max[Length[a], Length[b]]]}]]

libraryLoadQ[entry_Association] := Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs[entry["Context"]] === Null, False]]]

(* Probe the local runtime before compilation so readiness cannot trigger an elan download. *)
libraryReadyQ["LeanLink"] := Module[{handle, environment},
	If[! libraryLeanRuntimeQ[], Return[False]];
	handle = Quiet[Symbol["Wolfram`LeanLink`LeanLoadEnvironment"][{}, ""]];
	If[! IntegerQ[handle] || handle <= 0, Return[False]];
	Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][handle];
	environment = TimeConstrained[Quiet[Symbol["Wolfram`LeanLink`LeanImportString"]["theorem recursor_library_probe : 1 = 1 := rfl"]], 30, $TimedOut];
	If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]], Return[False]];
	WithCleanup[True, Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][Information[environment, "Handle"]]]
]

(* LeanLink caches a failed native load; do not attempt one before setup has
   provided the pinned toolchain. A later explicit installation can then recover. *)
libraryLeanRuntimeQ[] := With[{
	elan = Replace[Environment["ELAN_HOME"], Except[_String] :> FileNameJoin[{$HomeDirectory, ".elan"}]]
}, With[{directory = FileNameJoin[{elan, "toolchains", "leanprover--lean4---v4.35.0"}]},
	AllTrue[{
		FileNameJoin[{directory, "lib", "lean", "Init.olean"}],
		FileNameJoin[{directory, "bin", "lean" <> If[$OperatingSystem === "Windows", ".exe", ""]}]
	}, FileExistsQ]
]]

libraryReadyQ["Lambda"] := True
libraryReadyQ["MathlibLink"] := With[{info = mathlibInformation[]}, AssociationQ[info] && Lookup[info, "Status", None] === "Ready"]

mathlibInformation[] := If[libraryLoadQ[$libraryRegistry["MathlibLink"]],
	Quiet[Check[Symbol["WolframInstitute`MathlibLink`MathlibInstallation"][], $Failed]], $Failed
]

proofDirectory[] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "Recursor", "Lean", "4.35.0"}]
proofSourceDirectory[] := FileNameJoin[{PacletObject["WolframInstitute/Recursor"]["Location"], "Assets", "Lean"}]

libraryStatus[name_String] := With[{entry = $libraryRegistry[name]}, With[{installed = PacletFind[entry["Paclet"]]},
	Which[
		! MemberQ[entry["Platforms"], $SystemID], "Unsupported",
		installed === {}, "Not installed",
		! versionAtLeastQ[First[installed]["Version"], entry["MinimumVersion"]], "Update available",
		! libraryLoadQ[entry], "Needs setup",
		TrueQ[Quiet[Check[libraryReadyQ[name], False]]], "Ready",
		True, "Needs setup"
	]
]] /; KeyExistsQ[$libraryRegistry, name]

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

installLibraryPaclet[entry_Association] := Quiet[Which[
	TrueQ[libraryCancelledQ[]], libraryCancellation[],
	entry["Paclet"] === "WolframInstitute/MathlibLink",
		With[{archive = mathlibLinkArchive[]}, If[StringQ[archive],
			libraryInstallFile[File[archive]],
			Failure["MathlibLinkArchiveRequired", <|"MessageTemplate" -> "Build MathlibLink with make check-publish, or set MATHLIBLINK_PACLET to its local paclet archive."|>]
		]],
	KeyExistsQ[entry, "Archive"], libraryInstallURL[entry["Archive"]],
	True, libraryInstallResource[entry["Paclet"], entry["MinimumVersion"]]
]]

(* Resolve the repository's archive metadata, then use the same cancellable
   transfer as libraries with an explicit release archive. *)
libraryInstallResource[name_String, version_String] := With[{
	source = Quiet[TimeConstrained[ResourceObject[name, ResourceVersion -> version]["PacletFile"], 30, $Failed]]
}, With[{archive = Replace[source, {(URL | CloudObject)[url_String, ___] :> url}]}, Which[
	TrueQ[libraryCancelledQ[]], libraryCancellation[],
	StringQ[archive] && StringStartsQ[archive, "https://"], libraryInstallURL[archive],
	StringQ[archive] && FileExistsQ[archive],
		libraryInstallFile[File[archive]],
	MatchQ[archive, File[_String]] && FileExistsQ[First[archive]],
		libraryInstallFile[archive],
	True, Failure["LibraryDownloadFailed", <|
		"MessageTemplate" -> "The paclet download could not be found. Check your connection and try again.", "Result" -> source
	|>]
]]]

libraryCancellation[] := Failure["LibraryInstallCancelled", <|"MessageTemplate" -> "Installation cancelled. You can try again."|>]

libraryInstallFile[file_File] := (
	$libraryProgressFunction["Installing...", None];
	If[TrueQ[libraryCancelledQ[]], libraryCancellation[], PacletInstall[file]]
)

libraryInstallMathlib[] := If[
	ContainsAll[First /@ Options[Symbol["WolframInstitute`MathlibLink`InstallMathlib"]], {"ProgressFunction", "CancellationFunction"}],
	Symbol["WolframInstitute`MathlibLink`InstallMathlib"][
		"ProgressFunction" -> Function[{stage, fraction}, $libraryProgressFunction[stage, fraction]],
		"CancellationFunction" -> Function[Null, TrueQ[libraryCancelledQ[]]]
	],
	(* Older bridge releases cannot cancel an active runtime installation. *)
	$libraryProgressFunction["Installing...", None]; Symbol["WolframInstitute`MathlibLink`InstallMathlib"][]
]

libraryInstall[name_String] := Module[{entry = $libraryRegistry[name], result, status = libraryStatus[name]},
	If[status === "Ready", Return[First[PacletFind[entry["Paclet"]]]]];
	If[MemberQ[{"Needs setup", "Unsupported"}, status], Return[libraryFailure[name, "LibrarySetupRequired", RecursorLibraries[name]]]];
	$libraryProgressFunction["Preparing...", None];
	result = installLibraryPaclet[entry];
	$libraryProgressFunction["Checking...", None];
	Which[
		MatchQ[result, _Failure], result,
		! MatchQ[result, _PacletObject], libraryFailure[name, "LibraryInstallFailed", result],
		libraryStatus[name] === "Ready", result,
		True, libraryFailure[name, "LibrarySetupRequired", result]
	]
]

libraryInstall["MathlibLink"] := Module[{entry = $libraryRegistry["MathlibLink"], result, status = libraryStatus["MathlibLink"]},
	If[status === "Ready", Return[First[PacletFind[entry["Paclet"]]]]];
	If[status === "Unsupported", Return[libraryFailure["MathlibLink", "LibrarySetupRequired", RecursorLibraries["MathlibLink"]]]];
	$libraryProgressFunction["Preparing...", None];
	If[TrueQ[libraryCancelledQ[]], Return[libraryCancellation[]]];
	If[MemberQ[{"Not installed", "Update available"}, status],
		result = installLibraryPaclet[entry];
		If[MatchQ[result, _Failure], Return[result]];
		If[! MatchQ[result, _PacletObject], Return[libraryFailure["MathlibLink", "LibraryInstallFailed", result]]]
	];
	If[! libraryLoadQ[entry], Return[libraryFailure["MathlibLink", "LibrarySetupRequired", "Restart the kernel after updating the bridge."]]];
	If[TrueQ[libraryCancelledQ[]], Return[libraryCancellation[]]];
	result = Quiet[Check[libraryInstallMathlib[], $Failed]];
	$libraryProgressFunction["Checking...", None];
	If[MatchQ[result, Failure["MathlibInstallCancelled", _Association]], Return[libraryCancellation[]]];
	Which[
		MatchQ[result, _Failure], result,
		libraryReadyQ["MathlibLink"], First[PacletFind[entry["Paclet"]]],
		True, libraryFailure["MathlibLink", "LibrarySetupRequired", result]
	]
]

(* Retry interrupted transfers twice; a slow transfer has no overall deadline. *)
libraryDownload[url_String, file_String] := NestWhile[
	Function[previous,
		$libraryProgressFunction["Retrying...", None];
		libraryDownloadAttempt[url, file]
	],
	libraryDownloadAttempt[url, file],
	Function[result, MatchQ[result, Failure["LibraryDownloadFailed" | "IncompleteLibraryDownload", _Association]] &&
		! TrueQ[400 <= Lookup[result["Result"], "StatusCode", None] < 500]],
	1, 2
]

libraryDownloadAttempt[url_String, file_String] := Module[{response = <||>, task},
	If[TrueQ[libraryCancelledQ[]], Return[libraryCancellation[]]];
	WithCleanup[
		task = URLDownloadSubmit[url, file,
			TimeConstraint -> <|"Connecting" -> 30, "Reading" -> Infinity|>, ProgressReporting -> False,
			HandlerFunctions -> <|
				"TaskProgress" -> Function[event, $libraryProgressFunction["Downloading...", event["FractionComplete"]]],
				"TaskFinished" -> Function[event, response = event]
			|>, HandlerFunctionsKeys -> {"StatusCode", "Failure", "FractionComplete", "ByteCountDownloaded", "ByteCountTotal"}
		];
		If[MatchQ[task, _TaskObject],
			While[task["TaskStatus"] =!= "Removed" && ! libraryCancelledQ[], Pause[0.1]],
			response = <|"Failure" -> task|>
		];
		If[libraryCancelledQ[],
			Failure["LibraryInstallCancelled", <|"MessageTemplate" -> "Installation cancelled. You can try again."|>],
			libraryDownloadResult[url, file, response]
		],
		If[MatchQ[task, _TaskObject] && task["TaskStatus"] =!= "Removed", TaskRemove[task]]
	]
]

libraryDownloadResult[url_String, file_String, response_Association] := Which[
	(* A followed redirect can report its original status with the final file. *)
	FailureQ[Lookup[response, "Failure", None]] || ! TrueQ[200 <= Lookup[response, "StatusCode", None] < 400],
		Failure["LibraryDownloadFailed", <|
			"MessageTemplate" -> "The download could not finish. Check your connection and try again.",
			"URL" -> url, "Result" -> response
		|>],
	TrueQ[Lookup[response, "ByteCountTotal", 0] > 0] &&
		Lookup[response, "ByteCountDownloaded", None] =!= response["ByteCountTotal"],
		Failure["IncompleteLibraryDownload", <|
			"MessageTemplate" -> "The download is incomplete. Try again.", "URL" -> url, "Result" -> response
		|>],
	True, File[file]
]

(* Reject partial archives before handing them to PacletInstall. *)
libraryInstallURL[url_String] := Module[{
	file = Quiet[Check[CreateFile[FileNameJoin[{$TemporaryDirectory, CreateUUID["recursor-"] <> ".paclet"}]], $Failed]]
},
	If[! StringQ[file], Return[Failure["LibraryTemporaryFileFailed", <|
		"MessageTemplate" -> "A temporary download file could not be created. Check the temporary directory and try again."
	|>]]];
	WithCleanup[
		$libraryProgressFunction["Downloading...", 0];
		With[{download = libraryDownload[url, file]},
			Which[
				FailureQ[download], download,
				TrueQ[libraryCancelledQ[]], libraryCancellation[],
				! MatchQ[Quiet[Import[file, {"ZIP", "FileNames"}]], {__String}],
					Failure["InvalidPacletDownload", <|
						"MessageTemplate" -> "The downloaded paclet is incomplete or invalid. Try again.", "URL" -> url
					|>],
				True,
					libraryInstallFile[download]
			]
		],
		DeleteFile[file]
	]
]

libraryUninstall[name_String] := With[{paclet = $libraryRegistry[name]["Paclet"]},
	If[PacletFind[paclet] === {}, Null,
		With[{result = PacletUninstall[paclet]},
			Which[
				MatchQ[result, _Failure], result,
				result === Null && PacletFind[paclet] === {}, Null,
				True, Failure["LibraryUninstallFailed", <|
					"MessageTemplate" -> "Could not uninstall `1`. Restart the kernel and try again.",
					"MessageParameters" -> {name}, "Result" -> result
				|>]
			]
		]
	]
] /; KeyExistsQ[$libraryRegistry, name]

InstallRecursorLibraries[names : {___String}] := AssociationMap[libraryInstall, DeleteDuplicates[names]] /;
	AllTrue[names, KeyExistsQ[$libraryRegistry, #] &]
