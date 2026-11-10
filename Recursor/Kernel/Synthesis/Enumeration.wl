PackageScoped[{synthesisConstantCost, synthesisClasses, synthesisVectorValue, synthesisOffer, synthesisEarlier, synthesisHalved}]

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

(* Keep the cheaper of two candidates; ties keep the earlier one. *)
synthesisOffer[None, candidate_] := candidate
synthesisOffer[best_, candidate_] := If[candidate["Cost"] < best["Cost"], candidate, best]

(* c1 x + c0 with truncated subtraction for negative constants. *)
affineProgram[x_, c1_, c0_] := With[{scaled = If[Abs[c1] === 1, x, Mul[Const[Abs[c1]], x]]},
	Which[
		c1 > 0 && c0 > 0, Add[scaled, Const[c0]],
		c1 > 0 && c0 < 0, Monus[scaled, Const[-c0]],
		c1 > 0, scaled,
		True, Monus[Const[c0], scaled]
	]
]
affineCost[c1_, c0_] := If[Abs[c1] === 1, 0, 1 + synthesisConstantCost[c1]] + If[c0 === 0, 0, 1 + synthesisConstantCost[c0]]

bodyValues[body_, counts_, bases_, inputs_, cap_] := Module[{accumulator = bases, t = 0, top = Max[counts]},
	While[t < top && Max[accumulator] <= cap,
		accumulator = With[{running = UnitStep[counts - t - 1]},
			running synthesisVectorValue[body, <|"Input" -> inputs, "Accumulator" -> accumulator, "Index" -> t|>] + (1 - running) accumulator
		];
		t++
	];
	accumulator
]

(* leaves: {{expression, vector}, ...}. goal: a vector, or None to enumerate
   only. loops: None, or bodies by cost with the inputs they are run on.
   judge[expression, cost] gives the candidate for an expression that matches
   the goal, or None to reject it. Every matching candidate is judged, also
   one whose class is already stored, because equal values on the observed
   positions need not mean equal total cost. Leaf vectors may be longer than
   the goal: the extra columns only keep classes apart.
   Returns the cheapest candidate and the stored expressions by cost. *)
synthesisClasses[leaves_List, goal_, maximum_Integer, deadline_, loops_, affineQ_, judge_] := Module[{
	expressions = <||>, vectors = <||>, seen = <||>, conditions = <||>, patterns = <||>, best = None, candidates = 0,
	cap, differences, pivot, admit, pairs, ternary, loop, closure, width = If[goal === None, 0, Length[goal]]
},
	cap = If[goal === None, 2^40, Max[2^40, 16 Max[goal]]];
	differences = If[goal === None, {}, Differences[goal]];
	pivot = If[affineQ, First[FirstPosition[differences, _?(# =!= 0 &), {0}, {1}, Heads -> False]], 0];
	closure[cost_, rows_, made_] := Do[
		With[{step = rows[[r, pivot + 1]] - rows[[r, pivot]]},
			If[step =!= 0 && Divisible[differences[[pivot]], step],
				With[{c1 = Quotient[differences[[pivot]], step]},
					With[{c0 = First[goal] - c1 rows[[r, 1]]},
						If[c1 Differences[rows[[r]]] === differences && ! (c1 === 1 && c0 === 0) && (c1 > 0 || c0 > 0),
							best = synthesisOffer[best, <|"Cost" -> cost + affineCost[c1, c0], "Expression" -> affineProgram[made[[r]], c1, c0], "Method" -> "Affine"|>]
						]
					]
				]
			]
		],
		{r, Length[rows]}
	];
	admit[cost_, rows_, build_] := Module[{keep, first, fresh, indices, new, made},
		candidates += Length[rows];
		keep = If[rows === {}, {}, Pick[Range[Length[rows]], UnitStep[cap - (Max /@ rows)], 1]];
		If[keep =!= {} && goal =!= None,
			Do[
				With[{candidate = judge[First[build[{keep[[at]]}]], cost]},
					If[candidate =!= None, best = synthesisOffer[best, candidate]]
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
				Do[
					With[{key = Unitize[new[[r]]]},
						If[! KeyExistsQ[patterns, key] && 0 < Total[key] < Length[key],
							patterns[key] = True;
							conditions[cost] = Append[Lookup[conditions, cost, {}], {new[[r]], made[[r]]}]
						]
					],
					{r, Length[new]}
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
				Module[{rows = {}, made = {}},
					Do[
						If[! SameQ @@ vectors[sc][[c]] && Max[vectors[sc][[c]]] <= 64,
							Do[
								AppendTo[rows, bodyValues[body, vectors[sc][[c]], vectors[sa][[a]], loops["Inputs"], cap]];
								AppendTo[made, If[FreeQ[body, Idx], Iter, Rec][expressions[sc][[c]], expressions[sa][[a]], body]],
								{a, Length[Lookup[vectors, sa, {}]]}, {body, Lookup[loops["Bodies"], sb, {}]}
							]
						],
						{c, Length[Lookup[vectors, sc, {}]]}
					];
					admit[s, rows, made[[#]] &]
				]
			]
		],
		{sc, 1, 2}, {sa, 1, 2}
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
	<|"Best" -> best, "Expressions" -> expressions, "Candidates" -> candidates|>
]
