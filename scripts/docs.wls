Begin["PacletDevelopment`"]

script = ExpandFileName[$InputFileName];
repository = DirectoryName[DirectoryName[script]];
name = FileNameTake[repository];
paclet = FileNameJoin[{repository, name}];
mode = If[Length[$ScriptCommandLine] > 1, $ScriptCommandLine[[2]], "build"];
If[! MemberQ[{"build", "check", "publish", "page", "hero"}, mode], Print["Use build, check, publish or hero."]; Exit[1]];
source = FileNameJoin[{repository, "docs", "en"}];
definition = FileNameJoin[{paclet, "ResourceDefinition.md"}];
documentationFiles = Sort[FileNames["*.md", source, Infinity]];
PacletDirectoryLoad[paclet];
Needs["WolframInstitute`Recursor`"];
hero = FileNameJoin[{repository, "docs", "Hero.png"}];
(* docs/Hero.wl draws the resource page image; the number names one of its designs *)
If[mode === "hero",
	If[Length[$ScriptCommandLine] =!= 3 || ! StringMatchQ[Last[$ScriptCommandLine], DigitCharacter], Print["Give the number of a design."]; Exit[1]];
	Get[FileNameJoin[{repository, "docs", "Hero.wl"}]];
	RecursorHero`drawHero[ToExpression[Last[$ScriptCommandLine]], hero];
	Exit[0]
];
If[PacletFind["WolframInstitute/PacletPage"] === {}, Print["Install WolframInstitute/PacletPage before building documentation."]; Exit[1]];
Needs["WolframInstitute`PacletPage`"];
If[! MemberQ[$Packages, "WolframInstitute`PacletPage`"], Exit[1]];
Print["PacletPage ", PacletObject["WolframInstitute/PacletPage"]["Version"]];
documentationTools = Environment["RECURSOR_DOC_TOOLS"];
documentationOptions = {};
documentationDependencies = {"Wolfram/Lambda", "Wolfram/LeanLink", "WolframInstitute/MathlibLink"};
If[StringQ[documentationTools] && documentationTools =!= "",
	converter = FileNameJoin[{documentationTools, "MarkdownToNotebook", "MarkdownToNotebook.wl"}];
	If[! FileExistsQ[converter], Print["The pinned MarkdownToNotebook source is missing."]; Exit[1]];
	documentationOptions = {"Converter" -> converter};
	AppendTo[documentationDependencies, "Wolfram/Parser"]
];

If[MemberQ[{"build", "check"}, mode],
	libraries = RecursorLibraries[];
	If[! AllTrue[Values[libraries], #["Status"] === "Ready" &],
		Print["Run InstallRecursorLibraries[{\"LeanLink\", \"MathlibLink\", \"Lambda\"}] before building documentation."];
		Print[InputForm[libraries]]; Exit[1]
	]
];

(* As in PARILink and Ruliology, only PacletPage's fresh kernel scripts use
   the entitlement-aware launcher. Other processes and local licenses are unchanged. *)
kernelScriptQ[kernel_String] := MemberQ[{"WolframKernel", "WolframKernel.exe"}, Last[StringSplit[kernel, {"/", "\\"}]]];
SetAttributes[withEntitledKernels, HoldFirst];
withEntitledKernels[body_] := Internal`InheritedBlock[{RunProcess, StartProcess},
	Unprotect[RunProcess, StartProcess];
	DownValues[RunProcess] = Prepend[DownValues[RunProcess],
		HoldPattern[RunProcess[{kernel_String, "-noprompt", "-script", file_String}, arguments___] /; kernelScriptQ[kernel]] :>
			RunProcess[{"wolframscript", "-file", file}, arguments,
				ProcessEnvironment -> Append[Association[GetEnvironment[]], "WOLFRAMSCRIPT_KERNELPATH" -> kernel]]];
	DownValues[StartProcess] = Prepend[DownValues[StartProcess],
		HoldPattern[StartProcess[{kernel_String, "-noprompt", "-script", file_String}, options___] /; kernelScriptQ[kernel]] :>
			StartProcess[{"wolframscript", "-file", file}, options,
				ProcessEnvironment -> Append[Association[GetEnvironment[]], "WOLFRAMSCRIPT_KERNELPATH" -> kernel]]];
	Protect[RunProcess, StartProcess];
	body
];
pageCall[function_String, arguments___] := If[
	StringQ[Environment["WOLFRAMSCRIPT_ENTITLEMENTID"]] && Environment["WOLFRAMSCRIPT_ENTITLEMENTID"] =!= "",
	withEntitledKernels[Symbol["WolframInstitute`PacletPage`" <> function][arguments]],
	Symbol["WolframInstitute`PacletPage`" <> function][arguments]
];

(* The resource page shows the definition's Basic Description beside docs/Hero.png, as in
   BioDataLink. The stock page keeps only the prose, so publication renders the section itself:
   paragraphs, level-3 headings and lists of "Label: detail" rows, all plain text. *)
If[! FileExistsQ[hero], Print["The resource page image docs/Hero.png is missing; run make hero."]; Exit[1]];
heroOptions = {"HeroImage" -> hero};
heroReadQ[result_] := TrueQ[Lookup[result["Resource"], "HeroImage", False]];
descriptionCSS = "
.recursor-description { color: #243038; line-height: 1.55; }
.recursor-description .recursor-description-intro { margin: .75em 0 1.5em; line-height: 1.6; }
.recursor-description .recursor-description-heading { margin: 1.7em 0 .65em; color: #65737b; font-size: .78em;
  font-weight: 600; letter-spacing: .08em; line-height: 1.4; text-transform: uppercase; }
.recursor-description dl { margin: 0 0 1.5em; }
.recursor-description .recursor-description-row { padding: .55em 0; border-bottom: 1px solid #dfe6ea; }
.recursor-description dt, .recursor-description dd { display: inline; margin: 0; font-size: 1em; font-weight: 400; }
.recursor-description dd { margin-left: .4em; color: #65737b; }
";
descriptionBlocks[file_String] := Module[{lines = StringSplit[Import[file, "Text"], "\n"], start, blocks = {}, prose = {}, rows = {}, close},
	start = FirstPosition[lines, "## Basic Description", None, {1}];
	If[start === None, Print["The resource definition needs a Basic Description."]; Exit[1]];
	close[] := (
		If[prose =!= {}, AppendTo[blocks, {"Prose", StringRiffle[prose, " "]}]];
		If[rows =!= {}, AppendTo[blocks, {"List", rows}]];
		prose = rows = {}
	);
	Do[
		Which[
			StringStartsQ[line, "### "], close[]; AppendTo[blocks, {"Heading", StringTrim[StringDrop[line, 4]]}],
			StringStartsQ[line, "- "], If[prose =!= {}, close[]]; AppendTo[rows, StringTrim[StringDrop[line, 2]]],
			StringTrim[line] === "", close[],
			rows =!= {}, rows[[-1]] = rows[[-1]] <> " " <> StringTrim[line],
			True, AppendTo[prose, StringTrim[line]]
		],
		{line, TakeWhile[Drop[lines, First[start]], ! StringStartsQ[#, "## "] &]}
	];
	close[];
	If[! MemberQ[blocks, {"Prose", _}], Print["The Basic Description needs an opening paragraph."]; Exit[1]];
	blocks
];
descriptionRow[row_String] := With[{parts = StringTrim /@ StringSplit[row, ": ", 2]},
	If[Length[parts] =!= 2 || MemberQ[parts, ""], Print["Write each Basic Description row as Label: detail."]; Exit[1]];
	XMLElement["div", {"class" -> "recursor-description-row"}, {XMLElement["dt", {}, {First[parts]}], XMLElement["dd", {}, {Last[parts]}]}]
];
descriptionHTML[file_String] := ExportString[
	XMLElement["div", {"class" -> "recursor-description"}, Prepend[
		Replace[descriptionBlocks[file], {
			{"Prose", text_} :> XMLElement["p", {"class" -> "recursor-description-intro"}, {text}],
			{"Heading", text_} :> XMLElement["h3", {"class" -> "recursor-description-heading"}, {text}],
			{"List", rows_} :> XMLElement["dl", {}, descriptionRow /@ rows]
		}, {1}],
		XMLElement["style", {}, {descriptionCSS}]
	]],
	"XML", "Annotations" -> {}, "AttributeQuoting" -> "\"", "ElementFormatting" -> None
];
(* The publisher asks this function for the description of the page it deploys. Without it the
   page keeps the prose alone. *)
descriptionRendererQ[] := (
	Needs["PacletResource`"];
	Needs["ResourceSystemClient`"];
	ResourceSystemClient`Private`loadDeployResourceShingle[];
	DownValues[PacletResource`Private`moreDescriptionHTML] =!= {}
);
SetAttributes[withDescription, HoldRest];
withDescription[html_String, body_] := If[! descriptionRendererQ[],
	Print["Warning: this Wolfram version has no description renderer; the page keeps the prose alone."]; body,
	Internal`InheritedBlock[{PacletResource`Private`moreDescriptionHTML},
		PrependTo[DownValues[PacletResource`Private`moreDescriptionHTML],
			HoldPattern[PacletResource`Private`moreDescriptionHTML[
				_?(AssociationQ[#] && Lookup[#, "PacletName", Lookup[#, "Name", None]] === "WolframInstitute/" <> name &), _]] :> html];
		body
	]
];
description = descriptionHTML[definition];
If[! StringQ[description], Print["The Basic Description did not render."]; Exit[1]];

(* Imported Lean regions live until kernel exit. Isolate the proof-import
   tutorial; PacletPage evaluates the remaining pages together and resets each
   page's definitions. A fresh licensed process per page exhausts hosted slots. *)
buildPage[file_String] := Module[{worker, directories, program, result},
	directories = DeleteDuplicates[Flatten[(#["Location"] & /@ PacletFind[#] &) /@ documentationDependencies]];
	worker = CreateTemporary[];
	program = "Scan[PacletDirectoryLoad, " <> ToString[directories, InputForm, CharacterEncoding -> "PrintableASCII"] <> "];\n" <>
		"Block[{$ScriptCommandLine = " <> ToString[{script, "page", file}, InputForm, CharacterEncoding -> "PrintableASCII"] <>
		"}, Get[" <> ToString[script, InputForm, CharacterEncoding -> "PrintableASCII"] <> "]];\nExit[1];\n";
	Print["Evaluating ", FileNameTake[file]];
	result = WithCleanup[
		If[Export[worker, program, "Text", CharacterEncoding -> "UTF-8"] === $Failed, $Failed,
			RunProcess[{"wolframscript", "-file", worker}]],
		If[FileExistsQ[worker], DeleteFile[worker]]
	];
	If[! AssociationQ[result], Print["The page worker did not return a result."]; Exit[1]];
	If[result["StandardOutput"] =!= "", Print[result["StandardOutput"]]];
	If[result["StandardError"] =!= "", Print[result["StandardError"]]];
	If[result["ExitCode"] =!= 0, Print["Page evaluation failed: ", file]; Exit[1]]
];

If[mode =!= "publish",
	If[mode === "page",
		If[Length[$ScriptCommandLine] =!= 3 || ! MemberQ[Append[documentationFiles, definition], Last[$ScriptCommandLine]],
			Print["The page must be a documentation source in this checkout."]; Exit[1]
		];
		page = Last[$ScriptCommandLine],
		Scan[buildPage, Select[documentationFiles, FileNameTake[#] === "FormalVerification.md" &]]
	];
	build = pageCall["BuildPacletDocumentation", paclet,
		"Source" -> source,
		"Files" -> If[mode === "page", {If[page === definition, First[documentationFiles], page]}, All],
		"Definition" -> If[mode === "page" && page =!= definition, None, definition],
		"Parallel" -> False, "Prune" -> (mode =!= "page"), "Dependencies" -> documentationDependencies,
		Sequence @@ documentationOptions
	];
	If[! AssociationQ[build] || Lookup[build, "Failed", {"Build"}] =!= {} || Lookup[build, "Unevaluated", <||>] =!= <||>,
		Print[InputForm[build]]; Exit[1]
	];
	If[mode =!= "page" && Lookup[build, "Flagged", <||>] =!= <||>,
		Print["Resolve the flagged documentation before building an archive."]; Print[InputForm[build["Flagged"]]]; Exit[1]
	];
	Print[Length[build["Notebooks"]], " documentation notebooks built."];
	If[mode === "page", Exit[0]]
];
If[mode =!= "build",
	distribution = FileNameJoin[{repository, "dist"}];
	If[! DirectoryQ[distribution], CreateDirectory[distribution]];
	If[mode === "publish",
		expected = FileNameJoin[{distribution, "WolframInstitute__Recursor-" <> PacletObject[File[paclet]]["Version"] <> ".paclet"}];
		If[! FileExistsQ[expected], Print["Restore the verified archive to dist, or run make check-publish first."]; Exit[1]];
		expectedHash = FileHash[expected, "SHA256"];
		resourceOptions = Join[{"Build" -> False, "Parallel" -> False}, heroOptions];
		prepared = Block[{$CloudConnected = False}, pageCall["PublishPacletPage", paclet, name, "Build" -> False, "DryRun" -> True, "ResourceOptions" -> resourceOptions]];
		If[! AssociationQ[prepared] || ! AssociationQ[prepared["Resource"]] ||
			! StringQ[prepared["Resource"]["Archive"]] || ! FileExistsQ[prepared["Resource"]["Archive"]] ||
			FileHash[prepared["Resource"]["Archive"], "SHA256"] =!= expectedHash,
			Print["The restored PacletPage build does not match the verified archive."]; Exit[1]
		];
		If[! heroReadQ[prepared], Print["The resource page image docs/Hero.png is unreadable."]; Exit[1]];
		result = withDescription[description, pageCall["PublishPacletPage", paclet, name, "Build" -> False, "ResourceOptions" -> resourceOptions]],
		(* the check asks the publisher for the description through the replacement a publication uses *)
		If[descriptionRendererQ[] &&
			withDescription[description, PacletResource`Private`moreDescriptionHTML[<|"PacletName" -> "WolframInstitute/" <> name|>, {}]] =!= description,
			Print["The publisher would not show the Basic Description."]; Exit[1]
		];
		If[! DirectoryQ[FileNameJoin[{repository, "build"}]], CreateDirectory[FileNameJoin[{repository, "build"}]]];
		Export[FileNameJoin[{repository, "build", "resource-description.html"}], description, "Text"];
		result = pageCall["PublishPacletPage", paclet, name, "Build" -> False, "DryRun" -> True, "ResourceOptions" -> heroOptions]
	];
	If[! AssociationQ[result], Print[InputForm[result]]; Exit[1]];
	archive = Lookup[result["Resource"], "Archive", None];
	If[! StringQ[archive] || ! FileExistsQ[archive], Print["No archive was built."]; Exit[1]];
	If[mode === "publish" && (FileHash[archive, "SHA256"] =!= expectedHash ||
		! TrueQ[Lookup[result["Resource"], "Deployed", False]] || ! TrueQ[Lookup[result["Check"], "OK", False]]),
		Print[InputForm[result]]; Exit[1]
	];
	If[! heroReadQ[result], Print["The resource page image docs/Hero.png is unreadable."]; Exit[1]];
	(* A page without the rows still has the prose, so this does not stop a finished publication. *)
	If[mode === "publish",
		With[{page = Quiet[URLRead[StringTrim[Lookup[result["Resource"], "Resource", ""], "/"] <> "/", TimeConstraint -> 60]]},
			If[! MatchQ[page, _HTTPResponse] || page["StatusCode"] =!= 200 || ! StringContainsQ[page["Body"], "recursor-description-row"],
				Print["Warning: the published resource page does not show the formatted description yet."]
			]
		]
	];
	output = FileNameJoin[{distribution, FileNameTake[archive]}];
	CopyFile[archive, output, OverwriteTarget -> True];
	Print["Archive: ", output]
];

End[];
