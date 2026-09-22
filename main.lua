-- main.lua (GitHub-powered Synium Hub)

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local REPO = "SHub-I/SyniumHub"
local SCRIPTS_PATH = "scripts"

local function api(path)
    return "https://api.github.com/repos/" .. REPO .. "/contents/" .. path
end

local function raw(path)
    return "https://raw.githubusercontent.com/" .. REPO .. "/main/" .. path
end

local function getJSON(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then return nil end

    local ok2, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(res)
    end)
    if not ok2 then return nil end

    return decoded
end

local function getFolders()
    local data = getJSON(api(SCRIPTS_PATH))
    if not data then return {} end

    local out = {}
    for _, item in ipairs(data) do
        if item.type == "dir" then
            table.insert(out, item.name)
        end
    end
    table.sort(out)
    return out
end

local function getScripts(folder)
    local data = getJSON(api(SCRIPTS_PATH .. "/" .. folder))
    if not data then return {} end

    local out = {}
    for _, item in ipairs(data) do
        if item.type == "file" and item.name:match("%.lua$") then
            table.insert(out, item.name)
        end
    end
    table.sort(out)
    return out
end

local function fetchScript(folder, file)
    return game:HttpGet(raw(SCRIPTS_PATH .. "/" .. folder .. "/" .. file))
end

local function compile(code, id)
    local ok, fn = pcall(function() return loadstring(code) end)
    if not ok or type(fn) ~= "function" then return nil end

    local regName, regFn
    local env = {
        Register = function(name, fnc)
            if type(name) == "string" and type(fnc) == "function" then
                regName, regFn = name, fnc
            end
        end,
        print = print, warn = warn,
        string = string, table = table, math = math,
        os = { time = os.time }, wait = task.wait
    }

    if setfenv then setfenv(fn, env) end

    local ok2, ret = pcall(fn)
    if not ok2 then return nil end

    if regFn then
        return { Name = regName or id, Run = regFn }
    end

    if type(ret) == "function" then
        return { Name = id, Run = ret }
    end

    if type(ret) == "table" and type(ret.Run) == "function" then
        return { Name = ret.Name or id, Run = ret.Run }
    end

    return nil
end

local Window = OrionLib:MakeWindow({
    Name = "Synium Hub",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false
})

for _, folder in ipairs(getFolders()) do
    local tabName = folder:sub(1,1):upper() .. folder:sub(2)
    local Tab = Window:MakeTab({
        Name = tabName,
        Icon = "rbxassetid://4483345998"
    })

    Tab:AddSection(tabName .. " Scripts")

    for _, file in ipairs(getScripts(folder)) do
        local code = fetchScript(folder, file)
        local id = file:gsub("%.lua$", "")
        local mod = compile(code, id)

        if mod then
            Tab:AddButton({
                Name = mod.Name,
                Callback = function()
                    pcall(mod.Run)
                end
            })
        else
            Tab:AddLabel("Failed: " .. id)
        end
    end
end

OrionLib:Init()
