(* Registry, status and installation of the optional external libraries. *)

PackageExported[{RecursorLibraries, InstallRecursorLibraries}]
PackageScoped[{$libraryRegistry, libraryStatus, libraryReadyQ, libraryInstall, libraryUninstall,
	$libraryProgressFunction, $libraryCancellationFunction, libraryCancelledQ, proofDirectory, proofSourceDirectory, mathlibInformation,
	versionAtLeastQ, libraryLoadQ, libraryLeanRuntimeQ, mathlibLinkArchive, installLibraryPaclet, libraryInstallResource,
	libraryInstallFile, libraryInstallMathlib, libraryDownload, libraryDownloadAttempt, libraryDownloadResult, libraryInstallURL}]

RecursorLibraries::usage = "RecursorLibraries[] gives the external libraries and their status. RecursorLibraries[name] gives information about one \
library."
InstallRecursorLibraries::usage = "InstallRecursorLibraries[{name1, name2, ...}] installs and checks selected external libraries, keeping those \
already ready."
$libraryProgressFunction::usage = "$libraryProgressFunction is the function that an installation calls as $libraryProgressFunction[stage, fraction] \
to report its stage, a string, and the completed fraction of a download, a number or None."
$libraryCancellationFunction::usage = "$libraryCancellationFunction is the function that an installation calls with no arguments to ask whether the \
user has cancelled it."
libraryCancelledQ::usage = "libraryCancelledQ[] gives True when the running installation has been cancelled."
$libraryRegistry::usage = "$libraryRegistry is the association of the optional libraries: each name gives the paclet, context, minimum version, \
description, links, platforms, download sizes, license and, where there is one, the release archive."
versionAtLeastQ::usage = "versionAtLeastQ[installed, minimum] gives True when the version string installed is not older than the version string \
minimum, comparing the numbers between the dots."
libraryLoadQ::usage = "libraryLoadQ[entry] gives True when the context of a registry entry loads without messages; the context path is left as it was."
libraryReadyQ::usage = "libraryReadyQ[name] gives True when the installed library with that name can do its work."
libraryLeanLoaderQ::usage = "libraryLeanLoaderQ[] gives True when LeanLink's native loader opens an empty environment."
libraryLeanCompilerQ::usage = "libraryLeanCompilerQ[] gives True when LeanLink compiles a small theorem within 30 seconds."
libraryLeanRuntimeQ::usage = "libraryLeanRuntimeQ[] gives True when the pinned Lean toolchain is present in the local elan directory."
libraryInformationFailure::usage = "libraryInformationFailure[] gives the Failure for a MathlibLink installation record that could not be read."
mathlibInformation::usage = "mathlibInformation[] gives the installation record of MathlibLink, an association, or a Failure when MathlibLink \
does not load or cannot report it."
proofDirectory::usage = "proofDirectory[] gives the directory of the local Lean proof workspace."
proofSourceDirectory::usage = "proofSourceDirectory[] gives the directory of the Lean sources packaged with the paclet."
libraryStatus::usage = "libraryStatus[name] gives the status of a registered library: \"Unsupported\", \"Not installed\", \"Update available\", \
\"Needs setup\" or \"Ready\"."
libraryInformation::usage = "libraryInformation[name] gives the public registry entry of a registered library with its installed version, runtime \
details and status."
libraryRuntimeInformation::usage = "libraryRuntimeInformation[] gives the directories, toolchain and revision of the MathlibLink installation, or an \
empty association."
libraryFailure::usage = "libraryFailure[name, tag, result] gives the Failure with that tag for a library that could not be made ready; result is \
what the failed step gave."
mathlibLinkArchive::usage = "mathlibLinkArchive[] gives the path of a local MathlibLink paclet archive, from MATHLIBLINK_PACLET or the sibling \
source tree, or Missing[\"NotFound\"]."
installLibraryPaclet::usage = "installLibraryPaclet[entry] installs the paclet of a registry entry and gives the PacletObject or a Failure."
libraryInstallMathlibArchive::usage = "libraryInstallMathlibArchive[entry] installs the MathlibLink paclet from a local archive, or from its release \
when there is none."
libraryInstallMathlibRelease::usage = "libraryInstallMathlibRelease[entry] installs the MathlibLink paclet from its release archive; a missing \
release gives a Failure that names the local remedy."
libraryInstallResource::usage = "libraryInstallResource[name, version] finds the archive of a Paclet Repository resource and installs it."
libraryCancellation::usage = "libraryCancellation[] gives the Failure for a cancelled installation."
libraryInstallFile::usage = "libraryInstallFile[file] installs a paclet archive, a File, unless the installation has been cancelled."
libraryInstallMathlib::usage = "libraryInstallMathlib[] runs MathlibLink's runtime installer, with progress and cancellation where it supports them."
libraryInstall::usage = "libraryInstall[name] makes a registered library ready and gives its PacletObject or a Failure; a ready library is kept."
libraryInstallChecked::usage = "libraryInstallChecked[name, entry] installs the paclet of a library and checks that it is ready."
libraryInstallMathlibBridge::usage = "libraryInstallMathlibBridge[entry, status] installs the MathlibLink paclet when the status says it is missing \
or old, then its runtime."
libraryInstallMathlibRuntime::usage = "libraryInstallMathlibRuntime[entry] loads MathlibLink and installs its runtime unless the installation has \
been cancelled."
libraryInstallMathlibChecked::usage = "libraryInstallMathlibChecked[entry] runs the runtime installer and checks that MathlibLink is ready."
libraryDownload::usage = "libraryDownload[url, file] downloads url to file, retrying an interrupted transfer twice, and gives File[file] or a Failure."
libraryDownloadAttempt::usage = "libraryDownloadAttempt[url, file] makes one download unless the installation has been cancelled."
libraryTransfer::usage = "libraryTransfer[url, file] runs one download task until it ends or is cancelled, and gives File[file] or a Failure."
libraryTransferActiveQ::usage = "libraryTransferActiveQ[task] gives True while a download task runs and the installation is not cancelled."
libraryDownloadResult::usage = "libraryDownloadResult[url, file, response] gives File[file] for a complete transfer, and a Failure for a failed or \
incomplete one."
libraryTemporaryFileFailure::usage = "libraryTemporaryFileFailure[] gives the Failure for a temporary download file that could not be created."
libraryInstallURL::usage = "libraryInstallURL[url] downloads a paclet archive to a temporary file, validates it, installs it and deletes the file."
libraryInstallArchive::usage = "libraryInstallArchive[url, file] downloads url to the temporary file, validates and installs the archive, and \
deletes the file."
libraryUninstall::usage = "libraryUninstall[name] uninstalls the paclet of a registered library and gives Null or a Failure."
libraryInstallSelected::usage = "libraryInstallSelected[{name1, name2, ...}] installs the selected libraries, MathlibLink before LeanLink, and gives \
the results in the order selected."

