(* Desktop setup dialog for the optional library registry. *)

PackageExported[SetupRecursor]
PackageScoped[librarySetupOnLoad]

SetupRecursor::usage = "SetupRecursor[] opens a dialog to review, install, or uninstall optional libraries in a desktop notebook."
General::recursorlib = "Optional libraries are available. Run SetupRecursor[] to review and install."
librarySetupOnLoad::usage = "librarySetupOnLoad[] issues a setup message for missing optional libraries in a desktop notebook unless setup was dismissed."
librarySetupDesktopQ::usage = "librarySetupDesktopQ[] tests whether this is an interactive desktop kernel."
librarySetupMissing::usage = "librarySetupMissing[] gives the registry entries for missing libraries."
librarySetupRemember::usage = "librarySetupRemember[] remembers that the user has dismissed library setup."
librarySetupCommand::usage = "librarySetupCommand[name, action] gives a library's install or uninstall command as plain text."
$librarySetupDialog::usage = "$librarySetupDialog is the open library setup dialog."
$librarySetupPreference::usage = "$librarySetupPreference is the local preference key for library setup."

$librarySetupPreference = "WolframInstitute/Recursor/LibrarySetupSeen"

librarySetupDesktopQ[] := And[
	TrueQ[$Notebooks], ! TrueQ[$CloudEvaluation], ! TrueQ[$BatchInput], $KernelID === 0,
	! MemberQ[{"true", "1"}, Environment["CI"]]
]

librarySetupRemember[] := (PersistentSymbol[$librarySetupPreference, "Local"] = True)

librarySetupCommand[name_String] := librarySetupCommand[name, "Install"]

librarySetupCommand[name_String, "Install"] := "InstallRecursorLibraries[{" <> ToString[name, InputForm] <> "}]"

librarySetupCommand[name_String, "Uninstall"] :=
	"PacletUninstall[" <> ToString[$libraryRegistry[name]["Paclet"], InputForm] <> "]" /; KeyExistsQ[$libraryRegistry, name]

