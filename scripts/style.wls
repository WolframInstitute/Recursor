(* Checks the Wolfram Language files against the coding guides, or applies the mechanical fixes.

     wolframscript -file scripts/style.wls check [FILES]
     wolframscript -file scripts/style.wls fix [FILES] *)
Module[{command, files},
	command = Replace[$ScriptCommandLine, {{_String, "fix", ___} -> "FixStyle", _List -> "CheckStyle"}];
	files = Replace[$ScriptCommandLine, {{script_String, "check" | "fix", rest___} :> {script, rest}}];
	Block[{$ScriptCommandLine = files},
		Get[FileNameJoin[{DirectoryName[$InputFileName], "style", "run.wls"}]][command]
	]
]
