-- main.lua (Rayfield Gen2, GitHub-powered Synium Hub)
local HttpService = game:GetService("HttpService")
local REPO = "SHub-I/SyniumHub"
local SCRIPTS_PATH = "scripts"

-- Rayfield Gen2 stable loader (Sirius)
local RAYFIELD_URL = "https://sirius.menu/gen2"

-- Tabs you always want visible (even if GitHub hides empty folders)
local FORCED_TABS = { "brookhaven", "mm2", "ftap", "universal" }

local function api(path) return "https://api.github.com/repos/"..REPO.."/contents/"..path end
local function raw(path) return "https://raw.githubusercontent.com/"..REPO.."/main/"..path end

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res then return nil end
    return res
end

local function getJSON(url)
    local res = safeGet(url)
    if not res then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok then return nil end
    return decoded
end

local function getFolders()
    local data = getJSON(api(SCRIPTS_PATH))
    if not data or type(data) ~= "table" then
        local copy = {}
        for _, v in ipairs(FORCED_TABS) do table.insert(copy, v) end
        table.sort(copy)
        return copy
    end
    local out = {}
    for _, item in ipairs(data) do if item.type == "dir" then table.insert(out, item.name) end end
    local seen = {}
    for _, v in ipairs(out) do seen[v] = true end
    for _, v in ipairs(FORCED_TABS) do if not seen[v] then table.insert(out, v) end end
    table.sort(out)
    return out
end

local function getScripts(folder)
    local data = getJSON(api(SCRIPTS_PATH .. "/" .. folder))
    if not data or type(data) ~= "table" then return {} end
    local out = {}
    for _, item in ipairs(data) do
        if item.type == "file" and item.name:match("%.lua$") then table.insert(out, item.name) end
    end
    table.sort(out)
    return out
end

local function fetchScript(folder, file)
    return safeGet(raw(SCRIPTS_PATH .. "/" .. folder .. "/" .. file))
end

-- compile: returns table { Name=string, Description=string?, Icon=string|number?, Run=function }
local function compile(code, id)
    if type(code) ~= "string" then return nil end
    local ok, fn = pcall(function() return loadstring(code) end)
    if not ok or type(fn) ~= "function" then return nil end

    local regName, regFn, metaDesc, metaIcon
    local env = {
        Register = function(name, fnc)
            if type(name) == "string" and type(fnc) == "function" then regName, regFn = name, fnc end
        end,
        Description = nil,
        Icon = nil,
        print = print, warn = warn, tostring = tostring,
        string = string, table = table, math = math,
        os = { time = os.time }, wait = task.wait
    }

    if setfenv then pcall(setfenv, fn, env) end

    local ok2, ret = pcall(fn)
    if not ok2 then return nil end

    -- If Register was used
    if regFn then
        return { Name = regName or id, Description = env.Description, Icon = env.Icon, Run = regFn }
    end

    -- If script returned a function
    if type(ret) == "function" then
        return { Name = id, Description = env.Description, Icon = env.Icon, Run = ret }
    end

    -- If script returned a table with Run
    if type(ret) == "table" and type(ret.Run) == "function" then
        return { Name = ret.Name or id, Description = ret.Description, Icon = ret.Icon, Run = ret.Run }
    end

    return nil
end

-- Load Rayfield Gen2
local Rayfield = nil
do
    local loader = safeGet(RAYFIELD_URL)
    if loader then
        local ok, lib = pcall(function() return loadstring(loader)() end)
        if ok and lib then Rayfield = lib end
    end
end

-- Fallback stub so UI code never crashes
if not Rayfield then
    Rayfield = {
        CreateWindow = function() 
            return {
                CreateTab = function() 
                    return {
                        CreateSection = function() end,
                        CreateGroup = function() return { CreateButton = function() end, CreateSection = function() end } end,
                        CreateButton = function() end,
                        CreateLabel = function() end,
                        Select = function() end
                    }
                end,
                CreateSection = function() end,
                Notify = function() end,
                ChangeTheme = function() end,
                Save = function() return false end,
                Load = function() return false end,
                Navigate = function() end
            }
        end
    }
end

-- Create window (sidebarLayout true by default for rail)
local Window = Rayfield.CreateWindow({
    name = "Synium Hub",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
    theme = "default",
    configuration = { enabled = false }
})

-- Helper: safe add button using Rayfield API variants
local function addButtonToGroup(group, mod, folder)
    local ok, err = pcall(function()
        -- Rayfield Gen2 uses CreateButton with name/callback
        if group.CreateButton then
            group:CreateButton({
                name = mod.Name or ("script:"..(mod.Name or folder)),
                description = mod.Description or "",
                icon = mod.Icon or 0,
                callback = function() pcall(mod.Run) end
            })
        else
            -- older API fallback
            group:AddButton({
                Name = mod.Name or ("script:"..(mod.Name or folder)),
                Callback = function() pcall(mod.Run) end
            })
        end
    end)
    if not ok then warn("Failed to add button:", err) end
end

-- Build tabs
for _, folder in ipairs(getFolders()) do
    local okTab, err = pcall(function()
        local tabName = (folder and #folder>0) and (folder:sub(1,1):upper() .. folder:sub(2)) or folder
        local Tab = Window:CreateTab({ name = tabName or "Unknown", icon = 93364949241311 })
        Tab:CreateSection({ name = (tabName or "Unknown") .. " Scripts", icon = 93364949241311 })

        -- two-column grid
        local grid = Tab:CreateGroup({})
        local left = grid:CreateGroup({ direction = "column" })
        local right = grid:CreateGroup({ direction = "column" })

        local scripts = {}
        local ok, res = pcall(function() return getScripts(folder) end)
        if ok and type(res) == "table" then scripts = res end

        if #scripts == 0 then
            Tab:CreateLabel({ name = "No scripts found" })
            -- placeholder button so tab isn't empty
            Tab:CreateButton({
                name = "Placeholder: add scripts/"..folder,
                description = "Add a .lua file to this folder on GitHub",
                callback = function() print("No scripts in folder:", folder) end
            })
        else
            for i, file in ipairs(scripts) do
                local code = fetchScript(folder, file)
                local id = file:gsub("%.lua$", "")
                local mod = compile(code, id)
                if mod then
                    local target = (i % 2 == 1) and left or right
                    addButtonToGroup(target, mod, folder)
                else
                    Tab:CreateLabel({ name = "Failed to load: " .. id })
                end
            end
        end
    end)
    if not okTab then warn("Error building tab for folder:", folder, err) end
end

-- Example usage of window methods (exposed for scripts to call)
-- Window:Navigate("Brookhaven") -- navigate by name
-- Window:ChangeTheme("ember") -- change theme at runtime
-- Window:Save() -- save config (if enabled)
-- Window:Load() -- load config (if enabled)

-- If Rayfield has an Init or similar, call it safely
pcall(function() if Window.Init then Window.Init() end end)
