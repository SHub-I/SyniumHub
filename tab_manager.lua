-- tab_manager.lua (auto-populate fallback for empty tabs)
-- Defensive loader: safe remote loads, capture created Tab, auto-populate scripts if tab empty

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

local function safeLoadString(content, url)
    local ok, fn = pcall(function() return loadstring(content) end)
    if not ok or type(fn) ~= "function" then
        return false, ("compile failed for %s -> %s"):format(tostring(url), tostring(fn))
    end
    local ok2, ret = pcall(function() return fn() end)
    if not ok2 then
        return false, ("execute failed for %s -> %s"):format(tostring(url), tostring(ret))
    end
    return true, ret
end

local function fetchRaw(url)
    local ok, res = safeHttpGet(url)
    if not ok or not res or #res == 0 then
        return false, ("HttpGet failed for %s -> %s"):format(tostring(url), tostring(res))
    end
    if res:match("^%s*<!DOCTYPE") then
        return false, ("Remote returned HTML for %s"):format(url)
    end
    return true, res
end

local function safeLoadRemoteRaw(url)
    local ok, contentOrErr = fetchRaw(url .. "?ts=" .. tostring(os.time()))
    if not ok then return false, contentOrErr end
    return safeLoadString(contentOrErr, url)
end

local function safeLoadRemoteModule(path)
    local url = base .. path
    local ok, modOrErr = safeLoadRemoteRaw(url)
    if not ok then return nil, modOrErr end
    return modOrErr, nil
end

-- Load Rank and Exclusions with safe fallbacks
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

local tabs = {
    "universal",
    "ftap",
    "brookhaven",
    "mm2"
}

local function listScriptsForTab(tabName)
    local ok, apiRes = safeHttpGet(apiTree)
    if not ok or not apiRes then return {} end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(apiRes) end)
    if not ok2 or not decoded or not decoded.tree then return {} end
    local out = {}
    local prefix = ("scripts/%s/"):format(tabName)
    for _, entry in ipairs(decoded.tree) do
        if entry.type == "blob" and entry.path:sub(1, #prefix) == prefix then
            if entry.path:match("%.lua$") then
                table.insert(out, entry.path)
            end
        end
    end
    table.sort(out)
    return out
end

local function populateTabWithScripts(Tab, tabName)
    if not Tab or type(Tab.CreateSection) ~= "function" then return end
    local scripts = listScriptsForTab(tabName)
    if #scripts == 0 then return end

    Tab:CreateSection((tabName:gsub("^%l", string.upper) .. " Scripts"))
    for _, path in ipairs(scripts) do
        local fileName = path:match("([^/]+)$")
        local displayName = fileName:gsub("%.lua$", ""):gsub("_", " "):gsub("^%l", string.upper)
        pcall(function()
            Tab:CreateButton({
                Name = displayName,
                Callback = function()
                    local ok, contentOrErr = fetchRaw(base .. path)
                    if not ok then
                        warn("Failed to fetch script:", contentOrErr)
                        return
                    end
                    local ok2, fnOrErr = pcall(function() return loadstring(contentOrErr) end)
                    if not ok2 or type(fnOrErr) ~= "function" then
                        warn("Failed to compile script:", fnOrErr)
                        return
                    end
                    local ok3, retOrErr = pcall(function() return fnOrErr() end)
                    if not ok3 then
                        warn("Script execution error:", retOrErr)
                        return
                    end
                    if type(retOrErr) == "function" then
                        local ok4, err = pcall(function() retOrErr() end)
                        if not ok4 then warn("Script callback error:", err) end
                    end
                end
            })
        end)
    end
end

local function tabHasChildren(Tab)
    if not Tab then return false end
    if type(Tab.GetChildren) == "function" then
        local ok, children = pcall(function() return Tab:GetChildren() end)
        if ok and type(children) == "table" and #children > 0 then return true end
    end
    if Tab._sections and type(Tab._sections) == "table" and #Tab._sections > 0 then return true end
    return false
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
        local url = base .. path

        local originalCreateTab = Window.CreateTab
        local capturedTab = nil
        if type(originalCreateTab) == "function" then
            Window.CreateTab = function(...)
                local t = originalCreateTab(...)
                capturedTab = t
                return t
            end
        end

        local ok, contentOrErr = fetchRaw(url)
        if not ok then
            warn(("tab_manager: failed to fetch %s -> %s"):format(path, contentOrErr))
            if originalCreateTab then Window.CreateTab = originalCreateTab end
            goto continue
        end

        local ok2, modOrErr = safeLoadString(contentOrErr, path)
        if not ok2 then
            warn(("tab_manager: failed to load %s -> %s"):format(path, modOrErr))
            if originalCreateTab then Window.CreateTab = originalCreateTab end
            goto continue
        end

        local mod = modOrErr
        local calledOk, calledErr = pcall(function()
            if type(mod) == "function" then
                mod(Window, rank, Exclusions)
            elseif type(mod) == "table" then
                if type(mod.Load) == "function" then
                    mod:Load(Window, rank, Exclusions)
                elseif type(mod.Init) == "function" then
                    mod.Init(Window, rank, Exclusions)
                end
            else
                warn(("tab_manager: tab %s returned unsupported type: %s"):format(name, type(mod)))
            end
        end)
        if not calledOk then
            warn(("tab_manager: tab %s errored during execution -> %s"):format(name, tostring(calledErr)))
        end

        if originalCreateTab then Window.CreateTab = originalCreateTab end

        if capturedTab and not tabHasChildren(capturedTab) then
            pcall(function() populateTabWithScripts(capturedTab, name) end)
        end

        ::continue::
    end
end

return Manager