(* The libraries are external code whose messages are not known in advance, so the calls into them are quieted in full. *)

$libraryProgressFunction = (Null &)
$libraryCancellationFunction = (False &)
libraryCancelledQ[] := TrueQ[$libraryCancellationFunction[]]

(* Reading the registry never installs or downloads a library. *)
$libraryRegistry = <|
	"Lambda" -> <|"Paclet" -> "Wolfram/Lambda", "Context" -> "Wolfram`Lambda`", "MinimumVersion" -> "1.2.5",
		"Description" -> "Lambda-term diagrams and reduction graphs.",
		"URL" -> "https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/Lambda/",
		"Platforms" -> {"Linux-x86-64", "Linux-ARM64", "MacOSX-ARM64", "MacOSX-x86-64", "Windows-x86-64"},
		"DownloadSize" -> AssociationMap["1.3 MB" &,
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
		"Description" -> "Mathlib declarations, computation and proofs.",
		"URL" -> "https://www.wolframcloud.com/obj/wolframinstitute/MathlibLink/#ref/InstallMathlib",
		"SetupLinks" -> <|"mathlib documentation" -> "https://leanprover-community.github.io/mathlib4_docs/"|>,
		"Platforms" -> {"Linux-x86-64", "MacOSX-ARM64", "Windows-x86-64"},
		"DownloadSize" -> AssociationMap["varies; includes runtime" &,
			{"Linux-x86-64", "MacOSX-ARM64", "Windows-x86-64"}],
		"License" -> "MIT; runtime licenses apply",
		"Archive" -> "https://github.com/WolframInstitute/MathlibLink/releases/download/v0.1.0/WolframInstitute__MathlibLink-0.1.0.paclet"|>
|>

versionAtLeastQ[installed_String, minimum_String] := Module[{installedParts, minimumParts, length},
	installedParts = FromDigits /@ StringSplit[installed, "."];
	minimumParts = FromDigits /@ StringSplit[minimum, "."];
	length = Max[Length[installedParts], Length[minimumParts]];
	OrderedQ[{PadRight[minimumParts, length], PadRight[installedParts, length]}]
]

libraryLoadQ[entry_Association] := Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs[entry["Context"]] === Null, False], All]]

