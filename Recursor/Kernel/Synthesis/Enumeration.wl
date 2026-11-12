PackageScoped[{synthesisConstantCost, synthesisClasses, synthesisVectorValue, synthesisVectorFunction, $synthesisVectorOperations, synthesisOffer, synthesisEarlier,
	synthesisHalved, synthesisAffineProgram, synthesisAffineCost}]

(* Bottom-up enumeration up to observational equivalence. One program is kept
   for each distinct vector of values on the observed inputs, so a level holds
   the distinct functions of one cost rather than every syntax tree. *)

(* Constants 0..3 cost one node; every further two bits cost one more. *)
synthesisConstantCost[c_Integer] := If[Abs[c] <= 3, 1, 1 + Ceiling[(BitLength[Abs[c]] - 2) / 2]]

totalRemainder[x_, y_] := Mod[x, y + (1 - Unitize[y]) (x + 1)]
totalQuotient[x_, y_] := Quotient[x, y + (1 - Unitize[y]) (x + 1)]

(* Value of a loop-free expression on arrays of inputs. Both branches of Ifz
   are evaluated, which is sound because loop-free expressions are total. *)
synthesisVectorValue[Var, e_] := e["Input"]
synthesisVectorValue[Acc, e_] := e["Accumulator"]
synthesisVectorValue[Idx, e_] := e["Index"]
synthesisVectorValue[Const[c_], _] := c
(* Placeholders in recurrence steps: a(i-k) and a(floor(i/2)). *)
synthesisVectorValue[synthesisEarlier[k_], e_] := e["Earlier"][[k]]
synthesisVectorValue[synthesisHalved, e_] := e["Halved"]
synthesisVectorValue[Succ[a_], e_] := synthesisVectorValue[a, e] + 1
synthesisVectorValue[Pred[a_], e_] := Ramp[synthesisVectorValue[a, e] - 1]
synthesisVectorValue[Half[a_], e_] := Quotient[synthesisVectorValue[a, e], 2]
synthesisVectorValue[Add[a_, b_], e_] := synthesisVectorValue[a, e] + synthesisVectorValue[b, e]
synthesisVectorValue[Mul[a_, b_], e_] := synthesisVectorValue[a, e] synthesisVectorValue[b, e]
synthesisVectorValue[Monus[a_, b_], e_] := Ramp[synthesisVectorValue[a, e] - synthesisVectorValue[b, e]]
synthesisVectorValue[Rem[a_, b_], e_] := totalRemainder[synthesisVectorValue[a, e], synthesisVectorValue[b, e]]
synthesisVectorValue[Quot[a_, b_], e_] := totalQuotient[synthesisVectorValue[a, e], synthesisVectorValue[b, e]]
synthesisVectorValue[Ifz[c_, z_, p_], e_] := With[{nonzero = Unitize[synthesisVectorValue[c, e]]},
	(1 - nonzero) synthesisVectorValue[z, e] + nonzero synthesisVectorValue[p, e]
]

(* A loop-free expression in Var, Acc and Idx as one function of their arrays.
   The expression is translated once to array arithmetic, so a loop that
   applies it many times pays for the arithmetic only. *)
