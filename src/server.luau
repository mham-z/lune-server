local process = require("@lune/process")
local net = require("@lune/net")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local PORT = tonumber(process.env.PORT) or 8080
local AUTH = process.env.AUTH
local MAX_PAYLOAD_SIZE = 300 * 1024
local SHORT_HASH_LENGTH = 64
local CACHE_DIR = "cache/"
local MAX_CACHE_SIZE_BYTES = 50 * 1024 * 1024

local function checkAndCleanCache()
	local success, files = pcall(fs.readDir, CACHE_DIR)
	if not success or not files then
		return
	end

	local cacheEntries = {}
	local totalCurrentSize = 0

	for _, fileName in files do
		local fullPath = CACHE_DIR..fileName
		local metaSuccess, meta = pcall(fs.metadata, fullPath)
		
		if metaSuccess and meta and meta.size and meta.createdAt then
			totalCurrentSize = totalCurrentSize + meta.size
			table.insert(cacheEntries, {
				path = fullPath;
				size = meta.size;
				createdAt = meta.createdAt;
			})
		end
	end

	if totalCurrentSize <= MAX_CACHE_SIZE_BYTES then
		return
	end

	print("\nAttempting to purge files to clean cache")
	
	table.sort(cacheEntries, function(a, b)
		return a.createdAt < b.createdAt
	end)
	
	for _, fileInfo in cacheEntries do
		if totalCurrentSize <= MAX_CACHE_SIZE_BYTES then
			break
		end

		print("Removing", fileInfo.path)
		
		local removeSuccess = pcall(fs.removeFile, fileInfo.path)
		if removeSuccess then
			totalCurrentSize = totalCurrentSize - fileInfo.size
		end
	end

	print("Done\n")
end


local function compile(sourceCode)
	local uuid = serde.hash("md5", sourceCode)
	local shortHash = string.sub(uuid, 1, SHORT_HASH_LENGTH)
	local cachePath = CACHE_DIR .. shortHash .. ".luauc"

	if fs.isFile(cachePath) then
		print(uuid, ":", "Found in cache")
		local readSuccess, cachedBytecode = pcall(fs.readFile, cachePath)
		if readSuccess and cachedBytecode then
			print(uuid, ":", "Success, read from cache")
			return {
				status = 200;
				headers = {["Content-Type"] = "application/octet-stream"};
				body = cachedBytecode;
			}
		end
	end

	print(uuid, ":", "Compiling")
	local success, result = pcall(function()
		return luau.compile(sourceCode)
	end)

	if not success then
		print(uuid, ":", "Fail")
		local error = string.match(tostring(result), "(.-)%s*stack traceback:") or tostring(result)
		return {status = 422; body = error}
	end

	pcall(fs.writeFile, cachePath, result)
	print(uuid, ":", "Success, saved to cache")

	pcall(checkAndCleanCache)

	return {
		status = 200;
		headers = {["Content-Type"] = "application/octet-stream"};
		body = result;
	}
end

net.serve(PORT, function(request)
	if not AUTH or AUTH == "" then
		return {status = 503; body = "Authentication was not properly set up!"}
	end

	local clientToken = request.headers["authorization"]
	if clientToken ~= AUTH then
		return {status = 401; body = "Unauthorized"}
	end

	if request.method == "POST" then
		local sourceCode = request.body
		if not sourceCode or sourceCode == "" then
			return {status = 400; body = "No source code provided"}
		end
		if string.len(sourceCode) > MAX_PAYLOAD_SIZE then
			return {status = 413; body = "Max payload size: "..MAX_PAYLOAD_SIZE}
		end

		return compile(sourceCode)
	elseif request.method == "GET" then
		local scriptName = request.query["name"]

		if not scriptName or scriptName == "" or not string.match(scriptName, "^[%w%-_]+%.?%w*$") or string.find(scriptName, "%.%.") then
			return {status = 400; body = "Invalid filename"}
		end

		local filePath = "scripts/" .. scriptName

		if not fs.isFile(filePath) then
			return {status = 404; body = "File not found"..scriptName}
		end

		local success, sourceCode = pcall(fs.readFile, filePath)
		if not success or not sourceCode or sourceCode == "" then
			return {status = 500; body = "Failed to read script file"}
		end

		return compile(sourceCode)
	end

	return {status = 405; body = "Not allowed"}
end)

if not fs.isDir(CACHE_DIR) then
	fs.writeDir(CACHE_DIR)
end

print("Lune compilation server started on port", PORT)