librarySetupMissing[] := Select[$libraryRegistry, PacletFind[#["Paclet"]] === {} &]

librarySetupOnLoad[] := If[And[
	librarySetupDesktopQ[],
	! TrueQ[PersistentSymbol[$librarySetupPreference, "Local"]]
], If[librarySetupMissing[] =!= <||>, Message[General::recursorlib]]]

SetupRecursor[] := If[
	! librarySetupDesktopQ[],
	Failure["NotebookRequired", <|"MessageTemplate" -> "Open a desktop notebook to use SetupRecursor. Use InstallRecursorLibraries in scripts."|>],
	With[{libraries = $libraryRegistry}, Which[
		libraries === <||>, Null,
		ValueQ[$librarySetupDialog] && MemberQ[Notebooks[], $librarySetupDialog],
			SetSelectedNotebook[$librarySetupDialog]; Null,
		True,
			$librarySetupDialog = CreateDialog[
				DynamicModule[{statuses = AssociationMap[libraryStatus, Keys[libraries]],
					installed = AssociationMap[PacletFind[libraries[#]["Paclet"]] =!= {} &, Keys[libraries]],
					busy = False, active = None, cancelled = False, progress = <||>, errors = <||>, copied = None},
					Framed[Grid[{
						{Column[{
							Style["Optional libraries", 18, Bold],
							Pane["Install or remove libraries as needed.", 600]
						}, Alignment -> Left, Spacings -> 0.6]},
						{Pane[Dynamic[Grid[KeyValueMap[Function[{label, info}, {
								Pane[Column[{
									Style[label, 14, Bold], Pane[info["Description"], 396],
									Style[Row[{
										"Download: ", Lookup[info["DownloadSize"], $SystemID, "unavailable"],
										Spacer[16], "License: ", info["License"]
									}], Small, LightDarkSwitched[GrayLevel[0.35], GrayLevel[0.7]]],
									Row[Riffle[Prepend[
										KeyValueMap[Hyperlink, Lookup[info, "SetupLinks", <||>]],
										Hyperlink["Setup instructions", info["URL"]]
									], Spacer[16]]],
									Dynamic[Refresh[If[KeyExistsQ[errors, label],
										Style[Pane[errors[label], 396], If[statuses[label] === "Failed", StandardRed,
											LightDarkSwitched[GrayLevel[0.35], GrayLevel[0.7]]], Small],
										Spacer[{0, 0}]], TrackedSymbols :> {errors, statuses}]]
								}, Alignment -> Left, Spacings -> 0.5], 416, Alignment -> {Left, Top}],
								Pane[Column[{
									Dynamic[If[busy && active === label,
										If[NumberQ[Lookup[progress, label, None]],
											Column[{Row[{"Downloading ", Round[100 progress[label]], "%"}],
												ProgressIndicator[progress[label], {0, 1}, ImageSize -> {140, 10}]}, Alignment -> Right],
											Column[{statuses[label], ProgressIndicator[Appearance -> "Indeterminate", ImageSize -> {140, 10}]}, Alignment -> Right]
										],
										statuses[label]
									], TrackedSymbols :> {busy, active, statuses, progress}],
									Button[Dynamic[If[installed[label], "Uninstall", "Install"], TrackedSymbols :> {installed}],
										With[{uninstall = installed[label]},
											librarySetupRemember[];
											busy = True;
											active = label;
											cancelled = False;
											copied = None;
											progress = KeyDrop[progress, label];
											errors = KeyDrop[errors, label];
											statuses = Append[statuses, label -> If[uninstall, "Uninstalling...", "Preparing..."]];
											WithCleanup[
												FinishDynamic[];
												With[{result = If[uninstall,
													Quiet[libraryUninstall[label]],
													Block[{
														$libraryProgressFunction = Function[{stage, fraction},
															statuses = Append[statuses, label -> stage];
															progress = Append[progress, label -> If[NumberQ[fraction], Clip[fraction, {0, 1}], None]];
															FinishDynamic[]
														],
														libraryCancelledQ = Function[Null, cancelled], $ProgressReporting = False
													}, Lookup[Quiet[InstallRecursorLibraries[{label}]], label]]
												]}, Which[
													FailureQ[result],
														errors = Append[errors, label -> ToString[result["Message"]]];
														statuses = Append[statuses, label -> Switch[First[result],
															"LibraryInstallCancelled", "Cancelled", "LibrarySetupRequired", "Needs setup", _, "Failed"]],
													uninstall,
														errors = Append[errors, label -> "Uninstalled. Restart the kernel to clear any loaded library code."];
														statuses = Append[statuses, label -> libraryStatus[label]],
													True, statuses = Append[statuses, label -> "Ready"]
												]],
												(* A bridge can install another listed library or depend on one that was removed. *)
												installed = AssociationMap[PacletFind[libraries[#]["Paclet"]] =!= {} &, Keys[libraries]];
												Scan[Function[name,
													statuses = Append[statuses, name -> libraryStatus[name]];
													If[statuses[name] === "Ready", errors = KeyDrop[errors, name]]
												], DeleteCases[Keys[libraries], label]];
												If[MemberQ[{"Preparing...", "Downloading...", "Retrying...", "Installing...", "Checking...", "Uninstalling..."}, statuses[label]],
													statuses = Append[statuses, label -> libraryStatus[label]]
												];
												progress = KeyDrop[progress, label];
												busy = False;
												active = None;
												FinishDynamic[]
											]
										],
										ImageSize -> {110, Automatic}, Method -> "Queued",
										Enabled -> Dynamic[Refresh[! busy && (installed[label] || MemberQ[{"Not installed", "Failed", "Cancelled"}, statuses[label]]),
											TrackedSymbols :> {busy, installed, statuses}]]
									],
									Button[Dynamic[Which[copied === label, "Copied", installed[label], "Copy uninstall command", True, "Copy install command"],
										TrackedSymbols :> {installed, copied}],
										CopyToClipboard[librarySetupCommand[label, If[installed[label], "Uninstall", "Install"]]]; copied = label,
										Appearance -> "Frameless", BaseStyle -> "Hyperlink", Method -> "Preemptive",
										Enabled -> Dynamic[Refresh[! busy && (installed[label] || statuses[label] =!= "Unsupported"), TrackedSymbols :> {busy, installed, statuses}]]
									]
								}, Alignment -> Right, Spacings -> 0.8], 180, Alignment -> {Right, Top}]
							}], KeySortBy[libraries, Function[name, {Boole[installed[name]], name}]]],
							Alignment -> {{Left, Right}, Top}, Spacings -> {1, 1.5}], TrackedSymbols :> {installed}],
							ImageSize -> {616, UpTo[320]}, Scrollbars -> {False, Automatic},
							AppearanceElements -> None, Alignment -> {Left, Top}]},
						{Pane[Row[{
							PaneSelector[{
								True -> Button["Cancel download", cancelled = True, ImageSize -> {140, Automatic}, Method -> "Preemptive",
									Enabled -> Dynamic[! cancelled]],
								False -> Spacer[{140, 0}]
							}, Dynamic[Refresh[busy && MemberQ[{"Preparing...", "Downloading...", "Retrying..."}, Lookup[statuses, active, None]],
								TrackedSymbols :> {busy, active, statuses}]]],
							Spacer[12],
							DefaultButton["Close", cancelled = True; librarySetupRemember[]; DialogReturn[],
								ImageSize -> {90, Automatic}, Method -> "Preemptive"]
						}], 600, Alignment -> Right]}
					}, Alignment -> Left, Spacings -> {0, 1.3},
						Dividers -> {None, {False, False, GrayLevel[0.85], False}}],
						FrameStyle -> None, FrameMargins -> {{16, 0}, {16, 16}}],
					Deinitialization :> (cancelled = True)
				],
				WindowTitle -> "Recursor: Optional libraries",
				NotebookEventActions -> {"WindowClose" :> librarySetupRemember[], PassEventsDown -> True}
			];
			Null
	]]
]
