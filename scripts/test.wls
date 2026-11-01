Begin["PacletDevelopment`"]

repository = DirectoryName[DirectoryName[$InputFileName]];
name = FileNameTake[repository];
SetDirectory[repository];
PacletDirectoryLoad[FileNameJoin[{repository, name}]];
If[! TrueQ[Check[Needs["WolframInstitute`" <> name <> "`"]; True, False]], Exit[1]];
files = If[Length[$ScriptCommandLine] > 1, Rest[$ScriptCommandLine], FileNames["*.wlt", FileNameJoin[{repository, name, "Tests"}], Infinity]];
reports = TestReport /@ files;
Scan[Function[report,
	Print[report["TestsSucceededCount"], " passed; ", report["TestsFailedCount"], " failed"];
	Scan[Function[result, If[result["Outcome"] =!= "Success", Print[result["TestID"], ": ", InputForm[result["ActualOutput"]]]]], Values[report["TestResults"]]]
], reports];
If[! DirectoryQ["build"], CreateDirectory["build"]];
Put[reports, "build/TestReports.wl"];
Exit[If[files =!= {} && AllTrue[reports, MatchQ[#, _TestReportObject] && #["TestsFailedCount"] === 0 &], 0, 1]];
