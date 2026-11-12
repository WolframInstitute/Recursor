(* Build and audit of the Lean proofs packaged with the paclet. *)

PackageExported[{CheckRecursorProofs}]
PackageScoped[{proofAxiomsQ, proofWorkspace, proofProcessEnvironment, lakeExecutable}]

CheckRecursorProofs::usage = "CheckRecursorProofs[] builds the packaged Lean proofs, checks their axiom dependencies and replays their modules in \
Lean's kernel."
$leanToolchain::usage = "$leanToolchain is the Lean toolchain that the proof project pins."
$mathlibRevision::usage = "$mathlibRevision is the mathlib commit that the proof project pins."
$proofModules::usage = "$proofModules is the association from each Lean proof module to the names of its required theorems."
$proofTheorems::usage = "$proofTheorems is the list of the full names of the required theorems."
proofFailure::usage = "proofFailure[tag, message] gives a Failure with that tag and message.\n\
proofFailure[tag, message, data] adds the association data to the Failure."
lakeExecutable::usage = "lakeExecutable[] gives the path of elan's lake proxy, or Missing[\"NotFound\", \"lake\"]."
tomlString::usage = "tomlString[value] gives the string value as a quoted TOML string."
proofProcessEnvironment::usage = "proofProcessEnvironment[executables] gives the process environment for a proof command, with the directories of \
the managed executables first on PATH.\n\
proofProcessEnvironment[executables, paths] puts the directories paths before them."
proofCommand::usage = "proofCommand[arguments, directory, executables, paths] runs a command in the directory and gives the association of its \
exit code and output, or a Failure when it could not be run."
proofWorkspace::usage = "proofWorkspace[mathlib] copies the packaged Lean sources to the proof directory, points the Lake project at the mathlib \
directory and gives the proof directory."
proofAxiomsQ::usage = "proofAxiomsQ[axioms] gives True when axioms is a list of names among propext, Classical.choice and Quot.sound."
proofAudit::usage = "proofAudit[directory, mathlib] checks the theorems, axioms and kernel replay of every proof module and gives the report, an \
association, or a Failure."
proofAuditStep::usage = "proofAuditStep[report, module, directory, mathlib] audits one module and gives the report with its axioms and kernel \
check added, or a Failure."
proofAuditModule::usage = "proofAuditModule[directory, mathlib, module] imports one compiled module and gives the association of its axioms and \
kernel check, or a Failure."
proofAuditEnvironment::usage = "proofAuditEnvironment[environment, module] checks that a Lean environment declares the required theorems of the \
module, then audits them."
proofAuditTheorems::usage = "proofAuditTheorems[environment, module, names] checks the axioms of the named theorems and the kernel replay of the \
module."
proofCheck::usage = "proofCheck[information] builds and audits the proofs with the MathlibLink installation that information describes."
proofBuild::usage = "proofBuild[lake, information, executables, paths] prepares the proof workspace, runs lake update and lake build with a log, \
and audits the result."
proofBuildStep::usage = "proofBuildStep[command, directory, logStream, executables, paths] runs one build command, writes its output to the log and \
gives Null or a Failure."

$leanToolchain = "leanprover/lean4:v4.35.0"
$mathlibRevision = "56a005855ea17e0b0958f73ec801ae140b0a1679"
$proofModules = <|
	"Recursor" -> {"run_sound", "reaches_complete", "computes_iff_observed", "run_stable", "computes_deterministic", "countdown_correct", "pack_address", "pack_payload"},
	"Universality" -> {"compile_correct", "translate_correct", "translate_scoped", "universal"}
|>
$proofTheorems = "RecursorProofs." <> # & /@ Flatten[Values[$proofModules]]

proofFailure[tag_String, message_String, data_Association] := Failure[tag, Join[<|"MessageTemplate" -> message|>, data]]
proofFailure[tag_String, message_String] := proofFailure[tag, message, <||>]

