Needs["WolframInstitute`Recursor`"]

VerificationTest[InstallRecursorLibraries[{}], <||>, TestID -> "empty-installation-is-local-no-op"]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`libraryInstall = Function[name, Sow[name]; name]},
		Reap[InstallRecursorLibraries[{"LeanLink", "Lambda", "LeanLink"}]]
	],
	{<|"LeanLink" -> "LeanLink", "Lambda" -> "Lambda"|>, {{"LeanLink", "Lambda"}}},
	TestID -> "install-processes-each-selection-once"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`libraryInstall = Function[name, Sow[name]; name]},
		Last[Reap[InstallRecursorLibraries[{"Lambda", "Unknown"}]]]
	], {}, TestID -> "invalid-selection-starts-no-installation"
]

VerificationTest[Head[InstallRecursorLibraries["Lambda"]], InstallRecursorLibraries, TestID -> "install-requires-a-list"]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Needs setup" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Sow["download"]; $Failed &)
	},
		With[{result = Reap[InstallRecursorLibraries[{"LeanLink"}]]}, {result[[1, "LeanLink"]]["Tag"], Last[result]}]
	], {"LibrarySetupRequired", {}}, TestID -> "broken-installation-reports-setup-without-reinstall"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Not installed" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = ($Failed &)
	}, InstallRecursorLibraries[{"Lambda"}]["Lambda"]["Tag"]],
	"LibraryInstallFailed", TestID -> "download-failure-is-structured"
]

VerificationTest[
	WolframInstitute`Recursor`Libraries`Installation`Private`versionAtLeastQ @@@ {{"1.2.5", "1.2.5"}, {"1.2.10", "1.2.5"}, {"1.2.4", "1.2.5"}, {"1.3", "1.2.5"}},
	{True, True, False, True}, TestID -> "library-versions-compare-numerically"
]

VerificationTest[
	Keys[WolframInstitute`Recursor`PackageScope`$libraryRegistry],
	{"Lambda", "LeanLink", "MathlibLink"}, TestID -> "only-selected-external-libraries"
]

VerificationTest[
	Block[{
		PacletFind = ({PacletObject[<|"Name" -> "Wolfram/Lambda", "Version" -> "1.2.5"|>]} &),
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Ready" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Sow["download"]; $Failed &)
	}, Last[Reap[InstallRecursorLibraries[{"Lambda"}]]]],
	{}, TestID -> "ready-library-is-not-reinstalled"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`PackageScope`$libraryRegistry = Map[Append[#, "Platforms" -> {}] &,
			WolframInstitute`Recursor`PackageScope`$libraryRegistry],
		PacletFind = ({} &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Throw["Unexpected download"] &)
	}, Catch[{RecursorLibraries["Lambda"]["Status"], InstallRecursorLibraries[{"Lambda"}]["Lambda"]["Tag"]}]],
	{"Unsupported", "LibrarySetupRequired"}, TestID -> "unsupported-system-never-starts-installation"
]

VerificationTest[
	Module[{before = $ContextPath}, Block[{
		Needs = Function[context, $ContextPath = Prepend[$ContextPath, context]; Null]
	}, {
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryLoadQ[<|"Context" -> "TemporaryLibrary`"|>],
		$ContextPath === before
	}]],
	{True, True}, TestID -> "library-loading-preserves-context-path"
]

VerificationTest[
	Block[{
		PacletFind = ({} &), PacletUninstall = (Throw["Unexpected removal"] &)
	}, Catch[{
		WolframInstitute`Recursor`PackageScope`libraryUninstall["Lambda"],
		Head[WolframInstitute`Recursor`PackageScope`libraryUninstall["Unknown"]]
	}]],
	{Null, WolframInstitute`Recursor`PackageScope`libraryUninstall},
	TestID -> "uninstall-missing-or-unknown-library-is-local"
]

VerificationTest[
	Module[{installed = {"Wolfram/Lambda", "Wolfram/LeanLink"}, removed = {}}, Block[{
		PacletFind = Function[name, If[MemberQ[installed, name], {versionOne, versionTwo}, {}]],
		PacletUninstall = Function[name, AppendTo[removed, name]; installed = DeleteCases[installed, name]; Null]
	}, {
		WolframInstitute`Recursor`PackageScope`libraryUninstall["Lambda"], removed, installed
	}]],
	{Null, {"Wolfram/Lambda"}, {"Wolfram/LeanLink"}},
	TestID -> "uninstall-removes-only-the-selected-paclet"
]

