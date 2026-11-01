Needs["WolframInstitute`Recursor`"]

VerificationTest[
	WolframInstitute`Recursor`Libraries`Proofs`Private`proofAxiomsQ /@ {
		{}, {"propext", "Classical.choice", "Quot.sound"}, {"sorryAx"}, {"Custom.axiom"}, $Failed
	}, {True, True, False, False, False}, TestID -> "proof-audit-rejects-admissions-and-extra-axioms"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`mathlibInformation = (<|"Status" -> "Not installed"|> &)},
		WolframInstitute`Recursor`PackageScope`checkRecursorProofs[]["Tag"]
	], "MathlibSetupRequired", TestID -> "proof-check-does-not-install-missing-mathlib"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`mathlibInformation = (<|"Status" -> "Ready", "Toolchain" -> "wrong", "Revision" -> "wrong"|> &)},
		WolframInstitute`Recursor`PackageScope`checkRecursorProofs[]["Tag"]
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