(* Probe the local runtime before compilation so readiness cannot trigger an elan download. *)
libraryReadyQ["LeanLink"] := libraryLeanRuntimeQ[] && libraryLeanLoaderQ[] && libraryLeanCompilerQ[]

libraryLeanLoaderQ[] := Module[{handle},
	handle = Quiet[Symbol["Wolfram`LeanLink`LeanLoadEnvironment"][{}, ""], All];
	If[IntegerQ[handle] && handle > 0,
		Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][handle];
		True,
		False
	]
]

libraryLeanCompilerQ[] := Module[{environment},
	environment = TimeConstrained[
		Quiet[Symbol["Wolfram`LeanLink`LeanImportString"]["theorem recursor_library_probe : 1 = 1 := rfl"], All],
		30,
		$TimedOut
	];
	If[MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
		WithCleanup[True, Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][Information[environment, "Handle"]]],
		False
	]
]

(* LeanLink caches a failed native load; do not attempt one before setup has
   provided the pinned toolchain. A later explicit installation can then recover. *)
libraryLeanRuntimeQ[] := Module[{elanDirectory, toolchainDirectory},
	elanDirectory = Replace[Environment["ELAN_HOME"], Except[_String] :> FileNameJoin[{$HomeDirectory, ".elan"}]];
	toolchainDirectory = FileNameJoin[{elanDirectory, "toolchains", "leanprover--lean4---v4.35.0"}];
	AllTrue[{
		FileNameJoin[{toolchainDirectory, "lib", "lean", "Init.olean"}],
		FileNameJoin[{toolchainDirectory, "bin", "lean" <> If[$OperatingSystem === "Windows", ".exe", ""]}]
	}, FileExistsQ]
]

libraryReadyQ["Lambda"] := True
libraryReadyQ["MathlibLink"] := Module[{information},
	information = mathlibInformation[];
	AssociationQ[information] && Lookup[information, "Status", None] === "Ready"
]

libraryInformationFailure[] := Failure["MathlibInformationUnavailable", <|
	"MessageTemplate" -> "MathlibLink could not report its installation."
|>]

mathlibInformation[] := If[libraryLoadQ[$libraryRegistry["MathlibLink"]],
	Quiet[Check[Symbol["WolframInstitute`MathlibLink`MathlibInstallation"][], libraryInformationFailure[]], All],
	libraryInformationFailure[]
]

proofDirectory[] := FileNameJoin[{$UserBaseDirectory, "ApplicationData", "Recursor", "Lean", "4.35.0"}]
proofSourceDirectory[] := FileNameJoin[{PacletObject["WolframInstitute/Recursor"]["Location"], "Assets", "Lean"}]