VerificationTest[
	Table[Block[{PacletFind = ({installedPaclet} &), PacletUninstall = (result &)},
		WolframInstitute`Recursor`PackageScope`libraryUninstall["Lambda"] /. Failure[tag_, _] :> tag
	], {result, {$Failed, Null, Failure["PermissionDenied", <||>]}}],
	{"LibraryUninstallFailed", "LibraryUninstallFailed", "PermissionDenied"},
	TestID -> "uninstall-checks-removal-and-preserves-failures"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`PackageScope`libraryCancelledQ = (True &),
		URLDownloadSubmit = (Throw["Unexpected download"] &),
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownloadAttempt[
		"https://example.com/library.paclet", "download.paclet"]["Tag"]]],
	"LibraryInstallCancelled", TestID -> "cancelled-transfer-does-not-start"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Needs setup" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryLoadQ = (True &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallMathlib =
			(Failure["MathlibInstallCancelled", <|"MessageTemplate" -> "Cancelled."|>] &),
		WolframInstitute`Recursor`PackageScope`libraryReadyQ = (Throw["Unexpected readiness probe"] &)
	}, Catch[InstallRecursorLibraries[{"MathlibLink"}]["MathlibLink"]["Tag"]]],
	"LibraryInstallCancelled", TestID -> "mathlib-runtime-cancellation-reaches-dialog"
]

