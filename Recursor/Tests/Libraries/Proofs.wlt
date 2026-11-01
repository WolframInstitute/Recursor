Needs["WolframInstitute`Recursor`"]

VerificationTest[
	WolframInstitute`Recursor`Libraries`Proofs`Private`proofAxiomsQ /@ {
		{}, {"propext", "Classical.choice", "Quot.sound"}, {"sorryAx"}, {"Custom.axiom"}, $Failed
	}, {True, True, False, False, False}, TestID -> "proof-audit-rejects-admissions-and-extra-axioms"
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
				WolframInstitute`Recursor`Libraries`Proofs`Private`proofWorkspace["/tmp/mathlib path"];
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
		environment = WolframInstitute`Recursor`Libraries`Proofs`Private`proofProcessEnvironment[executables];
		extended = WolframInstitute`Recursor`Libraries`Proofs`Private`proofProcessEnvironment[executables, {path}];
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
				"ELAN_HOME", FileNameJoin[{directory, "elan"}], _, $Failed]]},
				{MissingQ[WolframInstitute`Recursor`Libraries`Proofs`Private`lakeExecutable[]],
					CreateDirectory[DirectoryName[proxy], CreateIntermediateDirectories -> True]; CreateFile[proxy];
					WolframInstitute`Recursor`Libraries`Proofs`Private`lakeExecutable[] === proxy}
			],
			DeleteDirectory[directory, DeleteContents -> True]
		]
	], {True, True}, TestID -> "proof-build-fallback-selects-elan-proxy-instead-of-native-lake"
]