$synthesisVectorOperations = {Succ -> (# + 1 &), Pred -> (Ramp[# - 1] &), Half -> (Quotient[#, 2] &), Add -> Plus, Mul -> Times, Monus -> (Ramp[#1 - #2] &),
	Rem -> totalRemainder, Quot -> totalQuotient, Ifz -> (With[{nonzero = Unitize[#1]}, (1 - nonzero) #2 + nonzero #3] &)}

synthesisVectorFunction[expression_] := synthesisVectorFunction[expression] = Function @@ {
	expression /. {Var -> Slot[1], Acc -> Slot[2], Idx -> Slot[3], Const[c_] :> c} /. $synthesisVectorOperations
}

(* Keep the cheaper of two candidates; ties keep the earlier one. *)
synthesisOffer[None, candidate_] := candidate
synthesisOffer[best_, candidate_] := If[candidate["Cost"] < best["Cost"], candidate, best]

(* c1 x + c0 with truncated subtraction for negative constants. *)
synthesisAffineProgram[x_, c1_, c0_] := affineProgram[x, c1, c0]
synthesisAffineCost[c1_, c0_] := affineCost[c1, c0]
affineProgram[x_, c1_, c0_] := With[{scaled = If[Abs[c1] === 1, x, Mul[Const[Abs[c1]], x]]},
	Which[
		c1 > 0 && c0 > 0, Add[scaled, Const[c0]],
		c1 > 0 && c0 < 0, Monus[scaled, Const[-c0]],
		c1 > 0, scaled,
		True, Monus[Const[c0], scaled]
	]
]
affineCost[c1_, c0_] := If[Abs[c1] === 1, 0, 1 + synthesisConstantCost[c1]] + If[c0 === 0, 0, 1 + synthesisConstantCost[c0]]

(* The shape of a loop body: its operations as one function of its leaves,
   which are numbered in reading order, and the leaves themselves. Bodies of
   one shape differ only in which of Var, Acc, Idx or a constant each leaf is. *)
bodyShape[body_] := bodyShape[body] = Module[{count = 0, leaves = {}},
	{Function @@ {body /. leaf : (Var | Acc | Idx | _Const) :> (AppendTo[leaves, leaf]; Slot[++count]) /. $synthesisVectorOperations}, leaves}
]

(* Loop bodies run for many loops at once. counts, bases and inputs are the
   loops laid end to end, width values each. All bodies of one shape advance
   together: a leaf is a matrix with one row per body, so a step of the group
   costs the arithmetic of one body. A loop whose values pass the cap stops
   and is marked with cap + 1, which keeps the arrays machine integers.
   Gives the values as bodies x loops x width. *)
loopValues[bodies_List, counts_, bases_, inputs_, width_, cap_] := Module[{
	shapes = bodyShape /@ bodies, groups, result = ConstantArray[0, Length[bodies]], length = Length[counts], top = Max[counts]
},
	groups = GroupBy[Range[Length[bodies]], shapes[[#, 1]] &];
	KeyValueMap[
		Function[{step, members},
			Module[{size = Length[members], leaves = Transpose[shapes[[members, 2]]], fixed, onAccumulator, onIndex, accumulator, live, t = 0, running, over},
				(* each leaf as a fixed part plus the accumulator or the index where the body reads them *)
				fixed = Map[Replace[#, {Var -> inputs, Const[c_] :> ConstantArray[c, length], _ -> ConstantArray[0, length]}] &, leaves, {2}];
				onAccumulator = Map[Boole[# === Acc] &, leaves, {2}];
				onIndex = Map[Boole[# === Idx] &, leaves, {2}];
				accumulator = ConstantArray[bases, size];
				live = ConstantArray[counts, size];
				While[t < top,
					running = UnitStep[live - t - 1];
					accumulator += running (step @@ MapThread[#1 + #2 accumulator + #3 t &, {fixed, onAccumulator, onIndex}] - accumulator);
					If[Max[accumulator] > cap,
						over = Unitize[Total[ArrayReshape[UnitStep[accumulator - cap - 1], {size, Quotient[length, width], width}], {3}]];
						over = ArrayReshape[Transpose[ConstantArray[over, width], {3, 1, 2}], {size, length}];
						live = (1 - over) live;
						accumulator = Developer`ToPackedArray[(1 - over) accumulator + over (cap + 1)];
						top = Max[live]
					];
					t++
				];
				result[[members]] = Partition[#, width] & /@ accumulator
			]
		],
		groups
	];
	result
]

(* leaves: {{expression, vector}, ...}. goal: a vector, or None to enumerate
   only. loops: None, or bodies by cost with the inputs they are run on.
   judge[expression, cost] gives the candidate for an expression that matches
   the goal, or None to reject it. Every matching candidate is judged, also
   one whose class is already stored, because equal values on the observed
   positions need not mean equal total cost. Leaf vectors may be longer than
   the goal: the extra columns only keep classes apart.
   Returns the cheapest candidate, the cheapest few of all candidates met,
   and the stored expressions and vectors by cost. *)
synthesisClasses[leaves_List, goal_, maximum_Integer, deadline_, loops_, affineQ_, judge_] := Module[{
	expressions = <||>, vectors = <||>, seen = <||>, conditions = <||>, patterns = <||>, best = None, matches = {}, candidates = 0,
	cap, differences, pivot, admit, pairs, ternary, loop, closure, join, offer, width = If[goal === None, 0, Length[goal]]
},
	offer[candidate_] := (
		best = synthesisOffer[best, candidate];
		matches = Append[matches, candidate];
		If[Length[matches] > 48, matches = Take[SortBy[matches, #["Cost"] &], 16]]
	);
	cap = If[goal === None, 2^40, Max[2^40, 16 Max[goal]]];
	differences = If[goal === None, {}, Differences[goal]];
	pivot = If[affineQ, First[FirstPosition[differences, _?(# =!= 0 &), {0}, {1}, Heads -> False]], 0];
	(* rows that become the goal after a scale and a shift, all tested at once *)
	closure[cost_, rows_, made_] := If[Length[First[rows]] === width,
		Module[{step = rows[[All, pivot + 1]] - rows[[All, pivot]], at, c1, c0, good},
			at = Pick[Range[Length[rows]], Unitize[step] (1 - Unitize[Mod[differences[[pivot]], step + (1 - Unitize[step])]]), 1];
			If[at =!= {},
				c1 = Quotient[differences[[pivot]], step[[at]]];
				c0 = First[goal] - c1 rows[[at, 1]];
				good = Pick[Range[Length[at]],
					(1 - Unitize[Total[Unitize[Transpose[c1 (rows[[at, 2 ;;]] - rows[[at, ;; -2]])] - differences]]]) *
						(1 - (1 - Unitize[c1 - 1]) (1 - Unitize[c0])) Unitize[UnitStep[c1 - 1] + UnitStep[c0 - 1]], 1];
				Scan[
					offer[<|"Cost" -> cost + affineCost[c1[[#]], c0[[#]]], "Expression" -> affineProgram[made[[at[[#]]]], c1[[#]], c0[[#]]], "Method" -> "Affine"|>] &,
					good
				]
			]
		]
	];
	admit[cost_, rows_, build_] := Module[{keep, first, fresh, indices, new, made},
		candidates += Length[rows];
		keep = If[rows === {}, {}, Pick[Range[Length[rows]], UnitStep[cap - (Max /@ rows)], 1]];
		If[keep =!= {} && goal =!= None,
			Do[
				With[{candidate = judge[First[build[{keep[[at]]}]], cost]},
					If[candidate =!= None, offer[candidate]]
				],
				{at, Flatten[Position[rows[[keep, ;; width]], goal, {1}]]}
			]
		];
		If[keep =!= {},
			first = AssociationThread[Reverse[rows[[keep]]], Reverse[keep]];
			fresh = KeySelect[first, ! KeyExistsQ[seen, #] &];
			If[Length[fresh] > 0,
				indices = Sort[Values[fresh]];
				new = rows[[indices]];
				made = build[indices];
				AssociateTo[seen, Thread[new -> True]];
				expressions[cost] = Join[Lookup[expressions, cost, {}], made];
				vectors[cost] = Join[Lookup[vectors, cost, {}], new];
				(* the first row of every new zero pattern serves as a condition *)
				With[{keys = Unitize[new]},
					With[{mixed = Pick[Range[Length[new]], Unitize[Total[keys, {2}]] Unitize[Total[1 - keys, {2}]], 1]},
						With[{fresh = Select[DeleteDuplicatesBy[mixed, keys[[#]] &], ! KeyExistsQ[patterns, keys[[#]]] &]},
							If[fresh =!= {},
								AssociateTo[patterns, Thread[keys[[fresh]] -> True]];
								conditions[cost] = Join[Lookup[conditions, cost, {}], Transpose[{new[[fresh]], made[[fresh]]}]]
							]
						]
					]
				];
				If[goal =!= None && pivot > 0, closure[cost, new, made]]
			]
		]
	];
	pairs[s_, i_, j_] := Module[{a = Lookup[vectors, i, {}], b = Lookup[vectors, j, {}], ea, eb, m, k, ia, ib, x, y, upper},
		If[a =!= {} && b =!= {},
			ea = expressions[i]; eb = expressions[j]; m = Length[a]; k = Length[b];
			ia = Flatten[Transpose[ConstantArray[Range[m], k]]];
			ib = Flatten[ConstantArray[Range[k], m]];
			x = a[[ia]]; y = b[[ib]];
			upper = If[i === j, Pick[Range[m k], UnitStep[ib - ia], 1], Range[m k]];
			admit[s, (x + y)[[upper]], Function[at, MapThread[Add, {ea[[ia[[upper[[at]]]]]], eb[[ib[[upper[[at]]]]]]}]]];
			admit[s, (x y)[[upper]], Function[at, MapThread[Mul, {ea[[ia[[upper[[at]]]]]], eb[[ib[[upper[[at]]]]]]}]]];
			admit[s, Ramp[x - y], Function[at, MapThread[Monus, {ea[[ia[[at]]]], eb[[ib[[at]]]]}]]];
			admit[s, totalRemainder[x, y], Function[at, MapThread[Rem, {ea[[ia[[at]]]], eb[[ib[[at]]]]}]]];
			admit[s, totalQuotient[x, y], Function[at, MapThread[Quot, {ea[[ia[[at]]]], eb[[ib[[at]]]]}]]];
			If[i =!= j,
				admit[s, Ramp[y - x], Function[at, MapThread[Monus, {eb[[ib[[at]]]], ea[[ia[[at]]]]}]]];
				admit[s, totalRemainder[y, x], Function[at, MapThread[Rem, {eb[[ib[[at]]]], ea[[ia[[at]]]]}]]];
				admit[s, totalQuotient[y, x], Function[at, MapThread[Quot, {eb[[ib[[at]]]], ea[[ia[[at]]]]}]]]
			]
		]
	];
	(* Only the zero pattern of a condition matters, so one condition per
	   pattern is enough. *)
	ternary[s_, i_, j_, k_] := Module[{tests = Lookup[conditions, i, {}], z = Lookup[vectors, j, {}], p = Lookup[vectors, k, {}], ez, ep, m, n, iz, ip, x, y, distinct},
		If[tests =!= {} && z =!= {} && p =!= {},
			ez = expressions[j]; ep = expressions[k]; m = Length[z]; n = Length[p];
			iz = Flatten[Transpose[ConstantArray[Range[m], n]]];
			ip = Flatten[ConstantArray[Range[n], m]];
			distinct = If[j === k, Pick[Range[m n], Unitize[iz - ip], 1], Range[m n]];
			If[distinct =!= {},
				x = Transpose[z[[iz[[distinct]]]]]; y = Transpose[p[[ip[[distinct]]]]];
				Do[
					With[{nonzero = Unitize[First[test]], condition = Last[test]},
						admit[s, Transpose[(1 - nonzero) x + nonzero y],
							Function[at, MapThread[Ifz[condition, #1, #2] &, {ez[[iz[[distinct[[at]]]]]], ep[[ip[[distinct[[at]]]]]]}]]]
					],
					{test, tests}
				]
			]
		]
	];
	(* Iter[count, base, step] and Rec[count, base, step]: count and base are
	   stored classes, step a loop body that reads Acc. *)
	loop[s_] := Do[
		With[{sb = s - 1 - sc - sa},
			If[1 <= sb <= loops["MaxBody"],
				(* every count, base and body: the loops of one body are run together *)
				Module[{counts = Lookup[vectors, sc, {}], bases = Lookup[vectors, sa, {}], bodies = Lookup[loops["Bodies"], sb, {}],
						pick, m, n, k, wide = Length[loops["Inputs"]]},
					pick = Select[Range[Length[counts]], ! SameQ @@ counts[[#]] && Max[counts[[#]]] <= 64 &];
					{m, n, k} = {Length[pick], Length[bases], Length[bodies]};
					If[m n k > 0,
						With[{
								allCounts = Flatten[counts[[Flatten[Transpose[ConstantArray[pick, n]]]]]],
								allBases = Flatten[ConstantArray[bases, m]],
								allInputs = Flatten[ConstantArray[loops["Inputs"], m n]]},
							admit[s,
								Flatten[Transpose[loopValues[bodies, allCounts, allBases, allInputs, wide, cap]], 1],
								Function[at, Map[
									With[{c = Quotient[# - 1, n k] + 1, a = Mod[Quotient[# - 1, k], n] + 1, body = bodies[[Mod[# - 1, k] + 1]]},
										If[FreeQ[body, Idx], Iter, Rec][expressions[sc][[pick[[c]]]], expressions[sa][[a]], body]] &,
									at]]
							]
						]
					]
				]
			]
		],
		{sc, 1, 2}, {sa, 1, 2}
	];
	(* Two stored classes joined at the root. The goal fixes one operand once
	   the other is chosen, so a lookup replaces the product of all pairs and a
	   match may cost up to twice the enumerated maximum. *)
	join[] := Module[{costs = Sort[Keys[vectors]], rows, made, levels, index, count, target, complete, positive},
		rows = Join @@ (vectors[#][[All, ;; width]] & /@ costs);
		made = Join @@ (expressions /@ costs);
		levels = Join @@ (ConstantArray[#, Length[vectors[#]]] & /@ costs);
		count = Length[rows];
		index = Association[Reverse[Thread[rows -> Range[count]]]];
		target = ConstantArray[goal, count];
		positive = Min[goal] > 0;
		(* partners[[k]] is the stored class that completes the k-th picked row, or zero *)
		complete[head_, picked_, partners_, swapQ_] := With[{found = Pick[Transpose[{picked, partners}], Unitize[partners], 1]},
			Do[
				With[{candidate = judge[If[swapQ, head[made[[Last[pair]]], made[[First[pair]]]], head[made[[First[pair]]], made[[Last[pair]]]]],
						levels[[First[pair]]] + levels[[Last[pair]]] + 1]},
					If[candidate =!= None, offer[candidate]]
				],
				{pair, Take[SortBy[found, levels[[First[#]]] + levels[[Last[#]]] &], UpTo[64]]}
			]
		];
		With[{rest = target - rows},
			With[{picked = Pick[Range[count], UnitStep[Min /@ rest], 1]},
				If[picked =!= {}, complete[Add, picked, Lookup[index, rest[[picked]], 0], False]]
			]
		];
		With[{picked = Pick[Range[count], Unitize[Min /@ rows], 1]},
			If[picked =!= {},
				With[{exact = Pick[picked, Unitize[Total /@ Mod[target[[picked]], rows[[picked]]]], 0]},
					If[exact =!= {}, complete[Mul, exact, Lookup[index, Quotient[target[[exact]], rows[[exact]]], 0], False]]
				]
			]
		];
		If[positive,
			complete[Monus, Range[count], Lookup[index, target + rows, 0], True];
			With[{rest = rows - target},
				With[{picked = Pick[Range[count], UnitStep[Min /@ rest], 1]},
					If[picked =!= {}, complete[Monus, picked, Lookup[index, rest[[picked]], 0], False]]
				]
			]
		]
	];
	admit[1, leaves[[All, 2]], leaves[[#, 1]] &];
	Do[
		If[(best =!= None && s >= best["Cost"]) || AbsoluteTime[] > deadline, Break[]];
		With[{a = Lookup[vectors, s - 1, {}], e = Lookup[expressions, s - 1, {}]},
			If[a =!= {},
				admit[s, a + 1, Succ /@ e[[#]] &];
				admit[s, Ramp[a - 1], Pred /@ e[[#]] &];
				admit[s, Quotient[a, 2], Half /@ e[[#]] &]
			]
		];
		Do[If[i <= s - 1 - i, pairs[s, i, s - 1 - i]], {i, 1, s - 2}];
		Do[ternary[s, i, j, s - 1 - i - j], {i, 1, s - 3}, {j, 1, s - 2 - i}];
		If[loops =!= None, loop[s]],
		{s, 2, maximum}
	];
	If[goal =!= None && best === None && width > 1 && AbsoluteTime[] <= deadline, join[]];
	(* The local functions refer to one another and to the tables, which would
	   keep all of them alive after the call. Clearing them frees the memory. *)
	With[{result = <|"Best" -> best, "Matches" -> Take[DeleteDuplicatesBy[SortBy[matches, #["Cost"] &], #["Expression"] &], UpTo[12]],
			"Expressions" -> expressions, "Vectors" -> vectors, "Candidates" -> candidates|>},
		Remove[closure, admit, pairs, ternary, loop, join, offer];
		seen = conditions = patterns = expressions = vectors = matches = Null;
		result
	]
]
