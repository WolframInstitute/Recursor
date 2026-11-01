Needs["WolframInstitute`Recursor`"]

(* Resolve the dynamic library rows without a front end. *)
setupResolveRows[boxes_] := boxes /. Cases[boxes,
	dynamic : HoldPattern[DynamicBox[ToBoxes[grid_Grid, StandardForm], ___]] :>
		With[{rendered = ToBoxes[grid]}, dynamic -> rendered], Infinity]

setupDialogBoxes[boxes_] := ReleaseHold @ First @ Cases[boxes,
	DynamicModuleBox[variables_, __] :> HoldComplete[Block[variables, setupResolveRows[boxes]]], {0, Infinity}]

VerificationTest[
	Block[{$Notebooks = False}, MatchQ[SetupRecursor[], Failure["NotebookRequired", _Association]]],
	True,
	TestID -> "Setup-needs-desktop-notebook"
]

VerificationTest[
	Block[{$Notebooks = False, PersistentSymbol = (Throw["Unexpected read"] &),
		Print = (Throw["Unexpected notice"] &), Message = (Throw["Unexpected message"] &),
		SetupRecursor = (Throw["Unexpected dialog"] &)},
		Catch[WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[]]
	],
	Null,
	TestID -> "Setup-headless-load-has-no-notice-panel-or-preference-access"
]

