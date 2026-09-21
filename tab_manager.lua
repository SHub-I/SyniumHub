-- tab_manager.lua
-- Robust manager that loads a single reusable tabs/auto_tab.lua module and invokes it for each tab.
-- Provides a proxy Tab that sanitizes UI inputs to avoid "string expected, got table" errors.

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
        if type(mod) == "function" then
            autoTabFn = mod
        elseif type(mod) == "table" and type(mod.Load) == "function" then
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

-- Create a proxy wrapper around a real Rayfield Tab to sanitize inputs
local function makeSafeTabProxy(realTab)
    if not realTab then return nil end

    local proxy = {}
    -- forward everything by default
    setmetatable(proxy, {
        __index = function(_, key)
            return realTab[key]
        end,
        __newindex = function(_, k, v)
            realTab[k] = v
        end
    })

    -- sanitize CreateLabel
    proxy.CreateLabel = function(params)
        -- Accept either string or table { Text = "..." }
        if type(params) == "string" then
            pcall(function() realTab:CreateLabel({ Text = params }) end)
            return
        end
        if type(params) ~= "table" then
            -- convert to string
            local s = safeStr(params)
            pcall(function() realTab:CreateLabel({ Text = s }) end)
            warn("tab_manager: sanitized CreateLabel param (non-table) ->", s)
            return
        end
        local text = params.Text
        if type(text) ~= "string" then
            local s = safeStr(text)
            local safeParams = {}
            for k,v in pairs(params) do
                if k ~= "Text" then safeParams[k] = v end
            end
            safeParams.Text = s
            pcall(function() realTab:CreateLabel(safeParams) end)
            warn(("tab_manager: sanitized CreateLabel.Text for label; original type=%s; value=%s"):format(type(text), safeStr(text)))
            return
        end
        pcall(function() realTab:CreateLabel(params) end)
    end

    -- sanitize CreateSection (section name should be string)
    proxy.CreateSection = function(name)
        if type(name) ~= "string" then
            local s = safeStr(name)
            pcall(function() realTab:CreateSection(s) end)
            warn("tab_manager: sanitized CreateSection name ->", s)
            return
        end
        pcall(function() realTab:CreateSection(name) end)
    end

    -- sanitize CreateButton
    proxy.CreateButton = function(params)
        if type(params) ~= "table" then
            -- if user passed a string, treat as Name and create a no-op callback
            if type(params) == "string" then
                local name = params
                pcall(function() realTab:CreateButton({ Name = name, Callback = function() end }) end)
                return
            end
            local s = safeStr(params)
            pcall(function() realTab:CreateButton({ Name = s, Callback = function() end }) end)
            warn("tab_manager: sanitized CreateButton param (non-table) ->", s)
            return
        end

        local name = params.Name
        if type(name) ~= "string" then
            local s = safeStr(name)
            local safeParams = {}
            for k,v in pairs(params) do
                if k ~= "Name" then safeParams[k] = v end
            end
            safeParams.Name = s
            -- ensure Callback is a function
            if type(safeParams.Callback) ~= "function" then
                safeParams.Callback = function() end
                warn(("tab_manager: CreateButton for %s had non-function Callback; replaced with noop"):format(s))
            end
            pcall(function() realTab:CreateButton(safeParams) end)
            warn(("tab_manager: sanitized CreateButton.Name; original type=%s; value=%s"):format(type(name), safeStr(name)))
            return
        end

        -- ensure Callback is a function
        if type(params.Callback) ~= "function" then
            local safeParams = {}
            for k,v in pairs(params) do safeParams[k] = v end
            safeParams.Callback = function() end
            pcall(function() realTab:CreateButton(safeParams) end)
            warn(("tab_manager: CreateButton '%s' had non-function Callback; replaced with noop"):format(name))
            return
        end

        pcall(function() realTab:CreateButton(params) end)
    end

    return proxy
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

    -- Wrap Window.CreateTab so modules that call it get a safe proxy
    local originalCreateTab = Window.CreateTab
    local function createSafeTab(...)
        local ok, realTab = pcall(function() return originalCreateTab(...) end)
        if not ok or not realTab then
            return realTab
        end
        return makeSafeTabProxy(realTab)
    end

    -- If autoTabFn is available, use it for all tabs
    if type(autoTabFn) == "function" then
        for _, name in ipairs(tabs) do
            local ok, err = pcall(function()
                -- temporarily replace CreateTab on Window
                Window.CreateTab = createSafeTab
                -- call shared module with tab name
                autoTabFn(Window, rank, Exclusions, name)
                -- restore
                Window.CreateTab = originalCreateTab
            end)
            if not ok then
                warn(("tab_manager: auto_tab for %s errored -> %s"):format(name, safeStr(err)))
                -- restore CreateTab in case of error
                Window.CreateTab = originalCreateTab
                createEmptyTab(Window, name)
            end
        end
    else
        -- fallback: try to load per-tab file (legacy support)
        for _, name in ipairs(tabs) do
            local path = "tabs/" .. name .. ".lua"
            local mod, err = safeLoadRemoteModule(path)
            if not mod then
                warn(("tab_manager: failed to load %s -> %s"):format(path, safeStr(err)))
                createEmptyTab(Window, name)
            else
                local ok, callErr = pcall(function()
                    Window.CreateTab = createSafeTab
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
                    Window.CreateTab = originalCreateTab
                end)
                if not ok then
                    warn(("tab_manager: tab %s errored during execution -> %s"):format(name, safeStr(callErr)))
                    Window.CreateTab = originalCreateTab
                    createEmptyTab(Window, name)
                end
            end
        end
    end

    -- restore CreateTab to original just in case
    Window.CreateTab = originalCreateTab
end

return Manager
