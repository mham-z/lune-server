local process = require("@lune/process")
local net = require("@lune/net")
local luau = require("@lune/luau")

local PORT = tonumber(process.env.PORT) or 8080
local AUTH_KEY = process.env.auth
local MAX_PAYLOAD_SIZE = 1 * 1024 * 1024

local function generate_uuid()
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
		return string.format('%x', v)
	end)
end

local function compile(sourceCode)
	local uuid = generate_uuid()
	print(uuid, ":", "Compiling")

	local success, result = pcall(function()
		return luau.compile(sourceCode)
	end)

	if not success then
		print(uuid, ":", "Fail")
		local error = string.match(tostring(result), "(.-)%s*stack traceback:") or tostring(result)
		return {
			status = 200,
			body = "-- COMPILE ERROR --\n" .. error
		}
	end

	print(uuid, ":", "Success")
	return {
		status = 200,
		headers = { ["Content-Type"] = "application/octet-stream" },
		body = result
	}
end

net.serve(PORT, function(request)
	if not AUTH_KEY or AUTH_KEY == "" then
		return {
			status = 500;
			body = "Internal Server Error";
		}
	end

	local clientToken = request.headers["authorization"]
	if clientToken ~= AUTH_KEY then
		return {
			status = 401;
			body = "Unauthorized";
		}
	end

	if request.method ~= "POST" then
		return {
			status = 405;
			body = "Method Not Allowed";
		}
	end

	local sourceCode = request.body
	if not sourceCode or sourceCode == "" then
		return {
			status = 400;
			body = "Bad Request";
		}
	end
	if string.len(sourceCode) > MAX_PAYLOAD_SIZE then
		return {
			status = 413;
			body = "Max payload size: "..MAX_PAYLOAD_SIZE;
		}
	end

	return compile(sourceCode)
end)

print("Lune compilation server started on port", PORT)