VerificationTest[
	Module[{stages = {}, cancelled = False}, Block[{
		Options = ({"ProgressFunction" -> (Null &), "CancellationFunction" -> (False &)} &),
		WolframInstitute`Recursor`PackageScope`$libraryProgressFunction = Function[{stage, fraction}, AppendTo[stages, {stage, fraction}]],
		WolframInstitute`Recursor`PackageScope`libraryCancelledQ = Function[Null, cancelled],
		WolframInstitute`MathlibLink`InstallMathlib = Function[Null, With[{options = Association[{##}]},
			options["ProgressFunction"]["Downloading...", None]; cancelled = True; options["CancellationFunction"][]]]
	}, {WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallMathlib[], stages}]],
	{True, {{"Downloading...", None}}}, TestID -> "mathlib-installer-receives-live-progress-and-cancellation-callbacks"
]

VerificationTest[
	Module[{stages = {}}, Block[{
		Options = ({"Directory" -> Automatic} &),
		WolframInstitute`Recursor`PackageScope`$libraryProgressFunction = Function[{stage, fraction}, AppendTo[stages, {stage, fraction}]],
		WolframInstitute`MathlibLink`InstallMathlib = Function[Null, Length[{##}]]
	}, {WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallMathlib[], stages}]],
	{0, {{"Installing...", None}}}, TestID -> "older-mathlib-installer-is-not-advertised-as-cancellable"
]

VerificationTest[
	Table[WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownloadResult[
		"https://example.com/library.paclet", "download.paclet", response] /. Failure[tag_, _] :> tag,
		{response, {
			<|"StatusCode" -> 200, "Failure" -> Failure["Interrupted", <||>], "ByteCountDownloaded" -> 4, "ByteCountTotal" -> 1024|>,
			<|"StatusCode" -> 200, "ByteCountDownloaded" -> 4, "ByteCountTotal" -> 1024|>,
			<|"StatusCode" -> 404|>, <||>,
			<|"StatusCode" -> 200, "ByteCountDownloaded" -> 1024, "ByteCountTotal" -> 1024|>,
			<|"StatusCode" -> 302, "ByteCountDownloaded" -> 1024, "ByteCountTotal" -> 1024|>,
			<|"StatusCode" -> 200, "ByteCountDownloaded" -> 1024, "ByteCountTotal" -> 0|>
		}}],
	{"LibraryDownloadFailed", "IncompleteLibraryDownload", "LibraryDownloadFailed", "LibraryDownloadFailed",
		File["download.paclet"], File["download.paclet"], File["download.paclet"]},
	TestID -> "Library-download-checks-transfer-errors-even-with-HTTP-success"
]

VerificationTest[
	Table[Module[{attempts = 0}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownloadAttempt = Function[{url, file},
			attempts++; If[attempts < 3, failure, File[file]]]
	}, {
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload["https://example.com/library.paclet", "download.paclet"] /. Failure[tag_, _] :> tag,
		attempts
	}]], {failure, {
		Failure["LibraryDownloadFailed", <|"Result" -> <|"StatusCode" -> None|>|>],
		Failure["IncompleteLibraryDownload", <|"Result" -> <|"StatusCode" -> 200|>|>],
		Failure["LibraryDownloadFailed", <|"Result" -> <|"StatusCode" -> 404|>|>],
		Failure["LibraryInstallCancelled", <||>]
	}}],
	{{File["download.paclet"], 3}, {File["download.paclet"], 3}, {"LibraryDownloadFailed", 1}, {"LibraryInstallCancelled", 1}},
	TestID -> "Library-retries-interrupted-transfers-without-retrying-cancellation-or-missing-downloads"
]

VerificationTest[
	Module[{attempts = 0}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownloadAttempt = Function[{url, file},
			attempts++; Failure["LibraryDownloadFailed", <|"Result" -> <|"StatusCode" -> None|>|>]]
	}, {
		FailureQ[WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload["https://example.com/library.paclet", "download.paclet"]],
		attempts
	}]],
	{True, 3},
	TestID -> "Library-stops-after-three-failed-download-attempts"
]

VerificationTest[
	Module[{attempts = 0, temporary, result}, Block[{
		URLDownloadSubmit = Function[{url, file, timeout, progress, handlers, keys},
			attempts++; temporary = file; Failure["Offline", <|"MessageTemplate" -> "No connection."|>]],
		TaskRemove = (Throw["Unexpected task removal"] &), PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[
		result = WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"];
		{MatchQ[result, Failure["LibraryDownloadFailed", _]], attempts, ! FileExistsQ[temporary], result["Result"]["Failure"]}
	]]],
	{True, 3, True, Failure["Offline", <|"MessageTemplate" -> "No connection."|>]},
	TestID -> "Library-failed-task-creation-preserves-the-error-and-cleans-up"
]

VerificationTest[
	Module[{temporary, stages = {}, installed}, Block[{
		WolframInstitute`Recursor`PackageScope`$libraryProgressFunction = Function[{stage, fraction},
			stages = Append[stages, {stage, fraction}]],
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file}, temporary = file; File[file]],
		Import = ({"PacletInfo.wl"} &),
		PacletInstall = Function[file, installed = {FileExtension[First[file]], FileExistsQ[First[file]]}; installedPaclet]
	}, {
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"],
		installed, stages, ! FileExistsQ[temporary]
	}]],
	{installedPaclet, {"paclet", True}, {{"Downloading...", 0}, {"Installing...", None}}, True},
	TestID -> "Library-install-reports-stages-and-cleans-completed-archive"
]

VerificationTest[
	Module[{temporary}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file},
			temporary = file; Failure["DownloadFailed", <|"MessageTemplate" -> "Download interrupted."|>]],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[{
		MatchQ[WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"],
			Failure["DownloadFailed", _Association]],
		! FileExistsQ[temporary]
	}]]],
	{True, True},
	TestID -> "Library-download-failure-is-preserved-and-cleans-up-without-installing"
]

VerificationTest[
	Module[{temporary}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file},
			temporary = file; BinaryWrite[file, {80, 75, 3, 4}]; Close[file]; File[file]],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[{
		MatchQ[WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"],
			Failure["InvalidPacletDownload", _Association]],
		! FileExistsQ[temporary]
	}]]],
	{True, True},
	TestID -> "Library-partial-ZIP-download-cleans-up-without-installing"
]

VerificationTest[
	Module[{temporary}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file}, temporary = file; Abort[]],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[{
		CheckAbort[WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"], "Aborted"],
		! FileExistsQ[temporary]
	}]]],
	{"Aborted", True},
	TestID -> "Library-download-abort-cleans-up-without-installing"
]

