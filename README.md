An API to compile Luau and return bytecode \
Needs:
- rokit
- lune

If you send a POST request with the script source code, the server will return the compiled bytecode. \
If you send a GET request with a script name (like https://example.com?name=helloworld.luau), the server will return the compiled bytecode of a file named that in the scripts directory. 

A MD5 hash of every source code recieved by the compiler is made and the code's resultant bytecode is cached. The cache auto-cleans if a size limit is ever hit.

---

Usage on server:
```sh
auth="secret" ./start
```
This starts the server along with a cloudflare tunnel

---

### Usage via curl
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
You can then try Lune's [luau.load](https://lune-org.github.io/docs/api-reference/luau/#load) on the resulting bytecode.

---

### Usage via Roblox
- POST:
	```lua
	local ADDRESS = "<address>"
	local SECRET = "secret"
	local HttpService = game:GetService("HttpService")

	local function compile(sourceCode)
		local success, response = pcall(function()
		return HttpService:RequestAsync {
				Url = ADDRESS;
				Method = "POST";
				Headers = {["Authorization"] = SECRET; ["Content-Type"] = "text/plain"};
				Body = sourceCode;
			}
		end)

		if success then
			return response
		else
			warn("Failure: ", response)
		end
	end

	compile("print(\"Hello world!\")")
	```
- GET:
	```lua
	local ADDRESS = "<address>"
	local SECRET = "secret"
	local HttpService = game:GetService("HttpService")

	local function compileFile(scriptName)
		local success, response = pcall(function()
			return HttpService:RequestAsync {
				Url = ADDRESS.."/?name="..HttpService:UrlEncode(scriptName);
				Method = "GET";
				Headers = {["Authorization"] = SECRET};
			}
		end)

		if success then
			return response
		else
			warn("Failure: ", response)
		end
	end

	compileFile("helloworld.luau")
	```
You can then straight up send this to [Fiu](https://github.com/rce-incorporated/Fiu), [Splice](https://github.com/malice-nz/Splice), or any other applicable bytecode interpreter to run it.