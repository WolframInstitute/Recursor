(* Explicit migration helpers for a clean notebook kernel. New code uses the
   operation-first APIs; no aliases are created by Needs alone. *)
Needs["WolframInstitute`Recursor`"]

Global`CompileProgram = CompileRecursor
Global`WellFormedQ = RecursorExpressionQ
Global`ValidProgramQ = RecursorProgramQ
Global`ParseProgramText = ParseRecursor
Global`NodeCount = RecursorNodeCount
Global`SimplifyProgram = SimplifyRecursor
Global`ProgramTree = RecursorProgramTree

Global`InterpretProgram[program_, input_] := EvaluateRecursor[program, input,
	"MaxSteps" -> Infinity, "TimeLimit" -> Infinity, "MemoryLimit" -> Infinity
]

Global`EvalProgram[program_, input_, cap_ : 2000, seconds_ : 0.4] :=
	EvaluateRecursor[program, input, "MaxSteps" -> cap, "TimeLimit" -> seconds]

Global`Mutate[program_, depth_ : 3, constant_ : 1] :=
	MutateRecursor[program, depth, "MaxConstant" -> constant]

Global`Crossover[left_, right_] := CrossoverRecursor[left, right]

Global`NormalizeProgram[program_, cap_ : 5000, fuel_ : 5000000, depth_ : 1500] :=
	NormalizeRecursor[program, "MaxSteps" -> Min[cap, fuel]]
