--!strict
--[[
	The purpose in life of this module
	is pretty self explanatory
]]--

local MAX_PAYLOAD_SIZE = 300 * 1024

local server = {}

local net = require("@lune/net")
local compileWrapper = require("./compileWrapper")

local serverAuth = ""

function server.setAuth(auth: string): ()
	serverAuth = auth
end

function server.start(port: number, handler: (net.ServeRequest) -> net.ServeResponse): net.ServeHandle
	print("Lune compilation server starting on port", port)
	return net.serve(port, handler)
end

function server.handleRequest(request: net.ServeRequest): net.ServeResponse
	if request.headers["authorization"] ~= serverAuth then
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
end

return server