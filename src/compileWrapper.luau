--!strict
--[[
	The purpose in life of this module is to return
	a cached version of source code if it already exists
	or compile it otherwise
	Also handles doing the same with the scripts directory
]]--

local SCRIPTS_DIR = "scripts/"

local compileWrapper = {}

local luau = require("@lune/luau")
local filesystem = require("@lune/fs")
local serde = require("@lune/serde")

local types = require("./types")
local cache = require("./cache")

function compileWrapper.compile(sourceCode: string): types.CompilationResult
		local hash = serde.hash("md5", sourceCode)
	
	local cached =
		if cache.isFile(hash) then
			cache.read(hash)
		else nil

	if cached then
		print(hash, ":", "Found in cache")
		return {
			success = true;
			bytecode = cached :: types.Bytecode;
		}
	end

	print(hash, ":", "Compiling")
	local success, result = pcall(function()
		return luau.compile(sourceCode)
	end)

	if not success then
		print(hash, ":", "Fail")

		result = tostring(result)
		return {
			success = false;
			error = string.match(result, "(.-)%s*stack traceback:") or result; -- remove stack traceback to hide project root dir because its unnecessary
		}
	end

	if cache.write(hash, result) then
		print(hash, ":", "Successfully written to cache")
	end

	print(hash, ":", "Compile successful")
	cache.autoClean()

	return {
		success = true;
		bytecode = result;
	}
end

-- returns nil if there is an issue getting the file
function compileWrapper.getFile(scriptName: string): types.CompilationResult | nil
	local scriptDir = SCRIPTS_DIR..scriptName

	if not pcall(filesystem.isFile, scriptDir) then
		return nil
	end

	local success, result = pcall(filesystem.readFile, scriptDir)
	if not success then
		return nil
	end

	return compileWrapper.compile(result)
end

return compileWrapper