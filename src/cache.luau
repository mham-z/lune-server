--!strict
--[[
	The purpose in life of this module is to provide
	safe functions for the caching system
]]--

local CACHE_DIR = "cache/"
local FILE_FORMAT = CACHE_DIR.."%s.luauc"
local MAX_CACHE_SIZE_BYTES = 50 * 1024 * 1024

local cache = {}

local filesystem = require("@lune/fs")
local types = require("./types")

if not filesystem.isDir(CACHE_DIR) then
	filesystem.writeDir(CACHE_DIR)
end

local function getFileSize(path: string): number? -- in bytes
	local success, result: string? = pcall(filesystem.readFile, path)

	if success and typeof(result) == "string" then
		return #result
	end

	return nil
end

function cache.autoClean(): ()
	local readDir_success, files = pcall(filesystem.readDir, CACHE_DIR)
	if not (readDir_success and files) then
		return
	end

	local cached = {}
	local totalSize = 0

	for _, name in files do
		local fullPath = CACHE_DIR..name
		local metadata_Success, metadata = pcall(filesystem.metadata, fullPath)
		
		if not (metadata_Success and metadata) then
			print("Cache auto-clean : File", fullPath, "metadata could not be retrieved")
			continue
		end

		local size = getFileSize(fullPath)
		if not size then
			print("Cache auto-clean : File", fullPath, "could not be read")
			continue
		end

		totalSize += size
		table.insert(cached, {
			path = fullPath;
			size = size;
			createdAt = metadata.createdAt;
		})
	end

	if totalSize <= MAX_CACHE_SIZE_BYTES then
		return
	end

	print("Cache auto-clean : Now purging files!")
	
	table.sort(cached, function(a, b)
		return a.createdAt < b.createdAt
	end)
	
	for _, fileInfo in cached do
		if totalSize <= MAX_CACHE_SIZE_BYTES then
			break
		end

		print("Cache auto-clean : Removing", fileInfo.path)
		
		local removeSuccess = pcall(filesystem.removeFile, fileInfo.path)
		if removeSuccess then
			totalSize = totalSize - fileInfo.size
			print("Cache auto-clean : Removed", fileInfo.path, "successfully")
		end
	end

	print("Cache auto-clean : Done")
end

function cache.isFile(name: string): boolean
	local cachePath = FILE_FORMAT:format(name)

	if filesystem.isFile(cachePath) then
		return true
	end

	return false
end

function cache.read(name: string): types.Bytecode?
	local cachePath = FILE_FORMAT:format(name)

	local success, result: string? = pcall(filesystem.readFile, cachePath)
	if success and typeof(result) == "string" then
		return result :: types.Bytecode
	end

	return nil
end

function cache.write(name: string, bytecode: types.Bytecode): boolean
	local cachePath = FILE_FORMAT:format(name)
	
	local success, result = pcall(filesystem.writeFile, cachePath, bytecode)
	if not success then
		print(name, ":", "Cache write failure >>>", result)	
	end

	return success
end

return cache