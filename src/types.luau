--!strict
local types = {}

-- we use string instead of buffer because only 2 things are done with it:
--	1. written and read from file
--	2. HTTP transmission
export type Bytecode = string

export type CompilationResult = 
	{ success: true, bytecode: Bytecode } | { success: false, error: string }

return types
