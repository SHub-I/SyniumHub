-- main.lua (robust, safe remote loading)
-- Synium Hub main entry with guarded remote loads and clear errors

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local useStudio = RunService:IsStudio() or false
local base = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"

local function fetchRaw(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res or #res == 0 then
        error("HttpGet failed for "..tostring(url).." -> "..tostring(res))
    end
    if res:match("^%s*<!DOCTYPE") then
        error("Remote returned unexpected content for "..tostring(url))
    end
    return res
end

local function safeLoadRemote(url)
    local content = fetchRaw(url .. "?ts=" .. tostring(os.time()))
    local ok, fn = pcall(function() return loadstring(content) end)
    if not ok or type(fn) ~= "function" then
        error("Failed to compile remote: "..tostring(url).." -> "..tostring(fn))
    end
    local ok2, ret = pcall(function() return fn() end)
    if not ok2 then
        error("Failed to execute remote: "..tostring(url).." -> "..tostring(ret))
    end
    return ret
end

-- Load Rayfield (correct raw URL)
local RayfieldURL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"
local Rayfield = safeLoadRemote(RayfieldURL)
if type(Rayfield) ~= "table" or type(Rayfield.CreateWindow) ~= "function" then
    error("Rayfield did not return a valid interface from "..RayfieldURL)
end

-- Create the main window
local Window = Rayfield:CreateWindow({
    Name = "Synium Hub",
    LoadingTitle = "Synium Hub",
    LoadingSubtitle = "by Syn",
    ConfigurationSaving = false,
    Discord = { Enabled = false, Invite = "", RememberJoins = false }
})

-- Load tab manager and initialize UI
local ok, TabManager = pcall(function() return safeLoadRemote(base .. "tab_manager.lua") end)
if not ok or not TabManager then
    warn("Failed to load tab_manager.lua:", TabManager)
else
    if type(TabManager.Load) == "function" then
        local success, err = pcall(function() TabManager:Load(Window) end)
        if not success then
            warn("TabManager:Load failed:", err)
        end
    elseif type(TabManager) == "function" then
        local success, err = pcall(function() TabManager(Window) end)
        if not success then
            warn("TabManager call failed:", err)
        end
    else
        warn("tab_manager.lua returned unexpected type:", type(TabManager))
    end
end

-- Optional: load other modules (rank, exclusions) safely for use by tabs
local function safeRequireRemote(path)
    local ok, mod = pcall(function() return safeLoadRemote(base .. path) end)
    if not ok then
        warn("Failed to load remote module:", path, mod)
        return nil
    end
    return mod
end

local Rank = safeRequireRemote("rank.lua") or {}
local Exclusions = safeRequireRemote("rank_exclusions.lua") or {}

-- Expose some API on Window for scripts to use (if desired)
if Window and type(Window.SetGlobal) == "function" then
    pcall(function()
        Window:SetGlobal("Rank", Rank)
        Window:SetGlobal("Exclusions", Exclusions)
    end)
end

-- Keep main.lua minimal; further remote loads should use safeLoadRemote.