libraryStatus[name_String] := Module[{entry, installed},
	entry = $libraryRegistry[name];
	installed = PacletFind[entry["Paclet"]];
	Which[
		! MemberQ[entry["Platforms"], $SystemID], "Unsupported",
		installed === {}, "Not installed",
		! versionAtLeastQ[First[installed]["Version"], entry["MinimumVersion"]], "Update available",
		! libraryLoadQ[entry], "Needs setup",
		TrueQ[Quiet[Check[libraryReadyQ[name], False], All]], "Ready",
		True, "Needs setup"
	]
] /; KeyExistsQ[$libraryRegistry, name]

libraryRuntimeInformation[] := Module[{information},
	information = mathlibInformation[];
	If[AssociationQ[information], KeyTake[information, {"Directory", "MathlibDirectory", "Toolchain", "Revision"}], <||>]
]

libraryInformation[name_String] := Module[{entry, installed, version, runtime},
	entry = $libraryRegistry[name];
	installed = PacletFind[entry["Paclet"]];
	version = If[installed === {}, Missing["NotInstalled"], First[installed]["Version"]];
	runtime = If[name === "MathlibLink" && installed =!= {}, libraryRuntimeInformation[], <||>];
	Join[KeyDrop[entry, {"Archive", "Context"}], <|"Version" -> version|>, runtime, <|"Status" -> libraryStatus[name]|>]
]

RecursorLibraries[name_String] := Block[{$ContextPath = $ContextPath}, libraryInformation[name]] /; KeyExistsQ[$libraryRegistry, name]
RecursorLibraries[] := Block[{$ContextPath = $ContextPath}, AssociationMap[RecursorLibraries, Keys[$libraryRegistry]]]
RecursorLibraries[___] := invalidArgumentsFailure[RecursorLibraries]

(* allow BarePattern: the result of a failed installation step can be any expression *)
libraryFailure[name_String, tag_String, result_] := Failure[tag, <|
	"MessageTemplate" -> "`1` could not be made ready. See the setup instructions and the returned result.",
	"MessageParameters" -> {name}, "Result" -> result, "URL" -> $libraryRegistry[name]["URL"]
|>]

