-- tab_manager.lua (robust, verbose on failure, safe fallback)
local HttpService = game:GetService("HttpService")

local owner = "SHub-I"
local repo = "SyniumHub"
local branch = "main"
local base = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(owner, repo, branch)
local apiTree = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1"):format(owner, repo, branch)

local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    return ok, res
end

local function fetchRaw(url)
    local ok, res = safeHttpGet(url .. "?ts=" .. tostring(os.time()))
    if not ok then
        return false, ("HttpGet error for %s -> %s"):format(url, tostring(res))
    end
    if not res or #res == 0 then
        return false, ("Empty response for %s"):format(url)
    end
    if res:match("^%s*<!DOCTYPE") or res:match("^%s*404") then
        return false, ("Non-Lua response for %s -> %s"):format(url, (res:sub(1,200):gsub("\n","\\n")))
    end
    return true, res
end

local function compileRemote(content, url)
    local ok, fn = pcall(function() return loadstring(content) end)
    if not ok or type(fn) ~= "function" then
        return false, ("compile failed for %s -> %s\nFirst 400 chars: %s"):format(url, tostring(fn), tostring(content:sub(1,400):gsub("\n","\\n")))
    end
    local ok2, ret = pcall(function() return fn() end)
    if not ok2 then
        return false, ("execute failed for %s -> %s"):format(url, tostring(ret))
    end
    return true, ret
end

-- Safe loader that returns module or nil + error
local function safeLoadRemoteModule(path)
    local url = base .. path
    local ok, contentOrErr = fetchRaw(url)
    if not ok then return nil, contentOrErr end
    local ok2, modOrErr = compileRemote(contentOrErr, url)
    if not ok2 then return nil, modOrErr end
    return modOrErr, nil
end

-- Fallback Rank/Exclusions
local Rank = { GetRank = function() return "None" end }
local Exclusions = { IsExcluded = function() return false end }

do
    local mod, err = safeLoadRemoteModule("rank.lua")
    if mod and type(mod) == "table" then Rank = mod end
end
do
    local mod, err = safeLoadRemoteModule("rank_exclusions.lua")
    if mod and type(mod) == "table" then Exclusions = mod end
end

local Manager = {}
local tabs = { "universal", "ftap", "brookhaven", "mm2" }

-- Minimal hardcoded fallback script lists (used only if remote tab module fails)
local fallbackScripts = {
    universal = {
        { path = "scripts/universal/script1.lua", name = "Infinite Yield" },
        { path = "scripts/universal/script2.lua", name = "Universal Script 2" },
    },
    ftap = {
        { path = "scripts/ftap/script1.lua", name = "FTAP Script 1" },
        { path = "scripts/ftap/script2.lua", name = "FTAP Script 2" },
    },
    brookhaven = {
        { path = "scripts/brookhaven/script1.lua", name = "Brookhaven Script 1" },
        { path = "scripts/brookhaven/script2.lua", name = "Brookhaven Script 2" },
    },
    mm2 = {
        { path = "scripts/mm2/script1.lua", name = "MM2 Script 1" },
        { path = "scripts/mm2/script2.lua", name = "MM2 Script 2" },
    }
}

local function createButtonsFromList(Tab, list)
    if not Tab or type(Tab.CreateButton) ~= "function" then return end
    for _, s in ipairs(list) do
        pcall(function()
            Tab:CreateButton({
                Name = s.name,
                Callback = function()
                    local ok, content = safeHttpGet(base .. s.path .. "?ts=" .. tostring(os.time()))
                    if not ok or not content or #content == 0 then
                        warn("Failed to fetch", s.path, content)
                        return
                    end
                    local ok2, fn = pcall(function() return loadstring(content) end)
                    if not ok2 or type(fn) ~= "function" then
                        warn("Compile failed for", s.path, fn)
                        return
                    end
                    local ok3, ret = pcall(function() return fn() end)
                    if not ok3 then warn("Execute failed for", s.path, ret) return end
                    if type(ret) == "function" then pcall(ret) end
                end
            })
        end)
    end
end

function Manager:Load(Window)
    if not Window then
        warn("tab_manager: Load called without Window")
        return
    end

    local rank = "None"
    if type(Rank) == "table" and type(Rank.GetRank) == "function" then
        local ok, r = pcall(function() return Rank:GetRank() end)
        if ok and r then rank = r end
    end

    for _, name in ipairs(tabs) do
        local path = "tabs/" .. name .. ".lua"
        local mod, err = safeLoadRemoteModule(path)
        if not mod then
            warn(("tab_manager: failed to load %s -> %s"):format(path, tostring(err)))
            -- create a simple tab and populate from fallback list
            local ok, Tab = pcall(function() return Window:CreateTab((name:gsub("^%l", string.upper)), 4483345998) end)
            if ok and Tab then
                Tab:CreateSection((name:gsub("^%l", string.upper) .. " Scripts"))
                createButtonsFromList(Tab, fallbackScripts[name] or {})
            end
        else
            -- module loaded; call it safely
            local ok, callErr = pcall(function()
                if type(mod) == "function" then
                    mod(Window, rank, Exclusions)
                elseif type(mod) == "table" then
                    if type(mod.Load) == "function" then
                        mod:Load(Window, rank, Exclusions)
                    elseif type(mod.Init) == "function" then
                        mod.Init(Window, rank, Exclusions)
                    else
                        warn(("tab_manager: module %s returned table without Load/Init"):format(path))
                    end
                else
                    warn(("tab_manager: module %s returned unsupported type: %s"):format(path, type(mod)))
                end
            end)
            if not ok then
                warn(("tab_manager: tab %s errored during execution -> %s"):format(name, tostring(callErr)))
                -- fallback: create tab and populate
                local ok2, Tab = pcall(function() return Window:CreateTab((name:gsub("^%l", string.upper)), 4483345998) end)
                if ok2 and Tab then
                    Tab:CreateSection((name:gsub("^%l", string.upper) .. " Scripts"))
                    createButtonsFromList(Tab, fallbackScripts[name] or {})
                end
            end
        end
    end
end

return Manager
