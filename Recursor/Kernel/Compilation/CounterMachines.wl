(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)

PackageExported[ToRecursor]

(* ::Section:: *)
(*Usage Messages*)

ToRecursor::usage = "ToRecursor[instructions] translates increment/decrement-jump instructions to a closed Recursor program. \
Input initializes register 1; output is its final value.\n\
ToRecursor[code, \"PartialRecursive\"] translates a partial-recursive code."

counterInstructionQ::usage = "counterInstructionQ[instruction, halt] gives True when instruction is {register, 0, {target}} or \
{register, 1, {positive}, {zero}} with a positive register and jump addresses of at most halt, and False otherwise."

counterMachineQ::usage = "counterMachineQ[instructions] gives True when instructions is a list of counter-machine instructions whose jump addresses \
are at most one more than the length of the list, and False otherwise."

quotientLoop::usage = "quotientLoop[expression, divisor] gives a Recursor expression for the integer quotient of expression by the positive integer divisor."

powerLoop::usage = "powerLoop[base, exponent] gives a Recursor expression for the positive integer base raised to the value of the expression exponent."

instructionStep::usage = "instructionStep[instruction, radix] gives a Recursor expression for the machine state after instruction, where Acc holds \
the state before it. A state is radix times the product of prime powers that holds the registers, plus the address of the next instruction."

addressBranch::usage = "addressBranch[otherwise, address, instruction, radix] gives a Recursor expression that takes the step of instruction when the \
state in Acc is at address, and has the value of otherwise at any other address."

dispatchStep::usage = "dispatchStep[instructions, radix] gives a Recursor expression for one step of the machine: the step of the instruction at \
the address of the state in Acc."

(* ::Section:: *)
(*Function Definitions*)

counterInstructionQ[{register_Integer?Positive, 0, {target_Integer?Positive}}, halt_Integer] := target <= halt
counterInstructionQ[{register_Integer?Positive, 1, {positive_Integer?Positive}, {zero_Integer?Positive}}, halt_Integer] := Max[positive, zero] <= halt
counterInstructionQ[_, _] := False

counterMachineQ[instructions_List] := AllTrue[instructions, counterInstructionQ[#, Length[instructions] + 1] &]
counterMachineQ[___] := False

(* Quotient and prime valuation are macros in the original bounded language. *)
quotientLoop[expression_?RecursorExpressionQ, divisor_Integer?Positive] := Rec[expression, Const[0],
	Ifz[Rem[Succ[Idx], Const[divisor]], Succ[Acc], Acc]
]

powerLoop[base_Integer?Positive, exponent_?RecursorExpressionQ] := Iter[exponent, Const[1], Mul[Const[base], Acc]]

instructionStep[{register_Integer, 0, {target_Integer}}, radix_Integer] :=
	Add[Mul[Const[radix * Prime[register]], quotientLoop[Acc, radix]], Const[target]]
instructionStep[{register_Integer, 1, {positive_Integer}, {zero_Integer}}, radix_Integer] :=
	Module[{payload, registerPrime},
		payload = quotientLoop[Acc, radix];
		registerPrime = Prime[register];
		Ifz[Rem[payload, Const[registerPrime]],
			Add[Mul[Const[radix], quotientLoop[payload, registerPrime]], Const[positive]],
			Add[Mul[Const[radix], payload], Const[zero]]
		]
	]

addressBranch[otherwise : (Acc | _Ifz), address_Integer, instruction_List, radix_Integer] :=
	Module[{counter},
		counter = Rem[Acc, Const[radix]];
		Ifz[Add[Monus[counter, Const[address]], Monus[Const[address], counter]], instructionStep[instruction, radix], otherwise]
	]

dispatchStep[instructions_List, radix_Integer] := Fold[
	Function[{otherwise, address}, addressBranch[otherwise, address, instructions[[address]], radix]],
	Acc,
	Reverse[Range[Length[instructions]]]
]

ToRecursor[instructions_?counterMachineQ] :=
	Module[{halt, radix, finalState},
		halt = Length[instructions] + 1;
		radix = Length[instructions] + 2;
		finalState = WhileLoop[
			Add[Mul[Const[radix], powerLoop[2, Var]], Const[1]],
			Monus[Const[halt], Rem[Acc, Const[radix]]],
			dispatchStep[instructions, radix]
		];
		(* Save the final payload at history index zero so the output decoder cannot
		   capture its accumulator or repeat the simulated machine. *)
		CoRec[Const[1], Ifz[Idx,
			quotientLoop[finalState, radix],
			Rec[CGet[Const[0]], Const[0], Ifz[Rem[CGet[Const[0]], powerLoop[2, Succ[Idx]]], Succ[Idx], Acc]]
		]]
	]

(* PartialRecursive.wl adds the definition for partial-recursive codes and repeats this catch-all. *)
ToRecursor[___] := invalidArgumentsFailure[ToRecursor]