VerificationTest[
	Module[{cancelled = False, temporary}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file}, temporary = file; File[file]],
		WolframInstitute`Recursor`PackageScope`libraryCancelledQ = Function[Null, cancelled],
		Import = Function[Null, cancelled = True; {"PacletInfo.wl"}],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL["https://example.com/library.paclet"]["Tag"],
		! FileExistsQ[temporary]
	}]]],
	{"LibraryInstallCancelled", True},
	TestID -> "cancellation-during-archive-validation-prevents-installation"
]

VerificationTest[
	Module[{cancelled = False}, Block[{
		WolframInstitute`Recursor`PackageScope`$libraryProgressFunction = Function[Null, cancelled = True],
		WolframInstitute`Recursor`PackageScope`libraryCancelledQ = Function[Null, cancelled],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallFile[File["local.paclet"]]["Tag"]]]],
	"LibraryInstallCancelled", TestID -> "cancellation-in-progress-callback-prevents-local-installation"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryLeanRuntimeQ = (False &),
		Wolfram`LeanLink`LeanLoadEnvironment = (Throw["Unexpected native load"] &),
		Wolfram`LeanLink`LeanImportString = (Throw["Unexpected compilation"] &)
	}, Catch[WolframInstitute`Recursor`PackageScope`libraryReadyQ["LeanLink"]]],
	False, TestID -> "readiness-before-toolchain-setup-does-not-poison-native-loader"
]

