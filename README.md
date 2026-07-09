An API to compile Luau and return bytecode \
Needs:
- rokit
- lune

If you send a POST request with the script source code, the server will return the compiled bytecode. \
If you send a GET request with a script name (like https://example.com?name=helloworld.luau), the server will return the compiled bytecode of a file named that in the scripts directory. 

---

Usage on server:
```sh
auth="secret" ./start
```
This starts the server along with a Pinggy tunnel

---

Usage via curl:
- POST:
	```sh
	curl -X POST <address> \
		-H "Content-Type: text/plain" \
		-H "Authorization: secret" \
		--data-binary "print(\"Hello world!\")"\
		-o a.luauc
	```
- GET:
	```sh
	curl -X GET "<address>?name=helloworld.luau" \
		-H "Authorization: secret"
		-o a.luauc
	```
---

Usage via Roblox:
- POST:
	```lua
	local function compile(sourceCode)
		local success, response = pcall(function()
		return game:GetService("HttpService"):RequestAsync({
				Url = "<address>",
				Method = "POST",
				Headers = { ["Authorization"] = "secret", ["Content-Type"] = "text/plain" },
				Body = sourceCode
			})
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
- GET:
	```lua
	local HttpService = game:GetService("HttpService")

	local function compileFile(scriptName)
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = "<address>".."?name="..HttpService:UrlEncode(scriptName),
				Method = "GET",
				Headers = {["Authorization"] = "secret"}
			})
		end)

		if success then
			return response
		else
			warn("Failure: ", response)
		end
	end

	compileFile("helloworld.luau")
	```