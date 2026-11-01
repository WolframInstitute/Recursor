PackageExported[{CheckRecursorProofs}]

CheckRecursorProofs::usage = "CheckRecursorProofs[] builds the packaged Lean proofs, checks their axiom dependencies and replays their modules in Lean's kernel."

$leanToolchain = "leanprover/lean4:v4.35.0"
$mathlibRevision = "56a005855ea17e0b0958f73ec801ae140b0a1679"
$proofModules = <|
	"Recursor" -> {"run_sound", "reaches_complete", "computes_iff_observed", "run_stable", "computes_deterministic", "countdown_correct", "pack_address", "pack_payload"},
	"Universality" -> {"compile_correct", "translate_correct", "translate_scoped", "universal"}
|>
$proofTheorems = "RecursorProofs." <> # & /@ Flatten[Values[$proofModules]]

proofFailure[tag_, message_, data_ : <||>] := Failure[tag, Join[<|"MessageTemplate" -> message|>, data]]

(* The +toolchain argument belongs to elan's proxy, not a native Lake binary. *)
lakeExecutable[] := With[{path = FileNameJoin[{
	Replace[Environment["ELAN_HOME"], Except[_String] -> FileNameJoin[{$HomeDirectory, ".elan"}]],
	"bin", "lake" <> If[$OperatingSystem === "Windows", ".exe", ""]
}]}, If[FileExistsQ[path], path, Missing["NotFound", "lake"]]]

tomlString[value_String] := "\"" <> StringReplace[value, {"\\" -> "\\\\", "\"" -> "\\\"", "\n" -> "\\n", "\r" -> "\\r", "\t" -> "\\t"}] <> "\""

proofProcessEnvironment[executables_Association, paths_List : {}] := With[{
	environment = Association[GetEnvironment[]],
	directories = DeleteDuplicates[Join[Cases[paths, _String], DirectoryName /@ Cases[Values[executables], _String]]],
	separator = If[$OperatingSystem === "Windows", ";", ":"]
}, Join[environment, <|
	"PATH" -> StringRiffle[Join[directories, DeleteCases[{Lookup[environment, "PATH", ""]}, ""]], separator],
	"MATHLIB_NO_CACHE_ON_UPDATE" -> "1"
|>]]

proofCommand[arguments_List, directory_String, executables_Association, paths_List] := Quiet[Check[
	RunProcess[arguments, All, ProcessDirectory -> directory,
		ProcessEnvironment -> proofProcessEnvironment[executables, paths]],
	$Failed
]]

proofWorkspace[mathlib_String] := Module[{source = proofSourceDirectory[], directory = proofDirectory[], configuration},
	If[! DirectoryQ[directory], CreateDirectory[directory, CreateIntermediateDirectories -> True]];
	Scan[CopyFile[#, FileNameJoin[{directory, FileNameTake[#]}], OverwriteTarget -> True] &,
		FileNames[{"*.lean", "lean-toolchain"}, source]];
	configuration = StringReplace[Import[FileNameJoin[{source, "lakefile.toml"}], "Text"],
		RegularExpression["(?m)^git = [^\n]+\nrev = [^\n]+\n"] -> "path = " <> tomlString[mathlib] <> "\n"];
	Export[FileNameJoin[{directory, "lakefile.toml"}], configuration, "Text"];
	directory
]

proofAxiomsQ[axioms_] := MatchQ[axioms, {___String}] && Complement[axioms, {"propext", "Classical.choice", "Quot.sound"}] === {}

(* Standalone imports use mathlib's project search path; LeanLink's native
   loader does not discover Lake path dependencies in the client project. *)
proofAudit[directory_String, mathlib_String] := Module[{environment, names, axioms = <||>, checks = <||>, dependencies, checked},
	If[! TrueQ[Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs["Wolfram`LeanLink`"] === Null, False]]]],
		Return[proofFailure["LeanLinkRequired", "Load a compatible LeanLink installation before checking proofs."]]
	];
	Do[
		environment = Quiet[Check[Symbol["Wolfram`LeanLink`LeanImport"][FileNameJoin[{directory, module <> ".lean"}], "ProjectDir" -> mathlib, "Filter" -> "RecursorProofs."], $Failed]];
		If[! MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
			Return[proofFailure["ProofImportFailed", "A compiled proof environment could not be loaded.", <|"Module" -> module|>]]
		];
		WithCleanup[
			names = "RecursorProofs." <> # & /@ $proofModules[module];
			If[! AllTrue[names, KeyExistsQ[environment, #] &], Return[proofFailure["ProofDeclarationMissing", "A required theorem is missing from the proof environment.", <|"Module" -> module|>]]];
			dependencies = AssociationMap[environment[#]["Axioms"] &, names];
			If[! AllTrue[Values[dependencies], proofAxiomsQ], Return[proofFailure["UntrustedProofAxioms", "A theorem uses an admitted proof or an unapproved axiom.", <|"Axioms" -> dependencies|>]]];
			checked = environment[First[names]]["KernelCheck"];
			If[! MatchQ[checked, Success["KernelChecked", _Association]], Return[proofFailure["ProofKernelRejected", "Lean's kernel did not accept a proof module.", <|"Module" -> module, "Result" -> checked|>]]];
			axioms = Join[axioms, dependencies];
			AssociateTo[checks, module -> checked],
			Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][Information[environment, "Handle"]]
		],
		{module, Keys[$proofModules]}
	];
	<|"Directory" -> directory, "Theorems" -> $proofTheorems, "Axioms" -> axioms, "KernelChecks" -> checks|>
]

CheckRecursorProofs[] := Module[{info = mathlibInformation[], executables, paths, lake, directory, log, result},
	If[! AssociationQ[info] || Lookup[info, "Status", None] =!= "Ready",
		Return[proofFailure["MathlibSetupRequired", "Run InstallRecursorLibraries[{\"MathlibLink\"}] before checking the proofs."]]
	];
	If[Lookup[info, "Toolchain", None] =!= $leanToolchain || Lookup[info, "Revision", None] =!= $mathlibRevision,
		Return[proofFailure["MathlibVersionMismatch", "The proof project requires the pinned Lean and mathlib versions.", <|"Installation" -> info|>]]
	];
	executables = Lookup[info, "Executables", <||>];
	paths = Lookup[info, "PathDirectories", {}];
	lake = Lookup[executables, "Lake", None];
	If[! StringQ[lake] || ! FileExistsQ[lake], lake = lakeExecutable[]];
	If[! StringQ[lake], Return[proofFailure["LakeNotFound", "Lake could not be found. Check the elan installation."]]];
	directory = proofWorkspace[info["MathlibDirectory"]];
	log = OpenWrite[FileNameJoin[{directory, "verification.log"}]];
	WithCleanup[
		Do[
			WriteString[log, StringRiffle[command, " "] <> "\n"];
			result = proofCommand[command, directory, executables, paths];
			If[AssociationQ[result], WriteString[log, result["StandardOutput"], result["StandardError"], "\n"]];
			If[! AssociationQ[result] || result["ExitCode"] =!= 0,
				Return[proofFailure["ProofBuildFailed", "The Lean proof build failed. See verification.log in the proof directory.", <|"Directory" -> directory, "Command" -> command, "Process" -> result|>]]
			],
			{command, {{lake, "+" <> $leanToolchain, "update"}, {lake, "+" <> $leanToolchain, "build"}}}
		];
		proofAudit[directory, info["MathlibDirectory"]],
		Close[log]
	]
]