VerificationTest[
	Module[{arguments}, Block[{
		ResourceObject = Function[Null,
			arguments = {##}; Message[ResourceObject::updavb, "Wolfram/Lambda"];
			<|"PacletFile" -> URL["https://example.com/library.paclet"]|>
		],
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL = Identity
	}, {
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallResource["Wolfram/Lambda", "1.2.5"], arguments
	}]],
	{"https://example.com/library.paclet", {"Wolfram/Lambda", ResourceVersion -> "1.2.5"}},
	TestID -> "resource-resolution-uses-versioned-metadata-and-keeps-valid-archive-with-update-notice"
]

VerificationTest[
	Module[{ready = False, before, result}, Block[{
		PacletFind = Function[name, {PacletObject[<|"Name" -> name, "Version" -> "1.2.5"|>]}],
		WolframInstitute`Recursor`PackageScope`libraryStatus = Function[Null, If[ready, "Ready", "Needs setup"]],
		WolframInstitute`Recursor`PackageScope`libraryReadyQ = Function[Null, ready],
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryLoadQ = (True &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallMathlib = Function[Null, ready = True; File["runtime"]],
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Throw["Unexpected reinstallation"] &)
	}, Catch[
		before = RecursorLibraries["LeanLink"]["Status"];
		result = InstallRecursorLibraries[{"LeanLink", "MathlibLink", "LeanLink"}];
		{before, Keys[result], MatchQ[result["LeanLink"], _PacletObject],
			MatchQ[result["MathlibLink"], _PacletObject], RecursorLibraries["LeanLink"]["Status"]}
	]]],
	{"Needs setup", {"LeanLink", "MathlibLink"}, True, True, "Ready"},
	TestID -> "bulk-install-prepares-toolchain-before-reporting-LeanLink-success"
]

VerificationTest[
	Module[{before = $ContextPath, result}, Block[{
		WolframInstitute`Recursor`PackageScope`libraryInstall = Function[name,
			PrependTo[$ContextPath, "TemporaryInstaller`"]; name]
	},
		result = InstallRecursorLibraries[{"Lambda", "LeanLink"}];
		{result, $ContextPath === before}
	]],
	{<|"Lambda" -> "Lambda", "LeanLink" -> "LeanLink"|>, True},
	TestID -> "public-installer-preserves-results-and-context-path-through-cold-initialization"
]

VerificationTest[
	Module[{before = $ContextPath, single, all, singlePreserved}, Block[{
		PacletFind = Function[Null, PrependTo[$ContextPath, "TemporaryPacletScan`"]; {}],
		WolframInstitute`Recursor`PackageScope`libraryStatus = Function[Null,
			PrependTo[$ContextPath, "TemporaryStatusProbe`"]; "Not installed"]
	},
		single = RecursorLibraries["Lambda"];
		singlePreserved = $ContextPath === before;
		all = RecursorLibraries[];
		{single["Status"], singlePreserved, Keys[all], Values[all][[All, "Status"]], $ContextPath === before}
	]],
	{"Not installed", True, {"Lambda", "LeanLink", "MathlibLink"}, ConstantArray["Not installed", 3], True},
	TestID -> "library-status-access-preserves-context-path"
]

VerificationTest[
	Module[{base = FileNameJoin[{$TemporaryDirectory, "recursor-archive-fixture"}], override, sibling, location},
		override = FileNameJoin[{base, "selected.paclet"}];
		sibling = FileNameJoin[{base, "Mathematics", "MathlibLink", "dist", "WolframInstitute__MathlibLink-0.1.0.paclet"}];
		location = FileNameJoin[{base, "AI", "Recursor", "Recursor"}];
		Table[Block[{
			Environment = Function[name, If[name === "MATHLIBLINK_PACLET", override, $Failed]],
			PacletObject = (<|"Location" -> location|> &),
			FileExistsQ = Function[file, MemberQ[present, file]]
		}, WolframInstitute`Recursor`Libraries`Installation`Private`mathlibLinkArchive[]],
			{present, {{override, sibling}, {sibling}, {}}}] === {override, sibling, Missing["NotFound"]}
	], True, TestID -> "mathlib-archive-prefers-explicit-path-then-sibling-archive"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`mathlibLinkArchive = ("local.paclet" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallFile = Identity,
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryInstallURL = (Throw["Unexpected download"] &)
	}, Catch[WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet[
		WolframInstitute`Recursor`PackageScope`$libraryRegistry["MathlibLink"]]]],
	File["local.paclet"], TestID -> "mathlib-local-archive-does-not-request-release-download"
]

VerificationTest[
	Module[{downloadURL, temporary, result, installed}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`mathlibLinkArchive = (Missing["NotFound"] &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file},
			downloadURL = url; temporary = file; File[file]],
		Import = ({"PacletInfo.wl"} &),
		PacletInstall = Function[file, installed = FileExistsQ[First[file]]; installedPaclet]
	},
		result = WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet[
			WolframInstitute`Recursor`PackageScope`$libraryRegistry["MathlibLink"]];
		{result, downloadURL, installed, ! FileExistsQ[temporary]}
	]],
	{installedPaclet, "https://github.com/WolframInstitute/MathlibLink/releases/download/v0.1.0/WolframInstitute__MathlibLink-0.1.0.paclet", True, True},
	TestID -> "mathlib-release-fallback-uses-verified-download-and-cleans-temporary-archive"
]

VerificationTest[
	Module[{result, temporary}, Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`mathlibLinkArchive = (Missing["NotFound"] &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownload = Function[{url, file},
			temporary = file;
			WolframInstitute`Recursor`Libraries`Installation`Private`libraryDownloadResult[url, file, <|"StatusCode" -> 404|>]],
		PacletInstall = (Throw["Unexpected installation"] &)
	}, Catch[
		result = WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet[
			WolframInstitute`Recursor`PackageScope`$libraryRegistry["MathlibLink"]];
		{result["Tag"], result["Result"]["Result"]["StatusCode"],
			StringContainsQ[result["MessageTemplate"], "MATHLIBLINK_PACLET"], ! FileExistsQ[temporary]}
	]]],
	{"MathlibLinkReleaseUnavailable", 404, True, True},
	TestID -> "unpublished-mathlib-release-reports-local-archive-remedy"
]

VerificationTest[
	Block[{
		PacletFind = ({} &),
		URLDownloadSubmit = (Throw["Unexpected download"] &),
		ResourceObject = (Throw["Unexpected repository lookup"] &),
		PacletInstall = (Throw["Unexpected installation"] &),
		WolframInstitute`Recursor`Libraries`Installation`Private`mathlibLinkArchive = (Throw["Unexpected archive lookup"] &)
	}, Catch[Values[RecursorLibraries[]][[All, "Status"]]]],
	ConstantArray["Not installed", 3], TestID -> "library-status-does-not-resolve-or-download-release-archives"
]
