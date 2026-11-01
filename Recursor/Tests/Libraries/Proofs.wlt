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
	Module[{before = GetEnvironment[], environment, executables, separator},
		executables = <|"Lake" -> FileNameJoin[{$TemporaryDirectory, "lean", "bin", "lake"}],
			"Git" -> FileNameJoin[{$TemporaryDirectory, "git", "bin", "git"}]|>;
		separator = If[$OperatingSystem === "Windows", ";", ":"];
		environment = WolframInstitute`Recursor`Libraries`Proofs`Private`proofProcessEnvironment[executables];
		{Take[StringSplit[environment["PATH"], separator], 2] === (DirectoryName /@ Values[executables]),
			environment["MATHLIB_NO_CACHE_ON_UPDATE"], GetEnvironment[] === before}
	], {True, "1", True}, TestID -> "proof-build-uses-managed-tools-without-changing-environment"
]