VerificationTest[
	Block[{$Notebooks = True, $CloudEvaluation = False, $BatchInput = False, $KernelID = 0, Environment = ("false" &)},
		{
			WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ[],
			Block[{$CloudEvaluation = True}, WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ[]],
			Block[{$BatchInput = True}, WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ[]],
			Block[{$KernelID = 1}, WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ[]],
			Block[{Environment = ("true" &)}, WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ[]]
		}
	],
	{True, False, False, False, False},
	TestID -> "Setup-only-on-interactive-desktop"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		PersistentSymbol = (Missing["NotFound"] &), PacletFind = ({} &),
		SetupRecursor = (Throw["Unexpected dialog"] &), PacletInstall = (Throw["Unexpected installation"] &),
		Print = (Throw["Unexpected print"] &)
	}, Catch[Check[WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[], "Setup message", General::recursorlib]]],
	"Setup message",
	{General::recursorlib},
	TestID -> "Setup-load-issues-standard-message-without-opening-or-installing"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`PackageScope`$libraryRegistry = AssociationMap[<|"Paclet" -> #|> &,
			{"First", "Installed", "Second"}],
		PersistentSymbol = (False &), PacletFind = (If[# === "Installed", {installedPaclet}, {}] &),
		SetupRecursor = (Throw["Unexpected dialog"] &), PacletInstall = (Throw["Unexpected installation"] &),
		Print = (Throw["Unexpected print"] &)
	},
		Catch[{
			Check[Quiet[WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[], General::recursorlib], "Unexpected message"],
			General::recursorlib
		}]
	],
	{Null, "Optional libraries are available. Run SetupRecursor[] to review and install."},
	TestID -> "Setup-message-is-generic-and-can-be-quieted"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		PersistentSymbol = (True &), PacletFind = (Throw["Unexpected scan"] &),
		Print = (Throw["Unexpected notice"] &), Message = (Throw["Unexpected message"] &), SetupRecursor = (Throw["Unexpected dialog"] &)
	}, Catch[WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[]]],
	Null,
	TestID -> "Setup-not-offered-after-dismissal"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		PersistentSymbol = (False &), PacletFind = ({installedPaclet} &),
		Print = (Throw["Unexpected notice"] &), Message = (Throw["Unexpected message"] &), CreateDialog = (Throw["Unexpected dialog"] &)
	}, Catch[WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[]]],
	Null,
	TestID -> "Setup-not-offered-when-installed"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`PackageScope`$libraryRegistry = <||>,
		PacletFind = ({installedPaclet} &), NotebookRead = (Throw["Unexpected dialog read"] &),
		CreateDialog = (Throw["Unexpected dialog"] &)
	}, Catch[SetupRecursor[]]],
	Null,
	TestID -> "Setup-stays-hidden-with-an-empty-registry"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog,
		WolframInstitute`Recursor`PackageScope`$libraryRegistry = AssociationMap[Function[name,
			Join[WolframInstitute`Recursor`PackageScope`$libraryRegistry["Lambda"], <|
				"Paclet" -> name, "Platforms" -> If[name === "UnsupportedLibrary", {}, {$SystemID}],
				"MinimumVersion" -> "1.2.5"
			|>]],
			{"MissingLibrary", "ReadyLibrary", "BrokenLibrary", "UnsupportedLibrary"}],
		WolframInstitute`Recursor`Libraries`Installation`Private`versionAtLeastQ = (True &),
		WolframInstitute`Recursor`Libraries`Installation`Private`libraryLoadQ = (True &),
		WolframInstitute`Recursor`PackageScope`libraryReadyQ = (# === "ReadyLibrary" &),
		PacletFind = Function[name, If[name === "MissingLibrary", {}, {installedPaclet}]],
		PacletInstall = (Throw["Unexpected installation"] &),
		CreateDialog = Function[{content, title, events}, setupDialogBoxes[ToBoxes[content]]]
	}, Catch[
		SetupRecursor[];
		With[{boxes = WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog},
			ReleaseHold @ First @ Cases[boxes, DynamicModuleBox[variables_, __] :> HoldComplete[Block[variables, {
				Count[boxes, _CheckboxBox, Infinity],
				Cases[boxes, DynamicBox[ToBoxes[value_, StandardForm], ___] /;
					! FreeQ[HoldComplete[value], _ProgressIndicator] :> value, Infinity],
				Cases[boxes, ButtonBox[DynamicBox[ToBoxes[label_, StandardForm], ___], ___, Enabled -> Dynamic[enabled_], ___] /;
					! FreeQ[HoldComplete[label], "Uninstall"] :> {label, enabled}, Infinity]
			}]], {0, Infinity}]
	]]],
	{0, {"Not installed", "Ready", "Needs setup", "Unsupported"},
		{{"Install", True}, {"Uninstall", True}, {"Uninstall", True}, {"Uninstall", True}}},
	TestID -> "Setup-offers-uninstall-for-ready-unusable-and-unsupported-installed-libraries"
]

VerificationTest[
	With[{key = "RecursorTest/" <> CreateUUID[]},
		WithCleanup[
			Block[{WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupPreference = key},
				WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupRemember[];
				PersistentSymbol[key, "Local"]
			],
			Remove[PersistentSymbol[key, "Local"]]
		]
	],
	True,
	TestID -> "Setup-remembers-dismissal"
]

VerificationTest[
	With[{key = "RecursorTest/" <> CreateUUID[]}, WithCleanup[
		Block[{
			WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupPreference = key,
			WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
			PacletFind = ({} &), Message = ("Offered" &)
		},
			WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupRemember[];
			{WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[],
				PersistentSymbol[key, "Local"] = False;
				WolframInstitute`Recursor`PackageScope`librarySetupOnLoad[]}
		],
		Remove[PersistentSymbol[key, "Local"]]
	]],
	{Null, "Offered"},
	TestID -> "Setup-dismissal-persists-until-preference-reset"
]

VerificationTest[
	Module[{selection}, Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog = setupCell,
		PacletFind = ({} &), Notebooks = ({setupCell} &),
		SetSelectedNotebook = Function[notebook, selection = notebook; Null],
		CreateDialog = (Throw["Unexpected dialog"] &)
	}, Catch[{SetupRecursor[], selection, WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog}]]],
	{Null, setupCell, setupCell},
	TestID -> "Setup-reuses-open-dialog"
]

VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog = oldCell,
		PacletFind = ({} &), PersistentSymbol = (Throw["Unexpected preference read"] &),
		Notebooks = ({} &),
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Not installed" &),
		CreateDialog = Function[{content, title, events}, title]
	}, {SetupRecursor[], WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog}],
	{Null, WindowTitle -> "Recursor: Optional libraries"},
	TestID -> "Setup-reopens-closed-dialog-without-preference-check"
]

VerificationTest[
	Block[{$ContextPath = {"System`"}},
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand["Lambda"]
	],
	"InstallRecursorLibraries[{\"Lambda\"}]",
	TestID -> "Setup-command-is-short-quoted-text"
]

VerificationTest[
	Block[{$ContextPath = {"System`"}}, {
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand["MathlibLink", "Install"],
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand["MathlibLink", "Uninstall"]
	}],
	{"InstallRecursorLibraries[{\"MathlibLink\"}]", "PacletUninstall[\"WolframInstitute/MathlibLink\"]"},
	TestID -> "Setup-MathlibLink-copy-commands-use-shared-installer-and-paclet-name"
]

VerificationTest[
	ToExpression[WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand["A\"B"], InputForm, HoldComplete],
	HoldComplete[InstallRecursorLibraries[{"A\"B"}]],
	TestID -> "Setup-command-escapes-library-name"
]

