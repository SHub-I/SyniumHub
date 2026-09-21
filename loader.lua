-- Synium Hub Loader (Rayfield)

local base = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"

local function load(path)
    return loadstring(game:HttpGet(base .. path))()
end

-- Core
load("rank.lua")
load("rank_exclusions.lua")
load("tab_manager.lua")

-- Main Hub
load("main.lua")
