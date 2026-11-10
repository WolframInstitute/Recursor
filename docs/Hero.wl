(* The resource page image, docs/Hero.png. Every picture is computed: by the paclet, or from the
   corpus v2 record in docs/notes/data/OEISCorpusV2Hero.json.gz. `make hero` draws the design the
   Makefile names; `make hero HERO=n` draws another of the five. scripts/docs.wls loads the paclet
   first. The Lambda library must be installed. *)
Begin["RecursorHero`"];
Needs["Wolfram`Lambda`"];
root = DirectoryName[$InputFileName, 2];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
data = Import[FileNameJoin[{root, "docs", "notes", "data", "OEISCorpusV2Hero.json.gz"}], "RawJSON"];
If[! AssociationQ[data], fail["cannot read the corpus record"]];
gallery = Association[#ID -> # & /@ data["Gallery"]];
program[id_String] := With[{p = ParseRecursor[gallery[id]["Program"]]}, If[RecursorProgramQ[p], p, fail["cannot read the program of " <> id]]];

(* ==================== style ==================== *)

font = "Helvetica";
ink = GrayLevel[0.2];
muted = GrayLevel[0.45];
hair = GrayLevel[0.85];
blue = RGBColor["#2a78d6"];
(* the colors RecursorProgramTree gives the four kinds of syntax node *)
families = <|"Loop" -> RGBColor["#2a78d6"], "Arithmetic" -> RGBColor["#eb6834"], "Choice" -> RGBColor["#1baf7a"], "Atom" -> RGBColor["#eda100"]|>;
familyNames = <|"Loop" -> "loops", "Arithmetic" -> "arithmetic", "Choice" -> "choice and binding", "Atom" -> "inputs and constants"|>;
familyMembers = <|"Loop" -> "Rec, Iter, CoRec, WhileLoop", "Arithmetic" -> "Succ, Pred, Half, Add, Mul, Monus, Quot, Rem",
	"Choice" -> "Ifz, Let, CGet", "Atom" -> "Var, Acc, Idx, 0, 1, 2, \[Ellipsis]"|>;
styled[s_, size_, color_ : ink, weight_ : Plain] := Style[s, FontFamily -> font, FontSize -> size, FontColor -> color, FontWeight -> weight];
grouped[n_Integer] := ToString[NumberForm[n, DigitBlock -> 3, NumberSeparator -> ","]];
legend[detail_ : False, size_ : 11] := Row[Riffle[KeyValueMap[Function[{key, color}, Row[{
	Graphics[{color, Disk[]}, ImageSize -> size - 1, BaselinePosition -> Scaled[0.1]], " ", styled[familyNames[key], size],
	If[detail, styled["  " <> familyMembers[key], size, muted], Nothing]}]], families], Spacer[24]]];
note[text_, width_, size_ : 10.5] := Pane[Style[text, FontFamily -> font, FontSize -> size, FontColor -> muted, TextAlignment -> Center], {width, Automatic}, Alignment -> Center];
framed[g_] := Framed[g, FrameStyle -> hair, RoundingRadius -> 6, FrameMargins -> 6, Background -> White];
tileSize = {360, 236};
tile[label_, text_, drawing_] := Column[{framed[drawing], styled[label, 14, ink, Bold],
	Pane[styled[text, 10.5, muted], {First[tileSize] + 12, Automatic}]}, Alignment -> Left, Spacings -> 0.35];
board[tiles_List, columns_Integer] := Grid[Partition[tiles, UpTo[columns]], Spacings -> {1.8, 1.5}, Alignment -> {Left, Top}];
(* a raster drawn at two pixels per point, the export resolution *)
halfSize[image_] := Image[image, ImageSize -> ImageDimensions[image]/2];
(* another drawing, scaled to fit a box *)
fit[expr_, {w_, h_}] := Module[{image = ImageCrop[Rasterize[expr, LightDark -> "Light", ImageResolution -> 288, Background -> White]], scale},
	scale = Min[2 w/First[ImageDimensions[image]], 2 h/Last[ImageDimensions[image]]];
	Pane[halfSize[ImageResize[image, Scaled[scale]]], {w, h}, Alignment -> Center]
];
tickStyle = Directive[FontFamily -> font, FontSize -> 8.5, FontColor -> muted];
plotOptions[size_] := Sequence[Axes -> False, Frame -> {{False, False}, {True, False}}, FrameStyle -> GrayLevel[0.75],
	FrameTicksStyle -> tickStyle, ImageSize -> size, AspectRatio -> Full, ImagePadding -> {{10, 10}, {20, 8}}];
marked[color_, text_, size_ : 9.5] := Row[{Graphics[{color, Disk[]}, ImageSize -> size - 2, BaselinePosition -> Scaled[0.05]], " ", styled[text, size]}];

(* ==================== syntax trees ==================== *)

children[Var | Acc | Idx | _Const] := {};
children[e_] := List @@ e;
family[Var | Acc | Idx | _Const] := "Atom";
family[e_] := Switch[Head[e], Rec | Iter | CoRec | WhileLoop, "Loop", Ifz | Let | CGet, "Choice", _, "Arithmetic"];

(* A tidy layout for trees drawn as dots: a subtree is as wide as its children, and a node sits
   over the middle of its first and last child. Positions are {x, -depth}. *)
treeLayout[expr_, width_] := Module[{nodes = {}, edges = {}, measure, place},
	measure[e_] := measure[e] = Max[width[e], Total[measure /@ children[e]]];
	place[e_, left_, depth_] := Module[{kids = children[e], offset, points, x},
		offset = left + (measure[e] - Total[measure /@ kids])/2;
		points = Table[With[{p = place[kid, offset, depth + 1]}, offset += measure[kid]; p], {kid, kids}];
		x = If[kids === {}, left + measure[e]/2, (points[[1, 1]] + points[[-1, 1]])/2];
		AppendTo[nodes, {{x, -depth}, e}];
		Scan[AppendTo[edges, {{x, -depth}, #}] &, points];
		{x, -depth}
	];
	place[expr, 0, 0];
	<|"Nodes" -> nodes, "Edges" -> edges, "Width" -> measure[expr], "Depth" -> Max[-nodes[[All, 1, 2]]]|>
];

(* A syntax tree as RecursorProgramTree draws it, fitted to a box. *)
treeBox[expr_, size_] := Pane[fit[RecursorProgramTree[expr], size - {12, 12}], size, Alignment -> Center];

(* The same tree as dots, for many programs side by side. *)
glyphTree[expr_, {w_, h_}] := Module[{layout = treeLayout[expr, 1 &], sx, sy, r, x0, y0, point},
	sx = Min[9, (w - 6)/layout["Width"]];
	r = Min[3.2, 0.4 sx];
	sy = If[layout["Depth"] == 0, 0, Min[11.5, (h - 2 r - 2)/layout["Depth"]]];
	x0 = (w - sx layout["Width"])/2;
	y0 = h - r - 1 - (h - 2 r - 2 - sy layout["Depth"])/2;
	point[{x_, y_}] := {x0 + sx x, y0 + sy y};
	Graphics[{
		{GrayLevel[0.62], AbsoluteThickness[0.6], Line[point /@ #] & /@ layout["Edges"]},
		{EdgeForm[Directive[White, AbsoluteThickness[0.4]]], {families[family[#[[2]]]], Disk[point[#[[1]]], r]} & /@ layout["Nodes"]}},
		PlotRange -> {{0, w}, {0, h}}, ImageSize -> {w, h}, PlotRangePadding -> None, ImagePadding -> None]
];

(* ==================== computed results ==================== *)

(* SynthesizeRecursor on sixteen terms of the binary digit count, checked on 240 further terms. *)
synthesis[] := synthesis[] = Module[{given = DigitCount[Range[0, 15], 2, 1], found, values},
	found = SynthesizeRecursor[given];
	If[! TrueQ[found["Solved"]], fail["no program for the binary digit count"]];
	values = Table[EvaluateRecursor[found["Program"], n], {n, 0, 255}];
	If[values =!= DigitCount[Range[0, 255], 2, 1], fail["the synthesized program differs on later terms"]];
	<|"Given" -> given, "Program" -> found["Program"], "Values" -> values|>
];
predictionPlot[size_, count_, pointSize_] := With[{values = Take[synthesis[]["Values"], count], top = Max[Take[synthesis[]["Values"], count]]},
	ListPlot[{Transpose[{Range[0, 15], Take[values, 16]}], Transpose[{Range[16, count - 1], Drop[values, 16]}]},
		PlotStyle -> {Directive[ink, AbsolutePointSize[pointSize]], Directive[blue, AbsolutePointSize[pointSize]]},
		Filling -> {1 -> {Axis, Directive[ink, Opacity[0.35]]}, 2 -> {Axis, Directive[blue, Opacity[0.35]]}},
		PlotRange -> {{-1, count}, {-0.25, top + 1.7}},
		FrameTicks -> {{None, None}, {Append[Select[{0, 16, 32, 48, 64, 128, 192}, # < count - 8 &], count - 1], None}},
		Epilog -> {Inset[marked[ink, "16 terms given"], Scaled[{0.012, 0.93}], {Left, Center}],
			Inset[marked[blue, ToString[count - 16] <> " further terms from the program"], Scaled[{0.988, 0.93}], {Right, Center}]},
		plotOptions[size]]
];

evaluationPlot[size_] := Module[{values = Table[EvaluateRecursor[RecursorExamples["DigitSum"], n], {n, 0, 199}]},
	If[values =!= (Total[IntegerDigits[#]] & /@ Range[0, 199]), fail["the digit sum program differs"]];
	ListPlot[values, DataRange -> {0, 199}, Filling -> Axis, FillingStyle -> Directive[blue, Opacity[0.35]],
		PlotStyle -> Directive[blue, AbsolutePointSize[2.8]], PlotRange -> {{-2, 201}, {0, 19.6}},
		FrameTicks -> {{None, None}, {{0, 50, 100, 150, 199}, None}}, plotOptions[size]]
];

(* One seeded evolution run and the ancestors of the first program that matches every example. *)
evolution[] := evolution[] = Module[{examples = Table[{n, n (n + 1)/2}, {n, 0, 7}], result, records, best, seen = {}, frontier},
	result = EvolveRecursor[examples, "RandomSeed" -> 6, "IncludeWhile" -> False];
	If[! TrueQ[result["Solved"]], fail["the evolution run did not solve its target"]];
	records = Association[#ID -> # & /@ result["Genealogy"]];
	best = First[SortBy[Select[result["Genealogy"], #Score === result["Fitness"] &], {#Generation, #ID} &]];
	frontier = {best["ID"]};
	While[frontier =!= {}, seen = Union[seen, frontier]; frontier = Complement[Union @@ (records[#]["Parents"] & /@ frontier), seen]];
	<|"Result" -> result, "Best" -> best, "Ancestors" -> (records /@ seen), "Records" -> records, "Examples" -> Length[examples]|>
];
lineage[{w_, h_}] := Module[{run = evolution[], nodes, last, childrenOf, byGeneration, y = <||>, ordered, dx, dy, point, ramp, base = 20},
	nodes = run["Ancestors"];
	last = run["Best"]["Generation"];
	childrenOf = GroupBy[Catenate[Function[r, (# -> r["ID"]) & /@ r["Parents"]] /@ nodes], First -> Last];
	byGeneration = GroupBy[nodes, #Generation &];
	y[run["Best"]["ID"]] = 0.;
	(* later generations first: a program sits near the mean of its descendants *)
	Do[ordered = SortBy[Lookup[byGeneration, g, {}], {Mean[Lookup[y, Lookup[childrenOf, #ID, {}], 0.]], #ID} &];
		MapIndexed[(y[#1["ID"]] = First[#2] - (Length[ordered] + 1)/2.) &, ordered], {g, last - 1, 0, -1}];
	dx = (w - 36)/last;
	dy = Min[(h - base - 16)/(Max[Length /@ byGeneration] + 1), 12];
	point[id_] := {18 + dx run["Records"][id]["Generation"], base + (h - base)/2 + dy y[id]};
	ramp[score_] := Blend[{RGBColor["#cde2fb"], RGBColor["#2a78d6"], RGBColor["#0d366b"]}, score/run["Examples"]];
	Graphics[{
		{GrayLevel[0.55], Opacity[0.55], AbsoluteThickness[0.7], Function[r, Line[{point[#], point[r["ID"]]}] & /@ r["Parents"]] /@ nodes},
		{EdgeForm[Directive[White, AbsoluteThickness[0.8]]], {ramp[#Score], Disk[point[#ID], 3.5]} & /@ SortBy[nodes, #Score &]},
		{GrayLevel[0.75], AbsoluteThickness[1], Line[{{8, base - 4}, {w - 8, base - 4}}]},
		Text[styled["generation 0", 8.5, muted], {18, base - 12}, {-0.6, 0}], Text[styled[ToString[last], 8.5, muted], {w - 18, base - 12}],
		{GrayLevel[0.6], AbsoluteThickness[0.7], Line[{point[run["Best"]["ID"]] + {0, 6}, point[run["Best"]["ID"]] + {0, 40}}]},
		Text[styled[FormatRecursor[run["Best"]["Program"]], 9.5], point[run["Best"]["ID"]] + {4, 48}, {1, 0}]},
		PlotRange -> {{0, w}, {0, h}}, ImageSize -> {w, h}, PlotRangePadding -> None, ImagePadding -> None]
];

(* The corpus v2 record: one cell per eligible OEIS sequence along a space-filling curve. *)
mapColors = List @@@ (ColorConvert[#, "RGB"] & /@ {RGBColor["#e7e6e1"], RGBColor["#86b6ef"], RGBColor["#184f95"], White});
mapMatrix := mapMatrix = ToCharacterCode[data["Map"]] - 48;
mapImage := mapImage = Image[Map[mapColors[[# + 1]] &, mapMatrix, {2}], ColorSpace -> "RGB"];
represented = data["Counts"]["Represented"];
validated = data["Counts"]["Validated"];
swatch[color_, text_, count_, size_ : 12] := Row[{Graphics[{color, Rectangle[{0, 0}, {1, 1}, RoundingRadius -> 0.2]}, ImageSize -> size - 1, BaselinePosition -> Scaled[0.05]],
	" ", styled[text, size], "  ", styled[count, size, muted]}];
mapLegend[size_ : 12] := Row[Riffle[{
	swatch[RGBColor["#184f95"], "a program reproduces twenty terms and every later one", grouped[validated], size],
	swatch[RGBColor["#86b6ef"], "a program reproduces the first twenty terms", grouped[represented - validated] <> " more", size],
	swatch[RGBColor["#e7e6e1"], "no program found", grouped[data["Eligible"] - represented], size]}, Spacer[26]]];

(* ==================== the five designs ==================== *)

(* 1. One computed result per area of the paclet, in the manner of the Ruliology image. *)
design[1] := Module[{catalan = RecursorExamples["Catalan"], digitSum = RecursorExamples["DigitSum"], run = evolution[]},
	board[{
		tile["Language", "the syntax tree of a " <> ToString[RecursorNodeCount[catalan]] <> "-node program for the Catalan numbers",
			treeBox[catalan, tileSize]],
		tile["Evaluation", "digit sums of 0 to 199, computed by a " <> ToString[RecursorNodeCount[digitSum]] <> "-node program",
			evaluationPlot[tileSize]],
		tile["Compilation", "the factorial program compiled to a closed lambda term",
			fit[LambdaTree[CompileRecursor[RecursorExamples["Factorial"]], PlotTheme -> "Minimal"], tileSize]],
		tile["Synthesis", "sixteen terms of the binary digit count, continued by the program found for them",
			predictionPlot[tileSize, 64, 4.5]],
		tile["Evolution", "the " <> ToString[Length[run["Ancestors"]]] <> " ancestors of the first program to match n(n + 1)/2 on eight inputs; darker programs match more",
			lineage[tileSize]],
		tile["OEIS experiment", grouped[data["Eligible"]] <> " OEIS sequences along a space-filling curve; the " <> grouped[represented] <> " in blue have a program",
			Pane[halfSize[ImageResize[mapImage, 2 First[tileSize]]], tileSize, Alignment -> Center]]
	}, 3]
];

(* 2. Well-known sequences, each with the program found for it. *)
famous = {{"A000040", "Primes"}, {"A000045", "Fibonacci numbers"}, {"A000108", "Catalan numbers"},
	{"A000005", "Number of divisors"}, {"A010060", "Thue\[Dash]Morse sequence"}, {"A000166", "Derangements"}};
termsLine[terms_List, limit_Integer] := Module[{line = ""},
	Do[If[StringLength[line] + StringLength[term] + 2 > limit, Break[]]; line = line <> term <> ", ", {term, terms}];
	line <> "\[Ellipsis]"];
sequenceTile[{id_, title_}] := framed[Column[{
	Row[{styled[title, 13.5, ink, Bold], styled["   " <> id, 10, muted]}],
	styled[termsLine[gallery[id]["Terms"], 56], 10.5, muted],
	treeBox[program[id], {First[tileSize], 258}]}, Alignment -> Left, Spacings -> 0.3]];
design[2] := (
	If[! AllTrue[famous[[All, 1]], gallery[#]["Track"] === "p20" &], fail["a shown program is not from the twenty-term protocol"]];
	Column[{board[sequenceTile /@ famous, 3], legend[],
		note["Each program was found by search from the first twenty terms of its OEIS sequence and reproduces every later recorded term.", 900]},
		Alignment -> Center, Spacings -> 1.1]);

(* 3. The whole experiment in one picture. *)
design[3] := Column[{
	halfSize[ImageResize[mapImage, Scaled[3], Resampling -> "Nearest"]],
	mapLegend[],
	note["Each cell is one of the " <> grouped[data["Eligible"]] <> " eligible OEIS sequences, placed in A-number order along a space-filling curve. " <>
		"Programs were found by search from the first twenty terms.", 900]},
	Alignment -> Center, Spacings -> 1.1];

(* 4. One sequence through the paclet: terms, program, lambda term, further terms. *)
design[4] := Module[{found = synthesis[], size = {352, 250}, header, terms, arrow},
	header[function_, text_] := Row[{styled[function, 12.5, ink, Bold], styled["  " <> text, 10.5, muted]}];
	terms = Graphics[Table[With[{n = 4 r + c}, {
			Text[styled[ToString[found["Given"][[n + 1]]], 32], {c, -r + 0.12}],
			Text[styled[IntegerString[n, 2, 4], 9.5, muted], {c, -r - 0.33}]}], {r, 0, 3}, {c, 0, 3}],
		PlotRange -> {{-0.75, 3.75}, {-3.62, 0.62}}, ImageSize -> size, AspectRatio -> Full, PlotRangePadding -> None, ImagePadding -> None];
	arrow = Graphics[{GrayLevel[0.55], AbsoluteThickness[1.6], Arrowheads[0.4], Arrow[{{0, 0}, {1, 0}}]}, ImageSize -> {30, 16}, PlotRange -> {{-0.1, 1.1}, {-0.3, 0.3}}];
	Column[{
		Grid[{
			{header["Sixteen terms", "1s in the binary digits of 0 to 15"], "",
				header["SynthesizeRecursor", "finds a " <> ToString[RecursorNodeCount[found["Program"]]] <> "-node program"], "",
				header["CompileRecursor", "gives a closed lambda term"]},
			{framed[terms], arrow, framed[treeBox[found["Program"], size]], arrow,
				framed[Pane[fit[LambdaDiagram[CompileRecursor[found["Program"]]], size - {20, 20}], size, Alignment -> Center]]}},
			Alignment -> {Left, Center}, Spacings -> {0.7, 0.5}],
		Column[{header["EvaluateRecursor", "continues the sequence: 240 further terms, each equal to the true count"],
			framed[predictionPlot[{3 First[size] + 2 44 + 37, 176}, 256, 3.4]]}, Alignment -> Left, Spacings -> 0.5]},
		Alignment -> Left, Spacings -> 1.3]
];

(* 5. A forest: every core sequence of the snapshot whose program reproduces all its recorded terms. *)
shortNames = <|"A000004" -> "zeros", "A000005" -> "divisor count", "A000007" -> "0^n", "A000012" -> "ones", "A000027" -> "positive integers",
	"A000032" -> "Lucas", "A000035" -> "parity", "A000040" -> "primes", "A000045" -> "Fibonacci", "A000079" -> "2^n", "A000085" -> "involutions",
	"A000108" -> "Catalan", "A000120" -> "binary weight", "A000123" -> "binary partitions", "A000124" -> "lazy caterer", "A000129" -> "Pell",
	"A000142" -> "factorial", "A000166" -> "derangements", "A000203" -> "divisor sum", "A000204" -> "Lucas from 1", "A000217" -> "triangular",
	"A000225" -> "2^n \[Minus] 1", "A000244" -> "3^n", "A000272" -> "labeled trees", "A000290" -> "squares", "A000292" -> "tetrahedral", "A000302" -> "4^n",
	"A000326" -> "pentagonal", "A000330" -> "square pyramidal", "A000578" -> "cubes", "A000583" -> "fourth powers", "A000984" -> "central binomial",
	"A001003" -> "little Schr\[ODoubleDot]der", "A001006" -> "Motzkin", "A001045" -> "Jacobsthal", "A001147" -> "(2n \[Minus] 1)!!", "A001227" -> "odd divisors",
	"A001333" -> "Pell\[Dash]Lucas", "A001405" -> "middle binomial", "A001477" -> "integers from 0", "A001511" -> "ruler", "A001519" -> "F(2n \[Minus] 1)",
	"A001700" -> "C(2n + 1, n + 1)", "A001764" -> "ternary trees", "A001906" -> "F(2n)", "A002275" -> "repunits", "A002378" -> "oblong",
	"A002426" -> "central trinomial", "A002530" -> "A002530", "A002531" -> "A002531", "A002620" -> "quarter-squares", "A002808" -> "composites",
	"A004526" -> "floor(n/2)", "A005408" -> "odd numbers", "A005811" -> "binary runs", "A005843" -> "even numbers", "A006318" -> "large Schr\[ODoubleDot]der",
	"A006882" -> "double factorial", "A010060" -> "Thue\[Dash]Morse", "A018252" -> "nonprimes", "A070939" -> "binary length"|>;
design[5] := Module[{ids = Keys[gallery], columns = 13, rows = 5, cell, cells, mark, slots, grid},
	If[Sort[ids] =!= Sort[Keys[shortNames]], fail["the short names do not cover the validated core sequences"]];
	cell[id_] := Column[{glyphTree[program[id], {84, 66}], Pane[styled[shortNames[id], 8.5, muted], {88, Automatic}, Alignment -> Center]},
		Alignment -> Center, Spacings -> 0.2];
	mark = Column[{styled["Recursor", 42, ink, Bold], styled[ToString[Length[ids]] <> " core OEIS sequences, each as a program", 10.5, muted]}, Alignment -> Center, Spacings -> 0.4];
	(* the wordmark takes the three middle cells; the trees fill the rest in A-number order *)
	slots = DeleteCases[Tuples[{Range[rows], Range[columns]}], {3, 6 | 7 | 8}];
	If[Length[slots] < Length[ids], fail["the forest has too few cells"]];
	grid = ConstantArray["", {rows, columns}];
	MapThread[(grid[[Sequence @@ #1]] = cell[#2]) &, {Take[slots, Length[ids]], Sort[ids]}];
	grid[[3, 6]] = Item[mark, Alignment -> {Center, Center}]; grid[[3, 7]] = SpanFromLeft; grid[[3, 8]] = SpanFromLeft;
	Column[{Grid[grid, Spacings -> {0.25, 1.1}, Alignment -> {Center, Top}], legend[True, 10.5],
		note["The " <> ToString[Length[ids]] <> " core sequences of the OEIS snapshot with a program that reproduces every recorded term.\n" <>
			"Each program was found by search from the first 8 or 20 terms; each dot is a node of its syntax tree.", 900]},
		Alignment -> Center, Spacings -> 1.1]
];

(* ==================== output ==================== *)

drawHero[number_Integer, file_String] := Module[{image},
	If[! MemberQ[Range[5], number], fail["expected a design from 1 to 5"]];
	image = UsingFrontEnd[Rasterize[Pane[design[number], ImageMargins -> 14], LightDark -> "Light", ImageResolution -> 144, Background -> White]];
	If[! ImageQ[image], fail["could not render design " <> ToString[number]]];
	If[! StringQ[Export[file, image, "PNG"]], fail["could not write " <> file]];
	Print["Wrote ", file, ": design ", number, ", ", ImageDimensions[image], " pixels"]
];
End[];
