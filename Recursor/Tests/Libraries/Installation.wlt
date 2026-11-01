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
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryStatus = ("Needs setup" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Sow["download"]; $Failed &)
	},
		With[{result = Reap[InstallRecursorLibraries[{"LeanLink"}]]}, {result[[1, "LeanLink"]]["Tag"], Last[result]}]
	], {"LibrarySetupRequired", {}}, TestID -> "broken-installation-reports-setup-without-reinstall"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryStatus = ("Not installed" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = ($Failed &)
	}, InstallRecursorLibraries[{"Lambda"}]["Lambda"]["Tag"]],
	"LibraryInstallFailed", TestID -> "download-failure-is-structured"
]

VerificationTest[
	WolframInstitute`Recursor`Libraries`Installation`Private`versionAtLeastQ @@@ {{"1.2.5", "1.2.5"}, {"1.2.10", "1.2.5"}, {"1.2.4", "1.2.5"}, {"1.3", "1.2.5"}},
	{True, True, False, True}, TestID -> "library-versions-compare-numerically"
]

VerificationTest[
	Keys[WolframInstitute`Recursor`Libraries`Installation`Private`$libraryRegistry],
	{"Lambda", "LeanLink", "MathlibLink"}, TestID -> "only-selected-external-libraries"
]

VerificationTest[
	Block[{
		PacletFind = ({PacletObject[<|"Name" -> "Wolfram/Lambda", "Version" -> "1.2.5"|>]} &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryStatus = ("Ready" &),
		WolframInstitute`Recursor`Libraries`Installation`Private`installLibraryPaclet = (Sow["download"]; $Failed &)
	}, Last[Reap[InstallRecursorLibraries[{"Lambda"}]]]],
	{}, TestID -> "ready-library-is-not-reinstalled"
]
