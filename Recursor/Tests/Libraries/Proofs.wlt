PacletDirectoryLoad[DirectoryName[$TestFileName, 3]]
Needs["WolframInstitute`Recursor`"]

VerificationTest[
	WolframInstitute`Recursor`PackageScope`proofAxiomsQ /@ {
		{}, {"propext", "Classical.choice", "Quot.sound"}, {"sorryAx"}, {"Custom.axiom"}, $Failed
	}, {True, True, False, False, False}, TestID -> "proof-audit-rejects-admissions-and-extra-axioms"
]

VerificationTest[
	CheckRecursorProofs["Recursor"]["Tag"],
	"InvalidArguments",
	{CheckRecursorProofs::args},
	TestID -> "CheckRecursorProofs-invalid-arguments-give-Failure"
]

(* a failed lake update gives its Failure: lake build and the audit do not run *)
VerificationTest[
	Module[{directory = CreateDirectory[], commands = {}, result},
		WithCleanup[
			Block[{
				WolframInstitute`Recursor`PackageScope`mathlibInformation = Function[Null, <|
					"Status" -> "Ready", "Toolchain" -> "leanprover/lean4:v4.35.0",
					"Revision" -> "56a005855ea17e0b0958f73ec801ae140b0a1679", "MathlibDirectory" -> "/tmp/mathlib path"
				|>],
				WolframInstitute`Recursor`PackageScope`proofDirectory = (directory &),
				WolframInstitute`Recursor`PackageScope`lakeExecutable = ("lake" &),
				RunProcess = Function[Null,
					commands = Append[commands, Last[First[{##}]]];
					<|"ExitCode" -> 1, "StandardOutput" -> "", "StandardError" -> "update failed"|>]
			},
				result = CheckRecursorProofs[]
			];
			{result["Tag"], commands, StringContainsQ[Import[FileNameJoin[{directory, "verification.log"}], "Text"], "update failed"]},
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], {"ProofBuildFailed", {"update"}, True}, TestID -> "proof-build-failure-is-returned-before-the-audit"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`mathlibInformation = (<|"Status" -> "Not installed"|> &)},
		CheckRecursorProofs[]["Tag"]
	], "MathlibSetupRequired", TestID -> "proof-check-does-not-install-missing-mathlib"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`mathlibInformation = (<|"Status" -> "Ready", "Toolchain" -> "wrong", "Revision" -> "wrong"|> &)},
		CheckRecursorProofs[]["Tag"]
	], "MathlibVersionMismatch", TestID -> "proof-check-rejects-unpinned-runtime"
]

VerificationTest[
	Module[{directory = CreateDirectory[], configuration},
		WithCleanup[
			Block[{WolframInstitute`Recursor`PackageScope`proofDirectory = (directory &)},
				WolframInstitute`Recursor`PackageScope`proofWorkspace["/tmp/mathlib path"];
				configuration = Import[FileNameJoin[{directory, "lakefile.toml"}], "Text"];
				{StringContainsQ[configuration, "path = \"/tmp/mathlib path\""], StringContainsQ[configuration, "git ="], FileExistsQ[FileNameJoin[{directory, "Recursor.lean"}]]}
			],
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], {True, False, True}, TestID -> "proof-workspace-shares-local-mathlib"
]

VerificationTest[
	Module[{before = GetEnvironment[], environment, extended, executables, separator, path},
		executables = <|"Lake" -> FileNameJoin[{$TemporaryDirectory, "lean", "bin", "lake"}],
			"Git" -> FileNameJoin[{$TemporaryDirectory, "git", "bin", "git"}]|>;
		separator = If[$OperatingSystem === "Windows", ";", ":"];
		path = FileNameJoin[{$TemporaryDirectory, "managed-libraries"}];
		environment = WolframInstitute`Recursor`PackageScope`proofProcessEnvironment[executables];
		extended = WolframInstitute`Recursor`PackageScope`proofProcessEnvironment[executables, {path}];
		{Take[StringSplit[environment["PATH"], separator], 2] === (DirectoryName /@ Values[executables]),
			First[StringSplit[extended["PATH"], separator]] === path,
			environment["MATHLIB_NO_CACHE_ON_UPDATE"], GetEnvironment[] === before}
	], {True, True, "1", True}, TestID -> "proof-build-uses-managed-tools-without-changing-environment"
]

VerificationTest[
	Module[{directory = CreateDirectory[], proxy, native},
		WithCleanup[
			native = FileNameJoin[{directory, "lake" <> If[$OperatingSystem === "Windows", ".exe", ""]}];
			proxy = FileNameJoin[{directory, "elan", "bin", FileNameTake[native]}];
			CreateFile[native];
			Block[{Environment = Function[name, Switch[name, "PATH", directory,
				"ELAN_HOME", FileNameJoin[{directory, "elan"}], _, $Failed
			]]},
				{MissingQ[WolframInstitute`Recursor`PackageScope`lakeExecutable[]],
					CreateDirectory[DirectoryName[proxy], CreateIntermediateDirectories -> True];
					CreateFile[proxy];
					WolframInstitute`Recursor`PackageScope`lakeExecutable[] === proxy}
			],
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], {True, True}, TestID -> "proof-build-fallback-selects-elan-proxy-instead-of-native-lake"
]
