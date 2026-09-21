-- tab_manager.lua
-- Robust manager that loads a single reusable tabs/auto_tab.lua module and invokes it for each tab.
-- Falls back to minimal UI if remote fetch/compile fails.

local HttpService = game:GetService("HttpService")

local OWNER = "SHub-I"
local REPO = "SyniumHub"
local BRANCH = "main"
local BASE_RAW = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(OWNER, REPO, BRANCH)
local API_TREE = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1"):format(OWNER, REPO, BRANCH)

local tabs = {
    "universal",
    "ftap",
    "brookhaven",
    "mm2"
}

-- Utility: safe http get
local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    return ok, res
end

-- Utility: convert value to safe string for UI labels/warnings
local function safeStr(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then
        local ok, json = pcall(function() return HttpService:JSONEncode(v) end)
        if ok and type(json) == "string" then return json end
    end
    return tostring(v)
end

-- Fetch raw content with cache-buster and basic HTML/404 detection
local function fetchRaw(url)
    local full = url .. "?ts=" .. tostring(os.time())
    local ok, res = safeHttpGet(full)
    if not ok then
        return false, ("HttpGet error for %s -> %s"):format(url, safeStr(res))
    end
    if not res or #res == 0 then
        return false, ("Empty response for %s"):format(url)
    end
    if res:match("^%s*<!DOCTYPE") or res:match("^%s*<html") or res:match("^%s*404") then
        return false, ("Non-Lua response for %s -> %s"):format(url, (res:sub(1,200):gsub("\n","\\n")))
    end
    return true, res
end

-- Compile a Lua chunk safely and return function or error
local function compileString(content, url)
    local ok, fn = pcall(function() return loadstring(content) end)
    if not ok or type(fn) ~= "function" then
        return false, ("compile failed for %s -> %s\nFirst 400 chars: %s"):format(url, safeStr(fn), safeStr(content:sub(1,400)))
    end
    return true, fn
end

-- Safe remote module loader that returns module value or nil + error
local function safeLoadRemoteModule(path)
    local url = BASE_RAW .. path
    local ok, contentOrErr = fetchRaw(url)
    if not ok then return nil, contentOrErr end
    local ok2, fnOrErr = compileString(contentOrErr, url)
    if not ok2 then return nil, fnOrErr end
    local ok3, retOrErr = pcall(function() return fnOrErr() end)
    if not ok3 then return nil, ("execute failed for %s -> %s"):format(url, safeStr(retOrErr)) end
    return retOrErr, nil
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

-- Load the shared auto_tab module once
local autoTabFn = nil
do
    local mod, err = safeLoadRemoteModule("tabs/auto_tab.lua")
    if not mod then
        warn("tab_manager: failed to load tabs/auto_tab.lua ->", safeStr(err))
    else
        -- Expect the module to return a function (the tab factory)
        if type(mod) == "function" then
            autoTabFn = mod
        elseif type(mod) == "table" and type(mod.Load) == "function" then
            -- support modules that return a table with a callable entry
            autoTabFn = function(Window, rank, Exclusions, tabName) return mod:Load(Window, rank, Exclusions, tabName) end
        else
            warn("tab_manager: tabs/auto_tab.lua returned unsupported type:", type(mod))
        end
    end
end

local Manager = {}

-- Minimal fallback tab creator
local function createEmptyTab(Window, name)
    local ok, Tab = pcall(function() return Window:CreateTab((name:gsub("^%l", string.upper)), 4483345998) end)
    if ok and Tab then
        pcall(function() Tab:CreateSection((name:gsub("^%l", string.upper) .. " Scripts")) end)
    end
end

function Manager:Load(Window)
    if not Window then
        warn("tab_manager: Load called without Window")
        return
    end

    -- Determine rank safely
    local rank = "None"
    if type(Rank) == "table" and type(Rank.GetRank) == "function" then
        local ok, r = pcall(function() return Rank:GetRank() end)
        if ok and r then rank = r end
    end

    for _, name in ipairs(tabs) do
        if type(autoTabFn) == "function" then
            local ok, err = pcall(function()
                -- call shared module with tab name
                autoTabFn(Window, rank, Exclusions, name)
            end)
            if not ok then
                warn(("tab_manager: auto_tab for %s errored -> %s"):format(name, safeStr(err)))
                createEmptyTab(Window, name)
            end
        else
            -- fallback: try to load per-tab file (legacy support)
            local path = "tabs/" .. name .. ".lua"
            local mod, err = safeLoadRemoteModule(path)
            if not mod then
                warn(("tab_manager: failed to load %s -> %s"):format(path, safeStr(err)))
                createEmptyTab(Window, name)
            else
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
                            createEmptyTab(Window, name)
                        end
                    else
                        warn(("tab_manager: module %s returned unsupported type: %s"):format(path, type(mod)))
                        createEmptyTab(Window, name)
                    end
                end)
                if not ok then
                    warn(("tab_manager: tab %s errored during execution -> %s"):format(name, safeStr(callErr)))
                    createEmptyTab(Window, name)
                end
            end
        end
    end
end

return Manager
