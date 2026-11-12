(* Loads the style check as the package Recursor`Scripts` and runs one command.
   scripts/style.wls calls Get[".../run.wls"]["CheckStyle"] or ["FixStyle"]. A test file calls
   Get[".../run.wls"]["Load"], which only loads the package, so that the test file runs on its own. *)
With[{scriptDirectory = DirectoryName[$InputFileName]},
	Function[command,
		Module[{context},
			context = "Recursor`Scripts`";
			If[!NameQ["System`PackageInitialize"],
				Print["ERROR: the style check requires Wolfram Language 15.0 or later; this kernel is ", $Version];
				Exit[1]
			];
			If[!MemberQ[$Packages, context],
				PackageInitialize[context, scriptDirectory, <|"LoadFirstFiles" -> {"common.wl", "style.wl"}, "IgnoreFiles" -> {"run.wls"}|>]
			];
			If[command =!= "Load", Symbol[context <> "RunScript"][Symbol[context <> command]]]
		]
	]
]
