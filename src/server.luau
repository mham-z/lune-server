--!strict
local process = require("@lune/process")
local net = require("@lune/net")

local compileWrapper = require("./compileWrapper")

local PORT = tonumber(process.env.PORT) or 8080
local AUTH = process.env.AUTH
local MAX_PAYLOAD_SIZE = 300 * 1024

if not AUTH or AUTH == "" or string.match(AUTH, "%S") == nil then
	return error("AUTH env var not set!", 0)
end

net.serve(PORT, function(request)
	if request.headers["authorization"] ~= AUTH then
		return {status = 401; body = "Unauthorized"}
	end

	if request.method == "POST" then
		local sourceCode = request.body
		if not sourceCode or sourceCode == "" then
			return {status = 400; body = "No source code provided"}
		end
		if #sourceCode > MAX_PAYLOAD_SIZE then
			return {status = 413; body = "Max payload size: "..MAX_PAYLOAD_SIZE}
		end

		local compileResult = compileWrapper.compile(sourceCode)
		if compileResult.success then
			return {
				status = 200;
				headers = {["Content-Type"] = "application/octet-stream"};
				body = compileResult.bytecode;
			}
		end

		return {
			status = 422;
			body = compileResult.error;
		}
	elseif request.method == "GET" then
		local scriptName = request.query["name"]

		if not scriptName or scriptName == "" or not string.match(scriptName, "^[%w%-_]+%.?%w*$") or string.find(scriptName, "%.%.") then
			return {status = 400; body = "Invalid filename"}
		end

		local compileResult = compileWrapper.getFile(scriptName)
		if not compileResult then
			return {status = 500; body = "Failed to read script file"}
		end

		if compileResult.success then
			return {
				status = 200;
				headers = {["Content-Type"] = "application/octet-stream"};
				body = compileResult.bytecode;
			}
		end

		return {
			status = 422;
			body = compileResult.error;
		}
	end

	return {status = 405; body = "Not allowed"}
end)

print("Lune compilation server started on port", PORT)