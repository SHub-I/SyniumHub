-- main.lua

-- Orion boot (from your docs)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- Create window
local Window = OrionLib:MakeWindow({
    Name = "Synium Hub",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false
})

-- Helpers
local function getFolders()
    if not listfiles then return {} end
    local out = {}
    for _, path in ipairs(listfiles("scripts")) do
        local folder = path:match("scripts/(.-)$")
        if folder and isfolder("scripts/" .. folder) then
            table.insert(out, folder)
        end
    end
    table.sort(out)
    return out
end

local function getScripts(folder)
    if not listfiles then return {} end
    local out = {}
    for _, path in ipairs(listfiles("scripts/" .. folder)) do
        if path:match("%.lua$") then
            table.insert(out, path)
        end
    end
    table.sort(out)
    return out
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

-- Build UI from scripts/
for _, folder in ipairs(getFolders()) do
    local tabName = folder:sub(1,1):upper() .. folder:sub(2)
    local Tab = Window:MakeTab({
        Name = tabName,
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    Tab:AddSection(tabName .. " Scripts")

    local scripts = getScripts(folder)
    if #scripts == 0 then
        Tab:AddLabel("No scripts found")
    end

    for _, path in ipairs(scripts) do
        local raw = readfile(path)
        local id = path:match("([^/]+)%.lua$") or path

        if not raw then
            Tab:AddLabel("Missing: " .. id)
        else
            local mod = compile(raw, id)
            if not mod then
                Tab:AddLabel("Failed: " .. id)
            else
                Tab:AddButton({
                    Name = mod.Name,
                    Callback = function()
                        pcall(mod.Run)
                    end
                })
            end
        end
    end
end

-- REQUIRED (from your docs)
OrionLib:Init()