(* Prefer an explicit or sibling development archive before the published release. *)
mathlibLinkArchive[] := SelectFirst[{
	Environment["MATHLIBLINK_PACLET"],
	FileNameJoin[{DirectoryName[PacletObject["WolframInstitute/Recursor"]["Location"], 3], "Mathematics", "MathlibLink", "dist", "WolframInstitute__MathlibLink-0.1.0.paclet"}]
}, StringQ[#] && FileExistsQ[#] &, Missing["NotFound"]]

installLibraryPaclet[entry_Association] := Quiet[
	Which[
		TrueQ[libraryCancelledQ[]], libraryCancellation[],
		entry["Paclet"] === "WolframInstitute/MathlibLink", libraryInstallMathlibArchive[entry],
		KeyExistsQ[entry, "Archive"], libraryInstallURL[entry["Archive"]],
		True, libraryInstallResource[entry["Paclet"], entry["MinimumVersion"]]
	],
	All
]

libraryInstallMathlibArchive[entry_Association] := Module[{archive},
	archive = mathlibLinkArchive[];
	If[StringQ[archive], libraryInstallFile[File[archive]], libraryInstallMathlibRelease[entry]]
]

libraryInstallMathlibRelease[entry_Association] := Module[{result},
	result = libraryInstallURL[entry["Archive"]];
	If[MatchQ[result, Failure["LibraryDownloadFailed", KeyValuePattern["Result" -> KeyValuePattern["StatusCode" -> 404]]]],
		Failure["MathlibLinkReleaseUnavailable", <|
			"MessageTemplate" -> "The MathlibLink release archive is not available. Build MathlibLink with make check-publish, or set MATHLIBLINK_PACLET to a local paclet archive.",
			"URL" -> entry["Archive"], "Result" -> result
		|>],
		result
	]
]

(* Resolve the repository's archive metadata, then use the same cancellable
   transfer as libraries with an explicit release archive. *)
libraryInstallResource[name_String, version_String] := Module[{timeout, source, archive},
	timeout = Failure["LibraryResourceTimedOut", <|"MessageTemplate" -> "The Paclet Repository did not answer in time."|>];
	source = Quiet[TimeConstrained[ResourceObject[name, ResourceVersion -> version]["PacletFile"], 30, timeout], All];
	archive = Replace[source, {(URL | CloudObject)[url_String, ___] :> url}];
	Which[
		TrueQ[libraryCancelledQ[]], libraryCancellation[],
		StringQ[archive] && StringStartsQ[archive, "https://"], libraryInstallURL[archive],
		StringQ[archive] && FileExistsQ[archive], libraryInstallFile[File[archive]],
		MatchQ[archive, File[_String]] && FileExistsQ[First[archive]], libraryInstallFile[archive],
		True, Failure["LibraryDownloadFailed", <|
			"MessageTemplate" -> "The paclet download could not be found. Check your connection and try again.", "Result" -> source
		|>]
	]
]

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
	$libraryProgressFunction["Installing...", None];
	Symbol["WolframInstitute`MathlibLink`InstallMathlib"][]
]

libraryInstall[name_String] := Module[{entry, status},
	entry = $libraryRegistry[name];
	status = libraryStatus[name];
	Which[
		status === "Ready", First[PacletFind[entry["Paclet"]]],
		MemberQ[{"Needs setup", "Unsupported"}, status], libraryFailure[name, "LibrarySetupRequired", RecursorLibraries[name]],
		True, libraryInstallChecked[name, entry]
	]
]

libraryInstallChecked[name_String, entry_Association] := Module[{result},
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

libraryInstall["MathlibLink"] := Module[{entry, status},
	entry = $libraryRegistry["MathlibLink"];
	status = libraryStatus["MathlibLink"];
	Which[
		status === "Ready", First[PacletFind[entry["Paclet"]]],
		status === "Unsupported", libraryFailure["MathlibLink", "LibrarySetupRequired", RecursorLibraries["MathlibLink"]],
		True, libraryInstallMathlibBridge[entry, status]
	]
]

libraryInstallMathlibBridge[entry_Association, status_String] := Module[{bridge},
	$libraryProgressFunction["Preparing...", None];
	Which[
		TrueQ[libraryCancelledQ[]], libraryCancellation[],
		! MemberQ[{"Not installed", "Update available"}, status], libraryInstallMathlibRuntime[entry],
		True,
			bridge = installLibraryPaclet[entry];
			Which[
				MatchQ[bridge, _Failure], bridge,
				! MatchQ[bridge, _PacletObject], libraryFailure["MathlibLink", "LibraryInstallFailed", bridge],
				True, libraryInstallMathlibRuntime[entry]
			]
	]
]

libraryInstallMathlibRuntime[entry_Association] := Which[
	! libraryLoadQ[entry], libraryFailure["MathlibLink", "LibrarySetupRequired", "Restart the kernel after updating the bridge."],
	TrueQ[libraryCancelledQ[]], libraryCancellation[],
	True, libraryInstallMathlibChecked[entry]
]

(* An installer that issued messages is not trusted to have finished: its result is replaced, and readiness decides. *)
libraryInstallMathlibChecked[entry_Association] := Module[{messages, result},
	messages = Failure["MathlibInstallMessages", <|"MessageTemplate" -> "The mathlib installer issued messages."|>];
	result = Quiet[Check[libraryInstallMathlib[], messages], All];
	$libraryProgressFunction["Checking...", None];
	Which[
		MatchQ[result, Failure["MathlibInstallCancelled", _Association]], libraryCancellation[],
		MatchQ[result, _Failure] && result =!= messages, result,
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
	Function[result,
		And[
			MatchQ[result, Failure["LibraryDownloadFailed" | "IncompleteLibraryDownload", _Association]],
			! TrueQ[400 <= Lookup[result["Result"], "StatusCode", None] < 500]
		]
	],
	1, 2
]

libraryDownloadAttempt[url_String, file_String] := If[TrueQ[libraryCancelledQ[]], libraryCancellation[], libraryTransfer[url, file]]

libraryTransferActiveQ[task_TaskObject] := task["TaskStatus"] =!= "Removed" && ! libraryCancelledQ[]

libraryTransfer[url_String, file_String] := Module[{response = <||>, task},
	WithCleanup[
		task = URLDownloadSubmit[url, file,
			TimeConstraint -> <|"Connecting" -> 30, "Reading" -> Infinity|>, ProgressReporting -> False,
			HandlerFunctions -> <|
				"TaskProgress" -> Function[event, $libraryProgressFunction["Downloading...", event["FractionComplete"]]],
				"TaskFinished" -> Function[event, response = event]
			|>, HandlerFunctionsKeys -> {"StatusCode", "Failure", "FractionComplete", "ByteCountDownloaded", "ByteCountTotal"}
		];
		If[MatchQ[task, _TaskObject],
			NestWhile[
				Function[running,
					Pause[0.1];
					running
				],
				task,
				libraryTransferActiveQ
			],
			response = <|"Failure" -> task|>
		];
		If[libraryCancelledQ[], libraryCancellation[], libraryDownloadResult[url, file, response]],
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
	And[
		TrueQ[Lookup[response, "ByteCountTotal", 0] > 0],
		Lookup[response, "ByteCountDownloaded", None] =!= response["ByteCountTotal"]
	],
		Failure["IncompleteLibraryDownload", <|
			"MessageTemplate" -> "The download is incomplete. Try again.", "URL" -> url, "Result" -> response
		|>],
	True, File[file]
]

libraryTemporaryFileFailure[] := Failure["LibraryTemporaryFileFailed", <|
	"MessageTemplate" -> "A temporary download file could not be created. Check the temporary directory and try again."
|>]

(* Reject partial archives before handing them to PacletInstall. *)
libraryInstallURL[url_String] := Module[{file},
	file = Quiet[Check[CreateFile[FileNameJoin[{$TemporaryDirectory, CreateUUID["recursor-"] <> ".paclet"}]], libraryTemporaryFileFailure[]], All];
	If[StringQ[file], libraryInstallArchive[url, file], libraryTemporaryFileFailure[]]
]

libraryInstallArchive[url_String, file_String] := Module[{download},
	WithCleanup[
		$libraryProgressFunction["Downloading...", 0];
		download = libraryDownload[url, file];
		Which[
			FailureQ[download], download,
			TrueQ[libraryCancelledQ[]], libraryCancellation[],
			! MatchQ[Quiet[Import[file, {"ZIP", "FileNames"}], All], {__String}],
				Failure["InvalidPacletDownload", <|
					"MessageTemplate" -> "The downloaded paclet is incomplete or invalid. Try again.", "URL" -> url
				|>],
			True, libraryInstallFile[download]
		],
		DeleteFile[file]
	]
]

libraryUninstall[name_String] := Module[{paclet, result},
	paclet = $libraryRegistry[name]["Paclet"];
	If[PacletFind[paclet] === {},
		Null,
		result = PacletUninstall[paclet];
		Which[
			MatchQ[result, _Failure], result,
			result === Null && PacletFind[paclet] === {}, Null,
			True, Failure["LibraryUninstallFailed", <|
				"MessageTemplate" -> "Could not uninstall `1`. Restart the kernel and try again.",
				"MessageParameters" -> {name}, "Result" -> result
			|>]
		]
	]
] /; KeyExistsQ[$libraryRegistry, name]

(* MathlibLink supplies the toolchain needed to make LeanLink ready. *)
libraryInstallSelected[selected : {___String}] := Module[{order},
	order = If[ContainsAll[selected, {"LeanLink", "MathlibLink"}],
		DeleteDuplicates[Replace[selected, "LeanLink" -> Sequence["MathlibLink", "LeanLink"], {1}]],
		selected
	];
	KeyTake[AssociationMap[libraryInstall, order], selected]
]

InstallRecursorLibraries[names : {___String}] :=
	Block[{$ContextPath = $ContextPath}, libraryInstallSelected[DeleteDuplicates[names]]] /; AllTrue[names, KeyExistsQ[$libraryRegistry, #] &]
InstallRecursorLibraries[___] := invalidArgumentsFailure[InstallRecursorLibraries]
