local net = require("@lune/net")
local luau = require("@lune/luau")

print("Lune compilation server starting on port 8080...")

net.serve(8080, function(request)
    -- Only allow POST requests
    if request.method ~= "POST" then
        return {
            status = 405,
            body = "Method Not Allowed"
        }
    end

    local sourceCode = request.body
    if not sourceCode or sourceCode == "" then
        return {
            status = 400,
            body = "Missing source code in request body"
        }
    end

    -- Compile the string to bytecode
    -- Wrap in pcall to catch syntax errors gracefully
    local success, result = pcall(function()
        return luau.compile(sourceCode)
    end)

    if not success then
        return {
            status = 400,
            body = "Compilation Error: " .. tostring(result)
        }
    end

    -- Return the raw binary bytecode string
    return {
        status = 200,
        headers = { ["Content-Type"] = "application/octet-stream" },
        body = result
    }
end)