VerificationTest[
	Table[Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog,
		WolframInstitute`Recursor`PackageScope`$libraryRegistry = AssociationThread[
			"Library " <> ToString[#] & /@ Range[count],
			ConstantArray[WolframInstitute`Recursor`PackageScope`$libraryRegistry["Lambda"], count]],
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Not installed" &),
		PacletFind = ({} &), CreateDialog = Function[{content, title, events}, setupDialogBoxes[ToBoxes[content]]]
	},
		SetupRecursor[];
		With[{list = First @ Cases[WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog,
			pane_PaneBox /; MemberQ[List @@ pane, Scrollbars -> {False, Automatic}], Infinity]},
			{Count[list, HoldPattern[WolframInstitute`Recursor`PackageScope`libraryUninstall[_String]], Infinity],
				MemberQ[List @@ list, ImageSize -> {_, UpTo[_?NumberQ]}],
				MemberQ[List @@ list, AppearanceElements -> None],
				FreeQ[list, "Close" | "Cancel download"]}
		]
	], {count, {4, 10, 20}}],
	{{4, True, True, True}, {10, True, True, True}, {20, True, True, True}},
	TestID -> "Setup-many-libraries-scroll-with-fixed-buttons"
]

VerificationTest[
	WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand[#, "Uninstall"] & /@ {"Lambda", "LeanLink", "MathlibLink"},
	{"PacletUninstall[\"Wolfram/Lambda\"]", "PacletUninstall[\"Wolfram/LeanLink\"]", "PacletUninstall[\"WolframInstitute/MathlibLink\"]"},
	TestID -> "Setup-uninstall-commands-use-the-registered-paclet-names"
]

(* the registered libraries as the dialog lists them, MathlibLink with its download size and setup
   instructions; statuses are given, so nothing loads *)
VerificationTest[
	Block[{
		WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
		WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog,
		WolframInstitute`Recursor`PackageScope`libraryStatus = ("Not installed" &),
		PacletFind = ({} &),
		PacletInstall = (Throw["Unexpected installation"] &),
		CreateDialog = Function[{content, title, events}, setupDialogBoxes[ToBoxes[content]]]
	}, Catch[
		SetupRecursor[];
		With[{boxes = WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog},
			{
				Cases[boxes, HoldPattern[WolframInstitute`Recursor`PackageScope`libraryUninstall[name_String]] :> name, Infinity],
				! FreeQ[boxes, "\"varies; includes runtime\""],
				! FreeQ[boxes, "https://leanprover-community.github.io/install/project.html"]
			}
		]
	]],
	{{"Lambda", "LeanLink", "MathlibLink"}, True, True},
	TestID -> "Setup-lists-MathlibLink-with-its-download-size-and-instructions"
]

VerificationTest[
	Block[{WolframInstitute`Recursor`PackageScope`$libraryRegistry = <|"Test" -> <|"Paclet" -> "A\"B"|>|>},
		ToExpression[WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand["Test", "Uninstall"], InputForm, HoldComplete]
	],
	HoldComplete[PacletUninstall["A\"B"]],
	TestID -> "Setup-uninstall-command-escapes-paclet-name"
]

(* Exercise dialog actions without a front end or real downloads. *)
SetAttributes[withSetupDialog, HoldAll]
withSetupDialog[body_, installedNames_ : {}, libraryNames_ : {"First", "Second"}] := Block[{
	setupBoxes, setupRawBoxes, setupEvents, setupClosed = False, setupRemembered = False, setupOpened = 0,
	setupInstalled = installedNames,
	WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupDesktopQ = (True &),
	WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupRemember = Function[Null, setupRemembered = True],
	WolframInstitute`Recursor`Libraries`Setup`Private`$librarySetupDialog,
	WolframInstitute`Recursor`PackageScope`$libraryRegistry = AssociationMap[
		Append[WolframInstitute`Recursor`PackageScope`$libraryRegistry["Lambda"], "Paclet" -> #] &, libraryNames],
	WolframInstitute`Recursor`PackageScope`libraryStatus = (If[MemberQ[setupInstalled, #], "Ready", "Not installed"] &),
	PacletFind = (If[MemberQ[setupInstalled, #], {installedPaclet}, {}] &),
	PacletInstall = (Throw["Unexpected installation"] &), PacletUninstall = (Throw["Unexpected uninstall"] &), Notebooks = ({} &),
	CreateDialog = Function[{content, title, events},
		setupOpened++; setupRawBoxes = ToBoxes[content]; setupBoxes = setupDialogBoxes[setupRawBoxes]; setupEvents = events; setupNotebook],
	DialogReturn = Function[Null, setupClosed = True; Null], FinishDynamic = (Null &)
},
	SetupRecursor[];
	ReleaseHold @ First @ Cases[setupBoxes,
		DynamicModuleBox[variables_, __] :> HoldComplete[Block[variables, body]], {0, Infinity}]
]

setupAction[label_] := First @ Cases[setupBoxes,
	button_ButtonBox /; StringContainsQ[ToString[First[button], InputForm], label] :>
		First @ Cases[button, HoldPattern[ButtonFunction :> action_] :> HoldComplete[action], Infinity], Infinity]

setupStatuses[] := Cases[setupBoxes,
	DynamicBox[ToBoxes[value_, StandardForm], ___] /; ! FreeQ[HoldComplete[value], _ProgressIndicator] :> value, Infinity]

setupLibraryButtons[] := Cases[setupBoxes,
	ButtonBox[DynamicBox[ToBoxes[label_, StandardForm], ___], ___, Enabled -> Dynamic[enabled_], ___] /;
		! FreeQ[HoldComplete[label], "Uninstall"] :> {label, enabled}, Infinity]

setupCopyButtons[] := Cases[setupBoxes,
	ButtonBox[DynamicBox[ToBoxes[label_, StandardForm], ___], ___, Appearance -> "Frameless", ___,
		BaseStyle -> "Hyperlink", ___, Enabled -> Dynamic[enabled_], ___] :> {label, enabled}, Infinity]

setupLibraryAction[name_] := First @ Cases[setupBoxes,
	button_ButtonBox /; ! FreeQ[button, HoldPattern[WolframInstitute`Recursor`PackageScope`libraryUninstall[name]]] :>
		First @ Cases[button, HoldPattern[ButtonFunction :> action_] :> HoldComplete[action], Infinity], Infinity]

setupCopyAction[name_] := First @ Cases[setupBoxes,
	button_ButtonBox /; ! FreeQ[button, HoldPattern[WolframInstitute`Recursor`Libraries`Setup`Private`librarySetupCommand[name, _]]] :>
		First @ Cases[button, HoldPattern[ButtonFunction :> action_] :> HoldComplete[action], Infinity], Infinity]

setupCancelVisible[] := First @ Cases[setupBoxes, PaneSelectorBox[_, Dynamic[value_, ___], ___] :> value, Infinity]

VerificationTest[
	withSetupDialog[Module[{downloads = {}, during, afterFirst},
		Block[{InstallRecursorLibraries = Function[names,
			during = {setupLibraryButtons[], setupCopyButtons[]};
			downloads = Join[downloads, names]; setupInstalled = Union[setupInstalled, names];
			AssociationMap[installedPaclet &, names]
		]},
			ReleaseHold[setupLibraryAction["First"]];
			afterFirst = {downloads, setupStatuses[], setupLibraryButtons[], setupClosed};
			ReleaseHold[setupLibraryAction["Second"]]
		];
		{afterFirst, downloads, setupStatuses[], setupLibraryButtons[], during, setupOpened, setupClosed}
	]],
	{{{"First"}, {"Ready", "Not installed"}, {{"Uninstall", True}, {"Install", True}}, False},
		{"First", "Second"}, {"Ready", "Ready"}, {{"Uninstall", True}, {"Uninstall", True}},
		{{{"Uninstall", False}, {"Install", False}}, {{"Copy uninstall command", False}, {"Copy install command", False}}}, 1, False},
	TestID -> "Setup-installs-one-library-at-a-time-and-keeps-the-same-window-open"
]

VerificationTest[
	withSetupDialog[Module[{removed = {}, during, after},
		Block[{PacletUninstall = Function[name,
			removed = Append[removed, name]; during = {setupLibraryButtons[], setupCopyButtons[]};
			setupInstalled = DeleteCases[setupInstalled, name]; Null
		]}, ReleaseHold[setupLibraryAction["First"]]];
		after = {setupStatuses[], setupLibraryButtons[], setupClosed};
		Block[{InstallRecursorLibraries = Function[names,
			setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]]},
			ReleaseHold[setupLibraryAction["First"]]
		];
		{removed, during, after, setupInstalled, setupClosed}
	], {"First", "Second"}],
	{{"First"}, {{{"Uninstall", False}, {"Uninstall", False}},
		{{"Copy uninstall command", False}, {"Copy uninstall command", False}}},
		{{"Not installed", "Ready"}, {{"Install", True}, {"Uninstall", True}}, False}, {"First", "Second"}, False},
	TestID -> "Setup-uninstalls-only-one-library-and-allows-reinstalling-it"
]

VerificationTest[
	withSetupDialog[
		Block[{PacletUninstall = Function[name, setupInstalled = DeleteCases[setupInstalled, name]; Null]},
			ReleaseHold[setupLibraryAction["Second"]]
		];
		setupBoxes = setupResolveRows[setupRawBoxes];
		{setupStatuses[], setupLibraryButtons[], Cases[setupBoxes,
			HoldPattern[WolframInstitute`Recursor`PackageScope`libraryUninstall[name_String]] :> name, Infinity]},
		{"First", "Second"}
	],
	{{"Ready", "Not installed"}, {{"Uninstall", True}, {"Install", True}}, {"First", "Second"}},
	TestID -> "Setup-preserves-library-order-after-uninstalling"
]

VerificationTest[
	withSetupDialog[
		Block[{InstallRecursorLibraries = Function[names,
			setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]]},
			ReleaseHold[setupLibraryAction["First"]]
		];
		setupBoxes = setupResolveRows[setupRawBoxes];
		{setupStatuses[], Cases[setupBoxes,
			HoldPattern[WolframInstitute`Recursor`PackageScope`libraryUninstall[name_String]] :> name, Infinity]}
	],
	{{"Ready", "Not installed"}, {"First", "Second"}},
	TestID -> "Setup-preserves-library-order-after-installing"
]

VerificationTest[
	withSetupDialog[Module[{afterFailure},
		Block[{PacletUninstall = ($Failed &)}, ReleaseHold[setupLibraryAction["First"]]];
		afterFailure = {setupStatuses[], setupLibraryButtons[], setupClosed};
		Block[{PacletUninstall = Function[name, setupInstalled = DeleteCases[setupInstalled, name]; Null]},
			ReleaseHold[setupLibraryAction["First"]]
		];
		{afterFailure, setupInstalled, setupLibraryButtons[], setupClosed}
	], {"First", "Second"}],
	{{{"Failed", "Ready"}, {{"Uninstall", True}, {"Uninstall", True}}, False},
		{"Second"}, {{"Install", True}, {"Uninstall", True}}, False},
	TestID -> "Setup-failed-uninstall-stays-visible-and-can-be-retried"
]

VerificationTest[
	Table[withSetupDialog[
		Block[{PacletUninstall = Function[name,
			If[removed, setupInstalled = DeleteCases[setupInstalled, name]]; Abort[]]},
			CheckAbort[ReleaseHold[setupLibraryAction["First"]], Null]
		];
		{setupStatuses[], setupLibraryButtons[], setupClosed}, {"First", "Second"}
	], {removed, {False, True}}],
	{
		{{"Ready", "Ready"}, {{"Uninstall", True}, {"Uninstall", True}}, False},
		{{"Not installed", "Ready"}, {{"Install", True}, {"Uninstall", True}}, False}
	},
	TestID -> "Setup-aborted-uninstall-refreshes-status-and-unlocks-the-dialog"
]

VerificationTest[
	withSetupDialog[
		Block[{InstallRecursorLibraries = Function[names,
			setupInstalled = Union[setupInstalled, names];
			AssociationMap[Failure["Test", <|"MessageTemplate" -> "Installation could not finish."|>] &, names]
		]}, ReleaseHold[setupLibraryAction["First"]]];
		{setupStatuses[], setupLibraryButtons[], setupCopyButtons[], setupClosed}
	],
	{{"Failed", "Not installed"}, {{"Uninstall", True}, {"Install", True}},
		{{"Copy uninstall command", True}, {"Copy install command", True}}, False},
	TestID -> "Setup-keeps-partial-installation-failures-open-and-allows-uninstalling"
]

VerificationTest[
	withSetupDialog[{
		Count[setupBoxes, _CheckboxBox, Infinity], setupLibraryButtons[],
		ReleaseHold[setupAction["Close"]]; {setupClosed, setupRemembered}
	}],
	{0, {{"Install", True}, {"Install", True}}, {True, True}},
	TestID -> "Setup-has-individual-actions-and-closes-only-when-requested"
]

VerificationTest[
	withSetupDialog[
		ReleaseHold @ First @ Cases[setupEvents, HoldPattern["WindowClose" :> action_] :> HoldComplete[action], Infinity];
		setupRemembered
	],
	True,
	TestID -> "Setup-window-close-remembers-dismissal"
]

VerificationTest[
	withSetupDialog[Module[{copied = {}, before, afterInstall, afterRemoval},
		before = setupCopyButtons[];
		Block[{CopyToClipboard = Function[text, copied = Append[copied, text]],
			InstallRecursorLibraries = Function[names,
				setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]],
			PacletUninstall = Function[name, setupInstalled = DeleteCases[setupInstalled, name]; Null]
		},
			ReleaseHold[setupCopyAction["First"]];
			ReleaseHold[setupLibraryAction["First"]]; afterInstall = setupCopyButtons[];
			ReleaseHold[setupCopyAction["First"]];
			ReleaseHold[setupLibraryAction["First"]]; afterRemoval = setupCopyButtons[];
			ReleaseHold[setupCopyAction["First"]]
		];
		{before, afterInstall, afterRemoval, copied, setupCopyButtons[], setupClosed}
	]],
	{{{"Copy install command", True}, {"Copy install command", True}},
		{{"Copy uninstall command", True}, {"Copy install command", True}},
		{{"Copy install command", True}, {"Copy install command", True}},
		{"InstallRecursorLibraries[{\"First\"}]", "PacletUninstall[\"First\"]", "InstallRecursorLibraries[{\"First\"}]"},
		{{"Copied", True}, {"Copy install command", True}}, False},
	TestID -> "Setup-copy-links-follow-the-installed-state-and-confirm-copying"
]

VerificationTest[
	Table[withSetupDialog[Module[{copied},
		Block[{CopyToClipboard = Function[text, copied = text]}, ReleaseHold[setupCopyAction["First"]]];
		{copied, setupInstalled, setupClosed, setupRemembered}
	], installedNames], {installedNames, {{}, {"First"}}}],
	{{"InstallRecursorLibraries[{\"First\"}]", {}, False, False},
		{"PacletUninstall[\"First\"]", {"First"}, False, False}},
	TestID -> "Setup-copying-either-command-does-not-install-uninstall-or-dismiss"
]

VerificationTest[
	withSetupDialog[Module[{downloads = {}, failed = True, afterFailure},
		Block[{InstallRecursorLibraries = Function[names,
			downloads = Join[downloads, names];
			If[failed,
				AssociationMap[Failure["Test", <|"MessageTemplate" -> "Test download failed."|>] &, names],
				setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]
			]
		]},
			ReleaseHold[setupLibraryAction["Second"]];
			afterFailure = {setupStatuses[], setupLibraryButtons[], setupClosed};
			failed = False;
			ReleaseHold[setupLibraryAction["Second"]];
			{afterFailure, downloads, setupStatuses[], setupClosed}
		]
	]],
	{{{"Not installed", "Failed"}, {{"Install", True}, {"Install", True}}, False},
		{"Second", "Second"}, {"Not installed", "Ready"}, False},
	TestID -> "Setup-retries-only-the-requested-library-without-closing"
]

VerificationTest[
	withSetupDialog[
		Block[{InstallRecursorLibraries = (Abort[] &)},
			CheckAbort[ReleaseHold[setupLibraryAction["First"]], Null]
		];
		{setupClosed, setupLibraryButtons[], setupStatuses[]}
	],
	{False, {{"Install", True}, {"Install", True}}, {"Not installed", "Not installed"}},
	TestID -> "Setup-aborted-installation-clears-progress-and-allows-retry"
]

VerificationTest[
	withSetupDialog[Module[{samples = {}, reporting, cancellation = {setupCancelVisible[]}},
		Block[{InstallRecursorLibraries = Function[names,
			reporting = $ProgressReporting;
			WolframInstitute`Recursor`PackageScope`$libraryProgressFunction["Downloading...", 0.25];
			samples = Append[samples, setupStatuses[]];
			cancellation = Append[cancellation, setupCancelVisible[]];
			WolframInstitute`Recursor`PackageScope`$libraryProgressFunction["Installing...", None];
			samples = Append[samples, setupStatuses[]];
			cancellation = Append[cancellation, setupCancelVisible[]];
			setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]
		]}, ReleaseHold[setupLibraryAction["First"]]];
		{Cases[samples, Column[{label_, _ProgressIndicator}, ___] :> label, Infinity], reporting, cancellation, setupStatuses[], setupClosed}
	]],
	{{Row[{"Downloading ", 25, "%"}], "Installing..."}, False, {False, True, False}, {"Ready", "Not installed"}, False},
	TestID -> "Setup-shows-download-percentage-inline-without-separate-progress-window"
]

VerificationTest[
	withSetupDialog[Module[{downloads = {}, cancel = True, afterCancel},
		Block[{InstallRecursorLibraries = Function[names,
			downloads = Join[downloads, names];
			WolframInstitute`Recursor`PackageScope`$libraryProgressFunction["Downloading...", 0.25];
			If[cancel, ReleaseHold[setupAction["Cancel download"]]];
			If[WolframInstitute`Recursor`PackageScope`libraryCancelledQ[],
				AssociationMap[Failure["LibraryInstallCancelled", <|"MessageTemplate" -> "Installation cancelled."|>] &, names],
				setupInstalled = Union[setupInstalled, names]; AssociationMap[installedPaclet &, names]
			]
		]},
			ReleaseHold[setupLibraryAction["First"]];
			afterCancel = {setupStatuses[], setupLibraryButtons[], setupClosed};
			cancel = False;
			ReleaseHold[setupLibraryAction["First"]];
			{afterCancel, downloads, setupStatuses[], setupClosed}
		]
	]],
	{{{"Cancelled", "Not installed"}, {{"Install", True}, {"Install", True}}, False},
		{"First", "First"}, {"Ready", "Not installed"}, False},
	TestID -> "Setup-cancels-only-the-current-download-and-allows-retry-without-closing"
]

VerificationTest[
	withSetupDialog[Module[{cancelled},
		Block[{InstallRecursorLibraries = Function[names,
			WolframInstitute`Recursor`PackageScope`$libraryProgressFunction["Downloading...", 0.25];
			ReleaseHold[setupAction["Close"]];
			cancelled = WolframInstitute`Recursor`PackageScope`libraryCancelledQ[];
			AssociationMap[Failure["LibraryInstallCancelled", <|"MessageTemplate" -> "Installation cancelled."|>] &, names]
		]}, ReleaseHold[setupLibraryAction["First"]]];
		{cancelled, setupClosed, setupRemembered}
	]],
	{True, True, True},
	TestID -> "Setup-explicit-close-cancels-an-active-download"
]

VerificationTest[
	withSetupDialog[
		Block[{InstallRecursorLibraries = Function[names,
			setupInstalled = Union[setupInstalled, names];
			AssociationMap[Failure["LibrarySetupRequired", <|"MessageTemplate" -> "Install the required toolchain."|>] &, names]
		]}, ReleaseHold[setupLibraryAction["First"]]];
		{setupStatuses[], setupLibraryButtons[], setupCopyButtons[], setupClosed}
	],
	{{"Needs setup", "Not installed"}, {{"Uninstall", True}, {"Install", True}},
		{{"Copy uninstall command", True}, {"Copy install command", True}}, False},
	TestID -> "Setup-keeps-manual-setup-instructions-visible-and-offers-uninstall"
]

VerificationTest[
	withSetupDialog[
		Block[{InstallRecursorLibraries = Function[names,
			setupInstalled = Union[setupInstalled, names, {"LeanLink"}]; AssociationMap[installedPaclet &, names]]},
			ReleaseHold[setupLibraryAction["MathlibLink"]]
		];
		{setupStatuses[], setupLibraryButtons[], setupClosed}, {}, {"LeanLink", "MathlibLink"}
	],
	{{"Ready", "Ready"}, {{"Uninstall", True}, {"Uninstall", True}}, False},
	TestID -> "Setup-refreshes-LeanLink-after-MathlibLink-installs-it"
]

VerificationTest[
	withSetupDialog[
		Block[{
			WolframInstitute`Recursor`PackageScope`libraryStatus = Function[name, Which[
				! MemberQ[setupInstalled, name], "Not installed",
				name === "MathlibLink" && ! MemberQ[setupInstalled, "LeanLink"], "Needs setup",
				True, "Ready"
			]],
			PacletUninstall = Function[name, setupInstalled = DeleteCases[setupInstalled, name]; Null]
		}, ReleaseHold[setupLibraryAction["LeanLink"]]];
		{setupStatuses[], setupLibraryButtons[], setupClosed}, {"LeanLink", "MathlibLink"}, {"LeanLink", "MathlibLink"}
	],
	{{"Not installed", "Needs setup"}, {{"Install", True}, {"Uninstall", True}}, False},
	TestID -> "Setup-refreshes-Mathlib-readiness-after-LeanLink-removal"
]
