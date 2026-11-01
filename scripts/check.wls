Begin["PacletDevelopment`"]

repository = DirectoryName[DirectoryName[$InputFileName]];
name = FileNameTake[repository];
paclet = FileNameJoin[{repository, name}];
context = "WolframInstitute`" <> name <> "`";
SetDirectory[repository];
PacletDirectoryLoad[paclet];
loaded = Check[Needs[context]; True, False];
If[! loaded || ! MemberQ[$Packages, context], Print["The paclet did not load cleanly."]; Exit[1]];
If[MemberQ[Rest[$ScriptCommandLine], "proofs"],
	result = Symbol[context <> "PackageScope`checkRecursorProofs"][];
	If[! AssociationQ[result], Print[InputForm[result]]; Exit[1]];
	Print[Length[result["Theorems"]], " theorems checked; ", Length[result["KernelChecks"]], " modules replayed by Lean."];
	Print["Proof project: ", result["Directory"]];
	Exit[0]
];
files = Join[FileNames["*.wl", FileNameJoin[{paclet, "Kernel"}], Infinity], FileNames["*.wlt", FileNameJoin[{paclet, "Tests"}], Infinity]];
syntax = AllTrue[files, Function[file, Check[ReadList[file, Hold[Expression]]; True, Print["Syntax: ", file]; False]]];
symbols = Select[
	If[StringContainsQ[#, "`"], #, context <> #] & /@ Names[context <> "*"],
	StringCount[#, "`"] === StringCount[context, "`"] &
];
documented = AllTrue[symbols, Function[symbol,
	With[{short = Last[StringSplit[symbol, "`"]]},
		If[FileExistsQ[FileNameJoin[{repository, "docs", "en", "ReferencePages", "Symbols", short <> ".md"}]], True,
			Print["Missing reference page: ", short]; False
		]
	]
]];
usage = AllTrue[symbols, Function[symbol, StringQ[ToExpression[symbol <> "::usage"]]]];
collisionFree = AllTrue[symbols, Function[symbol, ! NameQ["System`" <> Last[StringSplit[symbol, "`"]]]]];
metadata = PacletObject[File[paclet]];
metadataValid = metadata["Name"] === "WolframInstitute/" <> name && StringQ[metadata["Version"]];
Print[Length[files], " source/test files; ", Length[symbols], " documented exports."];
Exit[If[symbols =!= {} && syntax && documented && usage && collisionFree && metadataValid, 0, 1]];