(* The +toolchain argument belongs to elan's proxy, not a native Lake binary. *)
lakeExecutable[] := Module[{elanDirectory, path},
	elanDirectory = Replace[Environment["ELAN_HOME"], Except[_String] -> FileNameJoin[{$HomeDirectory, ".elan"}]];
	path = FileNameJoin[{elanDirectory, "bin", "lake" <> If[$OperatingSystem === "Windows", ".exe", ""]}];
	If[FileExistsQ[path], path, Missing["NotFound", "lake"]]
]

tomlString[value_String] := "\"" <> StringReplace[value, {"\\" -> "\\\\", "\"" -> "\\\"", "\n" -> "\\n", "\r" -> "\\r", "\t" -> "\\t"}] <> "\""

proofProcessEnvironment[executables_Association, paths_List] := Module[{environment, directories, separator},
	environment = Association[GetEnvironment[]];
	directories = DeleteDuplicates[Join[Cases[paths, _String], DirectoryName /@ Cases[Values[executables], _String]]];
	separator = If[$OperatingSystem === "Windows", ";", ":"];
	Join[environment, <|
		"PATH" -> StringRiffle[Join[directories, DeleteCases[{Lookup[environment, "PATH", ""]}, ""]], separator],
		"MATHLIB_NO_CACHE_ON_UPDATE" -> "1"
	|>]
]
proofProcessEnvironment[executables_Association] := proofProcessEnvironment[executables, {}]

(* An external process can issue any message, so the call is quieted in full. *)
proofCommand[arguments_List, directory_String, executables_Association, paths_List] := Quiet[
	Check[
		RunProcess[arguments, All, ProcessDirectory -> directory, ProcessEnvironment -> proofProcessEnvironment[executables, paths]],
		proofFailure["ProofProcessFailed", "The command could not be run.", <|"Command" -> arguments|>]
	],
	All
]

proofWorkspace[mathlib_String] := Module[{source = proofSourceDirectory[], directory = proofDirectory[], configuration},
	If[! DirectoryQ[directory], CreateDirectory[directory, CreateIntermediateDirectories -> True]];
	Scan[CopyFile[#, FileNameJoin[{directory, FileNameTake[#]}], OverwriteTarget -> True] &,
		FileNames[{"*.lean", "lean-toolchain"}, source]];
	configuration = StringReplace[Import[FileNameJoin[{source, "lakefile.toml"}], "Text"],
		RegularExpression["(?m)^git = [^\n]+\nrev = [^\n]+\n"] -> "path = " <> tomlString[mathlib] <> "\n"];
	Export[FileNameJoin[{directory, "lakefile.toml"}], configuration, "Text"];
	directory
]

proofAxiomsQ[axioms : {___String}] := Complement[axioms, {"propext", "Classical.choice", "Quot.sound"}] === {}
proofAxiomsQ[___] := False

(* The required theorems must be declared before their axioms are read. *)
(* The environment is a LeanEnvironment of LeanLink, whose head this file does not name. *)
proofAuditEnvironment[environment : _[_Association], module_String] := Module[{names},
	names = "RecursorProofs." <> # & /@ $proofModules[module];
	If[AllTrue[names, KeyExistsQ[environment, #] &],
		proofAuditTheorems[environment, module, names],
		proofFailure["ProofDeclarationMissing", "A required theorem is missing from the proof environment.", <|"Module" -> module|>]
	]
]

proofAuditTheorems[environment : _[_Association], module_String, names : {__String}] := Module[{dependencies, checked},
	dependencies = AssociationMap[environment[#]["Axioms"] &, names];
	If[AllTrue[Values[dependencies], proofAxiomsQ],
		checked = environment[First[names]]["KernelCheck"];
		If[MatchQ[checked, Success["KernelChecked", _Association]],
			<|"Axioms" -> dependencies, "KernelCheck" -> checked|>,
			proofFailure["ProofKernelRejected", "Lean's kernel did not accept a proof module.", <|"Module" -> module, "Result" -> checked|>]
		],
		proofFailure["UntrustedProofAxioms", "A theorem uses an admitted proof or an unapproved axiom.", <|"Axioms" -> dependencies|>]
	]
]

(* Standalone imports use mathlib's project search path; LeanLink's native
   loader does not discover Lake path dependencies in the client project. *)
proofAuditModule[directory_String, mathlib_String, module_String] := Module[{unloaded, environment},
	unloaded = proofFailure["ProofImportFailed", "A compiled proof environment could not be loaded.", <|"Module" -> module|>];
	environment = Quiet[
		Check[
			Symbol["Wolfram`LeanLink`LeanImport"][FileNameJoin[{directory, module <> ".lean"}], "ProjectDir" -> mathlib, "Filter" -> "RecursorProofs."],
			unloaded
		],
		All
	];
	If[MatchQ[environment, Symbol["Wolfram`LeanLink`LeanEnvironment"][_Association]],
		WithCleanup[
			proofAuditEnvironment[environment, module],
			Symbol["Wolfram`LeanLink`LeanFreeEnvironment"][Information[environment, "Handle"]]
		],
		unloaded
	]
]

proofAuditStep[report_Association, module_String, directory_String, mathlib_String] := Module[{audit},
	audit = proofAuditModule[directory, mathlib, module];
	If[FailureQ[audit],
		audit,
		Join[report, <|
			"Axioms" -> Join[report["Axioms"], audit["Axioms"]],
			"KernelChecks" -> Append[report["KernelChecks"], module -> audit["KernelCheck"]]
		|>]
	]
]

(* The first module that fails ends the audit: its Failure is the result. *)
proofAudit[directory_String, mathlib_String] :=
	If[TrueQ[Block[{$ContextPath = $ContextPath}, Quiet[Check[Needs["Wolfram`LeanLink`"] === Null, False], All]]],
		Fold[
			Function[{report, module}, If[FailureQ[report], report, proofAuditStep[report, module, directory, mathlib]]],
			<|"Directory" -> directory, "Theorems" -> $proofTheorems, "Axioms" -> <||>, "KernelChecks" -> <||>|>,
			Keys[$proofModules]
		],
		proofFailure["LeanLinkRequired", "Load a compatible LeanLink installation before checking proofs."]
	]

proofBuildStep[command : {__String}, directory_String, logStream_OutputStream, executables_Association, paths_List] := Module[{result},
	WriteString[logStream, StringRiffle[command, " "] <> "\n"];
	result = proofCommand[command, directory, executables, paths];
	If[AssociationQ[result], WriteString[logStream, result["StandardOutput"], result["StandardError"], "\n"]];
	If[AssociationQ[result] && result["ExitCode"] === 0,
		Null,
		proofFailure["ProofBuildFailed", "The Lean proof build failed. See verification.log in the proof directory.",
			<|"Directory" -> directory, "Command" -> command, "Process" -> result|>]
	]
]

(* The first command that fails ends the build: its Failure is the result, and nothing is audited. *)
proofBuild[lake_String, information_Association, executables_Association, paths_List] := Module[{directory, logStream, build},
	directory = proofWorkspace[information["MathlibDirectory"]];
	logStream = OpenWrite[FileNameJoin[{directory, "verification.log"}]];
	WithCleanup[
		build = Fold[
			Function[{previous, command}, If[FailureQ[previous], previous, proofBuildStep[command, directory, logStream, executables, paths]]],
			Null,
			{{lake, "+" <> $leanToolchain, "update"}, {lake, "+" <> $leanToolchain, "build"}}
		];
		If[FailureQ[build], build, proofAudit[directory, information["MathlibDirectory"]]],
		Close[logStream]
	]
]

proofCheck[information_Association] := Module[{executables, paths, managedLake, lake},
	executables = Lookup[information, "Executables", <||>];
	paths = Lookup[information, "PathDirectories", {}];
	managedLake = Lookup[executables, "Lake", None];
	lake = If[StringQ[managedLake] && FileExistsQ[managedLake], managedLake, lakeExecutable[]];
	If[StringQ[lake],
		proofBuild[lake, information, executables, paths],
		proofFailure["LakeNotFound", "Lake could not be found. Check the elan installation."]
	]
]

CheckRecursorProofs[] := Module[{information},
	information = mathlibInformation[];
	Which[
		! AssociationQ[information] || Lookup[information, "Status", None] =!= "Ready",
			proofFailure["MathlibSetupRequired", "Run InstallRecursorLibraries[{\"MathlibLink\"}] before checking the proofs."],
		Lookup[information, "Toolchain", None] =!= $leanToolchain || Lookup[information, "Revision", None] =!= $mathlibRevision,
			proofFailure["MathlibVersionMismatch", "The proof project requires the pinned Lean and mathlib versions.", <|"Installation" -> information|>],
		True, proofCheck[information]
	]
]
CheckRecursorProofs[___] := invalidArgumentsFailure[CheckRecursorProofs]
