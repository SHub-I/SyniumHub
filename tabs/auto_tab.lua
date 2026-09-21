-- tabs/auto_tab.lua
return function(Window, rank, Exclusions, tabName)
    local HttpService = game:GetService("HttpService")
    local owner, repo, branch = "SHub-I", "SyniumHub", "main"
    local baseRaw = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(owner, repo, branch)
    local apiTree = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1"):format(owner, repo, branch)

    local function httpGet(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        return ok and res or nil, res
    end

    local function safeStr(v)
        if type(v) == "string" then return v end
        if type(v) == "table" then
            local ok, json = pcall(function() return HttpService:JSONEncode(v) end)
            if ok and type(json) == "string" then return json end
        end
        return tostring(v)
    end

    local function listScriptsForTab(name)
        local ok, apiRes = httpGet(apiTree)
        if not ok or not apiRes then return {} end
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(apiRes) end)
        if not ok2 or not decoded or type(decoded.tree) ~= "table" then return {} end
        local prefix = ("scripts/%s/"):format(name)
        local out = {}
        for _, entry in ipairs(decoded.tree) do
            if entry.type == "blob" and entry.path:sub(1, #prefix) == prefix and entry.path:match("%.lua$") then
                table.insert(out, entry.path)
            end
        end
        table.sort(out)
        return out
    end

    local function fetchRaw(path)
        local url = baseRaw .. path .. "?ts=" .. tostring(os.time())
        local ok, res = httpGet(url)
        if not ok or not res or #res == 0 then
            warn("Failed to fetch", url, res)
            return nil
        end
        if res:match("^%s*<!DOCTYPE") or res:match("^%s*404") then
            warn("Non-lua response for", url, (res:sub(1,200):gsub("\n","\\n")))
            return nil
        end
        return res
    end

    local function compileAndWrap(content, path)
        local ok, fn = pcall(function() return loadstring(content) end)
        if not ok or type(fn) ~= "function" then
            return nil, ("compile failed for %s -> %s"):format(path, safeStr(fn))
        end

        local registeredName, registeredCallback
        local env = {
            Register = function(name, callback)
                if type(name) ~= "string" or type(callback) ~= "function" then
                    error("Register expects (string, function)")
                end
                registeredName, registeredCallback = name, callback
            end,
            print = print,
            pcall = pcall,
            pairs = pairs,
            ipairs = ipairs,
            string = string,
            table = table,
            math = math,
            os = { time = os.time },
            wait = task.wait or wait
        }

        if setfenv then
            setfenv(fn, env)
        end

        local ok2, ret = pcall(function() return fn() end)
        if not ok2 then
            return nil, ("execute failed for %s -> %s"):format(path, safeStr(ret))
        end

        if registeredCallback and type(registeredCallback) == "function" then
            return { Name = registeredName or path, Run = registeredCallback }, nil
        end

        if type(ret) == "table" and type(ret.Run) == "function" then
            return { Name = (type(ret.Name) == "string" and ret.Name) or path, Run = ret.Run }, nil
        end

        if type(ret) == "function" then
            local fileName = path:match("([^/]+)$") or path
            local display = fileName:gsub("%.lua$", ""):gsub("_", " "):gsub("^%l", string.upper)
            return { Name = display, Run = ret }, nil
        end

        return nil, ("no registration or return value from %s"):format(path)
    end

    tabName = tostring(tabName or "universal")
    local Tab = Window:CreateTab((tabName:gsub("^%l", string.upper)), 4483345998)
    Tab:CreateSection((tabName:gsub("^%l", string.upper) .. " Scripts"))

    local scripts = listScriptsForTab(tabName)
    if #scripts == 0 then
        Tab:CreateLabel({ Text = "No scripts found in scripts/" .. tabName .. "/" })
        return
    end

    for _, path in ipairs(scripts) do
        local content = fetchRaw(path)
        if not content then
            Tab:CreateLabel({ Text = safeStr(("Missing: %s"):format(path)) })
        else
            local mod, err = compileAndWrap(content, path)
            if not mod then
                Tab:CreateLabel({ Text = safeStr(("Error loading %s"):format(path)) })
                warn("Script load error:", safeStr(err))
            else
                if type(mod.Run) ~= "function" then
                    Tab:CreateLabel({ Text = safeStr(("Invalid script (no runnable) %s"):format(mod.Name)) })
                    warn("Script has no runnable function:", safeStr(mod))
                else
                    Tab:CreateButton({
                        Name = mod.Name,
                        Callback = function()
                            local ok, runErr = pcall(mod.Run)
                            if not ok then warn(("Script %s runtime error: %s"):format(mod.Name, safeStr(runErr))) end
                        end
                    })
                end
            end
        end
    end
end
