--!strict
local process = require("@lune/process")

local server = require("./server")

local PORT = tonumber(process.env.PORT) or 8080
local AUTH = process.env.AUTH

if not AUTH or AUTH == "" or string.match(AUTH, "%S") == nil then
	return error("AUTH env var not set!", 0)
end

server.setAuth(AUTH)
server.start(PORT, server.handleRequest)