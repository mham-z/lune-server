An API to compile Luau and return bytecode
Needs:
	- rokit
	- lune

Usage on server:
```sh
auth="secret" lune run server.luau
```

Usage via curl:
```sh
curl -X POST <address> \
	-H "Content-Type: text/plain" \
	-H "Authorization: secret" \
	--data-binary "print(\"Hello world!\")"\
	-o a.luauc
```

Usage via Roblox:
```lua
local function compile(sourceCode)
	local headers = {
		["Authorization"] = "secret",
		["Content-Type"] = "text/plain"
	}

	local success, response = pcall(function()
		return game:GetService("HttpService"):PostAsync("<address>", sourceCode, Enum.HttpContentType.ApplicationJson, false, headers)
	end)

	if success then
		return response
	else
		warn("Failure: ", response)
	end
end

compile("print(\"Hello world!\")")
-- you can then straight up send this to fiu or whatever to execute the bytecode (make sure its not nil!)
```